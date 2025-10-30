#!/usr/bin/env bash
set -euo pipefail
source cfg/.env 2>/dev/null || true

: "${IFACE:=lo}" "${DELAY_MS:=5}" "${JITTER_MS:=1}" "${LOSS_PCT:=0.0}"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then SUDO=sudo; else SUDO=; fi

${SUDO} tc qdisc replace dev "$IFACE" root netem delay ${DELAY_MS}ms ${JITTER_MS}ms loss ${LOSS_PCT}%
echo "Applied netem on $IFACE: delay=${DELAY_MS}ms jitter=${JITTER_MS}ms loss=${LOSS_PCT}%"




