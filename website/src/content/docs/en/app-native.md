---
title: Native apps — Tuner and AI
description: SkillFishOs's graphical tools for controlling hardware and AI without a terminal.
group: Usage
order: 3
---

SkillFishOs includes two native applications (written in **PyQt6**, themed with Kvantum) that put hardware and AI-stack control in the user's hands **without touching the terminal**.

## SkillFishOs Tuner

The **Tuner** is the hardware control panel. It lets you adjust:

- **CPU overclock and undervolt**;
- **GPU safe-points** (via the SMU governor, see [GPU and overclock](/en/docs/gpu-overclock));
- the **fan** (PWM control);
- the **UMA VRAM** (requires a reboot);
- enabling the **40 Compute Units** (requires a reboot).

Its most important feature is the **"Test"** flow: it applies a change → runs a benchmark (sysbench for the CPU, vkpeak for the GPU) → **verifies** stability and, if something is wrong, performs an automatic **rollback**. This lets you push the hardware safely.

Architecture: a user GUI plus a small **root daemon** that performs the privileged operations. On a personal PC it is configured not to ask for a password on every operation.

## SkillFishOs AI

The **AI panel** turns the local LLM stack on and off with one click, freeing GPU and RAM for games when not needed. It's the "easy" front-end of the stack described in [On-device AI](/en/docs/ai-locale).

## Why they exist

SkillFishOs's goal is that **anyone** — including the youngest — can use and tune the system without having to learn terminal commands. These apps translate complex operations (SMU governor, kernel parameters, Docker containers) into a few clicks, while keeping the **safeguards** (thermal-guard, test-and-rollback) always active.

## Sources

- [PyQt6 / Qt for Python](https://doc.qt.io/qtforpython/) · [Kvantum](https://github.com/tsujan/Kvantum)
- [sysbench](https://github.com/akopytov/sysbench) · [vkpeak](https://github.com/nihui/vkpeak)
- Project repository — [github.com/MTSistemi/SkillFishOS](https://github.com/MTSistemi/SkillFishOS) (`apps/tuner`, `apps/ai-panel`)
