#!/usr/bin/env bash
#
# fping_batch_scan.sh - 使用 fping 对超大规模 IP 列表做并发分片存活探测并汇总
#
# Usage:
#   ./fping_batch_scan.sh <ip_list_file> <output_file> [--chunk-size 10000] [--jobs auto] [--opts "<fping options>"]
#
# Example:
#   ./fping_batch_scan.sh ip_list.txt alive.txt --chunk-size 12000 --jobs 8 --opts "-a -q -t 800 -i 1 -p 10 -r 1"
#  ./t_fping_check_alive.sh ip_list.txt alive.txt  --chunk-size 8000 --jobs 4 --opts "-a -q -t 1000 -i 1 -p 20 -r 1"
#
# Notes:
#   1) <ip_list_file> 每行一个 IPv4 地址（不做 CIDR 展开）。
#   2) 需要已安装 fping。
#   3) 默认 fping 参数为: -a -q -t 800 -i 1 -p 10 -r 1
#      -a: 仅输出存活主机，-q: 静默，-t: 超时(ms), -i: 发包最小间隔(ms), -p: 重试间隔(ms), -r: 重试次数

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <ip_list_file> <output_file> [--chunk-size 10000] [--jobs auto] [--opts \"<fping options>\"]"
    exit 1
fi

INPUT_FILE="$1"; shift
OUTPUT_FILE="$1"; shift

# 默认参数
CHUNK_SIZE=10000
JOBS="auto"
FPING_OPTS='-a -q -t 800 -i 1 -p 10 -r 1'
# edit me
FPING_BIN='/home/user/.local/bin/fping'

# 解析可选参数
while (( "$#" )); do
  case "$1" in
    --chunk-size)
      CHUNK_SIZE="${2:?missing value for --chunk-size}"; shift 2 ;;
    --jobs)
      JOBS="${2:?missing value for --jobs}"; shift 2 ;;
    --opts)
      FPING_OPTS="${2:?missing value for --opts}"; shift 2 ;;
    *)
      echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# 依赖与输入检查
command -v $FPING_BIN >/dev/null 2>&1 || { echo "Error: fping not found"; exit 1; }
[ -f "$INPUT_FILE" ] || { echo "Error: input file '$INPUT_FILE' not found"; exit 1; }
[ -s "$INPUT_FILE" ] || { echo "Error: input file '$INPUT_FILE' is empty"; exit 1; }

# 并发度
if [ "$JOBS" = "auto" ]; then
  # 以 CPU 核数为基准，设上限 12，至少 2
  CPU="$( (command -v nproc >/dev/null 2>&1 && nproc) || getconf _NPROCESSORS_ONLN || echo 2 )"
  JOBS=$(( CPU < 2 ? 2 : ( CPU > 12 ? 12 : CPU ) ))
fi

# 临时目录与清理
TMPDIR="$(mktemp -d -t fping-batch-XXXXXXXX)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

# 分片
split -d -l "$CHUNK_SIZE" --additional-suffix=.txt "$INPUT_FILE" "$TMPDIR/chunk_"

# 并发执行：限制同时运行的后台任务数量为 $JOBS
run_chunk() {
  local chunk="$1"
  local out="$2"
  # 注意：-q 会把统计信息写到 stderr；我们只取 stdout 的存活列表
  # 如果你希望保留 fping 的统计，可把 2>> "$TMPDIR/fping_stats.log"
  sudo $FPING_BIN -f "$chunk" $FPING_OPTS > "$out" 2>> "$TMPDIR/fping_err.log" || true
}

active_jobs=0
for chunk in "$TMPDIR"/chunk_*.txt; do
  out="$TMPDIR/alive_$(basename "$chunk")"
  run_chunk "$chunk" "$out" &

  active_jobs=$((active_jobs + 1))
  # 控制并发，Bash 4.3+ 支持 wait -n
  if [ "$active_jobs" -ge "$JOBS" ]; then
    # 若系统不支持 wait -n，可退化为 wait（降低并发控制精度）
    if wait -n 2>/dev/null; then :; else wait; fi
    active_jobs=$((active_jobs - 1))
  fi
done

# 等待剩余任务
wait

# 汇总去重
cat "$TMPDIR"/alive_*.txt 2>/dev/null | awk 'NF' | sort -V -u > "$OUTPUT_FILE"

# 结果统计
TOTAL=$(wc -l < "$INPUT_FILE" | awk '{print $1}')
ALIVE=$(wc -l < "$OUTPUT_FILE" | awk '{print $1}')
CHUNKS=$(ls "$TMPDIR"/chunk_*.txt 2>/dev/null | wc -l | awk '{print $1}')

echo "==== Summary ===="
echo "Input IPs       : $TOTAL"
echo "Chunks          : $CHUNKS  (size=$CHUNK_SIZE)"
echo "Concurrency     : $JOBS"
echo "FPING options   : $FPING_OPTS"
echo "Alive count     : $ALIVE"
echo "Output file     : $OUTPUT_FILE"
cat $TMPDIR/fping_err.log
[ -s "$TMPDIR/fping_err.log" ] && echo "Note: fping stderr saved at $TMPDIR/fping_err.log (auto-removed on exit)"

