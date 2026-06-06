# SkillFishOS APT repository — `aetherium`

This folder builds the official SkillFishOS package repository (suite **`aetherium`**,
matching `VERSION_CODENAME=aetherium` in `/etc/os-release`). It lets installed systems
receive the SkillFishOS kernel, apps and themes **tested by us**, so Debian sid updates
can't break the BC-250 setup.

## Build (maintainer)

```sh
sudo apt install reprepro gnupg curl
cd distribution/apt
./build-repo.sh keygen      # one-time: create the signing key (then BACK UP the private key)
./build-repo.sh kernel      # add the linux-tkg kernel from the GitHub release
./build-repo.sh add path/to/skillfish-tuner_*.deb   # add other packages as they are built
```

The publishable repository is the `public/` directory:

```
public/
├── dists/aetherium/...     # Release (signed), Packages
├── pool/main/...           # .deb files
```

`skillfishos-archive-keyring.gpg` (+ `.asc`) is the **public** key users import.

## Hosting

The repo is just static files — host `public/` anywhere reachable over HTTPS:

| Host | Notes |
|---|---|
| **skillfishos.com/apt** | Cleanest. Point the web host at `public/`. Set `repoUrl` in the site accordingly. |
| **SourceForge file area** | Works; large files OK. Use the project's `apt/` path as base URL. |
| **GitHub Pages** | OK for metadata + small `.deb`s, **but** the kernel image `.deb` is ~152 MB and exceeds GitHub's 100 MB per-file limit → keep the kernel as a GitHub **Release asset** and host only the small packages here, *or* host the whole repo elsewhere. |

> ⚠️ Never commit the **private** signing key or the `public/pool` kernel blob to git.
> A `.gitignore` in this folder excludes `public/` and the private key.

## User setup (end users)

```sh
# 1. import the signing key
sudo curl -fsSL https://skillfishos.com/apt/skillfishos-archive-keyring.gpg \
  -o /usr/share/keyrings/skillfishos-archive-keyring.gpg

# 2. add the repo (suite = aetherium)
echo "deb [signed-by=/usr/share/keyrings/skillfishos-archive-keyring.gpg] \
https://skillfishos.com/apt aetherium main" \
  | sudo tee /etc/apt/sources.list.d/skillfishos.list

# 3. update
sudo apt update
```

On SkillFishOS the suite is detected from `VERSION_CODENAME` (`aetherium`); the Debian
`sid` lines in `sources.list` are independent and unaffected.
