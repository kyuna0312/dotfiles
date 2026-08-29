#!/usr/bin/env bash
# toggle-hud: hide/show the Übersicht ARASAKA bar and collapse the right
# gap with it. aerospace has no runtime gap API, so we rewrite outer.right
# and reload. Übersicht has no per-widget CLI toggle, so we quit/relaunch
# the app (only the one bar widget is loaded).
TOML="$HOME/.config/aerospace/aerospace.toml"

if pgrep -f "Übersicht.app/Contents/MacOS" >/dev/null; then
  osascript -e 'quit app "Übersicht"' 2>/dev/null
  sed -i '' 's/^outer.right =[ ]*64/outer.right =      24/' "$TOML"
else
  open -a "Übersicht"
  sed -i '' 's/^outer.right =[ ]*24/outer.right =      64/' "$TOML"
fi

aerospace reload-config
