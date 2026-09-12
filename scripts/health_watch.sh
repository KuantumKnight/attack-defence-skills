#!/usr/bin/env bash
set -u

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 PORT [SYSTEMD_SERVICE] [INTERVAL_SECONDS]" >&2
  exit 2
fi

PORT="$1"
SERVICE="${2:-}"
INTERVAL="${3:-5}"

while true; do
  clear
  date -Is
  echo
  echo "=== listener :$PORT ==="
  ss -lntp 2>/dev/null | grep -E ":${PORT}([[:space:]]|$)" || echo "NOT LISTENING"
  echo
  echo "=== matching established connections ==="
  ss -antp 2>/dev/null | grep -E ":${PORT}([[:space:]]|$)" | head -40 || true
  echo
  echo "=== resources ==="
  uptime
  df -h / | tail -1
  free -h | sed -n '1,2p'
  if [ -n "$SERVICE" ]; then
    echo
    echo "=== systemd: $SERVICE ==="
    systemctl --no-pager --full status "$SERVICE" 2>/dev/null | sed -n '1,16p' || true
  fi
  echo
  echo "Ctrl-C to stop. Read-only monitor; no traffic blocking."
  sleep "$INTERVAL"
done