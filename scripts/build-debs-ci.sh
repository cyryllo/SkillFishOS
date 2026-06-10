#!/bin/bash
# Build the SkillFishOS app .debs from the repo sources (CI / clean machine).
# Unlike the on-box builders, every input comes from git — this catches the
# "stale binary packaged into a new version" failure mode before publishing.
set -euo pipefail
cd "$(dirname "$0")/.."
VER="${1:-0.0~ci$(date +%Y%m%d)}"
OUT="${OUT:-/tmp/sfx-debs}"
rm -rf "$OUT"; mkdir -p "$OUT/out"

put() { # put <pkg> <mode> <src> <dest-rel>
  [ -f "$3" ] || { echo "FATAL: missing source file $3" >&2; exit 1; }
  install -D -m "$2" "$3" "$OUT/$1/$4"
}
opt() { # like put, but optional
  [ -f "$3" ] && install -D -m "$2" "$3" "$OUT/$1/$4" || echo "  (optional, skipped: $3)"
}
ctrl() { # ctrl <pkg> <depends> <desc-first-line>
  mkdir -p "$OUT/$1/DEBIAN"
  printf 'Package: %s\nVersion: %s\nArchitecture: all\nMaintainer: SkillFishOS <info@skillfishos.com>\nDepends: %s\nSection: utils\nPriority: optional\nHomepage: https://skillfishos.com\nDescription: %s\n built from git by CI.\n' \
    "$1" "$VER" "$2" "$3" > "$OUT/$1/DEBIAN/control"
  printf '#!/bin/sh\nset -e\nupdate-desktop-database -q 2>/dev/null || true\ngtk-update-icon-cache -q -f /usr/share/icons/hicolor 2>/dev/null || true\nappstreamcli refresh-cache --force >/dev/null 2>&1 || true\nexit 0\n' > "$OUT/$1/DEBIAN/postinst"
  chmod 0755 "$OUT/$1/DEBIAN/postinst"
}
shot() { # shot <pkg> <metainfo-path>: install metainfo + its referenced screenshots
  put "$1" 0644 "$2" "usr/share/metainfo/$(basename "$2")"
  for s in $(grep -oE 'screenshots/[A-Za-z0-9._-]+' "$2" | sed 's#screenshots/##' | sort -u); do
    opt "$1" 0644 "screenshots/$s" "usr/share/skillfish/screenshots/$s"
  done
}

P=skillfish-tuner
put $P 0755 apps/tuner/skillfish-tuner            usr/local/bin/skillfish-tuner
put $P 0755 apps/tuner/skillfish-tuner-helper     usr/local/bin/skillfish-tuner-helper
put $P 0755 system/usr/local/bin/skillfish-cu     usr/local/bin/skillfish-cu
put $P 0755 system/usr/local/bin/skillfish-hud-val usr/local/bin/skillfish-hud-val
put $P 0755 system/usr/local/bin/skillfish-hud-bt usr/local/bin/skillfish-hud-bt
put $P 0644 system/usr/share/skillfish/tuner-presets.json usr/share/skillfish/tuner-presets.json
put $P 0644 system/usr/share/applications/os.skillfish.Tuner.desktop usr/share/applications/os.skillfish.Tuner.desktop
put $P 0644 system/usr/share/icons/hicolor/256x256/apps/skillfish-tuner.png usr/share/icons/hicolor/256x256/apps/skillfish-tuner.png
put $P 0644 system/etc/systemd/system/skillfish-cu.service etc/systemd/system/skillfish-cu.service
opt $P 0644 system/usr/share/polkit-1/actions/os.skillfish.tuner.policy usr/share/polkit-1/actions/os.skillfish.tuner.policy
shot $P apps/tuner/os.skillfish.Tuner.metainfo.xml
ctrl $P "python3, python3-pyqt6, polkitd | policykit-1" "SkillFishOS Tuner - BC-250 hardware control GUI"

P=skillfish-hub
put $P 0755 apps/hub/skillfish-hub        usr/local/bin/skillfish-hub
put $P 0755 apps/hub/skillfish-hub-helper usr/local/bin/skillfish-hub-helper
put $P 0644 system/usr/share/applications/os.skillfish.hub.desktop usr/share/applications/os.skillfish.hub.desktop
shot $P apps/hub/os.skillfish.hub.metainfo.xml
ctrl $P "python3, python3-pyqt6, python3-apt, gir1.2-appstream-1.0, appstream, curl, polkitd | policykit-1" "SkillFishOS Hub - Discover-style software centre"

