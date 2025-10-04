#!/usr/bin/env bash
# ============================================================
# sync-ipad.sh v3
# Synchronisiert Textdateien zwischen /media/Linux/ipad/sync
# und lokalem Verzeichnis (~repos/stow/logs)
# ============================================================

set -euo pipefail

GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; RESET="\033[0m"

USB_DEVICE_LABEL="Linux"
MOUNT_POINT="/media/${USB_DEVICE_LABEL}"
SYNC_DIR="${MOUNT_POINT}/ipad/sync"
LOCAL_SYNC_DIR="$HOME/repos/stow/logs"
LOG_FILE="${SYNC_DIR}/sync-ipad.log"

echo -e "${GREEN}🔄 Starte iPad-Synchronisation (v3)...${RESET}"

# ------------------------------------------------------------
# 🔌 Sicherstellen, dass Laufwerk gemountet ist
# ------------------------------------------------------------
if ! mountpoint -q "$MOUNT_POINT"; then
  echo -e "${YELLOW}⚙️  ${MOUNT_POINT} ist nicht gemountet – versuche Mount...${RESET}"
  if command -v usbipd.exe &>/dev/null; then
    BUS_ID=$(usbipd.exe wsl list | grep -i "$USB_DEVICE_LABEL" | awk '{print $1}' | tr -d '\r' || true)
    [[ -n "$BUS_ID" ]] && powershell.exe "usbipd attach --wsl --busid $BUS_ID" >/dev/null 2>&1 || true
  fi
  sudo mkdir -p "$MOUNT_POINT"
  sudo mount -L "$USB_DEVICE_LABEL" "$MOUNT_POINT" || {
    echo -e "${RED}❌ Konnte ${USB_DEVICE_LABEL} nicht mounten.${RESET}"
    exit 1
  }
fi

# ------------------------------------------------------------
# 📁 Verzeichnisse prüfen
# ------------------------------------------------------------
mkdir -p "$LOCAL_SYNC_DIR" "$SYNC_DIR"

# ------------------------------------------------------------
# 🔄 Synchronisation (bidirektional)
# ------------------------------------------------------------
echo -e "${YELLOW}📂 Vergleiche Änderungen zwischen lokal und iPad...${RESET}"

rsync -av --update --progress \
  "$LOCAL_SYNC_DIR/" "$SYNC_DIR/" \
  >>"$LOG_FILE" 2>&1

rsync -av --update --progress \
  "$SYNC_DIR/" "$LOCAL_SYNC_DIR/" \
  >>"$LOG_FILE" 2>&1

echo -e "${GREEN}✅ Synchronisation abgeschlossen.${RESET}"
echo "$(date '+%Y-%m-%d %H:%M:%S') Synchronisiert" >>"$LOG_FILE"