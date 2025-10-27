#!/bin/bash
set -e

### ============================================================
### 1. Actualizar el sistema
### ============================================================
sudo apt update && sudo apt full-upgrade -y

### ============================================================
### 2. Instalar headers del kernel en uso
### ============================================================
# Detectamos la versión exacta del kernel en ejecución y
# instalamos sus headers correspondientes.
sudo apt install -y "linux-headers-$(uname -r)"

### ============================================================
### 3. Instalar drivers propietarios de NVIDIA
### ============================================================
sudo apt install -y nvidia-driver firmware-misc-nonfree nvidia-settings

### ============================================================
### 4. Deshabilitar el driver libre nouveau
### ============================================================
echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf

### ============================================================
### 5. Configurar opciones del módulo NVIDIA
### ============================================================
echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia-drm.conf
echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" | sudo tee /etc/modprobe.d/nvidia-options.conf

### ============================================================
### 6. Regenerar initramfs
### ============================================================
sudo update-initramfs -u

### ============================================================
### 7. Instalar Hyprland y utilidades básicas
### ============================================================
sudo apt install -y hyprland \
    xdg-desktop-portal-hyprland \
    waybar \
    rofi \
    kitty \
    wl-clipboard \
    grim slurp \
    brightnessctl \
    pavucontrol \
    network-manager-gnome

### ============================================================
### 8. Configurar variables de entorno para NVIDIA + Hyprland
### ============================================================
mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/nvidia.conf <<EOF
# Variables recomendadas por Hyprland para NVIDIA
WLR_NO_HARDWARE_CURSORS=1
WLR_RENDERER=vulkan
LIBVA_DRIVER_NAME=nvidia
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
EOF

### ============================================================
### 9. Mensaje final
### ============================================================
echo "=== Instalación completada ==="
echo "Reinicia el sistema y selecciona Hyprland en tu gestor de sesión."
