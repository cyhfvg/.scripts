#!/usr/bin/env bash
# Batch run fscan for ip:ports with xargs -P.
# Each line in input:  132.224.1.43:22,10050,17441,20048,55971
# - Always add -nobr to disable bruteforce
# - Avoid fscan -o; use shell redirection to create files safely

set -Eeuo pipefail
IFS=$'\n\t'

# ----------------------------
# Defaults
# ----------------------------
INPUT_FILE="ip_ports.txt"
FSCAN_BIN="${HOME}/.local/bin/fscan"
OUT_FILE="fscan_$(date +%Y%m%d_%H%M%S).txt"
PROCS=8                  # xargs -P
XARGS_VERBOSE=0          # use -t when =1
declare -a EXTRA_ARGS=()
NO_BRUTE_FLAG="-nobr"

usage() {
  cat <<'USAGE'
Usage:
  fscan_batch.sh [-i ip_ports.txt] [-b /path/to/fscan] [-o result.txt] [-P 8] [-t] [-x "<extra-args>"]...

Options:
  -i  Input file with lines like "IP:port1,port2,...". Default: ip_ports.txt
  -b  fscan binary path. Default: ~/.local/bin/fscan
  -o  Aggregated output file. Default: fscan_YYYYmmdd_HHMMSS.txt
  -P  Concurrency for xargs -P. Default: 8
  -t  Turn on xargs -t (echo commands as they run) for easier debugging
  -x  Extra args to pass to fscan (repeatable), e.g. -x "--timeout 5" -x "--nopoc"

Notes:
  - Script ALWAYS passes "-nobr" to disable bruteforce.
  - We do NOT use fscan's -o; stdout/stderr are redirected to per-target files by the shell.
USAGE
}

# ----------------------------
# Parse args
# ----------------------------
while getopts ":i:b:o:P:tx:h" opt; do
  case "$opt" in
    i) INPUT_FILE="$OPTARG" ;;
    b) FSCAN_BIN="$OPTARG" ;;
    o) OUT_FILE="$OPTARG" ;;
    P) PROCS="$OPTARG" ;;
    t) XARGS_VERBOSE=1 ;;
    x) EXTRA_ARGS+=("$OPTARG") ;;
    h) usage; exit 0 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage; exit 2 ;;
    :)  echo "Option -$OPTARG requires an argument." >&2; usage; exit 2 ;;
  esac
done

# ----------------------------
# Preflight
# ----------------------------
[[ -x "$FSCAN_BIN" ]] || { echo "[FATAL] fscan not executable: $FSCAN_BIN" >&2; exit 1; }
[[ -f "$INPUT_FILE" ]] || { echo "[FATAL] input file not found: $INPUT_FILE" >&2; exit 1; }

WORKDIR="$(mktemp -d -t fscan_batch_XXXXXX)"
trap 'rm -rf -- "$WORKDIR"' EXIT

EXTRA_STR=""
((${#EXTRA_ARGS[@]})) && EXTRA_STR="${EXTRA_ARGS[*]}"

echo "[INFO] fscan: $FSCAN_BIN"
echo "[INFO] input: $INPUT_FILE"
echo "[INFO] out  : $OUT_FILE"
echo "[INFO] procs: $PROCS (xargs -P)"
echo "[INFO] flag : $NO_BRUTE_FLAG"
[[ -n "$EXTRA_STR" ]] && echo "[INFO] extra: $EXTRA_STR"
(( XARGS_VERBOSE == 1 )) && echo "[INFO] xargs -t enabled"

# ----------------------------
# Validators
# ----------------------------
is_valid_ipv4() {
  local ip=$1
  [[ "$ip" =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9]{1,2})$ ]]
}
is_valid_portlist() {
  local plist=$1
  [[ "$plist" =~ ^[0-9,]+$ ]] || return 1
  IFS=',' read -r -a arr <<<"$plist"
  for p in "${arr[@]}"; do
    [[ "$p" =~ ^[0-9]+$ ]] && (( p>=1 && p<=65535 )) || return 1
  done
  return 0
}

# ----------------------------
# Build normalized target list: TSV "ip<TAB>ports"
# ----------------------------
TARGETS_TSV="${WORKDIR}/targets.tsv"
> "$TARGETS_TSV"

while IFS= read -r raw || [[ -n "$raw" ]]; do
  line="${raw%$'\r'}"
  # trim
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [[ -z "$line" || "$line" =~ ^# ]] && continue

  IFS=':' read -r ip ports <<<"$line"
  if ! is_valid_ipv4 "$ip"; then
    echo "[WARN] skip invalid IP: $ip"
    continue
  fi
  if ! is_valid_portlist "$ports"; then
    echo "[WARN] skip invalid port list for $ip: $ports"
    continue
  fi

  printf '%s\t%s\n' "$ip" "$ports" >> "$TARGETS_TSV"
done < "$INPUT_FILE"

[[ -s "$TARGETS_TSV" ]] || { echo "[FATAL] no valid targets parsed from $INPUT_FILE" >&2; exit 1; }

# ----------------------------
# Run with xargs -P
# - Feed each line (ip<TAB>ports) as one argument "{}"
# - Pass workdir/bin/flags/extras as fixed args
# - Redirect stdout/stderr to per-target file: ${ip}__p_${ports}.txt
# ----------------------------
XARGS_FLAGS=(-P "$PROCS" -n 1 -I{} )
(( XARGS_VERBOSE == 1 )) && XARGS_FLAGS+=(-t)

# shellcheck disable=SC2016
cat "$TARGETS_TSV" | xargs "${XARGS_FLAGS[@]}" bash -c '
line="$1"; workdir="$2"; fscan="$3"; nobr="$4"; extra="$5"

# parse "ip<TAB>ports"
ip="${line%%$'\''\t'\''*}"
ports="${line#*$'\''\t'\''}"
short_ports="${ports:0:20}"

# output file name per target; avoid collisions by embedding ports
outfile="${workdir}/${ip}__p_${short_ports//,/_}.txt"

# split extra string into array (no eval)
extras=()
if [[ -n "$extra" ]]; then
  read -r -a extras <<< "$extra"
fi

# run fscan; do NOT use -o; we redirect
"$fscan" -h "$ip" -p "$ports" "$nobr" "${extras[@]}" 1>"$outfile" 2>&1 \
  || { echo "[WARN] fscan failed for $ip:$ports" >&2; }
' _ '{}' "$WORKDIR" "$FSCAN_BIN" "$NO_BRUTE_FLAG" "$EXTRA_STR"

# ----------------------------
# Aggregate outputs
# ----------------------------
{
  # sort by IP “naturally”；文件名形如 1.2.3.4__p_22_80.txt
  for f in $(ls "$WORKDIR"/*.txt 2>/dev/null | sort -V); do
    base="$(basename "$f" .txt)"
    ip="${base%%__p_*}"
    ports="${base#*__p_}"; ports="${ports//_/','}"
    echo "==================== ${ip} (ports=${ports}) ===================="
    cat "$f"
    echo
  done
} > "$OUT_FILE"

echo "[OK] merged results -> $OUT_FILE"

