# Changelog

All notable changes to SkillFishOS. Dates are ISO-8601.

## [26.06 "Aetherium"] — 2026-06-07

### Kernel
- Updated the custom `linux-tkg` kernel to **`7.0.11-skillfishos`** (BORE, GCC `-O3`, 1000 Hz, NTsync + fsync, BC-250 patches: 350–2230 MHz clock unlock, 40-CU unlock, RDSEED boot-spam silenced).
- Now built in **three flavours**: **main** (`-march=znver2`, BC-250), **generic** (`-march=x86-64`, PCs & VMs) and **slim** (BC-250-only, lean module set).
- Published as GitHub Release `kernel-7.0.11-skillfishos`, and installable from the APT repo via the `skillfishos-kernel` wrapper (postinst fetches the full 152 MB `.deb` out-of-band, sidestepping GitHub Pages' 100 MB limit and the dpkg-in-postinst deadlock).

### ISOs
- Three installable editions for 26.06 "Aetherium" — **BC-250**, **Generic** and **Slim** — each ~6.2 GB, captured with penguins-eggs and verified to boot the matching kernel.
- Calamares installer now shows the release name **"SkillFishOS 26.06 Aetherium"** instead of the build date.
- First-boot service creates the Btrfs `.snapshots` subvolume and configures Snapper + grub-btrfs, so rollbacks appear in GRUB after the first updates.
- Published to **SourceForge Files** under `26.06-Aetherium/`.

### Apps (all shipped as updatable `.deb`s from the `aetherium` repo)
- **New — SkillFishOS Hub**: a native software centre that installs and updates SkillFishOS packages from our signed APT repo.
- **New — SkillFishOS Kernel Switch**: pick the boot kernel (set default / boot once) from a themed GUI.
- **New — SkillFishOS Monitor**: standalone live temperature / frequency / voltage / fan charts (extracted from the Tuner).
- **New — SkillFishOS menu**: a dedicated "SkillFishOS" submenu (via the `X-SkillFishOS` desktop category) that groups every native app.
- **AI Panel**: first-run setup wizard (installs the stack, picks a model from 38 options ≤14B), hardware readout (CPU/GPU/VRAM/RAM) and a shared-memory slider.

### Fixed
- **Apps would not launch from the KDE menu** — two distinct bugs:
  - desktop entries used a relative `Exec=`; KDE's launcher (KIO) has no `/usr/local/bin` on PATH, so it failed with *"Cannot find the program"*. All entries now use the absolute `/usr/local/bin/…` path.
  - `main()` called `Widget().show()` without keeping a Python reference, so the top-level window was garbage-collected immediately and stayed 1×1 / unmapped (invisible). Fixed by holding the reference and raising the window.
- **Monitor crash (SIGSEGV)** — `paintEvent` could leave a `QPainter` active on teardown; rewritten with a `begin()`-checked painter + `try/finally`, sensor sampling moved to a worker thread, and graceful `closeEvent` / SIGTERM shutdown.
- **Branding** — `os-release` no longer reverts to Debian on `apt upgrade` (dpkg-divert); KDE "About this system" shows *SkillFishOS 26.06 Aetherium*.

### Infrastructure
- Signed **`aetherium`** APT repository live at <https://mtsistemi.github.io/SkillFishOS/> (amd64 + i386), end-to-end update flow validated (`apt upgrade` pulls new kernel and app versions).
