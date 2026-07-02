#!/usr/bin/env bash
# Build the debai-250 BC-250 kernel (linux-tkg + 3 patches) and install it
# directly on this box. See README.md for what this does and why.
#
# Run as a normal user with sudo available (not as root).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${WORK:-$HOME/debai-250-kernel-build}"
REPO_URL="https://github.com/Frogging-Family/linux-tkg"

if [ "$(id -u)" -eq 0 ]; then
  echo "Don't run this as root — it uses sudo where needed." >&2
  exit 1
fi

echo "==> Installing kernel build dependencies"
sudo apt-get update
sudo apt-get install -y build-essential flex bison libssl-dev libelf-dev \
  libncurses-dev dwarves bc rsync git

echo "==> Cloning linux-tkg into $WORK"
rm -rf "$WORK"
git clone --depth 1 "$REPO_URL" "$WORK"

echo "==> Installing customization.cfg"
cp "$HERE/customization.cfg" "$WORK/customization.cfg"

echo "==> Patching install.sh (drop the tkg- localversion prefix)"
sed -i 's/_kernel_flavor="tkg-\${_kernel_localversion}"/_kernel_flavor="${_kernel_localversion}"/' "$WORK/install.sh"
if ! grep -q '_kernel_flavor="${_kernel_localversion}"' "$WORK/install.sh"; then
  echo "!! Expected line not found in install.sh — linux-tkg may have changed." >&2
  echo "   Apply the tkg- prefix strip manually around line 176, then re-run." >&2
  exit 1
fi

echo "==> Installing BC-250 userpatches"
mkdir -p "$WORK/linux70-tkg-userpatches"
cp "$HERE"/userpatches/*.mypatch "$WORK/linux70-tkg-userpatches/"

echo "==> Building (this takes a while)"
cd "$WORK"
./install.sh install

echo "==> Installing the built kernel"
sudo dpkg -i DEBS/linux-image-*.deb DEBS/linux-headers-*.deb
sudo update-grub

echo
echo "Done. Reboot and confirm with: uname -r"
