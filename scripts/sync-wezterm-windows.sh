#!/usr/bin/env bash
# ============================================================
# sync-wezterm-windows.sh v10
# Kopiert WezTerm-Config automatisch ins Windows-Profil
# ============================================================

set -euo pipefail

# 🧠 Windows-Username automatisch bestimmen
WIN_USER=$(powershell.exe -NoProfile -Command '$env:USERNAME' | tr -d '\r')
WIN_CONF="/mnt/c/Users/${WIN_USER}/.config/wezterm"
SRC="$HOME/repos/stow/dotfiles/wezterm/.config/wezterm/wezterm.lua"
LOG_FILE="/media/Linux/repos/ipad/sync/switch-wezterm.log"

echo "$(date '+%F %T') | sync-wezterm-windows gestartet (User: $WIN_USER)" >>"$LOG_FILE"

if [[ ! -f "$SRC" ]]; then
  echo "❌ Quelle $SRC fehlt" | tee -a "$LOG_FILE"
  exit 1
fi

mkdir -p "$WIN_CONF"
cp -u "$SRC" "$WIN_CONF/wezterm.lua"

echo "✅ Windows-WezTerm aktualisiert → $WIN_CONF/wezterm.lua" | tee -a "$LOG_FILE"
notify-send "🪟 Windows-WezTerm aktualisiert" "Datei kopiert für Benutzer ${WIN_USER}"