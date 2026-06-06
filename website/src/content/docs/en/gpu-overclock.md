---
title: GPU, governor and overclock
description: How SkillFishOS controls the BC-250's frequencies, voltages and temperatures.
group: System
order: 2
---

On a normal APU the GPU frequencies are tuned via the `amdgpu` sysfs. On the BC-250 **that's not how it works**: control goes through the **SMU** (System Management Unit) and requires a dedicated governor. SkillFishOS integrates one, already configured with safe profiles.

## The SMU governor

SkillFishOS uses the **[cyan-skillfish-governor](https://github.com/Magnap/cyan-skillfish-governor)** (written in Rust), installed as a system service with its configuration in `/etc/cyan-skillfish-governor/config.toml`. The governor defines frequency/voltage *safe-points*, e.g. 350/700 MHz at idle and **2000/1000** under load.

> ⚠️ **2000 MHz is the real safe-point**, not 2230. In testing (e.g. *Black Myth: Wukong*), 2230 MHz delivers the same FPS but runs hotter. 2230 MHz only makes sense for pure compute. The standard amdgpu sysfs does **not** control the BC-250: only the SMU governor does.

## The 40 Compute Units

With the 40 CUs active (see [kernel](/en/docs/kernel)) the GPU reaches ~**11.3 TFLOPS** FP32. VRAM is UMA: 8 GB by default, extendable with 5 GB of **GTT** so Vulkan sees ~13 GiB — see also [On-device AI](/en/docs/ai-locale).

## CPU overclock

The CPU can go up to **3700 MHz** at a voltage (Vid) ≤ **1.325 V**: that's the maximum stable value verified under 85 °C. Under **mixed CPU+GPU** load the APU tends to drop to ~3450 MHz: that's the chip's self-protection, not a defect.

The overclock is handled by a one-shot service (`bc250-smu-oc.service`) that applies the values from `/etc/bc250-smu-oc.conf` and then exits (showing as *inactive* after applying is normal). The underlying tool is the [bc250_smu_oc](https://github.com/bc250-collective/bc250_smu_oc) project.

## Thermal protection

A **thermal-guard** (watchdog) keeps the temperature under an 85 °C cap. Keep in mind:

- the stock cooling is **marginal**: back-to-back benchmark comparisons are invalid because of *heat-soak* (let it cool ~8 minutes between runs);
- only the GPU *edge* sensor exists; **no VRAM sensor**;
- memory bandwidth (~350–367 GB/s) is healthy but `mclk` is not adjustable.

## A practical case: CPU-bound games

Some titles, like *Black Myth: Wukong*, are **CPU/draw-call bound**: FPS depend neither on resolution nor GPU clock. In these cases there's no point lowering resolution or GPU frequency; what helps instead are CPU-side settings, the CPU overclock (already at 3700) and good cooling. For upscaling, FSR 4 is **not available** (it's RDNA 4 hardware); use gamescope (FSR1/NIS) or [OptiScaler](https://github.com/optiscaler/OptiScaler) per-game.

## All of this, without a terminal

Frequencies, undervolt, fan and Compute Units can also be tuned from the **Tuner** GUI, with ready presets and an automatic test — see [Native apps](/en/docs/app-native).

## Sources

- [cyan-skillfish-governor (Magnap)](https://github.com/Magnap/cyan-skillfish-governor)
- [bc250_smu_oc (bc250-collective)](https://github.com/bc250-collective/bc250_smu_oc)
- [bc250.info](https://bc250.info) — safe-points and thermal notes
- [clpeak](https://github.com/krrishnarraj/clpeak) · [vkpeak](https://github.com/nihui/vkpeak) — benchmark tools
