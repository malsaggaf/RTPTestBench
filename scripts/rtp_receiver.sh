#!/usr/bin/env bash
set -euo pipefail
source cfg/.env 2>/dev/null || true

: "${PORT:=5000}" "${PAYLOAD_TYPE:=96}" "${SINK_SYNC:=true}" \
  "${TIMEOVERLAY_TEXT:=SINK}" "${JITTERBUFFER_LATENCY_MS:=50}"

if [[ "${GST_LATENCY_TRACE:-0}" == "1" ]]; then
  export GST_TRACERS="latency"
  export GST_DEBUG="GST_TRACER:7"
  export GST_DEBUG_FILE="./gst_latency.log"
  echo "Latency tracer enabled; logs -> gst_latency.log"
fi

gst-launch-1.0 -v \
  udpsrc port=${PORT} caps="application/x-rtp, media=video, encoding-name=H264, payload=${PAYLOAD_TYPE}" ! \
  rtpjitterbuffer latency=${JITTERBUFFER_LATENCY_MS} drop-on-late=false ! \
  rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! \
  timeoverlay halignment=left valignment=bottom text="${TIMEOVERLAY_TEXT} " time-format="%H:%M:%S.%06N" shaded-background=true ! \
  fpsdisplaysink sync=${SINK_SYNC} text-overlay=true




