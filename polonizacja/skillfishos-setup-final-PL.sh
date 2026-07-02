#!/usr/bin/env bash
#
# skillfishos-setup.sh
# Narzędzie konfiguracyjne SkillFishOS z menu wyboru:
#   1) Ustawienie języka polskiego (główny) + angielskiego (zapasowy)
#   2) Dodanie bieżącego użytkownika do grupy docker
#   3) Włączenie GPU (Vulkan/iGPU) + obsługi 2 modeli dla SkillFish AI
#   4) Naprawa + polonizacja panelu AI (lista, usuwanie, wyróżnianie modeli)
#
# Uruchom JAKO ZWYKŁY UŻYTKOWNIK (nie przez sudo). Skrypt sam poprosi o hasło
# tam, gdzie potrzebne są uprawnienia administratora.
#
#   chmod +x skillfishos-setup.sh
#   ./skillfishos-setup.sh

set -uo pipefail

# --- Komunikaty --------------------------------------------------------------
B="\033[1m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; C="\033[1;36m"; N="\033[0m"
info(){ echo -e "${G}==>${N} ${B}$*${N}"; }
warn(){ echo -e "${Y}[uwaga]${N} $*"; }
err(){  echo -e "${R}[błąd]${N} $*"; }

# --- Zabezpieczenie: nie uruchamiaj jako root --------------------------------
# WHY: przez sudo $HOME wskazywałby katalog roota, a wtedy język i katalogi
#      użytkownika zostałyby założone w złym miejscu.
if [ "$(id -u)" -eq 0 ]; then
  err "Nie uruchamiaj przez sudo ani jako root. Uruchom jako zwykły użytkownik."
  exit 1
fi

USER_HOME="$HOME"
TS="$(date +%Y%m%d-%H%M%S)"
COMPOSE_FILE="/opt/stacks/skillfish-ai/compose.yaml"   # ustalona ścieżka
STACK_DIR="/opt/stacks/skillfish-ai"
NEED_REBOOT=0     # ustawiane przez zmianę języka
NEED_RELOGIN=0    # ustawiane przez dodanie do grupy docker

# =============================================================================
# FUNKCJA 1 — Język polski (główny) + angielski (zapasowy)
# =============================================================================
fn_language(){
  info "OPCJA 1 — Ustawianie języka polskiego (angielski jako zapasowy)"
  sudo -v

  # --- 1a. Wygeneruj locale pl_PL i en_US ------------------------------------
  info "Generowanie locale pl_PL.UTF-8 i en_US.UTF-8"
  sudo sed -i -E 's/^#\s*(pl_PL\.UTF-8 UTF-8)/\1/' /etc/locale.gen
  sudo sed -i -E 's/^#\s*(en_US\.UTF-8 UTF-8)/\1/' /etc/locale.gen
  grep -q '^pl_PL.UTF-8 UTF-8' /etc/locale.gen || echo 'pl_PL.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen >/dev/null
  grep -q '^en_US.UTF-8 UTF-8' /etc/locale.gen || echo 'en_US.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen >/dev/null
  sudo locale-gen

  # --- 1b. Ustaw locale systemowe --------------------------------------------
  info "Ustawianie locale w /etc/environment i /etc/default/locale"
  fix_locale_file(){
    local file="$1"
    [ -f "$file" ] || sudo touch "$file"
    sudo cp "$file" "${file}.bak.${TS}"
    sudo sed -i '/it_IT/d; /^LANG=/d; /^LANGUAGE=/d' "$file"
    echo 'LANG=pl_PL.UTF-8'     | sudo tee -a "$file" >/dev/null
    echo 'LANGUAGE=pl_PL:en_US' | sudo tee -a "$file" >/dev/null
  }
  fix_locale_file /etc/environment
  fix_locale_file /etc/default/locale
  echo "    Kopie zapasowe: *.bak.${TS}"

  # --- 1c. Ustaw język w KDE (zamiast klikania w ustawieniach) ---------------
  info "Ustawianie języka i formatów w KDE Plasma"
  local KW=""
  if command -v kwriteconfig6 >/dev/null 2>&1; then KW=kwriteconfig6
  elif command -v kwriteconfig5 >/dev/null 2>&1; then KW=kwriteconfig5
  fi
  if [ -n "$KW" ]; then
    "$KW" --file plasma-localerc --group Translations --key LANGUAGE "pl_PL:en_US"
    "$KW" --file plasma-localerc --group Formats      --key LANG     "pl_PL.UTF-8"
  else
    warn "Brak kwriteconfig — ustaw język ręcznie w Ustawieniach systemowych KDE."
  fi

  # --- 1d. Utwórz polskie katalogi użytkownika -------------------------------
  info "Tworzenie polskich katalogów (Dokumenty, Obrazy, Pobrane...)"
  rm -f "$USER_HOME/.config/user-dirs.dirs" "$USER_HOME/.config/user-dirs.locale"
  LANG=pl_PL.UTF-8 xdg-user-dirs-update --force

  # --- 1e. Przenieś dane z włoskich katalogów do polskich --------------------
  info "Przenoszenie danych z włoskich katalogów do polskich"
  move_contents(){
    # WHY: 'mv -n' nie nadpisuje istniejących plików; stary katalog kasujemy
    #      tylko gdy zrobił się pusty.
    local src="$USER_HOME/$1" dst="$USER_HOME/$2"
    [ -d "$src" ] || return 0
    [ "$src" = "$dst" ] && return 0
    mkdir -p "$dst"
    shopt -s dotglob nullglob
    local items=("$src"/*)
    [ "${#items[@]}" -gt 0 ] && mv -n "$src"/* "$dst"/ 2>/dev/null || true
    shopt -u dotglob nullglob
    if rmdir "$src" 2>/dev/null; then
      echo "    $1 -> $2"
    else
      warn "$1 nie jest pusty (część plików już istniała) — sprawdź ręcznie."
    fi
  }
  move_contents "Documenti" "Dokumenty"
  move_contents "Immagini"  "Obrazy"
  move_contents "Scaricati" "Pobrane"
  move_contents "Musica"    "Muzyka"
  move_contents "Video"     "Wideo"
  move_contents "Scrivania" "Pulpit"
  move_contents "Pubblici"  "Publiczny"
  move_contents "Modelli"   "Szablony"

  # --- 1f. Popraw zakładki w Dolphinie ---------------------------------------
  info "Poprawianie zakładek w Dolphinie"
  local PLACES="$USER_HOME/.local/share/user-places.xbel"
  if [ -f "$PLACES" ]; then
    cp "$PLACES" "${PLACES}.bak.${TS}"
    sed -i \
      -e 's#/Documenti#/Dokumenty#g' \
      -e 's#/Immagini#/Obrazy#g' \
      -e 's#/Scaricati#/Pobrane#g' \
      -e 's#/Musica#/Muzyka#g' \
      -e 's#/Video#/Wideo#g' \
      -e 's#/Scrivania#/Pulpit#g' \
      -e 's#/Pubblici#/Publiczny#g' \
      -e 's#/Modelli#/Szablony#g' \
      "$PLACES"
    echo "    Zaktualizowano zakładki (kopia: ${PLACES}.bak.${TS})"
  else
    echo "    Brak pliku zakładek — pomijam."
  fi

  NEED_REBOOT=1
  info "Język ustawiony. Pełny efekt po restarcie."
}

# =============================================================================
# FUNKCJA 2 — Dodanie użytkownika do grupy docker
# =============================================================================
fn_docker_group(){
  info "OPCJA 2 — Dodawanie użytkownika '$USER' do grupy docker"
  sudo -v

  # WHAT: utwórz grupę docker, jeśli jeszcze nie istnieje
  if ! getent group docker >/dev/null; then
    sudo groupadd docker
    echo "    Utworzono grupę docker."
  fi

  # WHAT: jeśli użytkownik już jest w grupie — nic nie rób
  if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    info "Użytkownik '$USER' już należy do grupy docker."
    return 0
  fi

  sudo usermod -aG docker "$USER"
  info "Dodano '$USER' do grupy docker."
  warn "Zmiana zadziała po wylogowaniu/restarcie."
  echo  "    (albo w bieżącym terminalu:  newgrp docker )"
  NEED_RELOGIN=1
}

# =============================================================================
# FUNKCJA 3 — Włączenie GPU (Vulkan/iGPU) w compose SkillFish AI
# =============================================================================
detect_docker(){
  # WHAT: ustala jak wołać docker/compose (z sudo czy bez)
  if docker ps >/dev/null 2>&1; then DOCKER="docker"
  elif sudo docker ps >/dev/null 2>&1; then DOCKER="sudo docker"
  else err "Docker nie odpowiada. Czy usługa jest uruchomiona?"; return 1; fi
  if $DOCKER compose version >/dev/null 2>&1; then COMPOSE="$DOCKER compose"
  elif command -v docker-compose >/dev/null 2>&1; then COMPOSE="docker-compose"
  else COMPOSE="$DOCKER compose"; fi
}

write_yaml_editor(){
  # WHY: edycję YAML robi Python, bo trzeba rozpoznać wcięcia i istniejący
  #      blok environment — sed by tu łatwo popsuł strukturę pliku.
  TMP_PY="$(mktemp --suffix=.py)"
  cat > "$TMP_PY" <<'PYEOF'
import sys, re
path = sys.argv[1]
WANT = [("OLLAMA_VULKAN","1"), ("OLLAMA_IGPU_ENABLE","1"), ("OLLAMA_MAX_LOADED_MODELS","2")]
with open(path) as f: lines = f.readlines()
n = len(lines)
def ind(s): return len(s)-len(s.lstrip(' '))
def blank(s): return s.strip()=="" or s.lstrip().startswith("#")

services_idx=None
for i,l in enumerate(lines):
    if ind(l)==0 and re.match(r'^services\s*:\s*$', l): services_idx=i; break
if services_idx is None: print("NO_SERVICES"); sys.exit(3)
svc_end=n
for i in range(services_idx+1,n):
    if blank(lines[i]): continue
    if ind(lines[i])==0: svc_end=i; break

svc_idx=None; svc_indent=None
for i in range(services_idx+1, svc_end):
    m=re.match(r'^(\s*)ollama\s*:\s*$', lines[i])
    if m: svc_idx=i; svc_indent=len(m.group(1)); break
if svc_idx is None: print("NO_OLLAMA"); sys.exit(3)

blk_start=svc_idx+1; blk_end=svc_end
for i in range(blk_start, svc_end):
    if blank(lines[i]): continue
    if ind(lines[i])<=svc_indent: blk_end=i; break

child_indent=svc_indent+2
for i in range(blk_start, blk_end):
    if not blank(lines[i]): child_indent=ind(lines[i]); break

env_idx=None; env_inline=""
for i in range(blk_start, blk_end):
    m=re.match(r'^(\s*)environment\s*:(.*)$', lines[i])
    if m and ind(lines[i])==child_indent: env_idx=i; env_inline=m.group(2).strip(); break

def as_list(k,v,w): return " "*w+f"- {k}={v}\n"
def as_map(k,v,w):  return " "*w+f'{k}: "{v}"\n'

if env_idx is None:
    block=[" "*child_indent+"environment:\n"]
    for k,v in WANT: block.append(as_list(k,v,child_indent+2))
    lines[svc_idx+1:svc_idx+1]=block
    with open(path,"w") as f: f.writelines(lines)
    print("ADDED_ENV"); sys.exit(0)

if env_inline[:1] in ("[","{"): print("MANUAL_INLINE"); sys.exit(4)

present=set(); style=None; child_ind=None; last_real=env_idx
i=env_idx+1
while i<blk_end:
    l=lines[i]
    if blank(l): i+=1; continue
    if ind(l)<=ind(lines[env_idx]): break
    if child_ind is None: child_ind=ind(l)
    s=l.strip()
    if s.startswith("- "):
        style="list"; body=s[2:].strip().strip('"\'')
        present.add(re.split(r'[=:]', body,1)[0].strip())
    else:
        style=style or "map"; present.add(s.split(":",1)[0].strip())
    last_real=i; i+=1
if style is None: style="list"
if child_ind is None: child_ind=ind(lines[env_idx])+2

new=[]
for k,v in WANT:
    if k in present: continue
    new.append(as_list(k,v,child_ind) if style=="list" else as_map(k,v,child_ind))
if not new: print("ALREADY"); sys.exit(2)
lines[last_real+1:last_real+1]=new
with open(path,"w") as f: f.writelines(lines)
print("ADDED_VARS"); sys.exit(0)
PYEOF
}

fn_gpu(){
  info "OPCJA 3 — Włączanie GPU + obsługi 2 modeli w SkillFish AI"
  detect_docker || return 1

  # WHAT: sprawdź, czy plik compose w ogóle istnieje pod ustaloną ścieżką
  local FILE="$COMPOSE_FILE"; local CN=""
  if [ ! -f "$FILE" ]; then
    warn "Nie ma pliku $FILE."
    # WHAT: może stack stoi gdzie indziej — zapytaj Dockera o kontener ollama
    CN="$($DOCKER ps -a --format '{{.Names}}' | grep -i ollama | head -n1 || true)"
    if [ -n "$CN" ]; then
      info "Znalazłem kontener '$CN' — odczytuję jego plik compose..."
      FILE="$($DOCKER inspect "$CN" --format '{{ index .Config.Labels "com.docker.compose.project.config_files" }}' 2>/dev/null || true)"
      STACK_DIR="$($DOCKER inspect "$CN" --format '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' 2>/dev/null || true)"
    fi
  fi

  # WHAT: nadal nic? Rozróżnij dwie sytuacje, żeby komunikat był jasny.
  # WHY: brak pliku ORAZ brak kontenera = narzędzie AI nie jest zainstalowane;
  #      to inny problem niż zła ścieżka do istniejącego stacka.
  if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    if [ -z "$CN" ]; then
      err "Nie znalazłem ani pliku compose, ani kontenera ollama."
      err "SkillFish AI prawdopodobnie NIE jest jeszcze zainstalowane."
      echo "    Zainstaluj je najpierw kreatorem SkillFish AI, a potem uruchom tę opcję ponownie."
    else
      err "Kontener '$CN' istnieje, ale nie mogę ustalić jego pliku compose."
      err "Podaj ścieżkę ręcznie w zmiennej COMPOSE_FILE na górze skryptu."
    fi
    return 1
  fi
  info "Plik compose: $FILE"

  write_yaml_editor
  # edycja i kopia przez sudo, bo plik w /opt należy do roota
  local SUDO=""; [ -w "$FILE" ] || SUDO="sudo"
  local BAK="${FILE}.bak.${TS}"
  $SUDO cp "$FILE" "$BAK"

  local OUT CODE
  OUT="$($SUDO python3 "$TMP_PY" "$FILE")"; CODE=$?
  rm -f "$TMP_PY"

  case "$CODE" in
    0)
      [ "$OUT" = "ADDED_ENV" ]  && echo "    Dodano nowy blok environment z dwiema zmiennymi."
      [ "$OUT" = "ADDED_VARS" ] && echo "    Dopisano brakujące zmienne do bloku environment."
      echo "    Kopia zapasowa: $BAK" ;;
    2)
      info "Zmienne już były w pliku — nic nie zmieniono."
      $SUDO rm -f "$BAK"
      return 0 ;;
    3) $SUDO rm -f "$BAK"; err "W $FILE nie ma usługi ollama."; return 1 ;;
    4) $SUDO rm -f "$BAK"; warn "Blok environment w jednej linii — dodaj ręcznie OLLAMA_VULKAN=1 i OLLAMA_IGPU_ENABLE=1."; return 1 ;;
    *) $SUDO rm -f "$BAK"; err "Błąd edycji (kod $CODE)."; return 1 ;;
  esac

  # --- przeładowanie stacka ---------------------------------------------------
  local RUN_DIR="$STACK_DIR"
  [ -n "$RUN_DIR" ] && [ -d "$RUN_DIR" ] || RUN_DIR="$(dirname "$FILE")"
  echo
  read -r -p "Przeładować kontenery teraz (down + up -d)? [t/N] " a
  case "$a" in
    t|T|tak|y|Y)
      ( cd "$RUN_DIR" && $COMPOSE down && $COMPOSE up -d )
      info "Przeładowano. Sprawdź:  $DOCKER exec skillfish-ollama ollama ps  (po zadaniu pytania w Open WebUI)." ;;
    *) warn "Pominięto restart. Wykonaj później: cd $RUN_DIR && $COMPOSE down && $COMPOSE up -d" ;;
  esac
}

# =============================================================================
# FUNKCJA 4 — Naprawa panelu AI (pobieranie kolejnych modeli)
# =============================================================================
write_panel_patcher(){
  # WHY: zmiany w kodzie panelu robi Python, bo trzeba wykryć granice metody po
  #      wcięciach i trafić w konkretne fragmenty. Każda zmiana jest niezależna,
  #      więc skrypt jest bezpieczny przy ponownych uruchomieniach. Patcher:
  #        1) naprawia refresh_models (lista = zainstalowane + katalog),
  #        2) wyróżnia zainstalowane modele (na górze, zielone, pogrubione + separator),
  #        3) dodaje przycisk usuwania i metody delete_model / _deleted,
  #        4) dokłada polskie tłumaczenie interfejsu (gdy język systemu = pl),
  #        5) odświeża listę modeli też po włączeniu/wyłączeniu silnika (nie
  #           tylko po pobraniu), żeby wyróżnienie działało od razu.
  TMP_PY2="$(mktemp --suffix=.py)"
  cat > "$TMP_PY2" <<'PYEOF'
import sys, re
path = sys.argv[1]
NEW_MARK = "# WHAT: zainstalowane na gorze, wyroznione; ponizej katalog"

# --- nowa metoda refresh_models: zainstalowane na gorze, wyroznione + separator
REFRESH = '''    def refresh_models(self):
        cur = self.modelbox.currentText()
        self.modelbox.blockSignals(True); self.modelbox.clear()
        inst = installed_models()
        # WHAT: zainstalowane na gorze, wyroznione; ponizej katalog do pobrania
        # WHY: po pobraniu pierwszego modelu katalog wczesniej znikal
        cat = [name for name, _ in CATALOG if name not in inst]
        self.modelbox.addItems(list(inst) + cat)
        # WHAT: zainstalowane modele na zielono i pogrubione
        green = QBrush(QColor("#9ccf6a")); bold = QFont(); bold.setBold(True)
        for r in range(len(inst)):
            self.modelbox.setItemData(r, green, Qt.ItemDataRole.ForegroundRole)
            self.modelbox.setItemData(r, bold, Qt.ItemDataRole.FontRole)
        # WHAT: linia oddzielajaca zainstalowane od katalogu do pobrania
        if inst and cat:
            self.modelbox.insertSeparator(len(inst))
        i = self.modelbox.findText(self.model)
        if i >= 0: self.modelbox.setCurrentIndex(i)
        elif cur: self.modelbox.setEditText(cur)
        self.modelbox.blockSignals(False)
        self.modelmsg.setText(L(f"{len(inst)} modelli installati" if inst else "nessun modello installato",
                                f"{len(inst)} models installed" if inst else "no models installed"))

'''

# --- metody usuwania modelu (wstawiane przed def pull_model) ------------------
DELETE_METHODS = '''    def delete_model(self):
        name = self.modelbox.currentText().strip()
        if not name: return
        if name not in installed_models():
            self.modelmsg.setText(L(f"{name} non risulta installato", f"{name} is not installed")); return
        if not engine_running():
            QMessageBox.information(self, "SkillFish AI", L("Accendi prima il motore AI.", "Turn the AI engine on first."))
            return
        if QMessageBox.question(self, "SkillFish AI",
                L(f"Eliminare il modello {name}?", f"Delete model {name}?")) != QMessageBox.StandardButton.Yes:
            return
        self.bdel.setEnabled(False); self.modelmsg.setText(L(f"Elimino {name}\u2026", f"Deleting {name}\u2026"))
        self._d = Worker(f"docker exec {CONTAINER} ollama rm {name}", 120)
        self._d.done.connect(lambda rc: self._deleted(rc, name)); self._d.start()
    def _deleted(self, rc, name):
        self.bdel.setEnabled(True)
        self.modelmsg.setText(L(f"\u2713 {name} eliminato" if rc == 0 else f"! errore eliminando {name}",
                                f"\u2713 {name} deleted" if rc == 0 else f"! error deleting {name}"))
        self.refresh_models()
'''

# --- blok jezyka: dodanie polskiego -------------------------------------------
LANG_OLD = '''def _detect_lang():
    val = (os.environ.get("LC_ALL") or os.environ.get("LC_MESSAGES")
           or os.environ.get("LANG") or os.environ.get("LANGUAGE") or "")
    return "it" if val.lower().startswith("it") else "en"
LANG = _detect_lang()
def L(it, en): return it if LANG == "it" else en
'''

LANG_NEW = '''def _detect_lang():
    val = (os.environ.get("LC_ALL") or os.environ.get("LC_MESSAGES")
           or os.environ.get("LANG") or os.environ.get("LANGUAGE") or "")
    v = val.lower()
    if v.startswith("it"): return "it"
    if v.startswith("pl"): return "pl"
    return "en"
LANG = _detect_lang()
# WHAT: polskie tlumaczenia interfejsu (klucz = tekst angielski)
PL = {
    "unknown": "nieznana",
    "SkillFish AI - Setup": "SkillFish AI - Konfiguracja",
    "Welcome to SkillFish AI": "Witaj w SkillFish AI",
    "All set!": "Gotowe!",
    "Installing the stack": "Instalacja stacka",
    "Install / Start": "Zainstaluj / Uruchom",
    "\\n\u2713 Stack started.": "\\n\u2713 Stack uruchomiony.",
    "Choose a model": "Wybierz model",
    "or custom name:": "lub wlasna nazwa:",
    "Download model": "Pobierz model",
    "\u2713 Model ready.": "\u2713 Model gotowy.",
    "! download failed": "! pobieranie nie powiodlo sie",
    "AI Engine (LLM)": "Silnik AI (LLM)",
    "On \u2014 starts/stops Ollama. Turn it off before gaming.":
        "Wlaczony \u2014 uruchamia/zatrzymuje Ollame. Wylacz przed graniem.",
    "Start automatically on boot (even if it was off)":
        "Automatyczne uruchamianie przy starcie komputera (nawet jesli byl wylaczony)",
    "Model": "Model",
    "active model / name to pull": "aktywny model / nazwa do pobrania",
    "Use": "Uzyj",
    "Pull": "Pobierz",
    "Delete": "Usun",
    "Hardware": "Sprzet",
    "Shared memory for the model": "Pamiec wspoldzielona dla modelu",
    "Apply and reboot": "Zastosuj i uruchom ponownie",
    "Open Chat (web)": "Otworz czat (web)",
    "Dockge": "Dockge",
    "Refresh": "Odswiez",
    "\u25cf Engine ON \u2014 ready": "\u25cf Silnik WLACZONY \u2014 gotowy",
    "\u25cb Engine OFF \u2014 GPU/memory free for games":
        "\u25cb Silnik WYLACZONY \u2014 GPU/pamiec wolne do gier",
    "free": "wolne",
    "n/a (non-AMD GPU or shared VRAM)": "n/d (GPU inne niz AMD lub wspoldzielony VRAM)",
    "not available on this GPU": "niedostepne na tej karcie GPU",
    "n/a": "n/d",
    "\u2026 working \u2026": "\u2026 operacja w toku \u2026",
    "Turn the AI engine on first.": "Najpierw wlacz silnik AI.",
    "operation cancelled": "operacja anulowana",
    "no models installed": "brak zainstalowanych modeli",
    "On the BC-250 memory is shared GPU/CPU: this raises the share of system RAM "
    "(GTT) the model may use on top of VRAM, so larger models fit. It is a kernel "
    "parameter \u2192 a reboot is required (a live change is not possible on this "
    "hardware, verified).":
        "Na BC-250 pamiec jest wspoldzielona GPU/CPU: to zwieksza ilosc pamieci RAM "
        "systemu (GTT), ktorej model moze uzyc oprocz VRAM, dzieki czemu mieszcza sie "
        "wieksze modele. To parametr jadra \u2192 wymaga ponownego uruchomienia (zmiana "
        "na goraco nie jest mozliwa na tym sprzecie, sprawdzone).",
}
def L(it, en):
    if LANG == "it": return it
    if LANG == "pl": return PL.get(en, en)
    return en
'''

BTN_OLD = ('        self.bpull = QPushButton(L("Scarica", "Pull")); self.bpull.clicked.connect(self.pull_model)\n'
           '        mv.addWidget(self.bset, 0, 2); mv.addWidget(self.bpull, 0, 3)\n')
BTN_NEW = ('        self.bpull = QPushButton(L("Scarica", "Pull")); self.bpull.clicked.connect(self.pull_model)\n'
           '        self.bdel = QPushButton(L("Elimina", "Delete")); self.bdel.clicked.connect(self.delete_model)\n'
           '        mv.addWidget(self.bset, 0, 2); mv.addWidget(self.bpull, 0, 3); mv.addWidget(self.bdel, 0, 4)\n')

MSG_OLD = "        mv.addWidget(self.modelmsg, 1, 0, 1, 4)\n"
MSG_NEW = "        mv.addWidget(self.modelmsg, 1, 0, 1, 5)\n"

# --- odswiez liste modeli tez po wlaczeniu/wylaczeniu silnika ------------------
# WHY: wyroznienie zainstalowanych modeli dzialo dopiero po pobraniu (_pulled
#      wola refresh_models), bo installed_models() widzi cokolwiek tylko gdy
#      silnik dziala, a wlaczenie silnika samo w sobie nie odswiezalo listy.
TOGGLE_OLD = "        self.busy = False; self.cb.setEnabled(True); self.refresh_engine()\n"
TOGGLE_NEW = "        self.busy = False; self.cb.setEnabled(True); self.refresh_engine(); self.refresh_models()\n"

IMP_OLD = "from PyQt6.QtGui import QIcon, QPixmap\n"
IMP_NEW = "from PyQt6.QtGui import QIcon, QPixmap, QColor, QBrush, QFont\n"

with open(path) as f: src = f.read()
changed = False

# 1) refresh_models (po granicach wciecia) — zawsze do najnowszej wersji
if NEW_MARK not in src:
    lines = src.splitlines(keepends=True)
    def ind(s): return len(s) - len(s.lstrip(' '))
    start = None; di = None
    for i, l in enumerate(lines):
        m = re.match(r'^(\s*)def\s+refresh_models\s*\(', l)
        if m: start = i; di = len(m.group(1)); break
    if start is None:
        print("NO_METHOD"); sys.exit(3)
    end = len(lines)
    for i in range(start + 1, len(lines)):
        if lines[i].strip() == "": continue
        if ind(lines[i]) <= di: end = i; break
    repl = REFRESH
    if di != 4:
        shift = di - 4; out = []
        for l in REFRESH.splitlines(keepends=True):
            if l.strip() == "": out.append(l)
            elif shift > 0: out.append(" " * shift + l)
            else: out.append(l[(-shift):])
        repl = "".join(out)
    lines[start:end] = [repl]; src = "".join(lines); changed = True

# 2) import kolorow/czcionek dla wyroznienia
#    (warunek na starej linii importu, bo QBrush trafia juz do refresh_models w kroku 1)
if IMP_OLD in src:
    src = src.replace(IMP_OLD, IMP_NEW, 1); changed = True

# 3) blok jezyka -> dodaj polski
if 'LANG == "pl"' not in src and LANG_OLD in src:
    src = src.replace(LANG_OLD, LANG_NEW, 1); changed = True

# 4) przycisk usuwania
if "self.bdel" not in src and BTN_OLD in src:
    src = src.replace(BTN_OLD, BTN_NEW, 1); changed = True

# 5) poszerzenie paska komunikatu
if "self.bdel" in src and MSG_OLD in src:
    src = src.replace(MSG_OLD, MSG_NEW, 1); changed = True

# 6) metody delete_model / _deleted
if "def delete_model" not in src and "    def pull_model(self):\n" in src:
    src = src.replace("    def pull_model(self):\n", DELETE_METHODS + "    def pull_model(self):\n", 1); changed = True

# 7) odswiezenie listy modeli po (de)aktywacji silnika
if TOGGLE_OLD in src:
    src = src.replace(TOGGLE_OLD, TOGGLE_NEW, 1); changed = True

if not changed:
    print("ALREADY"); sys.exit(2)

with open(path, "w") as f: f.write(src)
print("PATCHED"); sys.exit(0)
PYEOF
}

fn_fix_panel(){
  info "OPCJA 4 — Naprawa panelu AI (pobieranie kolejnych modeli)"

  # WHAT: znajdz plik panelu (skrypt Pythona)
  local PANEL
  PANEL="$(command -v skillfish-ai-panel 2>/dev/null || true)"
  [ -z "$PANEL" ] && PANEL="$(sudo find /usr /opt -type f -name 'skillfish-ai-panel' 2>/dev/null | head -n1 || true)"
  if [ -z "$PANEL" ] || [ ! -f "$PANEL" ]; then
    err "Nie znalazłem pliku skillfish-ai-panel. Czy panel jest zainstalowany?"
    return 1
  fi
  info "Plik panelu: $PANEL"

  # WHAT: prosta kontrola, czy to właściwy plik
  if ! grep -q 'def refresh_models' "$PANEL"; then
    err "To nie wygląda na właściwy plik panelu (brak refresh_models)."
    return 1
  fi

  write_panel_patcher
  local SUDO=""; [ -w "$PANEL" ] || SUDO="sudo"   # plik w /usr → sudo
  local BAK="${PANEL}.bak.${TS}"
  $SUDO cp "$PANEL" "$BAK"

  local OUT CODE
  OUT="$($SUDO python3 "$TMP_PY2" "$PANEL")"; CODE=$?
  rm -f "$TMP_PY2"

  case "$CODE" in
    0) info "Panel poprawiony. Kopia zapasowa: $BAK"
       echo "    - lista modeli: zainstalowane + katalog do pobrania,"
       echo "    - zainstalowane modele wyróżnione (na górze, zielone, z separatorem),"
       echo "    - przycisk usuwania wybranego modelu,"
       echo "    - polski interfejs (gdy język systemu jest polski),"
       echo "    - wyróżnienie działa od razu po włączeniu silnika, nie tylko po pobraniu." ;;
    2) info "Panel jest już naprawiony — nic nie zmieniono."; $SUDO rm -f "$BAK"; return 0 ;;
    3) $SUDO rm -f "$BAK"; err "Nie znalazłem funkcji refresh_models w pliku."; return 1 ;;
    *) $SUDO rm -f "$BAK"; err "Błąd podczas naprawy (kod $CODE)."; return 1 ;;
  esac

  # WHAT: sprawdź, czy plik nadal jest poprawnym Pythonem; jeśli nie — cofnij
  if $SUDO python3 -m py_compile "$PANEL" 2>/dev/null; then
    info "Składnia Pythona OK. Uruchom panel ponownie, by zobaczyć zmianę."
  else
    warn "py_compile zgłosił błąd — przywracam kopię zapasową."
    $SUDO cp "$BAK" "$PANEL"
    return 1
  fi
}

# =============================================================================
# MENU
# =============================================================================
finish(){
  echo
  if [ "$NEED_REBOOT" -eq 1 ]; then
    read -r -p "Zmiany języka wymagają restartu. Uruchomić ponownie teraz? [t/N] " r
    case "$r" in t|T|tak|y|Y) info "Restartuję..."; sudo systemctl reboot ;; esac
    warn "Pamiętaj o restarcie."
  elif [ "$NEED_RELOGIN" -eq 1 ]; then
    warn "Dodano do grupy docker — wyloguj się i zaloguj (lub zrestartuj), by zadziałało."
  fi
  exit 0
}

while true; do
  echo
  echo -e "${C}=== SkillFishOS — konfiguracja ===${N}"
  echo
  echo -e "  ${B}1) Ustaw język polski (główny) + angielski (zapasowy)${N}"
  echo    "     Generuje locale pl_PL/en_US, ustawia je w systemie i w KDE,"
  echo    "     tworzy polskie katalogi (Dokumenty, Obrazy...), przenosi dane"
  echo    "     z włoskich katalogów i poprawia zakładki w Dolphinie."
  echo
  echo -e "  ${B}2) Dodaj użytkownika '$USER' do grupy docker${N}"
  echo    "     Pozwala używać Dockera bez sudo. Zaczyna działać po ponownym"
  echo    "     zalogowaniu (lub restarcie)."
  echo
  echo -e "  ${B}3) Włącz GPU + obsługę 2 modeli w SkillFish AI${N}"
  echo    "     Dopisuje do /opt/stacks/skillfish-ai/compose.yaml: OLLAMA_VULKAN=1"
  echo    "     i OLLAMA_IGPU_ENABLE=1 (liczenie na iGPU zamiast CPU) oraz"
  echo    "     OLLAMA_MAX_LOADED_MODELS=2 (dwa modele naraz), i przeładowuje stack."
  echo
  echo -e "  ${B}4) Napraw i spolszcz panel AI${N}"
  echo    "     W pliku skillfish-ai-panel: naprawia listę modeli (zainstalowane"
  echo    "     + katalog do pobrania), wyróżnia zainstalowane, dodaje przycisk"
  echo    "     usuwania modelu i polskie tłumaczenie interfejsu. Robi kopię"
  echo    "     zapasową i sprawdza poprawność (py_compile)."
  echo
  echo -e "  ${B}5) Wykonaj wszystkie powyższe${N}  (1 -> 2 -> 3 -> 4)"
  echo
  echo    "  0) Wyjście"
  echo
  read -r -p "Twój wybór: " choice
  case "$choice" in
    1) fn_language ;;
    2) fn_docker_group ;;
    3) fn_gpu ;;
    4) fn_fix_panel ;;
    5) fn_language; fn_docker_group; fn_gpu; fn_fix_panel ;;
    0) finish ;;
    *) warn "Nieznana opcja: $choice" ;;
  esac
done
