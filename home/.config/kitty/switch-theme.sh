#!/bin/sh
set -eu

config_dir="$HOME/.config/kitty"
if [ "$(defaults read -g AppleInterfaceStyle 2>/dev/null || true)" = Dark ]; then
  theme=dark
else
  theme=light
fi
printf 'include themes/%s.conf\n' "$theme" > "$config_dir/theme.conf"
