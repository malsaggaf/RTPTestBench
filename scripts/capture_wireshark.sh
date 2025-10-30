#!/usr/bin/env bash
set -euo pipefail
source cfg/.env 2>/dev/null || true

: "${PORT:=5000}" "${CAPTURE_DIR:=captures}" "${CAPTURE_FILE:=rtp.pcapng}"

mkdir -p "${CAPTURE_DIR}"
OUT_PATH="${CAPTURE_DIR}/${CAPTURE_FILE}"

if ! command -v tshark >/dev/null 2>&1; then
  echo "tshark not found. Install with: make install" >&2
  exit 1
fi

echo "Capturing RTP on port ${PORT} to ${OUT_PATH} (Ctrl+C to stop)"
tshark -i any -f "udp port ${PORT}" -w "${OUT_PATH}"




