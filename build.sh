#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "=== SkillFish OS Build ==="
echo "Distribution: Debian forky | Desktop: Hyprland+DMS | Kernel: XanMod x64v3"
echo ""

# Prerequisites check
for cmd in lb debootstrap git curl gpg; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: '$cmd' is required. Run: apt-get install live-build debootstrap git curl gnupg"
        exit 1
    fi
done

# Run lb config (fetches keys, configures live-build)
echo ">>> Running auto/config ..."
bash auto/config

# Copy governor binaries into includes.chroot if they exist on the build host
GOV_SRC="/usr/local/bin/cyan-skillfish-governor-smu"
GOV_DEST="config/includes.chroot/usr/local/bin/cyan-skillfish-governor-smu"
if [ -x "$GOV_SRC" ] && [ ! -f "$GOV_DEST" ]; then
    mkdir -p "$(dirname "$GOV_DEST")"
    cp "$GOV_SRC" "$GOV_DEST"
    cp "/usr/local/bin/cyan-skillfish-performance-mode"        "config/includes.chroot/usr/local/bin/cyan-skillfish-performance-mode" 2>/dev/null || true
    echo "Governor binaries copied from build host."
fi

# Build
echo ">>> Running lb build ..."
lb build noauto 2>&1 | tee build.log
echo ""
echo "=== Build complete ==="
ls -lh skillfish-os*.iso 2>/dev/null || echo "Check build.log for errors."
