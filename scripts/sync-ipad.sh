#!/usr/bin/env bash
# ============================================================
# sync-ipad.sh v6
# Synchronisiert iPad <-> WSL + startet WezTerm-Branch-Sync
# ============================================================

set -euo pipefail
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; RESET="\033[0m"

USB_DEVICE_LABEL="Linux"
MOUNT_POINT="/media/${USB_DEVICE_LABEL}"
SYNC_DIR="${MOUNT_POINT}/ipad/sync"
LOCAL_SYNC_DIR="$HOME/repos/stow/logs"
LOG_FILE="${SYNC_DIR}/sync-ipad.log"
SWITCH_SCRIPT="${MOUNT_POINT}/ipad/scripts/switch-wezterm-branch.sh"

echo -e "${GREEN}🔄 Starte iPad-Synchronisation (v6)...${RESET}"

# 🔌 Sicherstellen, dass Laufwerk gemountet ist
if ! mountpoint -q "$MOUNT_POINT"; then
  echo -e "${YELLOW}⚙️  Mounten ${USB_DEVICE_LABEL}...${RESET}"
  sudo mkdir -p "$MOUNT_POINT"
  sudo mount -L "$USB_DEVICE_LABEL" "$MOUNT_POINT" || {
    notify-send "❌ Fehler beim Mount" "Konnte ${USB_DEVICE_LABEL} nicht mounten."
    exit 1
  }
  notify-send "📀 USB gemountet" "${USB_DEVICE_LABEL} eingebunden unter ${MOUNT_POINT}"
fi

# 📁 Verzeichnisse prüfen
mkdir -p "$LOCAL_SYNC_DIR" "$SYNC_DIR"

# 🔄 Bidirektionale Synchronisation
{
  echo "------------------------------------------------------------"
  echo "$(date '+%Y-%m-%d %H:%M:%S') | Sync gestartet"
} >>"$LOG_FILE"

rsync -av --update "$LOCAL_SYNC_DIR/" "$SYNC_DIR/" >>"$LOG_FILE" 2>&1
rsync -av --update "$SYNC_DIR/" "$LOCAL_SYNC_DIR/" >>"$LOG_FILE" 2>&1

notify-send "✅ iPad Sync abgeschlossen" "Dateien wurden abgeglichen."
echo "$(date '+%Y-%m-%d %H:%M:%S') | Sync abgeschlossen" >>"$LOG_FILE"

# 🚀 Danach automatisch WezTerm-Sync starten
if [[ -x "$SWITCH_SCRIPT" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') | Starte WezTerm Branch Sync" >>"$LOG_FILE"
  "$SWITCH_SCRIPT" >>"$LOG_FILE" 2>&1
  notify-send "🌿 WezTerm Branch Sync" "Automatische Aktualisierung abgeschlossen."
else
  notify-send "⚠️ Kein switch-wezterm-branch.sh gefunden" "Übersprungen."
fi

echo -e "${GREEN}🎉 Vollständiger iPad-Sync und WezTerm-Sync abgeschlossen.${RESET}"