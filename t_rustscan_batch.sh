#!/usr/bin/env bash
#
# t_rustscan_batch.sh - Batch rustscan greppable scan and merge open ports.
#
# Output files:
# - open_ports.csv  format: ip,port,proto,state,service
# - ip_ports.txt    format: ip:port1,port2,port3
#
# Greppable example:
#   127.0.0.1 -> [1716,22,52096,45703,40336]
#
set -euo pipefail
export LC_ALL=C

if [ $# -lt 2 ]; then
  echo "Usage: $0 <alive_ip_file> <out_dir> [--ports \"1-65535\" | --top 1000] [--chunk-size 256] [--jobs auto] [--batch-size 4096] [--ulimit 8192] [--rustscan-bin /path/to/rustscan]"
  exit 1
fi

ALIVE_FILE="$1"; shift
OUT_DIR="$1"; shift

# EDIT ME:
RUSTSCAN_BIN="/home/me/.local/bin/rustscan"
#

# Defaults
PORTS="1-65535"
TOP_PORTS=""
CHUNK_SIZE=256
JOBS="auto"
BATCH_SIZE=4096
ULIMIT_VAL=8192

require_cmd() {
  local bin="$1"
  command -v "$bin" >/dev/null 2>&1 || { echo "Error: '$bin' not found"; exit 1; }
}

warn() {
  echo "[WARN] $*" 1>&2
}

# Parse args
while (( "$#" )); do
  case "$1" in
    --ports)
      PORTS="${2:?missing value for --ports}"; TOP_PORTS=""; shift 2 ;;
    --top)
      TOP_PORTS="${2:?missing value for --top}"; PORTS=""; shift 2 ;;
    --chunk-size)
      CHUNK_SIZE="${2:?missing value for --chunk-size}"; shift 2 ;;
    --jobs)
      JOBS="${2:?missing value for --jobs}"; shift 2 ;;
    --batch-size)
      BATCH_SIZE="${2:?missing value for --batch-size}"; shift 2 ;;
    --ulimit)
      ULIMIT_VAL="${2:?missing value for --ulimit}"; shift 2 ;;
    --rustscan-bin)
      RUSTSCAN_BIN="${2:?missing value for --rustscan-bin}"; shift 2 ;;
    *)
      echo "Unknown arg: $1"
      exit 1 ;;
  esac
done

# Checks
for bin in awk paste split sort uniq cut wc ls grep sed; do
  require_cmd "$bin"
done
[ -f "$ALIVE_FILE" ] || { echo "Error: input file '$ALIVE_FILE' not found"; exit 1; }
[ -s "$ALIVE_FILE" ] || { echo "Error: input file '$ALIVE_FILE' is empty"; exit 1; }
[ -x "$RUSTSCAN_BIN" ] || { echo "Error: rustscan bin '$RUSTSCAN_BIN' not executable"; exit 1; }

# rustscan --top limitation
if [ -n "$TOP_PORTS" ] && [ "$TOP_PORTS" != "1000" ]; then
  echo "Error: rustscan --top only supports 1000. Use --ports for custom range."
  exit 1
fi

mkdir -p "$OUT_DIR"
TMPDIR="$(mktemp -d -t rustscan-batch-XXXXXXXX)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

# Auto jobs
if [ "$JOBS" = "auto" ]; then
  CPU="$( (command -v nproc >/dev/null 2>&1 && nproc) || getconf _NPROCESSORS_ONLN || echo 2 )"
  JOBS=$(( CPU < 2 ? 2 : ( CPU > 12 ? 12 : CPU ) ))
fi

# Split
split -d -l "$CHUNK_SIZE" --additional-suffix=.txt "$ALIVE_FILE" "$TMPDIR/chunk_"

# Parse greppable output to "ip,port" lines.
# Accept format: "IPv4 -> [p1,p2,...]".
extract_ip_port_pairs_csv() {
  local in_file="$1"
  local out_csv="$2"

  awk '
    {
      # Strictly match greppable line shape to avoid banners and logs.
      if (match($0, /^([0-9]{1,3}\.){3}[0-9]{1,3}[[:space:]]*->[[:space:]]*\[[0-9,[:space:]]*\][[:space:]]*$/)) {
        ip=$0
        sub(/[[:space:]]*->.*$/, "", ip)
        gsub(/[[:space:]]+/, "", ip)

        ports=$0
        sub(/^.*\[/, "", ports)
        sub(/\].*$/, "", ports)
        gsub(/[[:space:]]+/, "", ports)

        if (ports == "") next

        n=split(ports, p, ",")
        for (i=1; i<=n; i++) {
          if (p[i] ~ /^[0-9]+$/) {
            print ip "," p[i]
          }
        }
      }
    }
  ' "$in_file" \
    | sort -t, -k1,1V -k2,2n \
    | uniq > "$out_csv"
}

