# debai-250

*[Wersja polska: README.pl.md](README.pl.md)*

A minimal, standalone build for running the AMD BC-250 tuning stack on
**plain Debian 13**, without the rest of SkillFishOS's ISO/desktop pipeline.
Just three things:

1. **`kernel/`** — the patched linux-tkg kernel recipe (40 CU unlock, clock
   range unlock, boot-spam fix), pinned to an exact tag and scripted for a
   single-box build (no ISO, no GitHub-release meta-package).
2. **`tuning/`** — the CU/SMU/GPU-governor/fan control stack
   (`skillfish-tuner-helper` + `bc250_smu_oc` + `skillfish-cu` +
   `cyan-skillfish-governor`), extracted with several real wiring bugs fixed
   (see `tuning/README.md`) — the original had three different,
   mutually-inconsistent install paths for the same component, and a missing
   Python dependency that would have made the CPU-OC systemd service crash
   on start.
3. **`webui/`** — a browser-based control panel (`skillfish-tunerd`), a
   trimmed fork of SkillFishOS's web dashboard keeping only the tuner module,
   with a login screen added (the original tuner page had none — it relied
   entirely on a bigger SPA shell we're not using here), plus a small
   Wake-on-LAN status/toggle panel.
4. **`network/`** — persistent Wake-on-LAN: a systemd unit + udev rule that
   keep the primary NIC's magic-packet wake enabled across reboots (plain
   `ethtool -s wol g` alone doesn't survive a reboot). Generic — not
   BC-250-specific like the other three pieces.

Hardware assumption for `kernel/` and `tuning/`: an AMD BC-250 board. None of
that targets generic hardware — the kernel patches, SMU mailbox commands, and
CU/WGP register writes are all BC-250-specific. `webui/` and `network/` have
no such assumption baked in.

## Install order

```sh
cd kernel  && ./build.sh            # then reboot into the new kernel
cd ../tuning && sudo ./install.sh   # then build umr (required), optionally vkpeak
cd ../webui  && sudo ./install.sh
cd ../network && sudo ./install.sh
```

See each directory's own `README.md` for details, external dependencies not
resolved here (`umr`, optionally `vkpeak`, and an unresolved `bc250memcfg`
reference for VRAM resize), and verification steps.

Headless by default — the web panel is meant to be opened from another
device on the LAN, not on the box itself. See `docs/kde-optional.md` if you
want a local desktop later; it's not needed for anything else here.

## What's deliberately not carried over from SkillFishOS

- The ISO/live-build pipeline, first-run wizards, native Qt apps, app store,
  AI/Ollama stack, remote desktop/terminal, ZeroTier, and auto-rules — none
  of it is needed for "just the kernel and the tuner," and keeping it out
  keeps this directory small and easy to reason about. (Wake-on-LAN *is*
  carried over, in `network/` — see above.)
- The GitHub-release kernel distribution mechanism — irrelevant for a single
  personal box; build once, install the `.deb` directly.
- The passwordless polkit trust model for `skillfish-tuner-helper` **is**
  carried over as-is — this remains a personal-box design, not something to
  put on a network you don't fully trust.
