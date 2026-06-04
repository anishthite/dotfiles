#!/bin/bash

# Get macOS system appearance
THEME=$(defaults read -g AppleInterfaceStyle 2>/dev/null)

# Path to Alacritty config directory
ALACRITTY_CONFIG_DIR="$HOME/.config/alacritty"
CURRENT_THEME_FILE="$ALACRITTY_CONFIG_DIR/current_theme.yml"

# Determine which theme to use
if [[ "$THEME" == "Dark" ]]; then
    cp "$ALACRITTY_CONFIG_DIR/themes/dark.yml" "$CURRENT_THEME_FILE"
    echo "Switched to dark theme"
else
    cp "$ALACRITTY_CONFIG_DIR/themes/light.yml" "$CURRENT_THEME_FILE"
    echo "Switched to light theme"
fi

# Send SIGUSR1 to all Alacritty processes to reload config
pkill -USR1 alacritty 2>/dev/null || true