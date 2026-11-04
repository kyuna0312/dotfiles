#!/usr/bin/env python3
"""Scan an Ebitengine (v2) Go project for deprecated APIs and common game-loop mistakes.

This is a heuristic source scan, not a Go type checker or a quality verdict.
It recognises named/aliased imports, but not dot imports or variable shadowing;
it scans every selected file regardless of build constraints. Review warnings.
Reads Go sources and go.mod only and never modifies them. Heuristic findings
are warnings or informational notes: deprecated does not mean broken. Ambiguous
At calls are notes and never fail --strict. Use go build/vet for errors.
The deprecation table matches
Ebitengine v2.10; on an older pinned version some replacements may not exist yet
(each finding names the version that deprecated the API).

Exit status: 0 = no errors, 1 = errors found (or warnings with --strict),
2 = bad arguments, unreadable target, or no Ebitengine v2 project signal.

Examples:
  python3 check_ebitengine.py .
  python3 check_ebitengine.py ./cmd/mygame --strict
"""
import argparse
import json
import os
import re
import sys
from pathlib import Path

TOOL = "check_ebitengine"
SCHEMA = 1

# (pattern, message). Patterns run on code with comments and string literals removed.
DEPRECATED = [
    (r"\bebitenutil\.DrawRect\(", "ebitenutil.DrawRect (v2.5) -> vector.FillRect"),
    (r"\bebitenutil\.DrawLine\(", "ebitenutil.DrawLine (v2.5) -> vector.StrokeLine"),
    (r"\bebitenutil\.DrawCircle\(", "ebitenutil.DrawCircle (v2.5) -> vector.FillCircle"),
    (r"\bebitenutil\.OpenFile\(", "ebitenutil.OpenFile (v2.4) -> os.Open, or go:embed"),
    (r"\bvector\.DrawFilledRect\(", "vector.DrawFilledRect (v2.9) -> vector.FillRect"),
    (r"\bvector\.DrawFilledCircle\(", "vector.DrawFilledCircle (v2.9) -> vector.FillCircle"),
    (r"\bebiten\.SetMaxTPS\(", "ebiten.SetMaxTPS (v2.4) -> ebiten.SetTPS"),
    (r"\bebiten\.MaxTPS\(", "ebiten.MaxTPS (v2.4) -> ebiten.TPS"),
    (r"\bebiten\.CurrentTPS\(", "ebiten.CurrentTPS (v2.4) -> ebiten.ActualTPS"),
    (r"\bebiten\.CurrentFPS\(", "ebiten.CurrentFPS (v2.4) -> ebiten.ActualFPS"),
    (r"\bebiten\.UncappedTPS\b", "ebiten.UncappedTPS (v2.2) -> ebiten.SyncWithFPS"),
    (r"\bebiten\.DeviceScaleFactor\(", "ebiten.DeviceScaleFactor (v2.6) -> ebiten.Monitor().DeviceScaleFactor()"),
    (r"\bebiten\.ScreenSizeInFullscreen\(", "ebiten.ScreenSizeInFullscreen (v2.6) -> ebiten.Monitor().Size()"),
    (r"\bebiten\.SetFPSMode\(|\bebiten\.FPSMode\(|\bebiten\.FPSMode[A-Z]", "FPSMode (v2.5) -> ebiten.SetVsyncEnabled"),
    (r"\bebiten\.SetWindowResizable\(", "ebiten.SetWindowResizable (v2.3) -> ebiten.SetWindowResizingMode"),
    (r"\bebiten\.IsWindowResizable\(", "ebiten.IsWindowResizable (v2.3) -> ebiten.WindowResizingMode"),
    (r"\bebiten\.SetScreenTransparent\(|\bebiten\.SetInitFocused\(", "SetScreenTransparent/SetInitFocused (v2.5) -> RunGameWithOptions"),
    (r"\bebiten\.SetScreenFilterEnabled\(", "ebiten.SetScreenFilterEnabled (v2.5) -> FinalScreenDrawer"),
    (r"\bebiten\.ScheduleFrame\(", "ebiten.ScheduleFrame (v2.5) -> SetScreenClearedEveryFrame(false)"),
    (r"\bebiten\.InputChars\(", "ebiten.InputChars (v2.2) -> ebiten.AppendInputChars"),
    (r"\bebiten\.GamepadIDs\(", "ebiten.GamepadIDs (v2.2) -> ebiten.AppendGamepadIDs"),
    (r"\bebiten\.TouchIDs\(", "ebiten.TouchIDs (v2.2) -> ebiten.AppendTouchIDs"),
    (r"\bebiten\.GamepadAxis\(", "ebiten.GamepadAxis (v2.2) -> ebiten.GamepadAxisValue"),
    (r"\bebiten\.GamepadAxisNum\(|\bebiten\.GamepadButtonNum\(", "Gamepad*Num (v2.4) -> Gamepad*Count"),
    (r"\binpututil\.(PressedKeys|JustPressedTouchIDs|JustConnectedGamepadIDs)\(", "inpututil.* slice getters (v2.2) -> the Append* variants"),
    (r"\bebiten\.ColorM\b", "ebiten.ColorM (v2.5) -> ColorScale, or the colorm package"),
    (r"\bebiten\.CompositeMode\w*\b", "CompositeMode (v2.5) -> Blend"),
    (r"\baudio\.NewPlayer(FromBytes)?\(", "audio.NewPlayer* functions (v2.2) -> (*audio.Context).NewPlayer*"),
    (r"\b(wav|mp3|vorbis)\.Decode\(", "Decode(ctx, r) (v2.1) -> DecodeF32 or DecodeWithSampleRate"),
    (r"\baudio\.Resample(F32)?\(", "audio.Resample* (v2.9) -> audio.ResampleReader* (or decode at the context rate)"),
    (r"\btext\.Advance\(", "text.Advance (v2.10) -> text.AdvanceAt"),
]

