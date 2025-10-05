#!/usr/bin/env bash
# ============================================================
# setup-ipad.sh v9 – Einrichtung mit Lock und Retry
# ============================================================

set -euo pipefail
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; RESET="\033[0m"

IPAD_PATH="/media/Linux/repos/ipad"
USER_CONF="$HOME/.config/systemd/user"

echo -e "${GREEN}🚀 Starte iPad-AutoSync Setup (v9)...${RESET}"

# 🧱 Lock entfernen
rm -f /tmp/ipad-sync.lock 2>/dev/null || true

# 🔍 Skripte ausführbar machen
for f in "${IPAD_PATH}/scripts/"*.sh; do
  [[ -x "$f" ]] || chmod +x "$f"
done

mkdir -p "$USER_CONF"
cp "${IPAD_PATH}/scripts/sync-ipad.service" "$USER_CONF/"
systemctl --user daemon-reload

# 🔧 Root-Teil: Udev-Regel
if [[ $EUID -ne 0 ]]; then
  echo -e "${YELLOW}⚙️  Bitte neu starten mit sudo:${RESET}"
  echo "sudo $0"
  exit 1
fi

cp "${IPAD_PATH}/scripts/99-ipad-sync.rules" /etc/udev/rules.d/
udevadm control --reload-rules && udevadm trigger

loginctl enable-linger "$SUDO_USER"

mkdir -p "${IPAD_PATH}/sync"
touch "${IPAD_PATH}/sync/ipadSync.txt"
chown -R "$SUDO_USER":"$SUDO_USER" "${IPAD_PATH}"

echo -e "${GREEN}✅ Einrichtung abgeschlossen!"
echo "Lock- und Retry-Mechanismen aktiv."