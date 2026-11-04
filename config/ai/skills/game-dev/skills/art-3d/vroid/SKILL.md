---
name: vroid
description: Drive VRoid Studio on macOS to build/edit/export VRM characters. Use when the user asks to make, edit, or export a VRoid/VRM character, change hair/face/outfit/body in VRoid, or control VRoid Studio. Works by screenshot → look → click/drag/type loop.
---

# VRoid Studio control

Script: `~/.claude/skills/game-dev/skills/art-3d/vroid/scripts/vroid.sh` (first run compiles a tiny Swift input tool). All coordinates are **window-relative pixels** matching the screenshot.

```
vroid.sh check                 # Accessibility + Screen Recording permission probe (run first, once)
vroid.sh open                  # launch + focus VRoid Studio, prints "x y w h id"
vroid.sh shot [file]           # capture the VRoid window → PNG path. ALWAYS Read the PNG before acting.
vroid.sh click X Y | dclick | rclick | move
vroid.sh drag X1 Y1 X2 Y2      # sliders, camera orbit
vroid.sh scroll X Y DX DY      # DY<0 scrolls up
vroid.sh key NAME [cmd shift alt ctrl]   # e.g. key s cmd  /  key return  /  key esc
vroid.sh type TEXT             # unicode ok (Mongolian, Japanese)
vroid.sh set X Y VALUE         # click a numeric field, select-all, type, Enter (precise slider values)
vroid.sh savedialog /abs/path/Name.vrm   # fill a macOS save panel
```

## Loop (never skip a screenshot)
1. `shot` → Read the image → identify the element and its pixel position.
2. One action (`click`/`drag`/`set`/`key`).
3. `shot` again → verify the change happened. If not, adjust by a few pixels; after 3 misses, tell the user what you see.

## Permissions (one-time, the user must do it)
System Settings → Privacy & Security → **Accessibility**: enable the terminal app running Claude Code (Terminal / iTerm / Claude desktop / VS Code).
Same for **Screen Recording**. `vroid.sh check` reports status. Without them clicks are silently ignored and screenshots are black.

## VRoid Studio layout (v2.x, English UI)
- Home: model list; "Create New" → choose Female/Male base.
- Editor top tabs: **Face · Hairstyle · Body · Outfit · Accessories · Look**. Right side: parameter sliders per sub-category; left side: preset thumbnails. Bottom-left of viewport: camera presets. Numeric fields accept typed values → prefer `set` over dragging a slider.
- Hair: use presets first (left panel), then Hairstyle → Edit for color: Hair → Color swatch → set hex.
- Colors: click the swatch → color popup has a hex field → `set` the hex (e.g. `1a1a1a` black hair, `b3202a` red).
- Save project: `key s cmd`. Export VRM: top-right camera icon **Camera/Exporter** → **Export** → **Export as VRM** (choose **VRM 1.0**) → reduce polygons / textures if asked → **Export** → save panel → `savedialog`.
- Project KAZE target: `/Users/hana/Projects/ProjectKaze/Assets/Kaze/Resources/Riders/<Id>.vrm` (Ids: Borte, Khulan, Altangu, Saruul, Naran, Kokchin, Oyun, Javkhlan, Tomor, Kherlen, Zolzaya, Enkhtuul). Portrait references: `ProjectKaze/Assets/Kaze/Resources/Portraits/<Id>.png` — Read the portrait first and match hair color/length, eye color, outfit tone.

## Rules
- One action per step; re-screenshot after each. VRoid UI animates, wait ~0.5s before shooting after a tab switch.
- Do not guess coordinates from memory across sessions — window size changes. Always derive from the latest screenshot.
- If a modal/dialog is open, handle it first (`key esc` or click its button).
- Keep the user informed in one line per major step (tab switched, preset chosen, exported).
