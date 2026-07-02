# SkillFishOS Setup — konfigurator PL

Skrypt konfiguracyjny dla [SkillFishOS](https://github.com/MTSistemi/SkillFishOS) (Debian Sid + KDE Plasma, m.in. na AMD BC-250), który w jednym miejscu:

- ustawia **język polski** jako główny (z angielskim jako zapasowym),
- naprawia znane problemy świeżej instalacji (włoskie locale i katalogi),
- włącza **akcelerację GPU** dla panelu SkillFish AI (Ollama),
- **naprawia i spolszcza** panel SkillFish AI.

Skrypt jest interaktywny — po uruchomieniu pokazuje menu, z którego wybierasz pojedyncze opcje albo wykonujesz wszystko naraz.

## Wymagania

- SkillFishOS (Debian Sid + KDE Plasma)
- konto zwykłego użytkownika z dostępem do `sudo`
- do opcji 3 i 4: zainstalowany panel SkillFish AI (Docker + Ollama)

## Użycie

```bash
chmod +x skillfishos-setup.sh
./skillfishos-setup.sh
```

> **Ważne:** uruchamiaj jako **zwykły użytkownik**, nie przez `sudo`. Skrypt sam poprosi o hasło tam, gdzie potrzebne są uprawnienia administratora. Uruchomienie przez `sudo` jest blokowane, bo język i katalogi zostałyby ustawione dla roota zamiast dla Ciebie.

## Opcje menu

### 1) Język polski (główny) + angielski (zapasowy)

- generuje locale `pl_PL.UTF-8` i `en_US.UTF-8` (`/etc/locale.gen` + `locale-gen`),
- ustawia `LANG=pl_PL.UTF-8` oraz `LANGUAGE=pl_PL:en_US` w `/etc/environment` i `/etc/default/locale`, usuwając przy tym wpisy `it_IT`,
- ustawia język i formaty w KDE Plasma (`kwriteconfig6`/`kwriteconfig5`),
- tworzy polskie katalogi użytkownika (Dokumenty, Obrazy, Pobrane, Muzyka, Wideo, Pulpit, Publiczny, Szablony),
- przenosi dane z włoskich katalogów (Documenti, Immagini, Scaricati...) do polskich,
- poprawia zakładki w Dolphinie (`user-places.xbel`).

Dzięki `LANGUAGE=pl_PL:en_US` tam, gdzie brakuje polskiego tłumaczenia, system pokazuje angielskie zamiast włoskiego.

Po tej opcji wymagany jest **restart** — skrypt zaproponuje go na końcu.

### 2) Dodanie użytkownika do grupy docker

Dodaje bieżącego użytkownika do grupy `docker` (tworzy grupę, jeśli nie istnieje), dzięki czemu Docker działa bez `sudo`. Zmiana zaczyna działać po ponownym zalogowaniu lub restarcie.

### 3) GPU + obsługa 2 modeli w SkillFish AI

Dopisuje do usługi `ollama` w `/opt/stacks/skillfish-ai/compose.yaml`:

```yaml
environment:
  - OLLAMA_VULKAN=1
  - OLLAMA_IGPU_ENABLE=1
  - OLLAMA_MAX_LOADED_MODELS=2
```

- `OLLAMA_VULKAN=1` + `OLLAMA_IGPU_ENABLE=1` — modele liczą się na iGPU zamiast na CPU (rozwiązanie z [issue #14](https://github.com/MTSistemi/SkillFishOS/issues/14)),
- `OLLAMA_MAX_LOADED_MODELS=2` — pozwala trzymać w pamięci dwa modele naraz (o ile mieszczą się w budżecie VRAM+GTT).

Edycję YAML wykonuje wbudowany parser (Python), który rozpoznaje wcięcia i istniejący blok `environment` — nie psuje formatowania pliku. Jeśli ustalona ścieżka nie istnieje, skrypt sam pyta Dockera o plik compose kontenera `ollama`, a gdy nie ma ani pliku, ani kontenera — informuje, że panel AI nie jest jeszcze zainstalowany, i niczego nie zmienia. Na końcu proponuje przeładowanie stacka (`docker compose down && up -d`).

Weryfikacja po restarcie stacka (najpierw zadaj pytanie w Open WebUI, żeby model się załadował):

```bash
docker exec skillfish-ollama ollama ps
```

W kolumnie `PROCESSOR` powinno być `100% GPU` zamiast `100% CPU`.

### 4) Naprawa i spolszczenie panelu AI

Nakłada poprawki na plik `skillfish-ai-panel` (aplikacja PyQt6):

- **naprawa listy modeli** — po pobraniu pierwszego modelu katalog do pobrania znikał z listy; teraz lista pokazuje zainstalowane modele **oraz** katalog,
- **wyróżnienie zainstalowanych** — zainstalowane modele są na górze listy, zielone i pogrubione, oddzielone separatorem od katalogu,
- **przycisk usuwania** — nowy przycisk obok „Użyj" i „Pobierz" usuwa wybrany model (`ollama rm`) po potwierdzeniu,
- **polski interfejs** — przyciski, sekcje, statusy i komunikaty panelu po polsku, gdy język systemu jest polski (opcja 1); przy innym języku panel działa jak dotychczas (włoski/angielski).

Przed zmianą tworzona jest kopia zapasowa, a po zmianie plik jest sprawdzany przez `py_compile` — jeśli kompilacja się nie powiedzie, oryginał jest automatycznie przywracany. Po nałożeniu poprawki zamknij i otwórz panel ponownie.

### 5) Wykonaj wszystkie powyższe

Uruchamia opcje 1 → 2 → 3 → 4 po kolei. Jeden restart na końcu załatwia i zmianę języka, i aktywację grupy docker.

## Bezpieczeństwo

- Skrypt **nie usuwa danych użytkownika** — pliki z włoskich katalogów są przenoszone bez nadpisywania (`mv -n`), a stary katalog jest kasowany tylko wtedy, gdy jest pusty. Jeśli coś zostało, skrypt wypisuje ostrzeżenie do ręcznego sprawdzenia.
- Każdy modyfikowany plik (`/etc/environment`, `/etc/default/locale`, `compose.yaml`, `skillfish-ai-panel`, `user-places.xbel`) dostaje kopię zapasową `*.bak.<data-godzina>` obok oryginału.
- Wszystkie operacje są **idempotentne** — ponowne uruchomienie tej samej opcji wykrywa, że zmiany już są, i niczego nie psuje.
- Mimo to przed pierwszym uruchomieniem warto mieć kopię ważnych danych.

## Przywracanie zmian

Każdą zmianę można cofnąć z kopii zapasowej, np.:

```bash
sudo cp /etc/default/locale.bak.<data> /etc/default/locale
sudo cp /opt/stacks/skillfish-ai/compose.yaml.bak.<data> /opt/stacks/skillfish-ai/compose.yaml
sudo cp /usr/bin/skillfish-ai-panel.bak.<data> /usr/bin/skillfish-ai-panel
```

## Status projektu

Skrypt **nie będzie już rozwijany o kolejne funkcje** — pozostaje w obecnej formie jako gotowe narzędzie naprawcze. Dalsze poprawki i nowe funkcje będę wprowadzał bezpośrednio w repozytorium [SkillFishOS](https://github.com/MTSistemi/SkillFishOS) i wysyłał zmiany do autorów systemu (pull requesty), tak aby poprawki trafiły do oficjalnych wydań i skrypt przestał być potrzebny.

## Powiązane zgłoszenia

- [MTSistemi/SkillFishOS#11](https://github.com/MTSistemi/SkillFishOS/issues/11) — włoski język po instalacji
- [MTSistemi/SkillFishOS#14](https://github.com/MTSistemi/SkillFishOS/issues/14) — Ollama liczy na CPU zamiast GPU

## Licencja

Do użytku własnego — używasz na własną odpowiedzialność. Skrypt nie jest oficjalną częścią SkillFishOS.
