#!/usr/bin/env bash
set -euo pipefail

source cfg/.env 2>/dev/null || true

: "${WIDTH:=1280}" "${HEIGHT:=720}" "${FPS:=30}" "${BITRATE_KBPS:=4000}" \
  "${PAYLOAD_TYPE:=96}" "${HOST:=127.0.0.1}" "${PORT:=5000}" \
  "${CLOCKOVERLAY_TEXT:=SRC}" "${SENDER_MODE:=unicast}" \
  "${MULTICAST_ADDR:=239.0.0.1}" "${MULTICAST_TTL:=1}" "${IFACE:=lo}"

SRC_ELEMENT="videotestsrc pattern=ball is-live=true"

# Optionally use v4l2src if VIDEO_SRC is set
if [[ -n "${VIDEO_SRC:-}" ]]; then
  SRC_ELEMENT="v4l2src device=${VIDEO_SRC} ! videorate"
fi

if [[ "$SENDER_MODE" == "multicast" ]]; then
  HOST="$MULTICAST_ADDR"
  SINK_ELEMENT="udpsink host=$HOST port=$PORT auto-multicast=true multicast-iface=$IFACE ttl=$MULTICAST_TTL"
else
  SINK_ELEMENT="udpsink host=$HOST port=$PORT"
fi

echo "Sending RTP/H264 to $HOST:$PORT ($SENDER_MODE)"

gst-launch-1.0 -v \
  $SRC_ELEMENT ! video/x-raw,width=$WIDTH,height=$HEIGHT,framerate=${FPS}/1 ! \
  queue ! clockoverlay halignment=left valignment=bottom text="${CLOCKOVERLAY_TEXT} " time-format="%H:%M:%S.%06N" shaded-background=true ! \
  x264enc tune=zerolatency speed-preset=ultrafast bitrate=$BITRATE_KBPS key-int-max=$FPS ! \
  video/x-h264,profile=baseline ! h264parse ! \
  rtph264pay pt=$PAYLOAD_TYPE config-interval=1 ! \
  $SINK_ELEMENT
