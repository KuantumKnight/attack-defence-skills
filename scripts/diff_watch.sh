#!/usr/bin/env bash
set -u

ROOT="${1:-.}"
INTERVAL="${2:-5}"

while true; do
  clear
  date -Is
  echo
  echo "=== git status ==="
  git -C "$ROOT" status --short 2>/dev/null || echo "not a git repo"
  echo
  echo "=== git diff --stat ==="
  git -C "$ROOT" diff --stat 2>/dev/null || true
  echo
  echo "=== recent files (15 min) ==="
  find "$ROOT" -type f -mmin -15 -printf '%TY-%Tm-%Td %TH:%TM:%TS %p\n' 2>/dev/null \
    | sort -r | head -80
  echo
  echo "Read-only watcher. Ctrl-C to stop."
  sleep "$INTERVAL"
done