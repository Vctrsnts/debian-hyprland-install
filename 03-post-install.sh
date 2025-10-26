#!/bin/bash
set -euo pipefail

# --- Definicion de funciones para mensajes con color ---
# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Sin color

# ===== Variables =====
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")

# Funciones
apt_install(){
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends "$@"
}
apt_purge(){
  sudo apt purge -y "$@"
}
log_success() {
  echo -e "${GREEN}"
  echo "=========================================="
  echo -e "=== $1 ==="
  echo "=========================================="
  echo -e "${NC}"
}
ensure_dirs_user(){
    local dir="$1"
    install -d -m 755 -o "$TARGET_USER" -g "$TARGET_USER" "$dir"
}
mod_fuentes() {
  echo "🔠 Instalación de Nerd Fonts en el entorno del usuario…"
  read -p "¿Continuar con la instalación de Nerd Fonts? (s/n): " RESP
  [[ "$RESP" != "s" ]] && return 0

  local FONT_DIR="$USER_HOME/.local/share/fonts"
  ensure_dirs_user "$FONT_DIR"
  
  local font = "SourceCodePro"

  echo "⬇️ Descargando fuente: $font"
  local URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/$font.zip"
  local ZIP_PATH="/tmp/$font.zip"

  if ! wget -q --show-progress "$URL" -O "$ZIP_PATH"; then
    echo "⚠️ Fallo al descargar $font desde $URL; se omite."
    continue
  fi

  rm -f "$ZIP_PATH"

  echo -e "\n🔄 Refrescando caché de fuentes…"
  read -p "¿Actualizar caché de fuentes ahora? (s/n): " RESP
  [[ "$RESP" == "s" ]] && sudo -u "$TARGET_USER" fc-cache -fv "$FONT_DIR" >/dev/null || fc-cache -fv "$FONT_DIR" >/dev/null || true

  echo "✅ Fuentes instaladas y caché actualizada."
}
mod_tema_oscuro() {  
  THEME="Nordic"
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  echo "🖤 Aplicando tema GTK oscuro: $THEME con iconos $ICON_THEME"

  TMP_DIR=$(mktemp -d) || { echo "❌ No se pudo crear directorio temporal"; return 1; }
  ICON_TMP=$(mktemp -d) || { echo "❌ No se pudo crear directorio temporal para iconos"; return 1; }
  trap 'rm -rf "$TMP_DIR" "$ICON_TMP"' EXIT

  mkdir -p "$HOME/.local/share/themes"
  mkdir -p "$HOME/.local/share/icons"

  echo "🔧 Actualizando paquetes e instalando dependencias necesarias..."
  read -p "¿Continuar con la instalación de dependencias? (s/n): " RESP
  [[ "$RESP" == "s" ]] || return 0

  if ! sudo apt update && sudo apt install -y gtk2-engines-murrine git; then
      echo "❌ Error instalando dependencias"
      return 1
  fi

  echo "🎨 Preparando instalación del tema Nordic..."
  read -p "¿Instalar tema Nordic en ~/.local/share/themes? (s/n): " RESP
  [[ "$RESP" == "s" ]] || return 0

  THEME_DEST="$HOME/.local/share/themes/Nordic"
  if [[ ! -d "$THEME_DEST" ]]; then
      git clone https://github.com/EliverLara/Nordic.git "$TMP_DIR/Nordic" &&
      mkdir -p "$THEME_DEST" &&
      cp -r "$TMP_DIR/Nordic"/* "$THEME_DEST/" &&
      echo "✅ Tema Nordic instalado en el directorio del usuario"
  else
      echo "ℹ️ Tema Nordic ya está instalado en el directorio del usuario"
  fi
}

# INICI DE APLICACIO

log_success "Procedim a la instalacio de paquets suplementaris"
# instalacion de aplicaciones externas
pkgs=(
  btm fonts-roboto kitty mc 
  fonts-hack fonts-jetbrains-mono
  fonts-firacode fonts-font-awesome
  libglib2.0-bin
)

apt_install "${pkgs[@]}"

# Son paquetes para copiar al portapapeles
#clipman wl-clipboard

log_success "Procedim a copia el wallpaper de gtkgreet"
sudo mkdir -p /usr/share/backgrounds
sudo mv $HOME/.config/backgrounds/login.jpg /usr/share/backgrounds/login.jpg
sudo chmod 644 /usr/share/backgrounds/login.jpg
sudo chown -R root:root /usr/share/backgrounds/login.jpg
log_success "Instalacio de les fonts, estil obscurs i GTK"
mod_fuentes
mod_tema_oscuro
echo ""
log_success "Desinstalem paquets que ja no es faran servir"
pkgs=(
  git
)
apt_purge "${pkgs[@]}"
sudo apt -y autoremove

log_success "Procedim a moure iconos Adwaita"
sudo mv /usr/share/icons/Adwaita /usr/share/icons/Adwaita.bak
