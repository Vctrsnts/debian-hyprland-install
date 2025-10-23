#!/bin/bash

# --- Definicion de funciones para mensajes con color ---
# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Sin color

# Funciones de log
log_success() {
  echo -e "${GREEN}"
  echo "=========================================="
  echo -e "=== $1 ==="
  echo "=========================================="
  echo -e "${NC}"
}

# Este script prepara el sistema para la transicion a Debian Unstable.
# Se recomienda ejecutarlo como root o con sudo.

log_success "Iniciando la preparacion del sistema para Debian Unstable ---"

# --- Seccion 1: Preparacion del sistema ---

# 1. Desactivar la instalacion de paquetes sugeridos y recomendados
log_success "Configurando APT para evitar la instalacion de paquetes recomendados y sugeridos..."
echo 'APT::Install-Recommends "false";' | sudo tee /etc/apt/apt.conf.d/99-no-recommends.conf
echo 'APT::Install-Suggests "false";' | sudo tee -a /etc/apt/apt.conf.d/99-no-recommends.conf

# 2. Instalar localepurge
log_success "Instalando localepurge para limpiar idiomas no deseados..."
sudo apt install -y localepurge

# 3. Preguntar por la version de Debian actual y modificar sources.list
read -p "Por favor, introduce el nombre de la version actual de Debian (ej. 'forky'): " current_version
log_success "Modificando /etc/apt/sources.list para apuntar a 'testing'..."
sudo sed -i "s/$current_version/testing/g" /etc/apt/sources.list

log_success "Actualizando e instalando paquetes del repositorio 'testing'..."
sudo apt -y update
sudo apt -y upgrade

# 4. Modificar sources.list para usar 'unstable' (sid) y actualizar
log_success "Modificando /etc/apt/sources.list para apuntar a 'unstable' (sid)..."
# Reemplaza 'testing' por 'unstable'.
sudo sed -i 's/testing/unstable/g' /etc/apt/sources.list

log_success "Actualizando e instalando paquetes del repositorio 'unstable' (full-upgrade)..."
log_success "¡ADVERTENCIA! El siguiente paso podría eliminar paquetes. Revisa la salida de la consola cuidadosamente antes de confirmar."
# Nota: Se ha quitado el flag -y para que el usuario pueda revisar los cambios.
sudo apt -y update
sudo apt -y full-upgrade

# Eliminamos paquetes conocidos
pkgs=(
  bluez bluetooth 
  debian-faq debian-reference-common 
  debian-reference-es 
  doc-debian manpages 
  manpages-es nano 
  emacsen-common aspell 
  aspell-es dictionaries-common 
  ispanish ispell 
  wspanish task-spanish 
  laptop-detect
  apt-listchanges reportbug python3-reportbug
  python3-apt distro-info-data iso-codes
  python3-requests python3-debian
  python3-charset-normalizer
  python3-urllib3 python3-idna
  lsb-release python-apt-common
  python3-certifi python3-chardet
  python3-debconf python3-debianbts
  python3 libpython3-stdlib python3.13
  libpython3.13-stdlib python3-minimal
  python3.13-minimal libpython3.13-minimal
)

sudo apt purge -y "${pkgs[@]}"
sudo apt -y autoremove

log_success "Copiem scripts instalació"
git clone https://github.com/Vctrsnts/debian-hyprland-install.git

log_success "Se ejecuta la actualización del funcionamiento de los sources"
sudo apt -y modernize-sources

log_success "Eliminamos aplicacion aptitude"
sudo apt purge -y aptitude w3m task-laptop task-spanish && sudo apt -y autoremove

#log_success "Instalem aplicacions wireless"
#sudo apt install -y iw wireless-tools wpasupplicant wireless-regdb

exit 0
