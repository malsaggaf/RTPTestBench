#!/usr/bin/env bash
set -euo pipefail

INTERVAL="${1:-1}"
COUNT="${2:-0}"

echo "Monitoring CPU for gst-launch-1.0 processes every ${INTERVAL}s (count=${COUNT:-inf})"
if command -v pidstat >/dev/null 2>&1; then
  pidstat -C gst-launch-1.0 ${INTERVAL} ${COUNT}
else
  echo "pidstat not found; falling back to top. Press q to quit."
  top -d "${INTERVAL}" -p $(pgrep -d',' -f gst-launch-1.0 || echo 1)
fi




