#!/bin/bash

# Obtener volumen y estado de mute del sink por defecto
current_volume=$(pactl get-sink-volume @DEFAULT_SINK@ | head -n 1)
mute_state=$(pactl get-sink-mute @DEFAULT_SINK@)

# Extraer solo el valor numérico del volumen (sin %)
volume=$(echo "$current_volume" | awk '{print $5}' | tr -d '%')

# Si está muteado
if [[ $mute_state == *"yes"* ]]; then
    echo "  ---"
    exit 0
fi

# Mantener la misma lógica de tu script original
if [ "$volume" -gt "99" ]; then
    echo "  $volume%"
elif [ "$volume" -gt "65" ]; then
    echo "  $volume%"
elif [ "$volume" -gt "30" ]; then
    echo "  $volume%"
elif [ "$volume" -gt "10" ]; then
    echo "  $volume%"
elif [ "$volume" -gt "0" ]; then
    echo "  $volume%"
elif [ "$volume" -lt "1" ]; then
    echo "  ---"
fi
