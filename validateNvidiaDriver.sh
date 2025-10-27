#!/bin/bash
set -e

echo "=== Validación de instalación NVIDIA + Hyprland en Debian unstable ==="

### ============================================================
### 1. Comprobar versión del kernel y headers
### ============================================================
echo "[Kernel]"
uname -r
dpkg -l | grep "linux-headers-$(uname -r)" || echo "❌ Headers del kernel no instalados"

### ============================================================
### 2. Comprobar que nouveau está deshabilitado
### ============================================================
echo "[Módulos cargados - comprobando nouveau]"
if lsmod | grep -q nouveau; then
    echo "❌ El módulo nouveau sigue cargado"
else
    echo "✔️  nouveau está deshabilitado"
fi

### ============================================================
### 3. Comprobar que el driver NVIDIA está cargado
### ============================================================
echo "[Módulos cargados - comprobando nvidia]"
if lsmod | grep -q nvidia; then
    echo "✔️  El módulo nvidia está cargado"
else
    echo "❌ El módulo nvidia no está cargado"
fi

### ============================================================
### 4. Validar que DRM modeset está activo
### ============================================================
echo "[DRM modeset]"
if [ -f /sys/module/nvidia_drm/parameters/modeset ]; then
    cat /sys/module/nvidia_drm/parameters/modeset
else
    echo "❌ No se encontró el parámetro nvidia_drm modeset"
fi

### ============================================================
### 5. Comprobar estado de nvidia-smi
### ============================================================
echo "[nvidia-smi]"
if command -v nvidia-smi &>/dev/null; then
    nvidia-smi || echo "❌ nvidia-smi no pudo ejecutarse correctamente"
else
    echo "❌ nvidia-smi no está instalado"
fi

### ============================================================
### 6. Comprobar variables de entorno recomendadas
### ============================================================
echo "[Variables de entorno]"
for var in WLR_NO_HARDWARE_CURSORS WLR_RENDERER LIBVA_DRIVER_NAME GBM_BACKEND __GLX_VENDOR_LIBRARY_NAME; do
    grep -q "$var" ~/.config/environment.d/nvidia.conf && echo "✔️  $var configurada" || echo "❌ $var no encontrada"
done

### ============================================================
### 7. Comprobar que Hyprland está instalado
### ============================================================
echo "[Hyprland]"
if command -v Hyprland &>/dev/null; then
    echo "✔️  Hyprland está instalado"
else
    echo "❌ Hyprland no está instalado"
fi

echo "=== Validación completada ==="