# Method names that other types may share: reported as warnings.
DEPRECATED_MAYBE = [
    (r"\.AppendVerticesAndIndicesFor(Filling|Stroke)\(", "Path.AppendVerticesAndIndicesFor* (v2.9) -> vector.FillPath / StrokePath (if this is a vector.Path)"),
    (r"\.ColorM\.", "DrawImageOptions.ColorM (v2.5) -> ColorScale, or colorm (if this is an Ebitengine options value)"),
    (r"\.ReplacePixels\(", "Image.ReplacePixels (v2.4) -> Image.WritePixels (if this is an ebiten.Image)"),
    (r"\.Dispose\(\)", "Image/Shader.Dispose (v2.7) -> Deallocate, or just drop the reference (ignore if not an ebiten type)"),
]
# Like DEPRECATED_MAYBE, but only checked in files that import the Ebitengine audio package.
DEPRECATED_PLAYER = [
    (r"\.Close\(\)", "Player.Close (v2.10) -> Player.PauseAndStopReading (if this is an audio.Player)"),
    (r"\.Seek\([^,()]*\)", "Player.Seek (v2.6) -> Player.SetPosition (if this is an audio.Player)"),
    (r"\.Current\(\)", "Player.Current (v2.6) -> Player.Position (if this is an audio.Player)"),
]

# Checks inside Draw bodies. Capture bookkeeping is an intentional exception.
IN_DRAW = [
    (r"\bebiten\.NewImage(FromImage)?\(", "creates a GPU image every frame; create once and reuse"),
    (r"\btext\.NewGoTextFaceSource\(", "parses a font every frame; load fonts once"),
    (r"\binpututil\.", "inpututil must be called in Update, not Draw"),
    (r"\baudio\.NewContext\(", "audio context created in Draw"),
    (r"\.Play\(\)", "plays sound from Draw; Draw can run 0..n times per tick, trigger sounds in Update"),
]
# Checks inside Update and Draw bodies.
IN_LOOP = [
    (r"\btime\.(Now|Since)\(", "wall-clock time in the game loop; use ticks for simulation, wall time may be intentional for profiling or external deadlines"),
    (r"\.ReadPixels\(", "possible GPU readback (if this is an ebiten.Image); review repeated reads, screenshots/tests are intentional"),
]


def strip_go(src, keep_strings=False):
    """Mask comments and literals, preserving offsets and line structure."""
    out, i, n = [], 0, len(src)
    def mask(s):
        return "".join("\n" if c == "\n" else " " for c in s)
    while i < n:
        c = src[i]
        if src.startswith("//", i):
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append(mask(src[i:j]))
            i = j
        elif src.startswith("/*", i):
            j = src.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append(mask(src[i:j]))
            i = j
        elif c == "`":
            j = src.find("`", i + 1)
            j = n if j < 0 else j + 1
            out.append(src[i:j] if keep_strings else mask(src[i:j]))
            i = j
        elif c in "\"'":
            j = i + 1
            while j < n and src[j] != c and src[j] != "\n":
                j += 2 if src[j] == "\\" else 1
            out.append(src[i:j+1] if keep_strings and c == '"' else mask(src[i:j+1]))
            i = j + 1
        else:
            out.append(c)
            i += 1
    return "".join(out)


