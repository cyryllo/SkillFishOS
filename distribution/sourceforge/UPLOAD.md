# ISO upload checklist (SourceForge Files)

The Aetherium ISO is **5.6 GB** — too large for a GitHub Release asset (2 GB limit),
so the download is hosted on SourceForge (no size limit).

## Artifact (on the build box `192.168.5.40`)

```
/home/eggs/mnt/SkillFishOS-26.06-Aetherium-BC250-amd64.iso        (5.6 GB)
/home/eggs/mnt/SkillFishOS-26.06-Aetherium-BC250-amd64.iso.sha256
```

**SHA-256:**
```
8eea73d9dd23a1d8aa8fda3d8cc7639712b6391e2802282518c141145e1fce8c  SkillFishOS-26.06-Aetherium-BC250-amd64.iso
```

## Steps

1. SourceForge → project **Files** → create folder `26.06-Aetherium/`.
2. Upload the `.iso` and the `.iso.sha256` into that folder.
   - From the build box (fast): `scp /home/eggs/mnt/SkillFishOS-26.06-Aetherium-BC250-amd64.iso* user,skillfishos@frs.sourceforge.net:/home/frs/project/skillfishos/26.06-Aetherium/`
3. Set the `.iso` as the **default download** for Linux.
4. Add release notes (see `release-notes-26.06.md`).
5. Update the website download link:
   - `website/src/i18n.ts` → `SITE.isoUrl` → the SourceForge direct-download URL
     (e.g. `https://sourceforge.net/projects/skillfishos/files/26.06-Aetherium/SkillFishOS-26.06-Aetherium-BC250-amd64.iso/download`)
   - `SITE.isoSizeGb` → `5.6`
6. (Optional) keep the masked `skillfishos.com/dl/...` → 302 to SourceForge so the public
   URL stays stable across re-hosts.

## Verify after download

```sh
sha256sum -c SkillFishOS-26.06-Aetherium-BC250-amd64.iso.sha256
```
