# SkillFishOS APT repository — `aetherium`

The official SkillFishOS package repository (suite **`aetherium`**, matching
`VERSION_CODENAME=aetherium` in `/etc/os-release`). It lets installed systems receive the
SkillFishOS kernel, apps and themes **tested by us**, so Debian sid updates can't break the
BC-250 setup.

**Live at:** <https://mtsistemi.github.io/SkillFishOS/> — hosted on **GitHub Pages**
(branch `gh-pages` of this repo). GPG-signed.

## How the kernel is delivered (the 100 MB problem)

GitHub (repos *and* Pages) rejects any file over **100 MB**, and the
`linux-image-7.0.10-skillfishos` kernel `.deb` is **152 MB**. So:

- the kernel `.deb` lives as a **GitHub Release asset** (2 GB limit) at tag
  [`kernel-7.0.10-skillfishos`](https://github.com/MTSistemi/SkillFishOS/releases/tag/kernel-7.0.10-skillfishos);
- the APT pool ships a tiny **wrapper package** `skillfishos-kernel` (≈1.3 KB) whose
  `postinst` downloads that asset and installs it. So `apt install skillfishos-kernel`
  Just Works, and the whole repo still fits on GitHub Pages.

## User setup (end users)

```sh
# 1. import the signing key
sudo curl -fsSL https://mtsistemi.github.io/SkillFishOS/skillfishos-archive-keyring.gpg \
  -o /usr/share/keyrings/skillfishos-archive-keyring.gpg

# 2. add the repo (suite = aetherium)
echo "deb [signed-by=/usr/share/keyrings/skillfishos-archive-keyring.gpg] \
https://mtsistemi.github.io/SkillFishOS aetherium main" \
  | sudo tee /etc/apt/sources.list.d/skillfishos.list

# 3. update and install the kernel via apt
sudo apt update
sudo apt install skillfishos-kernel
```

On SkillFishOS the suite is `aetherium`; the Debian `sid` lines in `sources.list` are
independent and unaffected.

## Build / refresh (maintainer)

The repo is generated with **reprepro** on a Debian box (the BC-250 itself works):

```sh
sudo apt install reprepro gnupg curl
# conf/distributions in this folder defines suite 'aetherium', amd64, component main
reprepro -b <repo-dir> includedeb aetherium skillfishos-kernel_7.0.10-1_amd64.deb
reprepro -b <repo-dir> includedeb aetherium skillfish-tuner_*.deb   # as components get packaged
gpg --export apt@skillfishos.com > skillfishos-archive-keyring.gpg
```

Then publish `dists/`, `pool/` and the keyring to the `gh-pages` branch (Pages serves it).
A `.gitattributes` of `* -text` on that branch keeps the **GPG-signed** files byte-exact.
`build-repo.sh` automates keygen / add / export for a generic `public/` layout.

> ⚠️ Never commit the **private** signing key. It is backed up off-tree
> (`/root/skillfishos-apt-private.asc` on the build box) — keep an offline copy.

## What's published now

| Package | Version | Notes |
|---|---|---|
| `skillfishos-kernel` | 7.0.10-1 | wrapper → fetches the linux-tkg kernel from the Release |

Tuner, themes and configs will be added as native `.deb`s.
