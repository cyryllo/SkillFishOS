# debai-250 kernel build recipe (linux-tkg + BC-250 patches)

Standalone version of SkillFishOS's kernel recipe for a bare Debian 13 box —
no ISO/live-build, no GitHub-release meta-package. Just: clone linux-tkg,
drop in `customization.cfg` + the 3 patches, build a `.deb`, install it
directly with `dpkg -i`.

Tool: https://github.com/Frogging-Family/linux-tkg

## Before you build

`build.sh` installs these via apt, but if you're doing it by hand:

```
sudo apt-get install -y build-essential flex bison libssl-dev libelf-dev \
  libncurses-dev dwarves bc rsync git
```

Nothing in the original SkillFishOS repo actually listed these — only
DKMS-rebuild deps were documented there (for *after* the kernel exists), not
the kernel-build deps themselves.

## Pinning the version

`customization.cfg` here sets `_version="v7.0.11"` instead of the original
`"7.0-latest"`. The original build never recorded an exact upstream commit —
it cloned "latest" once and reused that same source tree for later point-bumps
— so this pin is a best-effort placeholder, **not a confirmed-working tag**.
Check that `v7.0.11` actually exists as a tag in the source linux-tkg pulls
from before relying on it; if it doesn't, pick the closest real tag and update
this file. The 40-CU patch (`0002-bc250-40cu-unlock.mypatch`) is a context
match against a specific `gfx_v10_0.c` revision and is the one most likely to
need re-fuzzing (`patch --fuzz` or a manual re-diff) if the exact tree
differs from what the patch was originally cut against.

## Steps

1. `git clone https://github.com/Frogging-Family/linux-tkg`
2. Copy this directory's `customization.cfg` over `linux-tkg/customization.cfg`.
3. Patch `linux-tkg/install.sh` around line 176:
   `_kernel_flavor="tkg-${_kernel_localversion}"` → `_kernel_flavor="${_kernel_localversion}"`
   (drops the `tkg-` prefix so `uname -r` reads `7.0.11-skillfishos` instead of
   `7.0.11-tkg-skillfishos`). Must be reapplied on every fresh linux-tkg clone.
4. Copy this directory's `userpatches/*.mypatch` into
   `linux-tkg/linux70-tkg-userpatches/`:
   - `0001-bc250-freq-unlock.mypatch` — SCLK 350–2230 MHz
   - `0002-bc250-40cu-unlock.mypatch` — 40 CU, opt-in via
     `amdgpu.bc250_cc_write_mode=3` boot param (from duggasco/bc250-40cu-unlock)
   - `0003-bc250-rdseed-quiet.mypatch` — drops cosmetic per-CPU
     `pr_emerg("RDSEED is not reliable...")` boot spam; RDSEED stays correctly
     disabled via `clear_cpu_cap`/`msr_clear_bit`, just silently
5. `./install.sh install` → `.deb`s land in `DEBS/`.
6. `sudo dpkg -i DEBS/linux-image-*.deb DEBS/linux-headers-*.deb`, then
   `sudo update-grub` and reboot.

`build.sh` in this directory scripts steps 1–6 end to end.

Key config carried over from SkillFishOS: BORE scheduler, GCC `-O3
-march=znver2`, 1000Hz tick, NTsync+fsync, no LTO, `localversion=skillfishos`.

Not carried over on purpose: the `skillfishos-kernel` GitHub-release
meta-package wrapper (`kernel-build/scripts/build-kernel-wrapper.sh` in the
main repo) — that exists to distribute a >100MB prebuilt kernel image past
GitHub's apt-pool size limit to *other* SkillFishOS machines. For a single
personal box, installing the locally-built `.deb` directly is simpler and has
no external dependency on a GitHub release existing.
