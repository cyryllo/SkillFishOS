# umr — AMD User Mode Register tool (required for CU/WGP control)

`skillfish-cu` (the script that actually routes Compute Units at runtime by
writing SPI/CC/RLC WGP mask registers) hard-depends on a `umr` binary at
`/usr/local/bin/umr`. Like `vkpeak`, this is an **undeclared dependency** in
the original SkillFishOS repo — it's never packaged or built by any hook, just
assumed to already be on the box.

**Likely upstream: `https://gitlab.freedesktop.org/tomstdenis/umr`** (AMD's
canonical User Mode Register debugging tool). *Verify this still resolves and
builds before relying on it* — same caveat as vkpeak.

## Build

```sh
sudo apt-get install -y cmake build-essential libpci-dev libelf-dev \
  python3-dev libreadline-dev
git clone https://gitlab.freedesktop.org/tomstdenis/umr /tmp/umr-src
cmake -S /tmp/umr-src -B /tmp/umr-src/build
cmake --build /tmp/umr-src/build -j"$(nproc)"
sudo install -m 0755 /tmp/umr-src/build/src/app/umr /usr/local/bin/umr
```

Without this, every CU/WGP action in `skillfish-cu` (and therefore the CU
grid / presets in the tuner) will fail — this one isn't optional the way
vkpeak is. Do this before running `tuning/install.sh`, or re-run
`skillfish-cu` actions manually afterward once `umr` is in place.
