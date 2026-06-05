---
title: The AMD BC-250 hardware
description: The board, the APU, its specs and its known hardware flaws.
group: Introduction
order: 2
---

The **AMD BC-250** is a compact board based on a **semi-custom APU** codenamed *Oberon* for the CPU and *Cyan Skillfish* for the graphics — the same silicon family as AMD's current-generation consoles. It was produced for mining systems (typically mounted several boards per chassis) and today shows up on the second-hand market at low prices.

## Key specifications

| Component | Detail |
|---|---|
| **CPU** | 6 cores / 12 threads **Zen 2** ("Oberon"), up to ~3.7 GHz overclocked |
| **GPU** | **RDNA 2** "Cyan Skillfish" (`gfx1013`), up to **40 Compute Units** unlockable |
| **Memory** | **16 GB GDDR6** shared (UMA) between CPU and GPU |
| **Compute** | ~**11.3 TFLOPS** FP32 at 40 CU / 2000 MHz (measured with vkpeak) |
| **Memory bandwidth** | ~350–367 GB/s (measured with clpeak) |
| **Video output** | 1× DisplayPort |

Memory is **unified**: the GDDR6 is shared between system and graphics. By default about 8 GB is assigned as VRAM, but on Linux the video space can be extended via the **GTT** (Graphics Translation Table), letting Vulkan see ~13 GiB of memory — especially useful for AI models.

## Unlocking the 40 CUs

By default the GPU exposes a reduced number of Compute Units. With a kernel parameter (`amdgpu.bc250_cc_write_mode=3`) it is possible to **unlock 40 CUs**, nearly doubling floating-point performance. The reverse-engineering work that made this unlock possible is documented by the [bc250-40cu-unlock](https://github.com/duggasco/bc250-40cu-unlock) project.

> With 40 CUs active, SkillFishOs measures **11385 GFLOPS** FP32 (vkpeak) from cold, versus ~6141 for a baseline 24-CU configuration: about **+85%**.

## Hardware flaws to know about

The BC-250 is repurposed "mining" hardware: it has some limitations that SkillFishOs works around in software. Knowing them explains many of the system's choices.

### Broken DisplayPort Hot-Plug Detect (HPD)

The monitor connection detection on the DisplayPort connector **does not work**: the board doesn't "see" when you plug in a screen. SkillFishOs solves this with a dedicated daemon (`skillfish-dp-hotswap`) that forces detection at boot and watches for monitor changes at runtime, plus the `video=DP-1:e` kernel parameter as a fallback. See [Desktop](/en/docs/desktop) and [Troubleshooting](/en/docs/risoluzione-problemi).

### Broken ACPI suspend

Suspend (**s2idle is broken**): the board goes to sleep but **does not wake up** and needs a reset. A suspended machine is also unreachable remotely. For this reason SkillFishOs **permanently disables** all sleep states (see [Desktop](/en/docs/desktop)). It is a mandatory measure.

### IOMMU unusable

The IOMMU on the BC-250 is unstable: it **must never be enabled**. The system always boots without IOMMU.

### Thermal sensors

Only the GPU *edge* temperature sensor is available; **there is no VRAM temperature sensor**. The stock cooling is marginal, so back-to-back benchmark comparisons are invalid (*heat-soak* effect): let the board cool down for a few minutes between runs.

## Sources

- [bc250.info](https://bc250.info) — community wiki
- [elektricm.github.io/amd-bc250-docs](https://elektricm.github.io/amd-bc250-docs) — technical documentation
- [bc250-40cu-unlock (duggasco)](https://github.com/duggasco/bc250-40cu-unlock) — Compute Unit unlock
- [bc250_memcfg (fanoush)](https://github.com/fanoush/bc250_memcfg) — memory configuration
- Linux `amdgpu` kernel driver — [docs.kernel.org/gpu/amdgpu](https://docs.kernel.org/gpu/amdgpu/)
