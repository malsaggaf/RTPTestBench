#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  SUDO=sudo
else
  SUDO=
fi

export DEBIAN_FRONTEND=noninteractive

${SUDO} apt-get update -y
${SUDO} apt-get install -y --no-install-recommends \
  bash ca-certificates make \
  gstreamer1.0-tools \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-libav \
  iproute2 \
  tshark \
  python3 python3-pip

# Ensure tshark can capture without sudo (best-effort)
if command -v tshark >/dev/null 2>&1; then
  ${SUDO} groupadd -f wireshark || true
  ${SUDO} usermod -a -G wireshark "${SUDO:+$USER}" || true
  ${SUDO} dpkg-reconfigure wireshark-common || true
  ${SUDO} setcap cap_net_raw,cap_net_admin+eip "$(command -v dumpcap)" || true
fi

# Make scripts executable
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x docker/entrypoint.sh 2>/dev/null || true

echo "Dependencies installed. You may need to re-login for wireshark group changes."



