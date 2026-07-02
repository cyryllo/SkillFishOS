# debai-250

*[English version: README.md](README.md)*

Minimalny, samodzielny build do uruchomienia stosu tuningowego AMD BC-250 na
**czystym Debianie 13**, bez reszty pipeline'u ISO/desktopu SkillFishOS.
Tylko trzy rzeczy:

1. **`kernel/`** — przepis budowy jądra linux-tkg z łatkami (odblokowanie
   40 CU, odblokowanie zakresu zegara, poprawka spamu przy starcie),
   przypięty do konkretnego tagu i zeskryptowany pod budowę na pojedynczej
   maszynie (bez ISO, bez paczki-wrappera z GitHub Releases).
2. **`tuning/`** — stos sterowania CU/SMU/governorem GPU/wentylatorem
   (`skillfish-tuner-helper` + `bc250_smu_oc` + `skillfish-cu` +
   `cyan-skillfish-governor`), wydzielony z naprawionymi kilkoma realnymi
   błędami w okablowaniu (zobacz `tuning/README.md`) — oryginał miał trzy
   różne, wzajemnie niespójne ścieżki instalacji tego samego komponentu oraz
   brakującą zależność Pythona, przez którą usługa systemd do OC CPU
   wywaliłaby się przy starcie.
3. **`webui/`** — panel sterowania w przeglądarce (`skillfish-tunerd`),
   okrojony fork webowego dashboardu SkillFishOS zachowujący tylko moduł
   tunera, z dodanym ekranem logowania (oryginalna strona tunera go nie miała
   — polegała w całości na większej powłoce SPA, której tutaj nie używamy),
   plus mały panel podglądu/przełącznika Wake-on-LAN.
4. **`network/`** — trwały Wake-on-LAN: usługa systemd + reguła udev, które
   utrzymują włączone budzenie magic-packet na głównej karcie sieciowej mimo
   restartów (samo `ethtool -s wol g` nie przeżywa restartu). Ogólne — nie
   specyficzne dla BC-250 jak pozostałe trzy elementy.

Założenie sprzętowe dla `kernel/` i `tuning/`: płytka AMD BC-250. Nic tam nie
jest pod sprzęt ogólnego przeznaczenia — łatki jądra, komendy mailboksa SMU i
zapisy rejestrów CU/WGP są specyficzne dla BC-250. `webui/` i `network/` nie
mają takiego założenia.

## Kolejność instalacji

```sh
cd kernel  && ./build.sh            # potem zrestartuj do nowego jądra
cd ../tuning && sudo ./install.sh   # potem zbuduj umr (wymagane), opcjonalnie vkpeak
cd ../webui  && sudo ./install.sh
cd ../network && sudo ./install.sh
```

Szczegóły, niezaspokojone tu zależności zewnętrzne (`umr`, opcjonalnie
`vkpeak`, oraz nierozwiązane odwołanie do `bc250memcfg`) i kroki weryfikacji
— zobacz `README.md` w każdym z podkatalogów (na razie tylko po angielsku).

Domyślnie bez środowiska graficznego (headless) — panel webowy ma być
otwierany z innego urządzenia w sieci LAN, nie na samej maszynie. Zobacz
`docs/kde-optional.md`, jeśli później zechcesz lokalny pulpit; nie jest on
potrzebny do niczego innego tutaj.

## Co celowo nie zostało przeniesione z SkillFishOS

- Pipeline ISO/live-build, kreatory pierwszego uruchomienia, natywne aplikacje
  Qt, sklep z aplikacjami, stos AI/Ollama, zdalny pulpit/terminal, ZeroTier i
  reguły automatyczne — nic z tego nie jest potrzebne do "samego jądra i
  tunera", a pominięcie tego utrzymuje ten katalog małym i łatwym do
  ogarnięcia. (Wake-on-LAN *jest* przeniesiony, w `network/` — zobacz wyżej.)
- Mechanizm dystrybucji jądra przez GitHub Releases — nieistotny dla
  pojedynczej prywatnej maszyny; buduje się raz i instaluje `.deb`
  bezpośrednio.
- Model zaufania polkit bez hasła dla `skillfish-tuner-helper` **jest**
  przeniesiony bez zmian — to nadal projekt pod prywatną maszynę, nie coś do
  postawienia w sieci, której w pełni nie ufasz.
