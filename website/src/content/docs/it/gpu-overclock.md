---
title: GPU, governor e overclock
description: Come SkillFishOs controlla frequenze, tensioni e temperature della BC-250.
group: Sistema
order: 2
---

Su una APU normale le frequenze della GPU si regolano via sysfs `amdgpu`. Sulla BC-250 **non funziona così**: il controllo passa per l'**SMU** (System Management Unit) e richiede un governor dedicato. SkillFishOs ne integra uno, già configurato con profili sicuri.

## Il governor SMU

SkillFishOs usa il **[cyan-skillfish-governor](https://github.com/Magnap/cyan-skillfish-governor)** (scritto in Rust), installato come servizio di sistema con la sua configurazione in `/etc/cyan-skillfish-governor/config.toml`. Il governor definisce dei *safe-point* di frequenza/tensione, ad esempio 350/700 MHz a riposo e **2000/1000** sotto carico.

> ⚠️ **2000 MHz è il safe-point reale**, non 2230. Test alla mano (es. *Black Myth: Wukong*), a 2230 MHz si ottengono gli stessi FPS ma con più calore. I 2230 MHz hanno senso solo per il *compute* puro. Il sysfs amdgpu standard **non** controlla la BC-250: solo il governor SMU lo fa.

## Le 40 Compute Unit

Con le 40 CU attive (vedi [kernel](/docs/kernel)) la GPU raggiunge ~**11.3 TFLOPS** FP32. La VRAM è UMA: di base 8 GB, estendibili con 5 GB di **GTT** così che Vulkan veda ~13 GiB — vedi anche [AI in locale](/docs/ai-locale).

## Overclock della CPU

La CPU può salire fino a **3700 MHz** con tensione (Vid) ≤ **1.325 V**: è il massimo stabile verificato sotto gli 85 °C. Sotto carico **misto CPU+GPU** la APU tende a scendere a ~3450 MHz: è l'autoprotezione del chip, non un difetto.

L'overclock è gestito da un servizio one-shot (`bc250-smu-oc.service`) che applica i valori da `/etc/bc250-smu-oc.conf` e poi termina (il fatto che risulti *inactive* dopo l'applicazione è normale). Lo strumento di base è il progetto [bc250_smu_oc](https://github.com/bc250-collective/bc250_smu_oc).

## Protezione termica

Un **thermal-guard** (watchdog) tiene la temperatura sotto un tetto di **85 °C**. Da tenere a mente:

- il raffreddamento di serie è **marginale**: i confronti di benchmark back-to-back non sono validi per via dell'*heat-soak* (lasciar raffreddare ~8 minuti tra una prova e l'altra);
- esiste solo il sensore *edge* della GPU; **nessun sensore per la VRAM**;
- la banda di memoria (~350–367 GB/s) è sana ma il `mclk` non è regolabile.

## Un caso pratico: giochi CPU-bound

Alcuni titoli, come *Black Myth: Wukong*, sono **CPU/draw-call bound**: gli FPS non dipendono dalla risoluzione né dal clock della GPU. In questi casi non serve abbassare risoluzione o frequenza GPU; aiutano invece le impostazioni lato CPU, l'overclock CPU (già a 3700) e un buon raffreddamento. Per l'upscaling, FSR 4 **non è disponibile** (è hardware RDNA 4); si usano gamescope (FSR1/NIS) o [OptiScaler](https://github.com/optiscaler/OptiScaler) per-gioco.

## Tutto questo, senza terminale

Frequenze, undervolt, ventola e Compute Unit si regolano anche dalla GUI **Tuner**, con preset pronti e test automatico — vedi [App native](/docs/app-native).

## Fonti

- [cyan-skillfish-governor (Magnap)](https://github.com/Magnap/cyan-skillfish-governor)
- [bc250_smu_oc (bc250-collective)](https://github.com/bc250-collective/bc250_smu_oc)
- [bc250.info](https://bc250.info) — safe-point e note termiche
- [clpeak](https://github.com/krrishnarraj/clpeak) · [vkpeak](https://github.com/nihui/vkpeak) — strumenti di benchmark
