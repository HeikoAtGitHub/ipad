#!/usr/bin/env bash
# ============================================================
# switch-wezterm-branch.sh v10
# Automatischer Wechsel der WezTerm-Konfig je nach Umgebung
# + Sync nach Windows
# ============================================================

set -euo pipefail
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; RESET="\033[0m"

REPO_ROOT="/media/Linux/repos/ipad"
WEZTERM_REPO="${REPO_ROOT}/wezterm"
LOG_FILE="${REPO_ROOT}/sync/switch-wezterm.log"
STATUS_FILE="$HOME/.ipad-sync-status"
WIN_SYNC_SCRIPT="${REPO_ROOT}/scripts/sync-wezterm-windows.sh"

echo "$(date '+%F %T') | switch-wezterm-branch gestartet" >>"$LOG_FILE"

# ------------------------------------------------------------
# 🔍 Umgebung erkennen
# ------------------------------------------------------------
if grep -qi microsoft /proc/version; then
  ENVIRONMENT="wsl"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  ENVIRONMENT="macos"
elif [[ "$OS" == "Windows_NT" ]]; then
  ENVIRONMENT="windows"
else
  ENVIRONMENT="linux"
fi

echo "$(date '+%F %T') | Umgebung erkannt: $ENVIRONMENT" >>"$LOG_FILE"

# ------------------------------------------------------------
# 🌿 Zielbranch wählen
# ------------------------------------------------------------
case "$ENVIRONMENT" in
  wsl)      TARGET_BRANCH="wsl-arch" ;;
  windows)  TARGET_BRANCH="windows" ;;
  macos)    TARGET_BRANCH="macos" ;;
  *)        TARGET_BRANCH="main" ;;
esac

cd "$WEZTERM_REPO"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "none")
if [[ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]]; then
  echo -e "${YELLOW}🔁 Wechsle Branch ${CURRENT_BRANCH} → ${TARGET_BRANCH}${RESET}"
  git fetch origin "$TARGET_BRANCH" >>"$LOG_FILE" 2>&1 || true
  git switch "$TARGET_BRANCH" >>"$LOG_FILE" 2>&1
  echo "$(date '+%F %T') | Branch gewechselt zu $TARGET_BRANCH" >>"$LOG_FILE"
else
  echo "$(date '+%F %T') | Bereits auf Branch $TARGET_BRANCH" >>"$LOG_FILE"
fi

# ------------------------------------------------------------
# 🧩 WezTerm-Konfig-Link prüfen
# ------------------------------------------------------------
CONFIG_SRC="${WEZTERM_REPO}/.config/wezterm/wezterm.lua"
CONFIG_DST="$HOME/.config/wezterm/wezterm.lua"

mkdir -p "$(dirname "$CONFIG_DST")"
if [[ ! -f "$CONFIG_DST" || "$CONFIG_SRC" -nt "$CONFIG_DST" ]]; then
  cp -u "$CONFIG_SRC" "$CONFIG_DST"
  echo "$(date '+%F %T') | Konfig aktualisiert → $CONFIG_DST" >>"$LOG_FILE"
fi

# ------------------------------------------------------------
# 🪟 Windows-WezTerm-Config synchronisieren (wenn möglich)
# ------------------------------------------------------------
if [[ -x "$WIN_SYNC_SCRIPT" ]]; then
  echo "$(date '+%F %T') | Starte sync-wezterm-windows.sh" >>"$LOG_FILE"
  "$WIN_SYNC_SCRIPT" >>"$LOG_FILE" 2>&1 || echo "$(date '+%F %T') | Windows-Sync Fehler" >>"$LOG_FILE"
fi

# ------------------------------------------------------------
# 💬 Status & Benachrichtigung
# ------------------------------------------------------------
echo "done" >"$STATUS_FILE"
notify-send "🌿 WezTerm Branch Sync" "Aktiver Branch: ${TARGET_BRANCH}"

echo "$(date '+%F %T') | switch-wezterm-branch abgeschlossen" >>"$LOG_FILE"