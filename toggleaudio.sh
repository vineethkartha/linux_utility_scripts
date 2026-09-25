#!/bin/bash

# 1. Get the current active default sink name
DEFAULT_SINK=$(pactl get-default-sink)

# 2. Loop through all short sink names and build the display text row by row
POPUP_ITEMS=""
while read -r name; do
    # Fetch the human-friendly description for this specific sink name
    desc=$(pactl list sinks | grep -A 50 "Name: $name" | grep "Description:" | head -n 1 | cut -d ':' -f2- | xargs)
    
    # Format the line and append it with a literal newline
    if [ "$name" = "$DEFAULT_SINK" ]; then
        POPUP_ITEMS+=$"(*) $desc | $name\n"
    else
        POPUP_ITEMS+=$"    $desc | $name\n"
    fi
done < <(pactl list short sinks | awk '{print $2}')

# 3. Mute xkbcommon errors and display the pop-up menu using Rofi
SELECTION=$(printf "$POPUP_ITEMS" | LC_ALL=C rofi -dmenu -font "Sans 36" -p "Select Audio Output:" -i -lines 5 2>/dev/null)

# Exit if the user closes the pop-up without choosing
if [ -z "$SELECTION" ]; then
    exit 0
fi

# 4. Extract the system name using native Bash string operations (everything after the last '|')
TARGET_SINK="${SELECTION##*| }"
TARGET_SINK=$(echo "$TARGET_SINK" | xargs) # Clean up trailing/leading spaces

# 5. Switch default device and move active audio streams safely
if [ -n "$TARGET_SINK" ]; then
    pactl set-default-sink "$TARGET_SINK"
    
    pactl list sink-inputs short | awk '{print $1}' | while read -r stream; do
        if [ -n "$stream" ]; then
            pactl move-sink-input "$stream" "$TARGET_SINK"
        fi
    done
fi
