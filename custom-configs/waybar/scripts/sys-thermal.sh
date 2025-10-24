#!/bin/bash
#
# Script: sys-thermal.sh
# Descripción:
#   Este script obtiene la temperatura actual de la CPU (concretamente del
#   "Package id 0" reportado por la utilidad `sensors`) y muestra el valor en
#   formato JSON para que Waybar lo represente como un módulo *custom*.
#
# Funcionamiento:
#   - Ejecuta `sensors` y busca la línea que comienza por "Package id 0:".
#   - Extrae el cuarto campo (ejemplo: +47.0°C).
#   - Elimina el signo "+" y el sufijo "°C".
#   - Convierte el valor a número entero.
#   - Si se obtiene un valor válido:
#       * Muestra un icono de termómetro y la temperatura.
#       * Asigna la clase "hot" si la temperatura es ≥70°C, o "normal" en caso contrario.
#   - Si no se obtiene un valor válido:
#       * Muestra un icono de interrogación y el texto "?".
#   - Si la temperatura supera los 90°C:
#       * Lanza una notificación de advertencia con `notify-send`.
#   - La salida en JSON permite a Waybar aplicar estilos CSS según la clase.
#
# Uso:
#   - Guardar como ~/.config/waybar/scripts/temperature.sh
#   - Dar permisos de ejecución: chmod +x temperature.sh
#   - Configurar en ~/.config/waybar/config como módulo "custom/temperature"
#

# Obtener la temperatura del "Package id 0" usando sensors
temp_c=$(sensors | awk '/^Package id 0:/ {gsub(/\+|°C/,"",$4); print int($4)}')

# Si se ha obtenido un valor válido, usar el icono de termómetro
if [[ -n "$temp_c" ]]; then
  temp_icon=""   # icono de termómetro (requiere Nerd Fonts)
else
  temp_c="?"
  temp_icon=""   # icono de interrogación
fi

# Definir la clase CSS según la temperatura
if [[ "$temp_c" != "?" && "$temp_c" -ge 70 ]]; then
  class="hot"
else
  class="normal"
fi

# Enviar una notificación si la temperatura supera los 90°C
if [[ "$temp_c" != "?" && "$temp_c" -ge 90 ]]; then
  notify-send "⚠️ CPU caliente" "La CPU está a ${temp_c}°C"
fi

# Imprimir la salida en formato JSON para Waybar
echo "{\"text\": \"$temp_icon ${temp_c}°C\", \"class\": \"$class\"}"