def imports(src, code):
    """Return named imports (local name, path, line), excluding comments/literals."""
    uncommented = strip_go(src, keep_strings=True)
    for m in re.finditer(r"\bimport\b", code):
        start = m.end()
        while start < len(code) and uncommented[start].isspace():
            start += 1
        end = code.find(")", start) if start < len(code) and code[start] == "(" else code.find("\n", start)
        if end < 0:
            end = len(code)
        for spec in re.finditer(r'(?:(\w+|\.)\s+)?["`]([^"`\n]+)["`]', uncommented[start:end]):
            path = spec.group(2)
            alias = spec.group(1) or ("text" if path.endswith("/text/v2") else path.rsplit("/", 1)[-1])
            if path == "github.com/hajimehoshi/ebiten/v2":
                alias = spec.group(1) or "ebiten"
            yield alias, path, src.count("\n", 0, start+spec.start()) + 1


def method_bodies(code, name):
    """Yield (start_line, body) for methods `func (recv) Name(`."""
    for m in re.finditer(r"func\s*\([^)]*\)\s*" + name + r"\s*\(", code):
        brace = code.find("{", m.end())
        if brace < 0:
            continue
        depth, j = 0, brace
        while j < len(code):
            if code[j] == "{":
                depth += 1
            elif code[j] == "}":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        yield code.count("\n", 0, brace) + 1, code[brace:j]


def scan_file(path, raw_imports):
    with open(path, encoding="utf-8", errors="replace") as f:
        src = f.read()
    code = strip_go(src)
    imported = list(imports(src, code))
    # Canonicalise only packages actually imported. Unrelated packages named
    # audio/text/vector must not be mistaken for Ebitengine APIs.
    names = {}
    base = "github.com/hajimehoshi/ebiten/v2"
    known = {base: "ebiten", "time": "time"}
    known.update({base+"/"+p: p.rsplit("/", 1)[-1] for p in
                  ("ebitenutil", "inpututil", "vector", "audio", "audio/wav", "audio/mp3", "audio/vorbis")})
    known.update({base+"/text": "text", base+"/text/v2": "text"})
    for alias, import_path, _ in imported:
        if alias not in (".", "_") and import_path in known:
            names[alias] = known[import_path]
    canonical = set(known.values())
    # A name after "." is a field or method (s.audio.NewPlayer), not a package.
    code = re.sub(r"(?<=\.)(" + "|".join(sorted(canonical)) + r")\b", r"__field_\1", code)
    code = re.sub(r"(?<![.\w])([A-Za-z_]\w*)\s*(?=\.)", lambda m: names.get(
        m.group(1), "__other_"+m.group(1) if m.group(1) in canonical else m.group(1)), code)
    found = []

    def add(sev, line, msg):
        found.append((sev, path, line, msg))

    for pat, msg in DEPRECATED:
        for m in re.finditer(pat, code):
            add("warn", code.count("\n", 0, m.start()) + 1, "deprecated: " + msg)
    for pat, msg in DEPRECATED_MAYBE + (DEPRECATED_PLAYER if "audio" in names.values() else []):
        for m in re.finditer(pat, code):
            add("warn", code.count("\n", 0, m.start()) + 1, "possibly deprecated: " + msg)
    for _, import_path, line in imported:
        if import_path == base+"/text":
            add("warn", line, 'old import: prefer "github.com/hajimehoshi/ebiten/v2/text/v2" for new text code')
        if import_path == "github.com/hajimehoshi/ebiten":
            add("warn", line, "old import: Ebitengine v1 -> github.com/hajimehoshi/ebiten/v2")
    for line0, body in method_bodies(code, "Draw"):
        for pat, msg in IN_DRAW:
            for m in re.finditer(pat, body):
                add("warn", line0 + body.count("\n", 0, m.start()), "in Draw: " + msg)
    for name in ("Update", "Draw"):
        for line0, body in method_bodies(code, name):
            # At is also a common grid/map method. Without Go type information,
            # neither its name nor argument count proves an Image readback.
            for m in re.finditer(r"\.At\s*\(", body):
                add("note", line0 + body.count("\n", 0, m.start()), "in " + name +
                    ": At call has an unknown receiver type; only ebiten.Image.At reads GPU pixels, ordinary grid/map lookups are fine")
            for pat, msg in IN_LOOP:
                for m in re.finditer(pat, body):
                    add("warn", line0 + body.count("\n", 0, m.start()), "in " + name + ": " + msg)
    for m in re.finditer(r"\baudio\.NewContext\(", code):
        raw_imports.append((path, code.count("\n", 0, m.start()) + 1))
    return found


