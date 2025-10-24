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

log_success "=== Preparando entorno para compilar módulos NVIDIA ==="
# Instalar headers del kernel actual y herramientas de compilación
apt_install linux-headers-$(uname -r) build-essential dkms

log_success "=== Desactivando driver nouveau ==="
sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null << EOF
blacklist nouveau
options nouveau modeset=0
EOF

log_success "Actualizando initramfs..."
sudo update-initramfs -u

# log_success "=== Habilitando repositorios contrib y non-free ==="
# sudo sed -i 's/main/main contrib non-free non-free-firmware/g' /etc/apt/sources.list

log_success "Configurando parámetro de kernel para nvidia-drm.modeset=1 en GRUB..."
GRUB_FILE="/etc/default/grub"
BACKUP_FILE="/etc/default/grub.bak.$(date +%F-%T)"

sudo cp "$GRUB_FILE" "$BACKUP_FILE"
log_success "Backup de grub creado en $BACKUP_FILE"

log_success "=== Instalando drivers propietarios de NVIDIA ==="
apt_install nvidia-driver firmware-misc-nonfree nvidia-settings nvidia-smi

if grep -q "nvidia-drm.modeset=1" "$GRUB_FILE"; then
  log_success "Parámetro nvidia-drm.modeset=1 ya está presente en GRUB_CMDLINE_LINUX_DEFAULT."
else
  sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1"/' "$GRUB_FILE"
  log_success "Parámetro añadido a GRUB_CMDLINE_LINUX_DEFAULT."
fi

log_success "Actualizando GRUB..."
sudo update-grub

log_success "=== Instalación completada. Reinicia el sistema para aplicar los cambios. ==="

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

log_success "Copiando scripts de configuración de Hyprland en ~/.config/hypr/hyprland.conf..."
cp -r ~/debian-hyprland-install/custom-configs/hypr ~/.config

log_success "Copiando scripts de configuración de Greetd en /etc/greetd"
cp -r ~/debian-hyprland-install/custom-configs/backgrounds ~/.config

log_success "Copiando scripts de configuración de Greetd en /etc/greetd"
sudo cp -r ~/debian-hyprland-install/custom-configs/greetd /etc/greetd

sudo apt -y autoremove

log_success "Procedim a moure iconos Adwaita"
sudo mv /usr/share/icons/Adwaita /usr/share/icons/Adwaita.bak

log_success "Script finalizado. Es recomendable reiniciar para aplicar todos los cambios."
