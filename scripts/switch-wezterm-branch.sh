#!/usr/bin/env bash
set -euo pipefail

GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; RESET="\033[0m"
echo -e "${GREEN}🔧 Starte WezTerm Branch Sync...${RESET}"

# 🔍 Automatische Erkennung des USB-Laufwerkslabels
USB_DEVICE_LABEL=${USB_DEVICE_LABEL:-}
if [[ -z "$USB_DEVICE_LABEL" ]]; then
  echo -e "${YELLOW}🔍 Suche nach Wechsellaufwerk...${RESET}"
  USB_DEVICE_LABEL=$(lsblk -o LABEL,FSTYPE,RM | awk '$3 == 1 && $2 != "" {print $1; exit}')
  USB_DEVICE_LABEL=${USB_DEVICE_LABEL:-Linux}
fi
MOUNT_POINT="/media/${USB_DEVICE_LABEL}"
echo -e "${GREEN}📀 Verwende Label: ${USB_DEVICE_LABEL}${RESET}"

# 🔌 Mount falls nicht vorhanden
if ! mountpoint -q "$MOUNT_POINT"; then
  echo -e "${YELLOW}⚙️  Mount ${MOUNT_POINT}...${RESET}"
  if command -v usbipd.exe &>/dev/null; then
    BUS_ID=$(usbipd.exe wsl list | grep -i "$USB_DEVICE_LABEL" | awk '{print $1}' | tr -d '\r' || true)
    [[ -n "$BUS_ID" ]] && powershell.exe "usbipd attach --wsl --busid $BUS_ID" >/dev/null 2>&1 || true
  fi
  sudo mkdir -p "$MOUNT_POINT"
  sudo mount -L "$USB_DEVICE_LABEL" "$MOUNT_POINT" || { echo -e "${RED}❌ Mount fehlgeschlagen.${RESET}"; exit 1; }
fi

# 🧠 Umgebungserkennung
if grep -qi microsoft /proc/version 2>/dev/null; then
  TARGET_BRANCH="wsl-arch"; TARGET_SYSTEM="🐧 WSL / Arch"
else
  TARGET_BRANCH="windows-proxy"; TARGET_SYSTEM="🪟 Windows"
fi
echo -e "${GREEN}➡️  System erkannt: ${TARGET_SYSTEM}${RESET}"

# 📁 Dotfiles
DOTFILES_DIR="$MOUNT_POINT/repos/stow/dotfiles"
PACKAGE="wezterm"
cd "$DOTFILES_DIR" || { echo -e "${RED}❌ Kein Dotfile-Verz.${RESET}"; exit 1; }

# 🌿 Branch-Handling
git fetch origin >/dev/null 2>&1 || true
if ! git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
  git checkout -b "$TARGET_BRANCH"
else
  git switch "$TARGET_BRANCH"
fi

# 🧰 stow anwenden
TARGET_DIR="$HOME"
if [[ $TARGET_BRANCH == "windows-proxy" ]]; then
  WIN_HOME=$(wslvar USERPROFILE 2>/dev/null || echo "/mnt/c/Users/$(powershell.exe '$env:UserName' | tr -d '\r')")
  TARGET_DIR="$WIN_HOME"
fi
stow --restow --target="$TARGET_DIR" "$PACKAGE"

# 💾 Git Commit + Push
if [[ -n "$(git status --porcelain)" ]]; then
  git add .
  git commit -m "Auto-update WezTerm $(date '+%Y-%m-%d %H:%M:%S') [$TARGET_BRANCH]"
  git push origin "$TARGET_BRANCH"
  echo -e "${GREEN}✅ Änderungen gepusht.${RESET}"
else
  echo -e "${GREEN}✔️  Keine Änderungen.${RESET}"
fi