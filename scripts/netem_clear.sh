#!/usr/bin/env bash
set -euo pipefail
source cfg/.env 2>/dev/null || true

: "${IFACE:=lo}"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then SUDO=sudo; else SUDO=; fi

${SUDO} tc qdisc del dev "$IFACE" root 2>/dev/null || true
echo "Cleared netem on $IFACE"




