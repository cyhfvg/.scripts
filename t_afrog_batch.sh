#!/usr/bin/env bash
# Extract WebTitle URLs from fscan result and run afrog in parallel batches via xargs -P.
# - Input fscan result lines like:
#   [*] WebTitle http://132.254.115.80:8040 code:200 len:124    title:None
# - We extract the first http(s):// URL after "WebTitle".
# - Outputs go into: <OUT_ROOT>/html/*.html and <OUT_ROOT>/json/*.json

set -Eeuo pipefail
IFS=$'\n\t'

# ----------------------------
# Defaults (customize as needed)
# ----------------------------
INPUT_FILE="20250908_fscan_result.txt"   # your generated fscan result file
AFROG_BIN="${HOME}/.local/bin/afrog"     # path to afrog binary
OUT_ROOT="./output"                      # root output dir; will create html/ and json/ inside
PROCS=8                                  # xargs -P concurrency
BATCH_SIZE=50                            # URLs per batch file
XARGS_VERBOSE=0                          # -t echo commands (0 off / 1 on)
declare -a EXTRA_ARGS=()                 # extra args for afrog (repeatable)

usage() {
  cat <<'USAGE'
Usage:
  afrog_from_fscan.sh [-i fscan_result.txt] [-a /path/to/afrog] [-o ./output] [-P 8] [-B 50] [-t] [-x "<afrog-extra-args>"]...

Options:
  -i  fscan result file. Default: 20250908_fscan_result.txt
  -a  afrog binary path. Default: ~/.local/bin/afrog
  -o  Output root dir. Default: ./output  (html in ./output/html, json in ./output/json)
  -P  Concurrency for xargs -P. Default: 8
  -B  Batch size (URLs per batch). Default: 50
  -t  Enable xargs -t (echo commands) for debugging
  -x  Extra args for afrog (repeatable), e.g. -x "--no-color" -x "--concurrency 50"

Notes:
  - This script extracts only lines containing "WebTitle" and the first http(s):// URL in that line.
  - One afrog run per batch file: -T <batch> -output <html> -json <json>
  - Outputs are NOT merged; they are stored under the specified output directories.
USAGE
}

# ----------------------------
# Parse args
# ----------------------------
while getopts ":i:a:o:P:B:tx:h" opt; do
  case "$opt" in
    i) INPUT_FILE="$OPTARG" ;;
    a) AFROG_BIN="$OPTARG" ;;
    o) OUT_ROOT="$OPTARG" ;;
    P) PROCS="$OPTARG" ;;
    B) BATCH_SIZE="$OPTARG" ;;
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
[[ -x "$AFROG_BIN" ]] || { echo "[FATAL] afrog not executable: $AFROG_BIN" >&2; exit 1; }
[[ -f "$INPUT_FILE" ]] || { echo "[FATAL] input file not found: $INPUT_FILE" >&2; exit 1; }

OUT_HTML="${OUT_ROOT%/}/html"
OUT_JSON="${OUT_ROOT%/}/json"
mkdir -p "$OUT_HTML" "$OUT_JSON"

WORKDIR="$(mktemp -d -t afrog_from_fscan_XXXXXX)"
trap 'rm -rf -- "$WORKDIR"' EXIT

EXTRA_STR=""
((${#EXTRA_ARGS[@]})) && EXTRA_STR="${EXTRA_ARGS[*]}"

echo "[INFO] afrog: $AFROG_BIN"
echo "[INFO] input: $INPUT_FILE"
echo "[INFO] out  : $OUT_ROOT (html: $OUT_HTML , json: $OUT_JSON)"
echo "[INFO] procs: $PROCS  batch_size: $BATCH_SIZE"
[[ -n "$EXTRA_STR" ]] && echo "[INFO] extra: $EXTRA_STR"
(( XARGS_VERBOSE == 1 )) && echo "[INFO] xargs -t enabled"

# ----------------------------
# Extract URLs (http/https) from WebTitle lines
# Robust sed: match first URL after 'WebTitle'
# ----------------------------
URLS_ALL="${WORKDIR}/urls_all.txt"
URLS_DEDUP="${WORKDIR}/urls.txt"

# 1) filter WebTitle lines
# 2) extract first http(s)://... token after WebTitle
#    - use sed to capture URL; stop at first whitespace
grep -a -E '\bWebTitle\b' "$INPUT_FILE" \
  | sed -n 's/.*WebTitle[[:space:]]\+\(https\?:\/\/[^[:space:]]\+\).*/\1/p' \
  > "$URLS_ALL" || true

# Normalize (optional): strip trailing CR, dedup, keep stable order
awk '!seen[$0]++' "$URLS_ALL" > "$URLS_DEDUP" || true

URL_COUNT=$(wc -l < "$URLS_DEDUP" | tr -d '[:space:]' || echo 0)
if (( URL_COUNT == 0 )); then
  echo "[FATAL] no WebTitle URLs extracted from $INPUT_FILE" >&2
  exit 1
fi
echo "[INFO] extracted URLs: $URL_COUNT"

# ----------------------------
# Split into batches
# ----------------------------
BATCH_DIR="${WORKDIR}/batches"
mkdir -p "$BATCH_DIR"

# GNU split: -d numeric suffix, -l lines per file, prefix "batch_"
split -d -l "$BATCH_SIZE" "$URLS_DEDUP" "${BATCH_DIR}/batch_"

BATCH_COUNT=$(find "$BATCH_DIR" -maxdepth 1 -type f -name 'batch_*' | wc -l | tr -d '[:space:]')
echo "[INFO] batch files: $BATCH_COUNT (size=$BATCH_SIZE)"

# ----------------------------
# Run afrog per batch with xargs -P
# For each batch file:
#   afrog -T <batch_file> -output <OUT_HTML>/<batch_base>.html -json <OUT_JSON>/<batch_base>.json
# ----------------------------
XARGS_FLAGS=(-0 -P "$PROCS" -n 1 -I{} )
(( XARGS_VERBOSE == 1 )) && XARGS_FLAGS+=(-t)

# Build null-delimited list to handle any odd chars safely
find "$BATCH_DIR" -maxdepth 1 -type f -name 'batch_*' -print0 \
| xargs "${XARGS_FLAGS[@]}" bash -c '
set -Eeuo pipefail
batch="$1"; out_html="$2"; out_json="$3"; afrog="$4"; extra="$5"

base="$(basename "$batch")"
html="${out_html}/${base}.html"
json="${out_json}/${base}.json"

# turn the extra string into an array safely (no eval)
extras=()
if [[ -n "$extra" ]]; then
  read -r -a extras <<< "$extra"
fi

# Run afrog; afrog expected flags per user requirement:
#   -T <targets-file>  -output <html>  -json <json>
"$afrog" -T "$batch" -output "$html" -json "$json" "${extras[@]}" \
  || { echo "[WARN] afrog failed for batch: $batch" >&2; }
' _ '{}' "$OUT_HTML" "$OUT_JSON" "$AFROG_BIN" "$EXTRA_STR"

echo "[OK] all done. HTML => $OUT_HTML , JSON => $OUT_JSON"