run_chunk() {
  local chunk_file="$1"
  local idx="$2"

  local target_csv
  target_csv="$(paste -sd, "$chunk_file")"

  local out_prefix="$OUT_DIR/rs_chunk_${idx}"
  local greppable_file="${out_prefix}.greppable.txt"
  local err_file="${out_prefix}.err"
  local ipport_csv="${out_prefix}.ipport.csv"

  # rustscan greppable scan, no nmap.
  if [ -n "$TOP_PORTS" ]; then
    sudo "$RUSTSCAN_BIN" -a "$target_csv" -b "$BATCH_SIZE" --ulimit "$ULIMIT_VAL" --top -g \
      >"$greppable_file" 2>"$err_file" || true
  else
    sudo "$RUSTSCAN_BIN" -a "$target_csv" -b "$BATCH_SIZE" --ulimit "$ULIMIT_VAL" -r "$PORTS" -g \
      >"$greppable_file" 2>"$err_file" || true
  fi

  extract_ip_port_pairs_csv "$greppable_file" "$ipport_csv"
}

# Parallel run
active_jobs=0
idx=0
for chunk in "$TMPDIR"/chunk_*.txt; do
  run_chunk "$chunk" "$idx" &
  active_jobs=$((active_jobs + 1))
  idx=$((idx + 1))

  if [ "$active_jobs" -ge "$JOBS" ]; then
    if wait -n 2>/dev/null; then :; else wait || true; fi
    active_jobs=$((active_jobs - 1))
  fi
done
wait || true

# Merge to open_ports.csv.
# rustscan only validates reachability of ports, protocol is tcp by nature of rustscan scanning.
# service is unknown here, keep empty.
MERGED_IPPORT="$TMPDIR/merged_ipport.csv"
cat "$OUT_DIR"/rs_chunk_*.ipport.csv 2>/dev/null \
  | sort -t, -k1,1V -k2,2n \
  | uniq > "$MERGED_IPPORT" || true

if [ -s "$MERGED_IPPORT" ]; then
  awk -F, '{ printf("%s,%s,tcp,open,\n", $1, $2) }' "$MERGED_IPPORT" > "$OUT_DIR/open_ports.csv"
else
  : > "$OUT_DIR/open_ports.csv"
fi

# Aggregate ip:ports
if [ -s "$OUT_DIR/open_ports.csv" ]; then
  cut -d, -f1,2 "$OUT_DIR/open_ports.csv" \
    | sort -t, -k1,1V -k2,2n \
    | uniq \
    | awk -F, '{
        if ($1 != ip) {
          if (ip != "") print ip ":" ports;
          ip=$1; ports=$2
        } else {
          ports = ports "," $2
        }
      } END { if (ip != "") print ip ":" ports }' \
    > "$OUT_DIR/ip_ports.txt"
else
  : > "$OUT_DIR/ip_ports.txt"
fi

# Stats
TOTAL_IPS=$(wc -l < "$ALIVE_FILE" | awk '{print $1}')
CHUNKS=$(ls "$TMPDIR"/chunk_*.txt 2>/dev/null | wc -l | awk '{print $1}')
OPEN_COUNT=$( [ -f "$OUT_DIR/open_ports.csv" ] && wc -l < "$OUT_DIR/open_ports.csv" | awk '{print $1}' || echo 0 )
LINES_IPPORT=$( [ -f "$OUT_DIR/ip_ports.txt" ] && wc -l < "$OUT_DIR/ip_ports.txt" | awk '{print $1}' || echo 0 )

echo "==== Summary ===="
echo "Alive IPs       : $TOTAL_IPS"
echo "Chunks          : $CHUNKS (size=$CHUNK_SIZE)"
echo "Concurrency     : $JOBS"
if [ -n "$TOP_PORTS" ]; then
  echo "Mode            : top-ports $TOP_PORTS"
else
  echo "Port range      : $PORTS"
fi
echo "Batch size      : $BATCH_SIZE"
echo "ulimit          : $ULIMIT_VAL"
echo "Open entries    : $OPEN_COUNT"
echo "IP:ports lines  : $LINES_IPPORT"
echo "Outputs:"
echo "  - CSV      : $OUT_DIR/open_ports.csv"
echo "  - Summary  : $OUT_DIR/ip_ports.txt"
