#!/usr/bin/env bash
# ============================================================
# sync-ipad.sh v9
# Bidirektionaler iPad <-> WSL Sync + Lock + Retry
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
LOCK_FILE="/tmp/ipad-sync.lock"
MAX_LOG_SIZE=50000   # 50 KB
MAX_RETRIES=3
RETRY_DELAY=10       # Sekunden

# ------------------------------------------------------------
# 🧱 Lock-Mechanismus
# ------------------------------------------------------------
if [[ -e "$LOCK_FILE" ]]; then
  pid=$(cat "$LOCK_FILE" 2>/dev/null || true)
  if [[ -n "$pid" && -d "/proc/$pid" ]]; then
    echo -e "${YELLOW}⚠️  Sync läuft bereits (PID $pid) – Überspringe...${RESET}"
    echo "$(date '+%F %T') | Übersprungen: Prozess läuft (PID $pid)" >>"$LOG_FILE"
    exit 0
  fi
fi
echo $$ >"$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT INT TERM

# ------------------------------------------------------------
# 🧹 Log-Rotation
# ------------------------------------------------------------
if [[ -f "$LOG_FILE" && $(stat -c%s "$LOG_FILE") -gt $MAX_LOG_SIZE ]]; then
  mv "$LOG_FILE" "${LOG_FILE}.old"
  echo "$(date '+%F %T') | Log rotiert" >"$LOG_FILE"
fi

# ------------------------------------------------------------
# 🔁 Retry-Schleife
# ------------------------------------------------------------
attempt=1
success=false
echo "running" >"$STATUS_FILE"
notify-send "🔄 iPad Sync gestartet" "Versuch $attempt von $MAX_RETRIES..."

while [[ $attempt -le $MAX_RETRIES ]]; do
  echo "$(date '+%F %T') | Versuch $attempt" >>"$LOG_FILE"

  # 🔌 Mount prüfen
  if ! mountpoint -q "$MOUNT_POINT"; then
    sudo mkdir -p "$MOUNT_POINT"
    if ! sudo mount -L "$USB_DEVICE_LABEL" "$MOUNT_POINT"; then
      echo -e "${RED}❌ Mount fehlgeschlagen (Versuch $attempt)${RESET}"
      echo "$(date '+%F %T') | Mount fehlgeschlagen" >>"$LOG_FILE"
      ((attempt++))
      sleep "$RETRY_DELAY"
      continue
    fi
  fi

  mkdir -p "$LOCAL_SYNC_DIR" "$SYNC_DIR"
  {
    rsync -av --update "$LOCAL_SYNC_DIR/" "$SYNC_DIR/"
    rsync -av --update "$SYNC_DIR/" "$LOCAL_SYNC_DIR/"
  } >>"$LOG_FILE" 2>&1 || {
    echo "$(date '+%F %T') | rsync Fehler" >>"$LOG_FILE"
    ((attempt++))
    sleep "$RETRY_DELAY"
    continue
  }

  success=true
  break
done

if [[ "$success" == false ]]; then
  echo "error" >"$STATUS_FILE"
  notify-send "❌ iPad Sync fehlgeschlagen" "Nach $MAX_RETRIES Versuchen"
  echo "$(date '+%F %T') | Sync fehlgeschlagen nach $MAX_RETRIES Versuchen" >>"$LOG_FILE"
  exit 1
fi

# ------------------------------------------------------------
# 🌿 WezTerm Branch Sync
# ------------------------------------------------------------
notify-send "✅ iPad Sync abgeschlossen" "Dateien wurden abgeglichen."
echo "$(date '+%F %T') | Sync abgeschlossen" >>"$LOG_FILE"

if [[ -x "$SWITCH_SCRIPT" ]]; then
  echo "$(date '+%F %T') | Starte WezTerm Branch Sync" >>"$LOG_FILE"
  "$SWITCH_SCRIPT" >>"$LOG_FILE" 2>&1
  notify-send "🌿 WezTerm Branch Sync" "Automatische Aktualisierung abgeschlossen."
fi

echo "done" >"$STATUS_FILE"
echo "$(date '+%F %T') | Sync erfolgreich beendet (PID $$)" >>"$LOG_FILE"