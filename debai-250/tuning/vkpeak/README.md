# vkpeak — Vulkan compute benchmark (CU health-test / benchmarks)

`skillfish-tuner-helper`'s CU health-test and GPU benchmark actions shell out
to a `vkpeak` binary. The original SkillFishOS repo never vendors or packages
it — the helper just globs a hardcoded dev-box path
(`/root/bench/vkpeak*/vkpeak`) that only ever existed on the box it was built
on. This is a real gap, not something carried over from a working recipe.

**Likely upstream: `https://github.com/nihui/vkpeak`** (a small Vulkan
compute peak-FLOPS benchmark). *This is unconfirmed — verify the repo exists
and still builds before relying on it.* If it's gone or renamed, any
comparable Vulkan compute micro-benchmark that reports sustained FLOPS will
do; `skillfish-tuner-helper` only cares about parsing a numeric score out of
stdout (check the `run_benchmark`/CU-health-test code path in
`../skillfish-tuner-helper` for the exact expected output format before
swapping tools).

## Build

```sh
sudo apt-get install -y cmake build-essential libvulkan-dev glslang-tools
git clone --depth 1 https://github.com/nihui/vkpeak /tmp/vkpeak-src
cmake -S /tmp/vkpeak-src -B /tmp/vkpeak-src/build
cmake --build /tmp/vkpeak-src/build -j"$(nproc)"
sudo install -m 0755 /tmp/vkpeak-src/build/vkpeak /opt/vkpeak/vkpeak
```

`skillfish-tuner-helper` looks for the binary at exactly `/opt/vkpeak/vkpeak`
(see `VKPEAK` near the top of the file) — install it there, or edit that
constant to match wherever you actually put it.

If you'd rather skip this for now: the helper checks `os.path.exists()` before
using `VKPEAK` and treats a missing binary as "benchmark/health-test
unavailable" rather than crashing — everything else in the tuning stack (CU
row selection, clocks, voltage, fan) works fine without it.
