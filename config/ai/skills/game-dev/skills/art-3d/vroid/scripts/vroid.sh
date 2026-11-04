#!/bin/bash
# Drive VRoid Studio (or any app via APP=...) with screenshots + synthetic input. Coordinates are WINDOW-RELATIVE pixels
# (same as the screenshot), origin top-left of the app window.
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$DIR/bin/input"
APP="${APP:-VRoid Studio}"   # window owner name; bundle is VRoidStudio.app
SHOT_DIR="${SHOT_DIR:-/tmp/vroid-shots}"
[ -x "$BIN" ] || { mkdir -p "$DIR/bin"; swiftc -O -o "$BIN" "$DIR/input.swift"; }

win() { "$BIN" window "$APP"; }   # x y w h id
abs() { read -r wx wy ww wh wid < <(win); echo "$((wx + $1)) $((wy + $2))"; }
front() { osascript -e "tell application \"$APP\" to activate" >/dev/null 2>&1 || true; sleep 0.3; }

case "$1" in
  check)
    "$BIN" check
    mkdir -p "$SHOT_DIR"; screencapture -x -R 0,0,2,2 "$SHOT_DIR/_probe.png" 2>/dev/null && echo "screen recording: OK (if captures are black, enable Screen Recording for your terminal)" ;;
  open)
    open -a "$APP" 2>/dev/null || open -a "${APP// /}"; for i in $(seq 1 60); do win >/dev/null 2>&1 && break; sleep 1; done; front; win ;;
  window) win ;;
  front) front ;;
  shot)
    mkdir -p "$SHOT_DIR"; out="${2:-$SHOT_DIR/$(date +%H%M%S).png}"
    read -r wx wy ww wh wid < <(win)
    screencapture -x -o -l "$wid" "$out"
    # downscale retina captures to window points so pixel coords == click coords
    pw=$(sips -g pixelWidth "$out" | awk '/pixelWidth/{print $2}')
    [ "$pw" -gt "$ww" ] && sips --resampleWidth "$ww" "$out" >/dev/null
    echo "$out ${ww}x${wh}" ;;
  click|dclick|rclick|move)
    front; "$BIN" "$1" $(abs "$2" "$3") ;;
  drag)
    front; "$BIN" drag $(abs "$2" "$3") $(abs "$4" "$5") ;;
  scroll)   # scroll X Y DX DY   (DY<0 = scroll content up)
    front; "$BIN" scroll $(abs "$2" "$3") "$4" "$5" ;;
  key)      # key return [cmd shift alt ctrl]
    front; shift; "$BIN" key "$@" ;;
  type)     # type "text"  (unicode ok)
    front; shift; "$BIN" type "$@" ;;
  set)      # set X Y VALUE  -> click a numeric field, select all, type value, enter
    front; "$BIN" click $(abs "$2" "$3"); "$BIN" key a cmd; "$BIN" type "$4"; "$BIN" key return ;;
  savedialog) # savedialog /abs/path/file.vrm  -> in an open macOS save panel: Cmd+Shift+G, folder, Enter, name, Enter
    front; "$BIN" key g cmd shift; sleep 0.4; "$BIN" key a cmd; "$BIN" type "$(dirname "$2")"; "$BIN" key return; sleep 0.6
    "$BIN" key a cmd; "$BIN" type "$(basename "$2")"; sleep 0.2; "$BIN" key return ;;
  *) echo "usage: vroid.sh check|open|window|front|shot [file]|click X Y|dclick X Y|rclick X Y|move X Y|drag X1 Y1 X2 Y2|scroll X Y DX DY|key NAME [mods]|type TEXT|set X Y VALUE|savedialog PATH"; exit 2 ;;
esac
