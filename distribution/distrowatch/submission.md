# DistroWatch — new distribution submission (draft)

Submit via DistroWatch's "Submit a distribution" page: <https://distrowatch.com/dwres.php?resource=submit>

## ⚠️ Read this first — alignment with DistroWatch's rules

DistroWatch only needs **four** things in the submission: project name, website URL, a short
description (incl. the base distro), and **a link to the installation media (ISO)**. But two
of its stated rules affect us directly:

1. **No cloud-storage downloads.** DistroWatch lists, among projects that are *not yet ready*,
   those offering *"non-transparent and/or 'unlinkable' download options, such as those from
   Google Drive, MEGA and other cloud storage services."*
   → Our masked `skillfishos.com/dl/…` link **302-redirects to Dropbox** — same category.
   **Do not submit the Dropbox link.** Host the ISO on a proper mirror first — **SourceForge**
   (DistroWatch-accepted; see `../sourceforge/UPLOAD.md`) — and submit *that* URL.
   The Dropbox-masked link is fine for the website; it is **not** fine for DistroWatch.

2. **Waiting list + maturity.** New distros go on a waiting list — *"be prepared for a
   year-long wait"* — and are expected to have *"proper infrastructure, including forums,
   mailing lists, documentation, bug tracking databases, etc."*
   → We have **docs** + **GitHub issues** (bug tracking). We do **not** have a forum or
   mailing list. Optional but it strengthens the submission: a Discussions/forum and a
   contact/mailing channel.

(There's also a paid fast-track: buy ≥100,000 ad impressions / $250 for immediate evaluation —
*no guarantee* of inclusion. Only if you want to skip the queue.)

## The 4 required fields

| Field | Value |
|---|---|
| **Project / distribution name** | SkillFishOS |
| **Website URL** | https://skillfishos.com |
| **Description (with base)** | Steampunk gaming Linux for the AMD BC-250, based on **Debian sid** + KDE Plasma 6 (see 100-word version below) |
| **ISO download link** | ⚠️ **SourceForge URL — upload first** (NOT the Dropbox-backed `skillfishos.com/dl/…`) |

## Useful extra context (DistroWatch fills the DB entry themselves)

- Origin: Italy · Architecture: x86_64 (amd64), BC-250-specific · Desktop: KDE Plasma 6
- Base: Debian unstable (sid) · Installer: Calamares · Packaging: APT/dpkg + Flatpak · Init: systemd
- Category: Desktop, Gaming, Live Medium · Release: 26.06 "Aetherium" · Status: Active
- License: open source (GPL-compatible) · Source: https://github.com/MTSistemi/SkillFishOS
- Screenshots: https://skillfishos.com/gallery

## Description (≈ 100 words)

SkillFishOS is a steampunk-themed gaming Linux distribution built specifically for the
AMD BC-250 — a salvaged, low-cost mining board carrying a semi-custom Zen 2 + RDNA 2 APU
(16 GB GDDR6). Based on Debian sid with KDE Plasma 6, it ships a custom linux-tkg kernel
that unlocks all 40 Compute Units, a dedicated SMU governor, CPU/GPU overclock and undervolt
profiles with thermal protection, Btrfs snapshots with one-click rollback, a full gaming and
emulation stack (Steam, EmuDeck, ES-DE, Heroic) and an on-device Vulkan AI stack. The system
boots in English with language selection at install. Open source; a generic x86-64 version is
planned. Not affiliated with AMD or any console manufacturer.
