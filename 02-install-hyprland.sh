#!/bin/bash
set -euo pipefail
# Este script instala los componentes esenciales para un entorno Sway funcional y minimalista
# en Debian Unstable, con todos los paquetes en una única sección de instalación.

# ===== Colores =====
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ===== Variables =====
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")

# Función para manejar errores
log_error() {
  echo -e "${RED}"
  echo "=========================================="
  echo -e "!!! Ha ocurrido un fallo en el script. Saliendo... !!!"
  echo "=========================================="
  echo -e "${NC}"
  exit 1
}
log_success() {
  echo -e "${GREEN}"
  echo "=========================================="
  echo -e "=== $1 ==="
  echo "=========================================="
  echo -e "${NC}"
}
log_info() {
  echo -e "${YELLOW}"
  echo "=========================================="
  echo -e "--- $1 ---"
  echo "=========================================="
  echo -e "${NC}"
}
apt_install(){
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends "$@"
}
mod_terminal(){
  log_info "Añadiendo el repositorio de WezTerm e instalando..."

  # Descargar la clave GPG
  curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg

  # Agregar el repositorio
  echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list

  sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg

  # Instalar WezTerm
  apt_install wezterm

  log_success "🎉 WezTerm instalado correctamente."
}
mod_librewolf(){
  log_info "Añadiendo el repositorio de WezTerm e instalando..."
  ! [ -d /etc/apt/keyrings ] && sudo mkdir -p /etc/apt/keyrings && sudo chmod 755 /etc/apt/keyrings
  
  log_info "Descargando y guardando clave gpg..."
  wget -O- https://download.opensuse.org/repositories/home:/bgstack15:/aftermozilla/Debian_Unstable/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/home_bgstack15_aftermozilla.gpg
  
  log_info "Añadiendo source..."
  
  sudo tee /etc/apt/sources.list.d/home_bgstack15_aftermozilla.sources << EOF > /dev/null
Types: deb
URIs: https://download.opensuse.org/repositories/home:/bgstack15:/aftermozilla/Debian_Unstable/
Suites: /
Signed-By: /etc/apt/keyrings/home_bgstack15_aftermozilla.gpg
EOF

  apt_install librewolf
}

log_success "Instalando Hyprland y paquetes relacionados..."

pkgs=(
  hyprland hyprpaper waybar nwg-look greetd gtkgreet
  mako-notifier wayland-protocols xwayland
  wofi polkitd lxpolkit hypridle
  acpi acpid eza 
  pulseaudio pulseaudio-utils pamixer
  pavucontrol curl gpg unzip 
  thunar gvfs gvfs-backends udisks2
  xdg-user-dirs xdg-utils 
  libpam0g libseat1 fastfetch
  libnotify-bin libgles-nvidia2
  gsettings-desktop-schemas 
)

apt_install "${pkgs[@]}"

log_success "Activant servei acpid"
sudo systemctl enable acpid

mod_terminal

mod_librewolf

log_success "Actualem .bashrc"
cp $HOME/debian-hyprland-install/custom-configs/bashrc $HOME/.bashrc
source $HOME/.bashrc

log_success "Copiando scripts de configuración de Hyprland en ~/.config/hypr/hyprland.conf..."
cp -r ~/debian-hyprland-install/custom-configs/hypr ~/.config/hypr

log_success "Copiando scripts de configuración de Greetd en /etc/greetd"
cp -r ~/debian-hyprland-install/custom-configs/backgrounds ~/.config/backgrounds

log_success "Copiando scripts de configuración de Greetd en /etc/greetd"
sudo cp -r ~/debian-hyprland-install/custom-configs/greetd /etc/greetd

sudo apt -y autoremove

log_success "Procedim a moure iconos Adwaita"
sudo mv /usr/share/icons/Adwaita /usr/share/icons/Adwaita.bak

log_success "Script finalizado. Es recomendable reiniciar para aplicar todos los cambios."
