# Distribution

Everything needed to publish SkillFishOS **26.06 "Aetherium"** (BC-250 release).

| Folder | What | Who acts |
|---|---|---|
| [`apt/`](apt/) | APT repository (reprepro, suite `aetherium`, GPG-signed) + user install docs | maintainer builds; host on skillfishos.com / SourceForge |
| [`sourceforge/`](sourceforge/) | Project metadata, release notes, ISO upload checklist (+ SHA-256) | needs a SourceForge account |
| [`distrowatch/`](distrowatch/) | New-distribution submission draft | submit after the ISO is public |

## Order of operations

1. **Host the ISO** → `sourceforge/UPLOAD.md` (5.6 GB, exceeds GitHub's 2 GB → SourceForge).
2. **Point the site** at the new download URL (`website/src/i18n.ts` → `SITE.isoUrl`, `isoSizeGb`).
3. **Stand up the APT repo** → `apt/README.md` (`build-repo.sh keygen` → `kernel` → publish `public/`).
4. **Submit to DistroWatch** → `distrowatch/submission.md` (only after step 1 — they need a working download).

## Release facts (single source of truth)

- Version: **26.06**, codename **Aetherium**, suite/codename `aetherium`
- Target: **AMD BC-250** (amd64); generic x86-64 to follow
- ISO: `SkillFishOS-26.06-Aetherium-BC250-amd64.iso` — 5.6 GB
- SHA-256: `8eea73d9dd23a1d8aa8fda3d8cc7639712b6391e2802282518c141145e1fce8c`
- Boots English; language/keyboard chosen at install. Open source.
