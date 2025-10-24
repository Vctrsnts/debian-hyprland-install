#!/bin/bash
#
# Script: sys-resources.sh
# Descripción:
#   Este script muestra en Waybar un resumen del estado del sistema:
#   - Uso de CPU en porcentaje.
#   - Uso de memoria RAM en porcentaje.
#   - Espacio libre en la partición /home.
#   La salida es un texto con iconos, pensado para integrarse como módulo *custom*.
#
# Funcionamiento:
#   - CPU: Lee /proc/stat y calcula el porcentaje de uso con `awk`.
#   - RAM: Usa `free` para obtener memoria usada/total y calcular el porcentaje.
#   - Disco: Usa `df -h /home` y extrae el espacio libre disponible.
#   - Finalmente imprime una línea con iconos (requiere Nerd Fonts) y los valores.
#
# Uso:
#   - Guardar como ~/.config/waybar/scripts/system_status.sh
#   - Dar permisos de ejecución: chmod +x system_status.sh
#   - Configurar en ~/.config/waybar/config como módulo "custom/system"
#

cpu=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.0f", usage}')
mem=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
disk=$(df -h /home | awk 'NR==2 {print $4}')
echo " ${cpu}%    ${mem}%   ${disk}"
