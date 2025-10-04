#!/usr/bin/env bash
# ============================================================
# sync-ipad.sh v7
# Bidirektionaler Sync + WezTerm-Statusmeldung
# ============================================================

set -euo pipefail
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; RESET="\033[0m"

USB_DEVICE_LABEL="Linux"
MOUNT_POINT="/media/${USB_DEVICE_LABEL}"
IPAD_ROOT="${MOUNT_POINT}/repos/ipad"
SYNC_DIR="${IPAD_ROOT}/sync"
LOCAL_SYNC_DIR="$HOME/repos/stow/logs"
LOG_FILE="${SYNC_DIR}/sync-ipad.log"
SWITCH_SCRIPT="${IPAD_ROOT}/scripts/switch-wezterm-branch.sh"
STATUS_FILE="$HOME/.ipad-sync-status"

echo "running" > "$STATUS_FILE"
notify-send "🔄 iPad Sync gestartet" "Synchronisation läuft..."

if ! mountpoint -q "$MOUNT_POINT"; then
  sudo mkdir -p "$MOUNT_POINT"
  sudo mount -L "$USB_DEVICE_LABEL" "$MOUNT_POINT" || {
    echo "error" > "$STATUS_FILE"
    notify-send "❌ Fehler" "Konnte ${USB_DEVICE_LABEL} nicht mounten."
    exit 1
  }
fi

mkdir -p "$LOCAL_SYNC_DIR" "$SYNC_DIR"

{
  echo "------------------------------------------------------------"
  echo "$(date '+%Y-%m-%d %H:%M:%S') | Sync gestartet"
} >>"$LOG_FILE"

rsync -av --update "$LOCAL_SYNC_DIR/" "$SYNC_DIR/" >>"$LOG_FILE" 2>&1
rsync -av --update "$SYNC_DIR/" "$LOCAL_SYNC_DIR/" >>"$LOG_FILE" 2>&1

notify-send "✅ iPad Sync abgeschlossen" "Dateien wurden abgeglichen."
echo "$(date '+%Y-%m-%d %H:%M:%S') | Sync abgeschlossen" >>"$LOG_FILE"

if [[ -x "$SWITCH_SCRIPT" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') | Starte WezTerm Branch Sync" >>"$LOG_FILE"
  "$SWITCH_SCRIPT" >>"$LOG_FILE" 2>&1
  notify-send "🌿 WezTerm Branch Sync" "Automatische Aktualisierung abgeschlossen."
fi

echo "done" > "$STATUS_FILE"