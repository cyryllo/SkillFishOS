#!/usr/bin/env bash
# Install persistent Wake-on-LAN support on this box. Run as root.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this as root: sudo ./install.sh" >&2
  exit 1
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing ethtool"
apt-get update
apt-get install -y ethtool

echo "==> Installing the WoL-enable script"
install -m 0755 "$HERE/enable-wol.sh" /usr/local/bin/skillfish-enable-wol

echo "==> Installing systemd unit (runs at every boot)"
install -m 0644 "$HERE/systemd/skillfish-wol.service" /etc/systemd/system/skillfish-wol.service
systemctl daemon-reload
systemctl enable --now skillfish-wol.service

echo "==> Installing udev rule (re-applies on NIC add/replug)"
install -m 0644 "$HERE/udev/70-skillfish-wol.rules" /etc/udev/rules.d/70-skillfish-wol.rules
udevadm control --reload

echo
echo "Done. Check with: sudo ethtool <nic> | grep Wake-on   (should show 'g')"
echo
echo "IMPORTANT: on most boards the OS-side setting above is only half of it —"
echo "you also need Wake-on-LAN / PME enabled in the BIOS/UEFI firmware setup"
echo "for the machine to actually power on from a fully shut-down (S5) state."
echo "Without that, ethtool will happily report WoL as enabled but the board"
echo "will just stay off when a magic packet arrives."
