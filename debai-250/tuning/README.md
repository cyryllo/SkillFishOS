# debai-250 tuning stack — CU / SMU / GPU governor / fan control

Everything needed to set Compute Units, CPU clock/voltage, GPU safe-point
governor mode, and fan curve on a bare-Debian BC-250 box, extracted from
SkillFishOS and with its wiring bugs fixed. Run `./install.sh` as root once
the kernel from `../kernel/` is installed and you've rebooted into it.

## What's here and how it fits together

- **`bc250_smu_oc/`** — vendored CPU overclock/undervolt engine (talks to the
  SMU mailbox). Needs the upstream `bc250_smu` pip package, which
  `install.sh` puts in a dedicated venv at `/opt/bc250_smu_oc/venv` — **fixing
  a real bug**: the original repo's systemd unit called plain `python3`,
  which never has `bc250_smu` installed anywhere, so the service as shipped
  would raise `ModuleNotFoundError`. Also fixed: `skillfish-tuner-helper` had
  a third, different hardcoded path (`/root/bc250_smu_oc`) than the systemd
  unit's `/opt/bc250_smu_oc` and the ISO's pipx install — this repo now
  canonically uses `/opt/bc250_smu_oc` everywhere, with an `OC_PY` constant so
  the helper always calls the venv's interpreter.
- **`skillfish-tuner-helper`** — the privileged daemon everything else talks
  to (CPU OC, GPU governor mode, fan curve, CU rows, benchmarks). Started via
  polkit (see `os.skillfish.tuner.policy`), reads one JSON command per stdin
  line. This is what `webui/skillfish-tunerd` (the browser panel) shells out
  to as well.
- **`skillfish-cu`** — bash script that actually flips Compute Units at
  runtime via raw register writes, using AMD's `umr` tool. **`umr` is not
  vendored or built by this repo** — see `umr/README.md`, required before any
  CU action works.
- **`cyan-skillfish-governor/`** — prebuilt binary (vendored as-is, already
  compiled x86-64 ELF) + default `config.toml`: the GPU safe-point governor
  that ramps clock/voltage under load. `skillfish-tuner-helper` rewrites this
  TOML directly for Balanced/Performance mode and preset switching.
- **`skillfish-hud-val`** — sensor readout (temps) used by the fan-curve
  auto mode; not otherwise required.
- **`vkpeak/`** — optional, only used by the CU health-test and benchmark
  actions. Not vendored; see its own README for a build recipe. Everything
  else works fine without it (the helper degrades gracefully).
- **`udev-and-modules/`** — forces the mainline `nct6683` driver to bind the
  BC-250's NCT6686 SuperIO chip (`force=1`), which is what exposes fan
  RPM/PWM control at all.
- **`os.skillfish.tuner.policy`** — polkit action allowing local users to run
  `skillfish-tuner-helper` as root without a password prompt. This is a
  deliberate personal-box trust model (from the original repo) — don't put
  this box on a network you don't fully trust.

## Not resolved here

- **`umr`** — hard requirement for CU control, not packaged anywhere. See
  `umr/README.md`.
- **`vkpeak`** — optional, for benchmarks/CU health-test only. See
  `vkpeak/README.md`.
- **`bc250memcfg`** (VRAM/UMA resize) — referenced by `skillfish-tuner-helper`
  at `/root/bc250_memcfg/bc250memcfg`, but this tool doesn't exist anywhere in
  the original SkillFishOS repo either — nowhere to source it from was found.
  The set-vram action will just fail gracefully (`{"ok": false}`) until you
  track this down yourself.

## Install order

1. Build + boot the kernel from `../kernel/` first (CU unlock and clock range
   need the patched kernel; nothing here works right on a stock kernel).
2. `sudo ./install.sh`
3. Build `umr` (required) and optionally `vkpeak` — see their READMEs.
4. Reboot (loads `nct6683 force=1` for fan control) or
   `sudo modprobe nct6683 force=1` to pick it up immediately.
