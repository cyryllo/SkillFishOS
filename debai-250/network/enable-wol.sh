#!/usr/bin/env bash
# Enable Wake-on-LAN (magic packet) on the primary NIC. Meant to be run at
# boot by skillfish-wol.service (and again on NIC add by the udev rule),
# since some drivers reset the WoL flag on link renegotiation / re-probe.
set -euo pipefail

nic="$(ip -o route get 1.1.1.1 2>/dev/null | grep -oP 'dev \K\S+' || true)"
if [ -z "$nic" ]; then
  echo "enable-wol: couldn't determine the primary NIC, aborting" >&2
  exit 1
fi

if ! ethtool "$nic" 2>/dev/null | grep -q "Supports Wake-on"; then
  echo "enable-wol: $nic doesn't report Wake-on-LAN support (ethtool), skipping" >&2
  exit 0
fi

ethtool -s "$nic" wol g
echo "enable-wol: magic-packet WoL enabled on $nic"
