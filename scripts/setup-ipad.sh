#!/usr/bin/env bash
# ============================================================
# setup-ipad.sh v7
# Einrichtung: Udev, systemd, Ausführbarkeit prüfen
# ============================================================

set -euo pipefail
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; RESET="\033[0m"

IPAD_PATH="/media/Linux/repos/ipad"
USER_CONF="$HOME/.config/systemd/user"

echo -e "${GREEN}🚀 Starte iPad-AutoSync Setup (v7)...${RESET}"

# 🔧 1️⃣ Prüfe, ob Skripte ausführbar sind
echo -e "${YELLOW}🔍 Prüfe Skript-Berechtigungen...${RESET}"
for f in "${IPAD_PATH}/scripts/"*.sh; do
  if [[ ! -x "$f" ]]; then
    echo "→ Setze +x für $(basename "$f")"
    chmod +x "$f"
  fi
done

# 🔧 2️⃣ systemd-User-Verzeichnis anlegen
mkdir -p "$USER_CONF"

# 🔧 3️⃣ systemd-Unit installieren
cp "${IPAD_PATH}/scripts/sync-ipad.service" "$USER_CONF/"
systemctl --user daemon-reload

# 🔧 4️⃣ udev-Regel (Root benötigt)
if [[ $EUID -ne 0 ]]; then
  echo -e "${YELLOW}⚙️  Starte neu mit sudo, um udev-Regel zu installieren:${RESET}"
  echo "sudo $0"
  exit 1
fi

echo -e "${YELLOW}📦 Installiere udev-Regel...${RESET}"
cp "${IPAD_PATH}/scripts/99-ipad-sync.rules" /etc/udev/rules.d/
udevadm control --reload-rules && udevadm trigger

# 🔧 5️⃣ Linger aktivieren
loginctl enable-linger "$SUDO_USER"

# 🔧 6️⃣ Sync-Verzeichnis vorbereiten
mkdir -p "${IPAD_PATH}/sync"
touch "${IPAD_PATH}/sync/ipadSync.txt"
chown -R "$SUDO_USER":"$SUDO_USER" "${IPAD_PATH}"

echo -e "${GREEN}✅ Einrichtung abgeschlossen!"
echo "Beim Einstecken von 'Linux' wird automatisch:"
echo " - das Laufwerk gemountet"
echo " - iPad-Sync ausgeführt"
echo " - WezTerm aktualisiert"