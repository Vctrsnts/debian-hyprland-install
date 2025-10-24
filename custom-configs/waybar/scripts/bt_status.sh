#!/bin/bash
#
# bt_status.sh
#
# Descripción:
#   Script para Waybar que muestra el estado de conexión de unos auriculares Bluetooth
#   utilizando la herramienta bluez-tools (bt-device). Genera una salida en formato JSON
#   que Waybar interpreta para mostrar un icono, un tooltip y una clase CSS.
#
# Funcionamiento:
#   - Comprueba si el dispositivo Bluetooth con la MAC indicada está conectado.
#   - Si está conectado:
#       * Muestra el icono de Bluetooth ().
#       * Clase CSS: "on".
#       * Tooltip con nivel de batería (si está disponible en journalctl) y volumen actual
#         de la salida de audio por defecto (obtenido con pactl).
#   - Si no está conectado:
#       * No muestra icono (ICON_OFF vacío).
#       * Clase CSS: "off".
#       * Tooltip indicando que el Bluetooth no está conectado o apagado.
#
# Dependencias:
#   - bluez-tools (bt-device, bt-adapter)
#   - pactl (PulseAudio o PipeWire con compatibilidad pactl)
#   - journalctl (para extraer el nivel de batería si el dispositivo lo reporta)
#   - Waybar (para consumir la salida JSON)
#
# Salida:
#   JSON con las claves:
#     - "text": icono a mostrar en la barra.
#     - "tooltip": texto emergente con información adicional.
#     - "class": clase CSS para aplicar estilos en Waybar.
#
# Ejemplo de salida (cuando está conectado):
#   {"text": "", "tooltip": "Auriculares conectados - 85%  45%", "class": "on"}
#
# Notas:
#   - El icono utiliza Nerd Font / Font Awesome, asegúrate de tener la fuente instalada.
#   - El nivel de batería depende de que el dispositivo lo reporte y de que BlueZ lo registre
#     en el journal.
#   - El script está pensado para integrarse en la configuración de Waybar como "custom module".
#

# Dirección MAC de los auriculares
MAC="84:0F:2A:9A:3D:E5"

# Iconos (Nerd Font / Font Awesome)
ICON_ON=""   # Bluetooth normal
ICON_OFF="󰂲"  # Bluetooth tachado

# Verifica si están conectados con bluez-tools
CONNECTED=$(bt-device -i "$MAC" | grep "Connected" | awk '{print $2}')

if [ "$CONNECTED" = "1" ]; then
    ICON="$ICON_ON"
    CLASS="on"

    # Batería desde journalctl (si el dispositivo la reporta)
    BATTERY=$(journalctl --user -n 50 | grep "Battery Level" | tail -n1 | sed -n 's/.*Battery Level: \([0-9]\+\)%.*/\1/p')

    # Volumen actual de la salida por defecto
    VOLUME=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]\+%' | head -n1)

    TOOLTIP="Auriculares conectados - ${BATTERY}%  ${VOLUME}"
else
    ICON="$ICON_OFF"
    CLASS="off"
    TOOLTIP="Bluetooth no conectado o apagado"
fi

# Salida JSON para waybar
echo "{\"text\": \"$ICON\", \"tooltip\": \"$TOOLTIP\", \"class\": \"$CLASS\"}"
