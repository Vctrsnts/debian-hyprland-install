#!/bin/bash
set -e

### ============================================================
### 1. Actualizar el sistema
### ============================================================
sudo apt update && sudo apt full-upgrade -y

### ============================================================
### 2. Instalar headers del kernel en uso
### ============================================================
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
### 5. Configurar opciones del módulo NVIDIA (para initramfs)
### ============================================================
# Esto es bueno para que initramfs conozca la opción
echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia-drm.conf
echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" | sudo tee /etc/modprobe.d/nvidia-options.conf

### ============================================================
### 6. [NUEVO] Configurar GRUB para Early KMS (El paso clave)
### ============================================================
# Esto fuerza al kernel a cargar el módulo con modeset activado en el arranque temprano
# Comprobamos si el parámetro ya existe para no duplicarlo
if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
    echo "Añadiendo 'nvidia-drm.modeset=1' a GRUB_CMDLINE_LINUX_DEFAULT..."
    sudo sed -i 's/^\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"/\1 nvidia-drm.modeset=1"/' /etc/default/grub
else
    echo "'nvidia-drm.modeset=1' ya está presente en la configuración de GRUB."
fi
# Actualizamos GRUB para aplicar el cambio
sudo update-grub

### ============================================================
### 7. Regenerar initramfs
### ============================================================
# Ahora que GRUB y modprobe están configurados, regeneramos
sudo update-initramfs -u

### ============================================================
### 8. Instalar Hyprland y utilidades básicas
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
    libnvidia-egl-wayland1 \
    vulkan-tools \
    libvulkan1 \
    nvidia-vulkan-icd

### ============================================================
### 9. [MODIFICADO] Configurar variables de entorno para Hyprland
### ============================================================
# Este método es más robusto que environment.d
# Aseguramos que el directorio de config de Hyprland exista
mkdir -p ~/.config/hypr/

# Creamos un archivo .conf solo para las variables de NVIDIA
# y nos aseguramos de que hyprland.conf lo cargue.
cat > ~/.config/hypr/nvidia.conf <<EOF
# Variables recomendadas por Hyprland para NVIDIA
env = WLR_NO_HARDWARE_CURSORS,1
env = WLR_RENDERER,vulkan
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
EOF

# Añadimos la línea para "sourcear" este archivo al final de hyprland.conf
# Usamos 'tee -a' para añadir sin sobrescribir
echo -e "\n# Cargar configuración específica de NVIDIA\nsource = ~/.config/hypr/nvidia.conf" | tee -a ~/.config/hypr/hyprland.conf

### ============================================================
### 10. Mensaje final
### ============================================================
echo "=== Instalación completada ==="
echo "Reinicia el sistema y selecciona Hyprland en tu gestor de sesión."
echo "IMPORTANTE: El Paso 6 modificó /etc/default/grub. Revísalo si algo falla."
