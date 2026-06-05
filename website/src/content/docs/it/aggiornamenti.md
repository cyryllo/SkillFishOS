---
title: Aggiornamenti e repository
description: Come SkillFishOs si aggiorna in sicurezza, senza farsi rompere da Debian sid.
group: Uso
order: 4
---

SkillFishOs è basato su **Debian sid** (*unstable*), il ramo di sviluppo di Debian: sempre aggiornato, ma per natura soggetto a regressioni occasionali. Su hardware "esotico" come la BC-250, un aggiornamento sbagliato (di Mesa, del firmware o del kernel) può rompere il sistema. SkillFishOs affronta questo problema con due strumenti.

## 1. Componenti nostri, da un repository dedicato

Le parti più critiche le costruiamo e distribuiamo **noi**, da un **repository APT proprio e firmato**:

- il **[kernel](/docs/kernel)** ottimizzato (immagine + headers);
- il **governor SMU** e gli strumenti di overclock;
- le **app native** [Tuner e AI](/docs/app-native);
- il **tema steampunk** e il **branding**;
- la configurazione di sistema.

Pubblicare un componente da un nostro repo significa poterlo **testare prima** sul ferro reale e aggiornarlo **solo quando porta benefici** — non quando capita a monte.

## 2. "Pinning" dei pacchetti fragili

Per i pacchetti che vengono da Debian ma che su questo hardware sono delicati, SkillFishOs usa l'**APT pinning**: li tiene a una versione **verificata** finché non ne testiamo una più recente. I principali candidati al pinning sono:

- **Mesa / driver Vulkan (RADV)** — un aggiornamento può regredire la `gfx1013`;
- **firmware AMD / `linux-firmware`** — microcodice della GPU;
- **kernel stock Debian** — per bloccare le versioni note problematiche (vedi [kernel](/docs/kernel));
- **KDE Plasma** — per evitare versioni instabili.

In questo modo gli aggiornamenti "normali" (la maggior parte del sistema) arrivano regolarmente, mentre la manciata di pacchetti che potrebbe rompere tutto resta congelata a versioni che sappiamo funzionare.

## Come si aggiorna

Come ogni sistema Debian, da terminale:

```bash
sudo apt update && sudo apt full-upgrade
```

…oppure dall'app grafica **Discover**. Grazie agli hook di [Snapper](/docs/storage-snapshot), **prima e dopo** ogni aggiornamento viene creato uno snapshot Btrfs: se qualcosa va storto, il rollback dal menu GRUB riporta il sistema allo stato precedente.

> In sintesi: **noi** ti diamo kernel, app e temi testati; **Debian** ti dà il resto del software aggiornato; il **pinning** evita le sorprese; **Btrfs** è la rete di sicurezza. Tre livelli di protezione, così aggiornare non fa paura.

## Architettura del server di aggiornamenti

Lato infrastruttura, il repository è un classico repo APT firmato (gestito con **[reprepro](https://salsa.debian.org/debian/reprepro)**) servito via HTTP, con il client che verifica la firma GPG tramite un *keyring* dedicato. Il sistema arriva già configurato per puntare al repository ufficiale di SkillFishOs.

## Fonti

- [Debian unstable (sid)](https://wiki.debian.org/DebianUnstable)
- [APT pinning — manuale Debian](https://wiki.debian.org/AptConfiguration)
- [reprepro](https://salsa.debian.org/debian/reprepro) — gestione di repository APT
- [Snapper](http://snapper.io/) — snapshot pre/post APT
