#!/bin/bash
set -euo pipefail

# ===== Colores =====
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ===== Variables =====
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")

# ===== Funciones =====
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

# ===== Preparación =====
log_success "=== Preparando entorno para compilar módulos NVIDIA ==="
apt_install linux-headers-$(uname -r) build-essential dkms

# ===== Blacklist nouveau =====
log_success "=== Desactivando driver nouveau ==="
sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null << EOF
blacklist nouveau
options nouveau modeset=0
EOF

# ===== Initramfs =====
log_success "Actualizando initramfs..."
sudo update-initramfs -u

# ===== Configuración de GRUB =====
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

# ===== Configuración de modprobe =====
log_success "Creando /etc/modprobe.d/nvidia.conf con modeset=1..."
sudo tee /etc/modprobe.d/nvidia.conf > /dev/null << EOF
options nvidia_drm modeset=1
EOF

# ===== Instalación de drivers NVIDIA =====
log_success "=== Instalando drivers propietarios de NVIDIA ==="
pkgs=(
  nvidia-driver
  firmware-misc-nonfree
  nvidia-settings
  nvidia-smi
  egl-wayland
  nvidia-utils
  nvidia-dkms
  nvidia-vaapi-driver
)
apt_install "${pkgs[@]}"

# ===== Variables de entorno para Hyprland =====
log_success "Añadiendo variables de entorno a Hyprland..."
mkdir -p "$USER_HOME/.config/hypr"
HYPR_CONF="$USER_HOME/.config/hypr/hyprland.conf"

{
  echo ""
  echo "# ===== Configuración NVIDIA ====="
  echo "env = LIBVA_DRIVER_NAME,nvidia"
  echo "env = __GLX_VENDOR_LIBRARY_NAME,nvidia"
  echo "env = ELECTRON_OZONE_PLATFORM_HINT,auto"
  echo "env = NVD_BACKEND,direct"
} >> "$HYPR_CONF"

chown "$TARGET_USER":"$TARGET_USER" "$HYPR_CONF"

# ===== Suspensión/Hibernación opcional =====
read -rp "¿Quieres habilitar soporte de suspensión/hibernación para NVIDIA? (S/N): " RESP
if [[ "$RESP" =~ ^[Ss]$ ]]; then
  log_success "Habilitando servicios de suspensión/hibernación NVIDIA..."
  sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service

  log_success "Añadiendo parámetro de kernel para preservar memoria de video..."
  if grep -q "nvidia.NVreg_PreserveVideoMemoryAllocations=1" "$GRUB_FILE"; then
    log_success "Parámetro ya presente en GRUB."
  else
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia.NVreg_PreserveVideoMemoryAllocations=1"/' "$GRUB_FILE"
    sudo update-grub
    log_success "Parámetro añadido y GRUB actualizado."
  fi
else
  log_info "Omitiendo configuración de suspensión/hibernación."
fi

# ===== Suspensión/Hibernación opcional =====
read -rp "¿Quieres habilitar soporte de suspensión/hibernación para NVIDIA? (S/N): " RESP
if [[ "$RESP" =~ ^[Ss]$ ]]; then
  log_success "Habilitando servicios de suspensión/hibernación NVIDIA..."
  sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service

  log_success "Añadiendo parámetro de kernel para preservar memoria de video..."
  if grep -q "nvidia.NVreg_PreserveVideoMemoryAllocations=1" "$GRUB_FILE"; then
    log_success "Parámetro ya presente en GRUB."
  else
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia.NVreg_PreserveVideoMemoryAllocations=1"/' "$GRUB_FILE"
    sudo update-grub
    log_success "Parámetro añadido y GRUB actualizado."
  fi
else
  log_info "Omitiendo configuración de suspensión/hibernación."
fi

log_success "=== Instalación completada. Reinicia el sistema para aplicar los cambios. ==="
