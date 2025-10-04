#!/usr/bin/env bash
# ============================================================
# setup-ipad.sh v6 – Einmalige Einrichtung für Auto-Mount + Auto-Sync
# ============================================================

set -euo pipefail
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; RESET="\033[0m"

echo -e "${GREEN}🚀 Starte iPad-AutoSync Setup (v6)...${RESET}"

USER_CONF="$HOME/.config/systemd/user"

# 🔧 1️⃣ UDEV-Regel installieren
if [[ $EUID -ne 0 ]]; then
  echo -e "${YELLOW}⚙️  Bitte mit sudo neu starten für udev-Regel-Installation.${RESET}"
  echo "sudo $0"
  exit 1
fi

echo -e "${YELLOW}📦 Installiere udev-Regel...${RESET}"
cp /media/Linux/ipad/scripts/99-ipad-sync.rules /etc/udev/rules.d/
udevadm control --reload-rules
udevadm trigger

# 🔧 2️⃣ systemd user units installieren
echo -e "${YELLOW}⚙️  Installiere systemd-Units...${RESET}"
mkdir -p "$USER_CONF"
cp /media/Linux/ipad/scripts/sync-ipad.service "$USER_CONF/"
systemctl --user daemon-reload

# 🔧 3️⃣ systemd linger aktivieren
loginctl enable-linger "$SUDO_USER"

# 🔧 4️⃣ Berechtigungen und Ausführbarkeit
chmod +x /media/Linux/ipad/scripts/*.sh

# ✅ Fertig
echo -e "${GREEN}✅ Einrichtung abgeschlossen!"
echo "Laufwerk 'Linux' wird beim Einstecken automatisch gemountet & synchronisiert."
echo "Bei erfolgreichem Sync wird WezTerm automatisch aktualisiert."
echo -e "${GREEN}-----------------------------------------------------------${RESET}"