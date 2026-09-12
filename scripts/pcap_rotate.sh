#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 ANNOUNCED_PORT [OUT_DIR] [MB_PER_FILE] [FILE_COUNT]" >&2
  exit 2
fi

PORT="$1"
OUT="${2:-$HOME/siege/pcaps}"
SIZE_MB="${3:-40}"
COUNT="${4:-8}"

mkdir -p "$OUT"

echo "Capturing announced service port $PORT"
echo "Rotation: ${COUNT} files x ~${SIZE_MB}MB"
echo "Output: $OUT/service.pcap*"
echo "Ctrl-C to stop."

exec sudo tcpdump -i any -nn -s0 \
  -C "$SIZE_MB" -W "$COUNT" \
  -w "$OUT/service.pcap" \
  "port $PORT"