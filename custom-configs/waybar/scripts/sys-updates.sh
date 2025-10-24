#!/bin/bash
#
# Script: sys-updates.sh
# Descripción:
#   Este script cuenta el número de paquetes pendientes de actualización en un
#   sistema Debian/Ubuntu usando `apt-get --just-print upgrade`.
#   La salida está formateada en JSON para que Waybar (con Sway/Wayland)
#   pueda mostrarlo como un módulo *custom*.
#
# Funcionamiento:
#   - Ejecuta una simulación de `apt-get upgrade` sin aplicar cambios.
#   - Filtra las líneas que comienzan con "Inst", que corresponden a paquetes
#     que serían instalados/actualizados.
#   - Cuenta esas líneas para obtener el número total de actualizaciones.
#   - Según el resultado:
#       * Si hay actualizaciones, muestra un icono y el número.
#       * Si no hay, muestra un icono distinto indicando que está al día.
#   - Además asigna una clase CSS distinta para personalizar estilos en Waybar.
#
# Uso:
#   - Colocar este script en ~/.config/waybar/scripts/updates.sh
#   - Dar permisos de ejecución: chmod +x updates.sh
#   - Configurar en ~/.config/waybar/config como módulo "custom/updates"
#

updates=$(apt-get --just-print upgrade 2>/dev/null | grep "^Inst" | wc -l)

icon_full="󰮏"   # flecha de descarga (ej. "⬇️")
icon_empty="󱂱"  # flecha tachada (ej. "✔️")

if [ "$updates" -gt 0 ]; then
  text="$icon_full $updates"
  if [ "$updates" -ge 10 ]; then
    class="many-updates"
  else
    class="default"
  fi
else
  text="$icon_empty"
  class="normal"
fi

echo "{\"text\": \"$text\", \"class\": \"$class\"}"
