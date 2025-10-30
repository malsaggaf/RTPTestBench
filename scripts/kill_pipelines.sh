#!/usr/bin/env bash
set -euo pipefail

pkill -f gst-launch-1.0 || true
echo "Killed any running gst-launch-1.0 processes"