def main(argv=None):
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(errors="backslashreplace")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("path", help="project directory or a single .go file")
    ap.add_argument("--json", action="store_true", help="print one JSON object instead of text")
    ap.add_argument("--strict", action="store_true", help="exit 1 on warnings too")
    ap.add_argument("--max-issues", type=int, default=50, metavar="N",
                    help="show at most N issues (default: 50; 0 = no limit)")
    ap.add_argument("--include-tests", action="store_true", help="also scan _test.go files")
    args = ap.parse_args(argv)
    if args.max_issues < 0:
        ap.error("--max-issues must be 0 or more")

    target = Path(args.path).expanduser().resolve()
    if not target.exists():
        print(f"error: {target} does not exist", file=sys.stderr)
        return 2
    files = []
    if target.is_file():
        if target.suffix != ".go":
            print("error: not a .go file", file=sys.stderr)
            return 2
        files = [target]
        root = target.parent
    elif target.is_dir():
        root = target

        def walk_error(error):
            raise error

        try:
            for directory, dirs, names in os.walk(target, onerror=walk_error):
                dirs[:] = [d for d in dirs if d not in ("vendor", "node_modules") and not d.startswith(".")]
                for name in names:
                    if name.endswith(".go") and (args.include_tests or not name.endswith("_test.go")):
                        files.append(Path(directory) / name)
        except OSError as error:
            print(f"error: cannot scan target: {error}", file=sys.stderr)
            return 2
    else:
        print(f"error: {target} is not a file or folder", file=sys.stderr)
        return 2
    if not files:
        print("error: no .go files found", file=sys.stderr)
        return 2

    findings, contexts = [], []
    base = "github.com/hajimehoshi/ebiten/v2"
    has_engine = False
    try:
        module = root / "go.mod"
        if module.is_file():
            has_engine = bool(re.search(r"(?m)^\s*(?:require\s+)?" + re.escape(base) + r"\s+v2\.",
                                        module.read_text(encoding="utf-8")))
        for path in sorted(files):
            source = path.read_text(encoding="utf-8", errors="replace")
            has_engine |= any(p == base or p.startswith(base + "/")
                              for _, p, _ in imports(source, strip_go(source)))
            findings += scan_file(path, contexts)
    except (OSError, UnicodeError) as error:
        print(f"error: cannot read target: {error}", file=sys.stderr)
        return 2
    if not has_engine:
        print("error: no Ebitengine v2 dependency or Go import found", file=sys.stderr)
        return 2
    if len(contexts) > 1:
        for p, line in contexts:
            findings.append(("warn", p, line, "multiple audio.NewContext call sites; only one context may exist per process. "
                             "Check whether these sites can execute together (build tags and alternative entry points may exclude them)"))

    warnings, notes = [], []
    for severity, path, line, message in sorted(findings, key=lambda f: (str(f[1]), f[2], f[3])):
        if severity == "note":
            code = "ambiguous-at"
            fix = "Check the receiver type; avoid repeated Image.At reads in the loop. No action is needed for CPU grid/map lookups."
        elif "deprecated:" in message or message.startswith("old import:"):
            code = "deprecated-api" if "deprecated:" in message else "old-import"
            fix = "Confirm the imported type and pinned engine version before applying the suggested replacement."
        elif message.startswith("multiple audio.NewContext"):
            code = "audio-context-sites"
            fix = "Ensure only one context is constructed per process; inspect build tags and alternative entrypoints."
        else:
            code = "loop-review"
            fix = "Review the operation in context; keep gameplay/input/audio triggers in Update and reuse expensive resources."
        (notes if severity == "note" else warnings).append(
            {"code": code, "file": Path(path).relative_to(root).as_posix(),
             "line": line, "message": message, "fix": fix})
    shown = warnings[:args.max_issues] if args.max_issues else warnings
    shown_notes = notes[:max(0, args.max_issues - len(shown))] if args.max_issues else notes
    omitted = len(warnings) + len(notes) - len(shown) - len(shown_notes)
    truncated = omitted > 0
    if args.json:
        print(json.dumps({"tool": TOOL, "schema": SCHEMA, "root": root.as_posix(),
                          "files_checked": len(files), "error_count": 0,
                          "warning_count": len(warnings), "errors": [],
                          "warnings": shown, "note_count": len(notes), "notes": shown_notes,
                          "truncated": truncated}, indent=2))
    else:
        for issue in shown:
            print(f"WARNING {issue['file']}:{issue['line']}: {issue['message']}")
            print(f"  fix: {issue['fix']}")
        for issue in shown_notes:
            print(f"NOTE {issue['file']}:{issue['line']}: {issue['message']}")
            print(f"  fix: {issue['fix']}")
        if truncated:
            print(f"... and {omitted} more")
        print(f"Summary: 0 errors, {len(warnings)} warnings in {len(files)} files checked")
        if notes:
            print(f"Notes: {len(notes)} informational findings (do not affect --strict)")
    return 1 if args.strict and warnings else 0


if __name__ == "__main__":
    sys.exit(main())
