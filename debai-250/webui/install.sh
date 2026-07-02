#!/usr/bin/env bash
# Install the debai-250 browser tuner panel (skillfish-tunerd + tuner.html)
# on a bare Debian 13 box. Run as root. Requires ../tuning/install.sh to have
# been run first (this panel just shells out to skillfish-tuner-helper).
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this as root: sudo ./install.sh" >&2
  exit 1
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing skillfish-tunerd"
install -m 0755 "$HERE/skillfish-tunerd" /usr/local/bin/skillfish-tunerd

echo "==> Installing tuner.html"
mkdir -p /usr/share/skillfish/tunerd
install -m 0644 "$HERE/tuner.html" /usr/share/skillfish/tunerd/tuner.html

echo "==> Seeding /etc/skillfish/tunerd.json (skip if already present)"
mkdir -p /etc/skillfish
if [ ! -f /etc/skillfish/tunerd.json ]; then
  cat > /etc/skillfish/tunerd.json <<'EOF'
{
  "bind": "0.0.0.0",
  "port": 8443,
  "user": "skillfish",
  "modules": { "tuner": true }
}
EOF
fi
echo "    NOTE: set \"user\" above to the actual local Linux username you'll log in with."

echo "==> Installing systemd unit"
install -m 0644 "$HERE/systemd/skillfish-tunerd.service" /etc/systemd/system/skillfish-tunerd.service
systemctl daemon-reload
systemctl enable --now skillfish-tunerd.service

echo
echo "Done. Panel: https://<this-box-hostname-or-ip>:8443/ — self-signed cert,"
echo "log in with the local Linux username/password set in /etc/skillfish/tunerd.json."
echo "Make sure the tuning stack (../tuning/install.sh) is installed first, or every"
echo "action in the panel will fail against a missing skillfish-tuner-helper."