P=skillfish-monitor
put $P 0755 apps/monitor/skillfish-monitor usr/local/bin/skillfish-monitor
put $P 0644 system/usr/share/applications/os.skillfish.monitor.desktop usr/share/applications/os.skillfish.monitor.desktop
shot $P apps/monitor/os.skillfish.monitor.metainfo.xml
ctrl $P "python3, python3-pyqt6" "SkillFishOS Monitor - live sensor charts"

P=skillfish-kernel-manager
put $P 0755 apps/kernel-manager/skillfish-kernel-manager usr/local/bin/skillfish-kernel-manager
put $P 0755 apps/kernel-manager/skillfish-kernel-helper  usr/local/bin/skillfish-kernel-helper
put $P 0644 system/usr/share/applications/os.skillfish.kernel.desktop usr/share/applications/os.skillfish.kernel.desktop
shot $P apps/kernel-manager/os.skillfish.kernel.metainfo.xml
ctrl $P "python3, python3-pyqt6, polkitd | policykit-1" "SkillFishOS Kernel Manager"

P=skillfish-ai-panel
put $P 0755 apps/ai-panel/skillfish-ai-panel usr/local/bin/skillfish-ai-panel
put $P 0755 apps/ai-panel/skillfish-gtt      usr/local/bin/skillfish-gtt
put $P 0644 system/usr/share/applications/os.skillfish.ai.desktop usr/share/applications/os.skillfish.ai.desktop
shot $P apps/ai-panel/os.skillfish.ai.metainfo.xml
ctrl $P "python3, python3-pyqt6, polkitd | policykit-1" "SkillFish AI - on-device LLM control panel"

P=skillfish-base
put $P 0755 system/usr/local/bin/skillfish-freeze-check.sh  usr/local/bin/skillfish-freeze-check.sh
put $P 0755 system/usr/local/bin/skillfish-freeze-notify.sh usr/local/bin/skillfish-freeze-notify.sh
put $P 0644 system/etc/systemd/system/skillfish-freeze-check.service etc/systemd/system/skillfish-freeze-check.service
put $P 0644 system/etc/xdg/autostart/skillfish-freeze-notify.desktop  etc/xdg/autostart/skillfish-freeze-notify.desktop
put $P 0644 system/etc/modules-load.d/skillfish-watchdog.conf         etc/modules-load.d/skillfish-watchdog.conf
put $P 0644 system/etc/systemd/system.conf.d/10-skillfish-watchdog.conf etc/systemd/system.conf.d/10-skillfish-watchdog.conf
ctrl $P "systemd, libnotify-bin" "SkillFishOS base - hardware watchdog + freeze detector"
# base needs its own postinst: enable the watchdog and the freeze check
printf '#!/bin/sh\nset -e\nif [ -d /run/systemd/system ]; then\n  systemctl daemon-reload || true\n  systemctl enable --now skillfish-freeze-check.service || true\n  modprobe sp5100_tco 2>/dev/null || true\n  systemctl daemon-reexec || true\nfi\nexit 0\n' > "$OUT/$P/DEBIAN/postinst"
chmod 0755 "$OUT/$P/DEBIAN/postinst"

echo "== building =="
for P in skillfish-tuner skillfish-hub skillfish-monitor skillfish-kernel-manager skillfish-ai-panel skillfish-base; do
  find "$OUT/$P" -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true
  dpkg-deb --root-owner-group --build "$OUT/$P" "$OUT/out/${P}_${VER}_all.deb" >/dev/null
done
ls -l "$OUT/out"

echo "== content verification (the bogus-deb guard) =="
check() { dpkg-deb --fsys-tarfile "$OUT/out/$1" | tar -xO "$2" | grep "$3" >/dev/null \
  && echo "OK  $1: $2 contains '$3'" || { echo "FAIL $1: $2 missing '$3'" >&2; exit 1; }; }
check skillfish-tuner_${VER}_all.deb         ./usr/local/bin/skillfish-tuner-helper  gov-mode
check skillfish-tuner_${VER}_all.deb         ./usr/local/bin/skillfish-tuner         gov_perf
check skillfish-hub_${VER}_all.deb           ./usr/local/bin/skillfish-hub           "return None"
check skillfish-kernel-manager_${VER}_all.deb ./usr/local/bin/skillfish-kernel-manager skillfish
check skillfish-ai-panel_${VER}_all.deb      ./usr/local/bin/skillfish-ai-panel       skillfish
check skillfish-base_${VER}_all.deb          ./usr/local/bin/skillfish-freeze-check.sh unclean-shutdown
check skillfish-tuner_${VER}_all.deb         ./usr/local/bin/skillfish-tuner          _silicon
echo "ALL DEBS VERIFIED"
