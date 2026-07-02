#!/usr/bin/env bash
# Install the debai-250 CU/SMU/fan/GPU tuning stack on a bare Debian 13 box.
# Run as root (sudo). See tuning/README.md for what each piece does and for
# the external dependencies (umr, vkpeak) this script does NOT build for you.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this as root: sudo ./install.sh" >&2
  exit 1
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing packages needed by this stack"
apt-get update
apt-get install -y python3-venv python3-pip policykit-1

echo "==> Installing bc250_smu_oc into the canonical location: /opt/bc250_smu_oc"
mkdir -p /opt/bc250_smu_oc
cp "$HERE"/bc250_smu_oc/*.py /opt/bc250_smu_oc/
chmod +x /opt/bc250_smu_oc/*.py

echo "==> Creating a dedicated venv for bc250_smu_oc's bc250_smu dependency"
# WHY: the vendored bc250_apply.py/bc250_detect.py import `bc250_smu`, which is
# never installed system-wide anywhere in the original SkillFishOS repo either
# (its ISO hook uses pipx into its own venv, but the systemd unit and the
# tuner-helper both call plain `python3`, which doesn't have it — this venv
# plus the OC_PY constant in skillfish-tuner-helper fixes that mismatch).
python3 -m venv /opt/bc250_smu_oc/venv
/opt/bc250_smu_oc/venv/bin/pip install --upgrade pip
/opt/bc250_smu_oc/venv/bin/pip install "git+https://github.com/bc250-collective/bc250_smu_oc.git"

echo "==> Seeding /etc/bc250-smu-oc.conf (skip if already present)"
if [ ! -f /etc/bc250-smu-oc.conf ]; then
  cat > /etc/bc250-smu-oc.conf <<'EOF'
[overclock]
frequency = 3900
scale = -24
max_temperature = 85
EOF
fi

echo "==> Installing skillfish-tuner-helper, skillfish-cu, skillfish-hud-val"
install -m 0755 "$HERE/skillfish-tuner-helper" /usr/local/bin/skillfish-tuner-helper
install -m 0755 "$HERE/skillfish-cu" /usr/local/bin/skillfish-cu
install -m 0755 "$HERE/skillfish-hud-val" /usr/local/bin/skillfish-hud-val

echo "==> Installing cyan-skillfish-governor (prebuilt binary, vendored)"
install -m 0755 "$HERE/cyan-skillfish-governor/cyan-skillfish-governor" /usr/bin/cyan-skillfish-governor
mkdir -p /etc/cyan-skillfish-governor
[ -f /etc/cyan-skillfish-governor/config.toml ] || \
  install -m 0644 "$HERE/cyan-skillfish-governor/config.toml" /etc/cyan-skillfish-governor/config.toml

echo "==> Installing systemd units"
install -m 0644 "$HERE/systemd/bc250-smu-oc.service" /etc/systemd/system/bc250-smu-oc.service
install -m 0644 "$HERE/systemd/skillfish-cu.service" /etc/systemd/system/skillfish-cu.service
install -m 0644 "$HERE/systemd/cyan-skillfish-governor.service" /etc/systemd/system/cyan-skillfish-governor.service
mkdir -p /etc/systemd/system/cyan-skillfish-governor.service.d
install -m 0644 "$HERE/systemd/cyan-skillfish-governor.service.d/after-oc.conf" \
  /etc/systemd/system/cyan-skillfish-governor.service.d/after-oc.conf

echo "==> Installing fan/sensor module load config (nct6683, force=1)"
install -m 0644 "$HERE/udev-and-modules/skillfish-nct6686.modprobe.conf" /etc/modprobe.d/skillfish-nct6686.conf
install -m 0644 "$HERE/udev-and-modules/skillfish-nct6686.modules-load.conf" /etc/modules-load.d/skillfish-nct6686.conf

echo "==> Installing polkit policy (passwordless local exec of skillfish-tuner-helper)"
install -m 0644 "$HERE/os.skillfish.tuner.policy" /usr/share/polkit-1/actions/os.skillfish.tuner.policy

echo "==> Enabling services"
systemctl daemon-reload
systemctl enable --now bc250-smu-oc.service
systemctl enable --now skillfish-cu.service
systemctl enable --now cyan-skillfish-governor.service

echo
echo "Done. Still needed before everything works:"
echo "  - umr (required for any CU/WGP action) — see tuning/umr/README.md"
echo "  - vkpeak (optional, CU health-test + benchmarks only) — see tuning/vkpeak/README.md"
echo "  - bc250memcfg (optional, VRAM/UMA resize action only) — not sourced anywhere,"
echo "    see the MEMCFG comment at the top of skillfish-tuner-helper"
echo "  - load the fan module now (or reboot): modprobe nct6683 force=1"
