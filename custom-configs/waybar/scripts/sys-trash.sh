#!/bin/bash
#
# Script: sys-trash.sh
# Descripción:
#   Este script cuenta el número de archivos presentes en la papelera de usuario
#   (ubicada en ~/.local/share/Trash/files) y muestra el resultado en formato JSON
#   para que Waybar lo represente como un módulo *custom*.
#
# Funcionamiento:
#   - Usa `find` para localizar todos los archivos dentro de la carpeta de la papelera.
#   - Cuenta el total con `wc -l`.
#   - Si hay archivos:
#       * Muestra un icono de papelera llena y el número de elementos.
#       * Asigna la clase "default" o "many-trash" si supera un umbral (≥10).
#   - Si no hay archivos:
#       * Muestra un icono de papelera vacía.
#       * Asigna la clase "normal".
#   - La salida en JSON permite a Waybar aplicar estilos CSS según la clase.
#
# Uso:
#   - Guardar como ~/.config/waybar/scripts/trash.sh
#   - Dar permisos de ejecución: chmod +x trash.sh
#   - Configurar en ~/.config/waybar/config como módulo "custom/trash"
#

trash_count=$(find ~/.local/share/Trash/files -type f 2>/dev/null | wc -l)

icon_full=""   # icono de papelera llena (requiere Nerd Fonts)
icon_empty=""  # icono de papelera vacía (requiere Nerd Fonts)

if [ "$trash_count" -gt 0 ]; then
  text="$icon_full $trash_count"
  if [ "$trash_count" -ge 10 ]; then
    class="many-trash"
  else
    class="default"
  fi
else
  text="$icon_empty"
  class="normal"
fi

echo "{\"text\": \"$text\", \"class\": \"$class\"}"
