# SkillFishOS apps

Small native apps shipped with SkillFishOS (KDE Plasma), all themed by Kvantum.

- **`tuner/`** — **SkillFishOS Tuner** (PyQt6): GUI to control the BC-250 hardware
  with no terminal — CPU OC/UV, GPU governor safe-point, fan, UMA VRAM split,
  40-CU toggle, with *apply → benchmark → verify/rollback* tests. `skillfish-tuner`
  is the GUI (→ `/usr/local/bin/`); `skillfish-tuner-helper` is the privileged
  daemon (JSON-per-line over a single `pkexec`).
- **`ai-panel/`** — **SkillFish AI** (PyQt6): one-click on/off for the on-device
  LLM stack (Ollama + Vulkan), freeing the GPU/RAM for gaming. See [../docs/AI.md](../docs/AI.md).
- **`iso-mount/`** — native KDE ISO mounting via udisks2 (no GNOME). See its README.

The Tuner/AI panels were originally GTK4/libadwaita; they were rewritten in PyQt6
so Kvantum themes them natively with no GTK CSS hacks.
