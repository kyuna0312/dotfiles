#!/usr/bin/env bash
# toggle-hud: hide/show sketchybar and collapse the right gap with it.
# aerospace has no runtime gap API, so we rewrite outer.right and reload.
TOML="$HOME/.config/aerospace/aerospace.toml"

hidden=$(sketchybar --query bar | grep -o '"hidden": "[a-z]*"' | cut -d'"' -f4)

if [ "$hidden" = "off" ]; then
  sketchybar --bar hidden=on
  sed -i '' 's/^outer.right =[ ]*80/outer.right =      24/' "$TOML"
else
  sketchybar --bar hidden=off
  sed -i '' 's/^outer.right =[ ]*24/outer.right =      80/' "$TOML"
fi

aerospace reload-config
