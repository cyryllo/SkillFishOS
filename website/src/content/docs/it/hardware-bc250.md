---
title: L'hardware AMD BC-250
description: La scheda, l'APU, le sue caratteristiche e i suoi difetti hardware noti.
group: Introduzione
order: 2
---

La **AMD BC-250** è una scheda compatta basata su un'**APU semi-custom** chiamata in codice *Oberon* per la parte CPU e *Cyan Skillfish* per la parte grafica — la stessa famiglia di silicio delle console AMD di generazione attuale. Fu prodotta per sistemi di mining (tipicamente montata in cestelli da più schede) e oggi si trova sul mercato dell'usato a prezzi contenuti.

## Specifiche principali

| Componente | Dettaglio |
|---|---|
| **CPU** | 6 core / 12 thread **Zen 2** ("Oberon"), fino a ~3.7 GHz in overclock |
| **GPU** | **RDNA 2** "Cyan Skillfish" (`gfx1013`), fino a **40 Compute Unit** sbloccabili |
| **Memoria** | **16 GB GDDR6** condivisa (UMA) tra CPU e GPU |
| **Potenza** | ~**11.3 TFLOPS** FP32 con 40 CU a 2000 MHz (misurato con vkpeak) |
| **Banda memoria** | ~350–367 GB/s (misurata con clpeak) |
| **Uscita video** | 1× DisplayPort |

La memoria è **unificata**: la GDDR6 è condivisa tra sistema e grafica. Di default circa 8 GB sono assegnati come VRAM, ma su Linux si può estendere lo spazio video sfruttando il **GTT** (Graphics Translation Table), arrivando a far vedere a Vulkan ~13 GiB di memoria — utile soprattutto per i modelli AI.

## Lo sblocco delle 40 CU

La GPU espone di default un numero ridotto di Compute Unit. Tramite un parametro del kernel (`amdgpu.bc250_cc_write_mode=3`) è possibile **sbloccare 40 CU**, quasi raddoppiando le prestazioni in virgola mobile. Il lavoro di reverse engineering che ha reso possibile questo sblocco è documentato dal progetto [bc250-40cu-unlock](https://github.com/duggasco/bc250-40cu-unlock).

> Con 40 CU attive SkillFishOS misura **11385 GFLOPS** FP32 (vkpeak) da freddo, contro i ~6141 di una configurazione baseline a 24 CU: un **+85%** circa.

## Difetti hardware da conoscere

La BC-250 è hardware "da mining" riadattato: ha alcuni limiti che SkillFishOS aggira via software. Conoscerli aiuta a capire molte scelte del sistema.

### Hot-Plug Detect (HPD) del DisplayPort rotto

Il rilevamento del collegamento del monitor sul connettore DisplayPort **non funziona**: la scheda non "vede" quando si attacca uno schermo. SkillFishOS risolve con un demone dedicato (`skillfish-dp-hotswap`) che forza il rilevamento all'avvio e monitora i cambi di monitor a runtime, più il parametro kernel `video=DP-1:e` come fallback. Vedi [Desktop](/docs/desktop) e [Risoluzione problemi](/docs/risoluzione-problemi).

### Sospensione (suspend) ACPI rotta

La sospensione **s2idle è guasta**: la scheda va in sospensione ma **non si risveglia** e richiede un reset. Inoltre una macchina sospesa è irraggiungibile da remoto. Per questo SkillFishOS **disabilita in modo permanente** tutti gli stati di sospensione (vedi [Desktop](/docs/desktop)). È una misura obbligatoria.

### IOMMU non utilizzabile

L'IOMMU sulla BC-250 è instabile: **non va mai abilitato**. Il sistema parte sempre senza IOMMU.

### Sensori termici

È disponibile solo il sensore di temperatura *edge* della GPU; **non esiste un sensore per la temperatura della VRAM**. Il raffreddamento di serie è marginale, quindi i confronti di benchmark "back-to-back" non sono validi (effetto *heat-soak*): tra una prova e l'altra conviene lasciare raffreddare la scheda alcuni minuti.

## Fonti

- [bc250.info](https://bc250.info) — wiki comunitaria
- [elektricm.github.io/amd-bc250-docs](https://elektricm.github.io/amd-bc250-docs) — documentazione tecnica
- [bc250-40cu-unlock (duggasco)](https://github.com/duggasco/bc250-40cu-unlock) — sblocco delle Compute Unit
- [bc250_memcfg (fanoush)](https://github.com/fanoush/bc250_memcfg) — configurazione della memoria
- Driver `amdgpu` del kernel Linux — [docs.kernel.org/gpu/amdgpu](https://docs.kernel.org/gpu/amdgpu/)
