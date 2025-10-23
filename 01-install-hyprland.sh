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

echo "Actualizando lista de paquetes..."
sudo apt update

log_success "Instalando drivers NVIDIA y firmware..."
apt_install nvidia-driver firmware-misc-nonfree

log_success "Creando archivo para blacklist de nouveau..."
sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null << EOF
blacklist nouveau
options nouveau modeset=0
EOF

log_success "Actualizando initramfs..."
sudo update-initramfs -u

log_success "Configurando parámetro de kernel para nvidia-drm.modeset=1 en GRUB..."

GRUB_FILE="/etc/default/grub"
BACKUP_FILE="/etc/default/grub.bak.$(date +%F-%T)"

sudo cp "$GRUB_FILE" "$BACKUP_FILE"
log_success "Backup de grub creado en $BACKUP_FILE"

if grep -q "nvidia-drm.modeset=1" "$GRUB_FILE"; then
  log_success "Parámetro nvidia-drm.modeset=1 ya está presente en GRUB_CMDLINE_LINUX_DEFAULT."
else
  sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1"/' "$GRUB_FILE"
  log_success "Parámetro añadido a GRUB_CMDLINE_LINUX_DEFAULT."
fi

log_success "Actualizando GRUB..."
sudo update-grub

log_success "Instalando Hyprland y paquetes relacionados..."

pkgs=(
  hyprland hyprpaper waybar nwg-look greetd gtkgreet
  mako-notifier wayland-protocols xwayland
  wofi polkitd lxpolkit
  acpi acpid eza mc 
  pulseaudio pulseaudio-utils pamixer
  pavucontrol 
  curl gpg unzip 
  thunar gvfs gvfs-backends udisks2
  xdg-user-dirs xdg-utils 
  libpam0g libseat1 fastfetch
  libnotify-bin
  gsettings-desktop-schemas 
)

apt_install "${pkgs[@]}"

log_success "Activant servei acpid"
sudo systemctl enable acpid

mod_terminal

log_success "Copiando scripts de configuración de Hyprland en ~/.config/hypr/hyprland.conf..."
cp -r ~/debian-hyprland-install/custom-configs/hypr ~/.config

log_success "Copiando scripts de configuración de Greetd en /etc/greetd"
cp -r ~/debian-hyprland-install/custom-configs/backgrounds ~/.config

log_success "Procedim a copia el wallpaper de gtkgreet"
sudo mkdir -p /usr/share/backgrounds
sudo mv $HOME/.config/backgrounds/login.jpg /usr/share/backgrounds/login.jpg
sudo chmod 644 /usr/share/backgrounds/login.jpg
sudo chown -R root:root /usr/share/backgrounds/login.jpg

log_success "Copiando scripts de configuración de Greetd en /etc/greetd"
sudo cp -r ~/debian-hyprland-install/custom-configs/greetd /etc/greetd

log_success "Desinstalem paquets que ja no es faran servir"
pkgs=(
  git
)
apt_purge "${pkgs[@]}"
sudo apt -y autoremove

log_success "Procedim a moure iconos Adwaita"
sudo mv /usr/share/icons/Adwaita /usr/share/icons/Adwaita.bak

log_success "Script finalizado. Es recomendable reiniciar para aplicar todos los cambios."
