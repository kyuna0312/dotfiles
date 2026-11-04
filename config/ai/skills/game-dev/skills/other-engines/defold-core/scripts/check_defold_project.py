#!/usr/bin/env python3
"""Check a Defold project for broken resource references. Read-only.

Run it after creating, moving or renaming collections, game objects, scripts,
atlases or other resources. It reads the project's text files and reports
references that Bob (the Defold build tool) will fail to resolve. It never
edits anything and needs no Defold editor, Java or bob.jar.

What it checks:

* ``game.project``: ``bootstrap.main_collection`` and ``input.game_binding``
  must name an existing file and carry the compiled suffix (``.collectionc``,
  ``.input_bindingc``). When a key is absent, Defold's default
  (``/logic/main.collectionc``, ``/input/game.input_bindingc``) is checked
  instead. Other settings whose value is a root-absolute path, and the
  ``custom_resources``, ``bundle_resources`` and ``include_dirs`` lists, are
  checked as warnings.
* Every quoted root-absolute resource path (``"/main/player.go"``, also inside
  the escaped ``data:`` strings of embedded components) in collections, game
  objects, atlases, GUI scenes, tile sources and the other Defold text resource
  files. A string is treated as a path only when its last part has a file
  extension and it contains no ``#`` or ``:``, so game object ids and URLs
  are left alone.
* In ``.script``, ``.gui_script``, ``.render_script`` and ``.lua`` files:
  literal ``require "a.b"`` modules (``/a/b.lua``) and literal
  ``resource.*("/path")`` properties; ``sys.load_resource("/path")`` is a
  warning because it reads custom resources at run time. Comments are ignored.
* Paths whose letter case differs from the file on disk. This can work on
  Windows and macOS and break on Linux and in CI.

Bob only builds files reachable from ``game.project``, so a broken reference
in a file nothing uses is reported as a warning, not an error.

Paths under ``/builtins/`` are skipped. Paths provided by library
dependencies are checked against the archives Bob fetched into
``.internal/lib/``; when a dependency has not been fetched, an unresolved path
is only a warning. Skipped while scanning: the ``build/`` folder, hidden files
and folders (``.internal/``, ``.git/``, ``.editor_settings``) and anything
listed in ``.defignore``.

Exit codes: 0 no errors, 1 errors (or warnings with --strict),
2 usage problem or no game.project found.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import zipfile
from dataclasses import dataclass
from pathlib import Path

TOOL = "check_defold_project"
SCHEMA = 1

# Defold resource files stored as protobuf text; any quoted "/path.ext" in them is a resource.
RESOURCE_EXTS = {
    ".animationset", ".atlas", ".buffer", ".camera", ".collection", ".collectionfactory",
    ".collectionproxy", ".collisionobject", ".compute", ".convexshape", ".display_profiles",
    ".factory", ".font", ".gamepads", ".go", ".gui", ".input_binding", ".label", ".material",
    ".mesh", ".model", ".particlefx", ".render", ".render_target", ".sound", ".sprite",
    ".texture_profiles", ".tilemap", ".tilesource",
}
SCRIPT_EXTS = {".script", ".gui_script", ".render_script", ".lua"}

# Names Bob accepts in require() without a project file (engine-provided modules).
ENGINE_MODULES = {"socket", "string", "table", "math", "debug", "os", "io", "coroutine", "bit", "package"}

# Defaults from the Defold project settings manual and Bob's behaviour when a key is absent.
DEFAULT_MAIN_COLLECTION = "/logic/main.collectionc"
DEFAULT_GAME_BINDING = "/input/game.input_bindingc"

QUOTED_PATH_RE = re.compile(r'\\*"(/[^"\\\n]+)\\*"')
# Matched against masked code (string contents blanked); each ends at a string's opening quote.
REQUIRE_RE = re.compile(r"""(?<![\w.:])require\s*\(?\s*["']""")
RESOURCE_CALL_RE = re.compile(r"""\bresource\.[a-z_]+\s*\(\s*["']""")
LOAD_RESOURCE_RE = re.compile(r"""\bsys\.load_resource\s*\(\s*["']""")
EXT_RE = re.compile(r"\.[A-Za-z0-9_]+$")


@dataclass
class Issue:
    severity: str  # "error" or "warning"
    code: str
    file: str
    line: int | None
    message: str
    fix: str

    def as_dict(self) -> dict:
        return {"code": self.code, "file": self.file, "line": self.line, "message": self.message, "fix": self.fix}


@dataclass
class Ref:
    file: str  # project-relative file that holds the reference
    line: int
    path: str  # root-absolute path as written, e.g. "/main/player.go"
    kind: str  # resource, require, resource-property, load-resource, setting
    severity: str  # severity when the target is missing and the file is reachable


# ---------------------------------------------------------------- text helpers


def read_text(path: Path) -> str:
    """Read a text file, tolerating a UTF-8 BOM, CRLF line endings and bad bytes."""
    text = path.read_bytes().decode("utf-8", errors="replace")
    if text.startswith("\ufeff"):
        text = text[1:]
    return text.replace("\r\n", "\n").replace("\r", "\n")


def line_of(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def parse_ini(text: str) -> dict[str, tuple[str, int]]:
    """Parse game.project into ``{"section.key": (value, line)}``."""
    values: dict[str, tuple[str, int]] = {}
    section = ""
    for lineno, raw in enumerate(text.split("\n"), 1):
        line = raw.strip()
        if not line or line[0] in "#;":
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1].strip()
            continue
        if "=" in line:
            key, value = line.split("=", 1)
            values[f"{section}.{key.strip()}"] = (value.strip(), lineno)
    return values


def mask_lua(code: str) -> tuple[str, dict[int, str]]:
    """Blank out Lua comments and the contents of string literals.

    Returns the masked code (same length and line breaks as the input) and a map
    from the offset of each short string's opening quote to its contents, so a
    call such as ``require "a.b"`` is found in code but never inside a string.
    """
    out: list[str] = []
    strings: dict[int, str] = {}
    i, n = 0, len(code)
    long_open = re.compile(r"\[(=*)\[")

    def blank(text: str) -> str:
        return re.sub(r"[^\n]", " ", text)

    while i < n:
        ch = code[i]
        if code.startswith("--", i):
            m = long_open.match(code, i + 2)
            if m:
                close = "]" + m.group(1) + "]"
                end = code.find(close, m.end())
                end = n if end < 0 else end + len(close)
            else:
                end = code.find("\n", i)
                end = n if end < 0 else end
            out.append(blank(code[i:end]))
            i = end
        elif ch in "\"'":
            j = i + 1
            while j < n and code[j] != ch and code[j] != "\n":
                j += 2 if code[j] == "\\" else 1
            strings[i] = code[i + 1 : j]
            out.append(ch + blank(code[i + 1 : j]) + (ch if j < n and code[j] == ch else ""))
            i = j + 1
        elif ch == "[" and long_open.match(code, i):
            m = long_open.match(code, i)
            close = "]" + m.group(1) + "]"
            end = code.find(close, m.end())
            end = n if end < 0 else end + len(close)
            out.append(blank(code[i:end]))
            i = end
        else:
            out.append(ch)
            i += 1
    return "".join(out), strings


def defignore_regex(pattern: str) -> re.Pattern[str] | None:
    """Translate one .defignore line into a regex over project paths ("/a/b")."""
    pattern = pattern.strip()
    if not pattern.startswith("/"):
        return None
    parts = []
    i = 0
    while i < len(pattern):
        if pattern.startswith("/**/", i):
            parts.append("/(?:.*/)?")
            i += 4
        elif pattern.startswith("/**", i) and i + 3 == len(pattern):
            parts.append("(?:/.*)?")
            i += 3
        elif pattern[i] == "*":
            parts.append("[^/]*")
            i += 1
        elif pattern[i] == "?":
            parts.append("[^/]")
            i += 1
        else:
            parts.append(re.escape(pattern[i]))
            i += 1
    # A pattern matches the path itself or any of its parent folders.
    return re.compile("".join(parts) + "(?:/.*)?$")


# ------------------------------------------------------------------- project


class Project:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.files: list[str] = []  # project-relative posix paths ("main/player.go")
        self.file_set: set[str] = set()
        self.dir_set: set[str] = set()
        self.by_casefold: dict[str, str] = {}
        self.ignore: list[re.Pattern[str]] = []
        self.ignored_files: set[str] = set()
        self.lib_files: set[str] = set()  # files provided by fetched library archives
        self.lib_dirs: set[str] = set()  # top folders those archives provide
        self.unfetched: list[str] = []  # dependency URLs with no fetched archive
        self.settings: dict[str, tuple[str, int]] = {}
        self.refs: list[Ref] = []
        self.issues: list[Issue] = []
        self.files_checked = 0

    def add(self, severity: str, code: str, file: str, line: int | None, message: str, fix: str) -> None:
        self.issues.append(Issue(severity, code, file, line, message, fix))

    # -- scanning

    def ignored(self, rel: str) -> bool:
        return any(p.match("/" + rel) for p in self.ignore)

    def read_defignore(self) -> None:
        path = self.root / ".defignore"
        if path.is_file():
            for line in read_text(path).split("\n"):
                regex = defignore_regex(line)
                if regex:
                    self.ignore.append(regex)

    def scan(self) -> None:
        stack = [""]
        seen: set[tuple[int, int]] = set()
        while stack:
            rel_dir = stack.pop()
            full = self.root / rel_dir if rel_dir else self.root
            try:
                info = os.stat(full)
                if info.st_ino:
                    key = (info.st_dev, info.st_ino)
                    if key in seen:
                        continue  # symlink loop
                    seen.add(key)
                entries = sorted(os.scandir(full), key=lambda e: e.name)
            except OSError:
                self.add("warning", "dir-unreadable", rel_dir or ".", None,
                         "Folder could not be read, so files in it were not checked.",
                         "Check the folder's permissions.")
                continue
            for entry in entries:
                rel = f"{rel_dir}/{entry.name}" if rel_dir else entry.name
                if entry.name.startswith(".") or (not rel_dir and entry.name == "build"):
                    continue
                try:
                    is_dir = entry.is_dir()
                    is_file = entry.is_file()
                except OSError:
                    continue
                if is_dir:
                    if self.ignored(rel):
                        continue
                    self.dir_set.add(rel)
                    stack.append(rel)
                elif is_file:
                    if self.ignored(rel):
                        self.ignored_files.add(rel)
                        continue
                    self.files.append(rel)
        self.files.sort()
        self.file_set = set(self.files)
        for rel in self.files:
            self.by_casefold.setdefault(rel.casefold(), rel)

    # -- library dependencies

    def dependency_urls(self) -> list[tuple[str, int]]:
        urls: list[tuple[str, int]] = []
        for key, (value, line) in self.settings.items():
            if key == "project.dependencies" or key.startswith("project.dependencies#"):
                urls.extend((u.strip(), line) for u in value.split(",") if u.strip())
        return urls

    def load_libraries(self) -> None:
        lib_dir = self.root / ".internal" / "lib"
        try:
            archives = sorted(os.listdir(lib_dir))
        except OSError:
            archives = []
        for url, _line in self.dependency_urls():
            # Bob stores each fetched library as .internal/lib/<sha1 of the URL>-<etag>.zip.
            prefix = hashlib.sha1(url.encode("utf-8")).hexdigest() + "-"
            match = next((a for a in archives if a.startswith(prefix) and a.endswith(".zip")), None)
            if not match or not self.read_library(lib_dir / match):
                self.unfetched.append(url)

    def read_library(self, archive: Path) -> bool:
        try:
            with zipfile.ZipFile(archive) as zf:
                names = zf.namelist()
                project = next((n for n in names if n.count("/") <= 1 and n.endswith("game.project")), None)
                if project is None:
                    return False
                base = project[: -len("game.project")]
                text = zf.read(project).decode("utf-8", errors="replace")
        except (OSError, zipfile.BadZipFile, KeyError):
            return False
        include = parse_ini(text.replace("\r\n", "\n")).get("library.include_dirs", ("", 0))[0]
        dirs = [d.strip("/") for d in include.split() if d.strip("/")]
        for name in names:
            if not name.startswith(base) or name.endswith("/"):
                continue
            rel = name[len(base):]
            if rel.split("/", 1)[0] in dirs:
                self.lib_files.add(rel)
        self.lib_dirs.update(dirs)
        return True

    # -- path lookup

    def lookup(self, path: str) -> tuple[str, str | None]:
        """Return (status, actual) for a root-absolute path.

        status is ok, builtin, case, ignored, maybe-library or missing.
        """
        rel = path.lstrip("/")
        if rel.startswith("builtins/"):
            return "builtin", None
        if rel in self.file_set or rel in self.lib_files:
            return "ok", rel
        if rel in self.ignored_files or self.ignored(rel):
            return "ignored", None
        actual = self.by_casefold.get(rel.casefold())
        if actual:
            return "case", actual
        if self.unfetched and rel.split("/", 1)[0] not in self.dir_set:
            return "maybe-library", None
        return "missing", None

    def similar(self, path: str) -> list[str]:
        name = path.rsplit("/", 1)[-1].casefold()
        return ["/" + f for f in self.files if f.rsplit("/", 1)[-1].casefold() == name][:3]

    # -- reference collection

    def collect_resource_refs(self, rel: str, text: str) -> None:
        for m in QUOTED_PATH_RE.finditer(text):
            path = m.group(1)
            last = path.rsplit("/", 1)[-1]
            if "#" in path or ":" in path or not EXT_RE.search(last):
                continue
            self.refs.append(Ref(rel, line_of(text, m.start()), path, "resource", "error"))

    def collect_script_refs(self, rel: str, text: str) -> None:
        code, strings = mask_lua(text)

        def literal_args(regex: re.Pattern[str]):
            for m in regex.finditer(code):
                value = strings.get(m.end() - 1)
                if value is not None:
                    yield m, value

        for m, module in literal_args(REQUIRE_RE):
            module = module.strip()
            if module.startswith("builtins."):
                continue
            if "." not in module and "/" not in module:
                if module in ENGINE_MODULES:
                    continue
                severity = "warning"  # a single name might be provided by the engine or an extension
            else:
                severity = "error"
            path = "/" + module.replace(".", "/") + ".lua"
            self.refs.append(Ref(rel, line_of(code, m.start()), path, "require", severity))
        for m, path in literal_args(RESOURCE_CALL_RE):
            if path.startswith("/"):
                self.refs.append(Ref(rel, line_of(code, m.start()), path, "resource-property", "error"))
        for m, path in literal_args(LOAD_RESOURCE_RE):
            if path.startswith("/"):
                self.refs.append(Ref(rel, line_of(code, m.start()), path, "load-resource", "warning"))

    # -- game.project

    def check_settings(self) -> list[str]:
        """Check game.project and return the root resources Bob builds from."""
        roots: list[str] = []
        for key, default, suffix, what in (
            ("bootstrap.main_collection", DEFAULT_MAIN_COLLECTION, ".collectionc", "main collection"),
            ("input.game_binding", DEFAULT_GAME_BINDING, ".input_bindingc", "input binding"),
        ):
            value, line = self.settings.get(key, ("", 0))
            written = bool(value)
            value = value or default
            note = "" if written else f" ({key} is not set, so Defold uses {default})"
            if not value.endswith(suffix):
                if value.endswith(suffix[:-1]):
                    fix = f"Write {value}c: game.project names the compiled file."
                else:
                    fix = f"Point {key} at a {suffix[1:-1]} file, written with a trailing 'c' ({suffix})."
                self.add("error", "setting-suffix", "game.project", line or None,
                         f"{key} = {value} must use the compiled suffix '{suffix}'.", fix)
                source = value
            else:
                source = value[:-1]
            status, actual = self.lookup(source)
            if status in ("ok", "builtin"):
                if actual:
                    roots.append(actual)
            elif status == "case":
                self.add("error", "path-case", "game.project", line or None,
                         f"{key} points to {source} but the file on disk is /{actual}{note}.",
                         "Match the letter case exactly; Linux builds are case-sensitive.")
            elif status == "maybe-library":
                self.add("warning", "path-unverified", "game.project", line or None,
                         f"{key} points to {source}, which is not in the project and may come "
                         f"from a library dependency that is not fetched{note}.",
                         "Fetch libraries (Project > Fetch Libraries, or bob 'resolve') and re-run.")
            else:
                self.add("error", "setting-missing", "game.project", line or None,
                         f"The {what} {source} does not exist{note}.",
                         self.missing_fix(source, f"Point {key} at an existing file"))

        for key, (value, line) in sorted(self.settings.items()):
            if key in ("bootstrap.main_collection", "input.game_binding"):
                continue
            if key in ("project.custom_resources", "project.bundle_resources"):
                for item in (v.strip() for v in value.split(",")):
                    rel = item.strip("/")
                    if rel and rel not in self.file_set and rel not in self.dir_set:
                        self.add("warning", "setting-missing", "game.project", line,
                                 f"{key} lists '{item}', which is not a file or folder in the project.",
                                 "Fix the path (relative to the project root) or remove it from the list.")
                continue
            if key == "library.include_dirs":
                for item in value.split():
                    if item.strip("/") not in self.dir_set:
                        self.add("warning", "setting-missing", "game.project", line,
                                 f"library.include_dirs lists '{item}', which is not a folder in the project.",
                                 "Name a top-level folder that this library shares, or remove it.")
                continue
            if not value.startswith("/") or "," in value or " " in value or not EXT_RE.search(value):
                continue
            candidates = [value[:-1], value] if value.endswith("c") else [value]
            found = None
            for candidate in candidates:
                status, actual = self.lookup(candidate)
                if status in ("ok", "builtin"):
                    found = actual or ""
                    break
            if found is None:
                status, actual = self.lookup(candidates[0])
                if status == "case":
                    message = f"{key} = {value} differs in letter case from /{actual}."
                elif status == "maybe-library":
                    continue
                else:
                    message = f"{key} = {value} points to a file that does not exist."
                self.add("warning", "setting-missing", "game.project", line, message,
                         self.missing_fix(candidates[0], f"Point {key} at an existing file"))
            elif found:
                roots.append(found)
        return roots

    def missing_fix(self, path: str, action: str) -> str:
        similar = [s for s in self.similar(path) if s != path]
        if similar:
            return f"{action}; a file with that name exists at {', '.join(similar)}."
        return f"{action}, or restore the file."

    # -- run

    def run(self) -> None:
        self.settings = parse_ini(read_text(self.root / "game.project"))
        self.read_defignore()
        self.scan()
        self.load_libraries()
        self.files_checked = 1  # game.project
        for rel in self.files:
            suffix = Path(rel).suffix.lower()
            if suffix not in RESOURCE_EXTS and suffix not in SCRIPT_EXTS:
                continue
            try:
                text = read_text(self.root / rel)
            except OSError:
                self.add("warning", "file-unreadable", rel, None, "File could not be read, so it was not checked.",
                         "Check the file's permissions.")
                continue
            self.files_checked += 1
            if suffix in RESOURCE_EXTS:
                self.collect_resource_refs(rel, text)
            else:
                self.collect_script_refs(rel, text)

        roots = self.check_settings()
        reachable = self.reachable(roots)
        for ref in self.refs:
            self.report_ref(ref, ref.file in reachable)

        if self.unfetched:
            line = self.dependency_urls()[0][1]
            self.add("warning", "dependencies-unfetched", "game.project", line,
                     f"{len(self.unfetched)} library dependenc{'y is' if len(self.unfetched) == 1 else 'ies are'} "
                     "not fetched, so paths they provide could not be checked.",
                     "Fetch libraries (Project > Fetch Libraries in the editor, or "
                     "'java -jar bob.jar resolve') and re-run this check.")

    def reachable(self, roots: list[str]) -> set[str]:
        edges: dict[str, list[str]] = {}
        for ref in self.refs:
            status, actual = self.lookup(ref.path)
            if status == "ok" and actual in self.file_set:
                edges.setdefault(ref.file, []).append(actual)
        seen: set[str] = set()
        stack = [r for r in roots if r in self.file_set]
        while stack:
            rel = stack.pop()
            if rel in seen:
                continue
            seen.add(rel)
            stack.extend(edges.get(rel, []))
        return seen

    def report_ref(self, ref: Ref, reachable: bool) -> None:
        status, actual = self.lookup(ref.path)
        if status in ("ok", "builtin"):
            return
        what = {
            "resource": "Resource",
            "require": "Lua module file",
            "resource-property": "Resource property",
            "load-resource": "sys.load_resource() file",
        }[ref.kind]
        severity = ref.severity if reachable else "warning"
        unused = "" if reachable else " This file is not used by the build yet, so Bob does not report it."
        if status == "case":
            self.add(severity, "path-case", ref.file, ref.line,
                     f"{what} {ref.path} differs in letter case from /{actual}.{unused}",
                     "Match the letter case exactly; Linux builds and CI are case-sensitive.")
        elif status == "ignored":
            self.add(severity, "path-ignored", ref.file, ref.line,
                     f"{what} {ref.path} is excluded by .defignore, so Bob cannot find it.{unused}",
                     "Remove the matching line from .defignore or stop referencing the file.")
        elif status == "maybe-library":
            self.add("warning", "path-unverified", ref.file, ref.line,
                     f"{what} {ref.path} is not in the project and may come from a library "
                     "dependency that is not fetched.",
                     "Fetch libraries and re-run; if no library provides it, fix the path.")
        elif ref.kind == "load-resource":
            self.add("warning", "path-missing", ref.file, ref.line,
                     f"{what} {ref.path} does not exist.",
                     "Fix the path and list the file or its folder in project.custom_resources.")
        else:
            if ref.kind == "require" and ref.severity == "warning":
                fix = (f"Add {ref.path}, or ignore this if the module is provided by the engine "
                       "or a native extension.")
            elif ref.kind == "require":
                fix = self.missing_fix(ref.path, "Fix the dotted module name (a.b means /a/b.lua)")
            else:
                fix = self.missing_fix(ref.path, "Fix the path")
            self.add(severity, "path-missing", ref.file, ref.line,
                     f"{what} {ref.path} does not exist.{unused}", fix)


# ----------------------------------------------------------------------- CLI


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="check_defold_project.py",
        description=(
            "Read-only check of a Defold project for broken references: game.project main "
            "collection and input binding (with the compiled 'c' suffix), quoted /paths in "
            "collections, game objects, atlases, GUI and other resources, require() modules "
            "and resource properties in scripts, letter-case mismatches, .defignore'd files "
            "and paths from fetched library dependencies."
        ),
        epilog=(
            "example:\n"
            "  python scripts/check_defold_project.py path/to/my_game\n"
            "  python scripts/check_defold_project.py . --json --max-issues 20\n\n"
            "exit codes: 0 no errors, 1 errors found (or warnings with --strict), "
            "2 usage problem or no game.project"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("project_dir", nargs="?", default=".", metavar="PROJECT_DIR",
                        help="folder that contains game.project (default: current folder)")
    parser.add_argument("--json", action="store_true", help="print one JSON object instead of text")
    parser.add_argument("--strict", action="store_true", help="exit 1 when there are warnings too")
    parser.add_argument("--max-issues", type=int, default=50, metavar="N",
                        help="print at most N issues, errors first (default: 50; 0 = no limit)")
    return parser


def main(argv: list[str] | None = None) -> int:
    # A console or pipe that cannot encode a file name (Windows code pages) must not crash the report.
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(errors="backslashreplace")
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.max_issues < 0:
        parser.error("--max-issues must be 0 or more")
    root = Path(args.project_dir).expanduser()
    if not root.is_dir():
        print(f"error: {args.project_dir} is not a folder", file=sys.stderr)
        return 2
    if not (root / "game.project").is_file():
        print(f"error: {args.project_dir} is not a Defold project (no game.project found there)",
              file=sys.stderr)
        return 2
    root = root.resolve()
    project = Project(root)
    project.run()

    def sort_key(issue: Issue) -> tuple:
        return (issue.file, issue.line or 0, issue.code, issue.message)

    errors = sorted((i for i in project.issues if i.severity == "error"), key=sort_key)
    warnings = sorted((i for i in project.issues if i.severity == "warning"), key=sort_key)
    ordered = errors + warnings
    shown = ordered[: args.max_issues] if args.max_issues else ordered
    truncated = len(ordered) > len(shown)

    if args.json:
        payload = {
            "tool": TOOL,
            "schema": SCHEMA,
            "root": root.as_posix(),
            "files_checked": project.files_checked,
            "error_count": len(errors),
            "warning_count": len(warnings),
            "errors": [i.as_dict() for i in shown if i.severity == "error"],
            "warnings": [i.as_dict() for i in shown if i.severity == "warning"],
            "truncated": truncated,
        }
        print(json.dumps(payload, indent=2))
    else:
        for issue in shown:
            where = f"{issue.file}:{issue.line}" if issue.line else issue.file
            print(f"{issue.severity.upper()} {where}: {issue.message}")
            print(f"  fix: {issue.fix}")
        if truncated:
            print(f"... and {len(ordered) - len(shown)} more")
        print(f"Summary: {len(errors)} errors, {len(warnings)} warnings in {project.files_checked} files checked")

    if errors or (args.strict and warnings):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
