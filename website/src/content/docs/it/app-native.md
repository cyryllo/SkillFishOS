---
title: App native — Tuner e AI
description: Gli strumenti grafici di SkillFishOs per controllare l'hardware e l'AI senza terminale.
group: Uso
order: 3
---

SkillFishOs include due applicazioni native (scritte in **PyQt6**, tematizzate con Kvantum) che mettono in mano all'utente il controllo dell'hardware e dello stack AI **senza toccare il terminale**.

## SkillFishOs Tuner

Il **Tuner** è il pannello di controllo dell'hardware. Permette di regolare:

- **overclock e undervolt della CPU**;
- **safe-point della GPU** (tramite il governor SMU, vedi [GPU e overclock](/docs/gpu-overclock));
- la **ventola** (controllo PWM);
- la **VRAM UMA** (richiede riavvio);
- l'attivazione delle **40 Compute Unit** (richiede riavvio).

La caratteristica più importante è il flusso **"Test"**: applica una modifica → esegue un benchmark (sysbench per la CPU, vkpeak per la GPU) → **verifica** la stabilità e, se qualcosa non va, fa il **rollback** automatico. Così si può spingere l'hardware in sicurezza.

Architettura: una GUI utente più un piccolo **daemon di root** che esegue le operazioni privilegiate. Su un PC personale è configurato per non richiedere password a ogni operazione.

## SkillFishOs AI

Il **pannello AI** accende e spegne lo stack LLM locale con un clic, liberando GPU e RAM per i giochi quando non serve. È il front-end "facile" dello stack descritto in [AI in locale](/docs/ai-locale).

## Perché esistono

L'obiettivo di SkillFishOs è che **chiunque** — compresi i più piccoli — possa usare e regolare il sistema senza dover imparare comandi da terminale. Queste app traducono operazioni complesse (governor SMU, parametri del kernel, container Docker) in pochi clic, mantenendo le **protezioni** (thermal-guard, test-and-rollback) sempre attive.

## Fonti

- [PyQt6 / Qt for Python](https://doc.qt.io/qtforpython/) · [Kvantum](https://github.com/tsujan/Kvantum)
- [sysbench](https://github.com/akopytov/sysbench) · [vkpeak](https://github.com/nihui/vkpeak)
- Repository del progetto — [github.com/MTSistemi/SkillFishOS](https://github.com/MTSistemi/SkillFishOS) (`apps/tuner`, `apps/ai-panel`)
