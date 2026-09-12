#!/usr/bin/env bash
set -u

OUT="${1:-$HOME/siege/notes}"
mkdir -p "$OUT"
TS="$(date +%Y%m%d-%H%M%S)"
REPORT="$OUT/triage-$TS.txt"

{
  echo "=== Siege of Servers quick triage ==="
  date -Is
  echo
  echo "=== identity ==="
  whoami
  hostname
  uname -a
  echo
  echo "=== addresses ==="
  ip -br addr
  echo
  ip route
  echo
  echo "=== listeners ==="
  ss -lntup
  echo
  echo "=== process tree ==="
  ps auxf
  echo
  echo "=== running systemd services ==="
  systemctl --type=service --state=running --no-pager 2>/dev/null || true
  echo
  echo "=== docker ==="
  docker ps -a 2>/dev/null || true
  echo
  echo "=== disk/memory ==="
  df -h
  df -i
  free -h
  echo
  echo "=== likely application markers ==="
  find /opt /srv /var/www /home -maxdepth 3 -type f \
    \( -name 'docker-compose.yml' -o -name 'compose.yml' -o -name 'Dockerfile' \
    -o -name 'package.json' -o -name 'requirements.txt' -o -name 'pyproject.toml' \
    -o -name 'go.mod' -o -name 'pom.xml' -o -name 'build.gradle' -o -name '*.jar' \) \
    -print 2>/dev/null | head -300
  echo
  echo "=== recent temp files ==="
  find /tmp /var/tmp -type f -mmin -30 -ls 2>/dev/null | head -200
} | tee "$REPORT"

echo
echo "Saved: $REPORT"
echo "This script does not scan opponents and does not modify firewall/traffic rules."