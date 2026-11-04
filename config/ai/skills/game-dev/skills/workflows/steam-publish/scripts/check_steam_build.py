#!/usr/bin/env python3
"""Check a SteamPipe app build script before running ``steamcmd +run_app_build``.

Reads an ``app_build_<appid>.vdf`` file, every depot script it references, and
the content folders those scripts point at, then reports what would go wrong
with the upload. It never writes anything, never runs steamcmd, never opens the
network and never reads Steam login files.

Errors (the upload would be wrong or fail):
  vdf-parse                 the VDF text does not parse (with the line number)
  appid-missing             AppBuild has no AppID
  appid-not-numeric         AppID is not a positive whole number
  depots-missing            no Depots block, or it is empty
  depotid-not-numeric       a depot ID (Depots key or DepotID) is not a number
  depot-duplicate           the same depot ID is listed twice
  depot-script-missing      a depot script path does not exist
  contentroot-missing       a ContentRoot folder does not exist
  filemapping-no-localpath  a FileMapping block has no LocalPath
  localpath-is-folder       LocalPath names a folder; it needs a wildcard
  localpath-no-match        a FileMapping LocalPath matches no files
  depot-empty               a depot would upload zero files
  installscript-missing     an InstallScript file does not exist

Warnings (worth a look, the upload may still be what you meant):
  desc-missing, setlive-immediate, setlive-default, local-content-server,
  buildoutput-in-contentroot, contentroot-not-set, contentroot-ambiguous,
  depotid-mismatch, depot-script-root, installscript-not-mapped, case-mismatch,
  flag-not-numeric, duplicate-key, unknown-key, include-not-followed

Path rules follow the Steamworks "Uploading to Steam" page
(partner.steamgames.com/doc/sdk/uploading) and the ContentBuilder sample
scripts shipped in the Steamworks SDK:
  * AppBuild ContentRoot / BuildOutput: absolute, or relative to the folder of
    the build script file.
  * Depots entries: "<DepotID>" "<depot script path>" (absolute, or relative to
    the app build script's folder), or "<DepotID>" { ...inline DepotBuild... }.
  * DepotBuild ContentRoot overrides the app ContentRoot. When neither is set,
    the SDK sample says the content root is the folder of the script file.
  * LocalPath, FileExclusion and InstallScript: absolute, or relative to the
    depot's content root. '*' and '?' are wildcards. With Recursive "1" the
    LocalPath file name (wildcard or plain) also matches files in subfolders.
    A FileExclusion '*' also crosses folders ("bin\\tools*" drops everything
    under bin\\tools\\).
  * Quoted strings end at the next double quote. Backslashes are literal, so
    "..\\content\\" is a Windows path, not an escaped quote. Keys are not case
    sensitive. Backslash paths are read as forward slashes on every OS.
    Platform tags such as [$WIN32] or [$LINUX] are evaluated for this machine
    the way Valve's KeyValues does, and keys whose tag is false are dropped.

Exit codes: 0 no errors, 1 errors (or warnings with --strict), 2 usage problem,
file missing, or the file is not an AppBuild script.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterator

TOOL = "check_steam_build"
SCHEMA = 1

# Windows and macOS file systems ignore letter case by default.
FOLD_CASE_PLATFORM = sys.platform.startswith(("win", "darwin", "cygwin"))

APP_KEYS = {"appid", "desc", "contentroot", "buildoutput", "preview", "local", "setlive", "depots"}
DEPOT_KEYS = {"depotid", "contentroot", "filemapping", "fileexclusion", "installscript", "fileproperties"}
MAPPING_KEYS = {"localpath", "depotpath", "recursive"}
PROPERTY_KEYS = {"localpath", "attributes"}
DEPOT_ROOT_NAMES = {"depotbuild", "depotbuildconfig"}
# Keys that may legally repeat inside one block.
REPEATABLE = {"filemapping", "fileexclusion", "fileproperties"}

WINDOWS_ABS_RE = re.compile(r"^(?:[A-Za-z]:[\\/]|\\\\|//)")
NUMBER_RE = re.compile(r"^[0-9]+$")


# --------------------------------------------------------------------------
# VDF (Valve KeyValues text) parser
# --------------------------------------------------------------------------


class VdfError(Exception):
    def __init__(self, message: str, line: int) -> None:
        super().__init__(message)
        self.message = message
        self.line = line


@dataclass
class Node:
    key: str
    line: int
    value: str | None = None
    children: list["Node"] | None = None

    @property
    def is_block(self) -> bool:
        return self.children is not None

    def all(self, name: str) -> list["Node"]:
        name = name.lower()
        return [child for child in self.children or [] if child.key.lower() == name]

    def first(self, name: str) -> "Node | None":
        found = self.all(name)
        return found[0] if found else None

    def text(self, name: str) -> str | None:
        """String value of the first child called ``name``; None if absent or a block."""
        node = self.first(name)
        if node is None or node.is_block:
            return None
        return node.value


@dataclass
class Directive:
    name: str
    target: str
    line: int


@dataclass
class Token:
    kind: str  # "str", "{", "}", "cond", "directive"
    text: str
    line: int
    multiline: bool = False


def read_vdf_text(path: Path) -> str:
    raw = path.read_bytes()
    try:
        text = raw.decode("utf-8-sig")
    except UnicodeDecodeError:
        text = raw.decode("latin-1")
    return text.replace("\r\n", "\n").replace("\r", "\n")


def tokenize(text: str) -> Iterator[Token]:
    i, line, n = 0, 1, len(text)
    first_multiline: int | None = None
    while i < n:
        ch = text[i]
        if ch == "\n":
            line += 1
            i += 1
        elif ch in " \t\f\v":
            i += 1
        elif text.startswith("//", i):
            end = text.find("\n", i)
            i = n if end == -1 else end
        elif ch in "{}":
            yield Token(ch, ch, line)
            i += 1
        elif ch == '"':
            # No escape processing: Valve's own samples end paths with \" .
            end = text.find('"', i + 1)
            if end == -1:
                if first_multiline is not None:
                    raise VdfError(
                        f"quoted string opened on line {first_multiline} is not closed on that line (missing \")",
                        first_multiline,
                    )
                raise VdfError("quoted string is never closed (missing \")", line)
            value = text[i + 1 : end]
            newlines = value.count("\n")
            if newlines and first_multiline is None:
                first_multiline = line
            yield Token("str", value, line, multiline=newlines > 0)
            line += newlines
            i = end + 1
        elif ch == "[" and _condition_end(text, i) != -1:
            # Platform conditionals such as [$WIN32]; the parser evaluates them.
            end = _condition_end(text, i)
            yield Token("cond", text[i : end + 1], line)
            i = end + 1
        else:
            j = _unquoted_end(text, i)
            word = text[i:j]
            if word.lower() in ("#include", "#base"):
                yield Token("directive", word.lower(), line)
            else:
                yield Token("str", word, line)
            i = j


def _condition_end(text: str, i: int) -> int:
    """Index of the ']' closing a [$PLATFORM] conditional on the same line, or -1."""
    end = text.find("]", i)
    newline = text.find("\n", i)
    if end == -1 or (newline != -1 and newline < end):
        return -1
    return end


# Tags in the order Valve's KeyValues tests them; $WIN32 means "any PC".
PLATFORM_TAGS = (
    ("$X360", False),
    ("$WIN32", True),
    ("$WINDOWS", sys.platform.startswith(("win", "cygwin"))),
    ("$OSX", sys.platform == "darwin"),
    ("$LINUX", sys.platform.startswith("linux")),
    ("$POSIX", not sys.platform.startswith("win")),
)


def condition_holds(cond: str) -> bool:
    """Evaluate a [$PLATFORM] tag for this machine, like KeyValues: optional '!', unknown tags are false."""
    text = cond.strip("[] \t").upper()
    negate = text.startswith("!")
    for tag, on in PLATFORM_TAGS:
        if tag in text:
            return on != negate
    return False


def _unquoted_end(text: str, i: int) -> int:
    j = i
    while j < len(text) and text[j] not in ' \t\f\v\n"{}' and not text.startswith("//", j):
        j += 1
    return j


def parse_vdf(text: str) -> tuple[list[Node], list[Directive]]:
    tokens = list(tokenize(text))
    pos = 0
    directives: list[Directive] = []
    # A missing closing quote swallows text up to the next quote, so later
    # errors point here. Name the line where such a long string started.
    multiline_at: list[int] = [t.line for t in tokens if t.multiline]

    def fail(message: str, line: int) -> VdfError:
        earlier = [m for m in multiline_at if m <= line]
        if earlier:
            return VdfError(
                f"quoted string opened on line {earlier[0]} is not closed on that line (missing \"),"
                f" which then breaks line {line}: {message}",
                earlier[0],
            )
        return VdfError(message, line)

    def next_token(skip_cond: bool = True) -> Token | None:
        nonlocal pos
        while pos < len(tokens):
            tok = tokens[pos]
            pos += 1
            if skip_cond and tok.kind == "cond":
                continue
            return tok
        return None

    def block(opened_line: int | None) -> list[Node]:
        nonlocal pos
        nodes: list[Node] = []
        while True:
            tok = next_token()
            if tok is None:
                if opened_line is not None:
                    last = tokens[-1].line if tokens else opened_line
                    raise fail(f"block opened on line {opened_line} is never closed (missing '}}')", last)
                return nodes
            if tok.kind == "}":
                if opened_line is None:
                    raise fail("unexpected '}' with no open block", tok.line)
                return nodes
            if tok.kind == "{":
                raise fail("'{' without a key before it", tok.line)
            if tok.kind == "directive":
                target = next_token()
                if target is None or target.kind != "str":
                    raise fail(f"{tok.text} needs a file name", tok.line)
                directives.append(Directive(tok.text, target.text, tok.line))
                continue
            # A conditional may sit between key and value, or right after a string value.
            # Keys whose conditional is false on this machine are dropped, as KeyValues does.
            accepted = True
            value_tok = next_token(skip_cond=False)
            if value_tok is not None and value_tok.kind == "cond":
                accepted = condition_holds(value_tok.text)
                value_tok = next_token()
            if value_tok is None or value_tok.kind == "}":
                raise fail(f'key "{tok.text}" has no value', tok.line)
            if value_tok.kind == "{":
                node = Node(tok.text, tok.line, children=block(value_tok.line))
            elif value_tok.kind == "str":
                node = Node(tok.text, tok.line, value=value_tok.text)
                if pos < len(tokens) and tokens[pos].kind == "cond":
                    accepted = condition_holds(tokens[pos].text)
                    pos += 1
            else:
                raise fail(f'key "{tok.text}" has no value', tok.line)
            if accepted:
                nodes.append(node)

    return block(None), directives


# --------------------------------------------------------------------------
# Paths and wildcard matching
# --------------------------------------------------------------------------


def slashes(raw: str) -> str:
    return raw.strip().replace("\\", "/")


def is_foreign_windows_path(raw: str) -> bool:
    return os.name != "nt" and bool(WINDOWS_ABS_RE.match(raw.strip()))


def resolve(base: Path, raw: str) -> Path | None:
    """Resolve a VDF path value. None means a Windows drive path on a non-Windows OS."""
    if is_foreign_windows_path(raw):
        return None
    candidate = Path(slashes(raw))
    if not candidate.is_absolute():
        candidate = base / candidate
    return Path(os.path.normpath(str(candidate)))


def has_wildcard(text: str) -> bool:
    return "*" in text or "?" in text


def wildcard_regex(pattern: str, *, cross_folders: bool, fold: bool) -> re.Pattern[str]:
    parts = []
    for ch in pattern:
        if ch == "*":
            parts.append(".*" if cross_folders else "[^/]*")
        elif ch == "?":
            parts.append("." if cross_folders else "[^/]")
        else:
            parts.append(re.escape(ch))
    flags = re.DOTALL | (re.IGNORECASE if fold else 0)
    return re.compile("".join(parts) + r"\Z", flags)


def scandir(folder: Path) -> list[os.DirEntry[str]]:
    try:
        with os.scandir(folder) as entries:
            return list(entries)
    except OSError:
        return []


@dataclass
class Match:
    path: Path  # absolute file on disk
    rel: str  # path below the mapping's base folder, used for the depot path
    exact_case: bool


@dataclass
class MappingResult:
    matches: list[Match] = field(default_factory=list)
    names_folder: bool = False


def match_local_path(content_root: Path, raw: str, recursive: bool) -> MappingResult:
    """Expand a FileMapping LocalPath the way SteamPipe documents it.

    Matching ignores letter case so that a case slip is reported as a warning,
    not as an empty depot. Each match records whether the case was exact.
    """
    text = slashes(raw)
    if is_foreign_windows_path(raw):
        return MappingResult()
    as_path = Path(text)
    if as_path.is_absolute():
        start = Path(as_path.anchor)
        comps = list(as_path.parts[1:])
    else:
        start = content_root
        comps = text.split("/")
    if text.endswith("/"):
        comps = [c for c in comps if c]
        folders = _expand_folders(start, comps)
        return MappingResult(names_folder=any(f.is_dir() for f, _ in folders))
    comps = [c for c in comps if c not in ("", ".")]
    if not comps:
        return MappingResult(names_folder=start.is_dir())
    *dir_comps, name = comps
    if name == "..":
        return MappingResult(names_folder=True)
    result = MappingResult()
    for folder, folder_exact in _expand_folders(start, dir_comps):
        if not has_wildcard(name) and not recursive:
            exact = folder / name
            if exact.is_file():
                result.matches.append(Match(exact, name, folder_exact))
            elif exact.is_dir():
                result.names_folder = True
            else:
                for entry in scandir(folder):
                    if entry.name.lower() == name.lower():
                        if entry.is_file():
                            result.matches.append(Match(Path(entry.path), entry.name, False))
                        elif entry.is_dir():
                            result.names_folder = True
            continue
        # With Recursive on, a plain name is matched in every subfolder too.
        if not has_wildcard(name) and (folder / name).is_dir():
            result.names_folder = True
        loose = wildcard_regex(name, cross_folders=False, fold=True)
        strict = wildcard_regex(name, cross_folders=False, fold=False)
        if recursive:
            for here, dirs, files in os.walk(folder):
                dirs.sort()
                sub = os.path.relpath(here, folder)
                prefix = "" if sub == "." else Path(sub).as_posix() + "/"
                for file_name in sorted(files):
                    if loose.match(file_name):
                        full = Path(here, file_name)
                        exact_case = folder_exact and bool(strict.match(file_name))
                        result.matches.append(Match(full, prefix + file_name, exact_case))
        else:
            for entry in sorted(scandir(folder), key=lambda e: e.name):
                if entry.is_file() and loose.match(entry.name):
                    exact_case = folder_exact and bool(strict.match(entry.name))
                    result.matches.append(Match(Path(entry.path), entry.name, exact_case))
    return result


def _expand_folders(start: Path, comps: list[str]) -> list[tuple[Path, bool]]:
    current: list[tuple[Path, bool]] = [(start, True)] if start.is_dir() else []
    for comp in comps:
        if comp in ("", "."):
            continue
        found: dict[str, tuple[Path, bool]] = {}
        for folder, exact in current:
            if comp == "..":
                parent = folder.parent
                found.setdefault(str(parent), (parent, exact))
                continue
            if not has_wildcard(comp) and (folder / comp).is_dir():
                child = folder / comp
                found.setdefault(str(child), (child, exact))
                continue
            loose = wildcard_regex(comp, cross_folders=False, fold=True)
            strict = wildcard_regex(comp, cross_folders=False, fold=False)
            for entry in scandir(folder):
                if entry.is_dir() and loose.match(entry.name):
                    found.setdefault(entry.path, (Path(entry.path), exact and bool(strict.match(entry.name))))
        current = list(found.values())
    return current


def join_depot_path(depot_path: str, rel: str) -> str:
    base = slashes(depot_path).strip("/")
    joined = f"{base}/{rel}" if base and base != "." else rel
    return os.path.normpath(joined).replace("\\", "/")


def is_inside(child: Path, parent: Path) -> bool:
    child_s = os.path.normcase(str(child))
    parent_s = os.path.normcase(str(parent))
    return child_s == parent_s or child_s.startswith(parent_s.rstrip(os.sep) + os.sep)


# --------------------------------------------------------------------------
# Checker
# --------------------------------------------------------------------------


@dataclass
class Issue:
    level: str
    code: str
    file: str
    line: int | None
    message: str
    fix: str

    def as_json(self) -> dict[str, object]:
        return {"code": self.code, "file": self.file, "line": self.line, "message": self.message, "fix": self.fix}


class UsageProblem(Exception):
    pass


class Checker:
    def __init__(self, app_file: Path) -> None:
        self.app_file = Path(os.path.normpath(str(app_file.resolve())))
        self.root = self.app_file.parent
        self.issues: list[Issue] = []
        self.files_checked = 0
        self.depots: list[dict[str, object]] = []
        self.preview = False

    # -- reporting helpers ---------------------------------------------------

    def show(self, path: Path) -> str:
        """Path for messages: relative to the app script folder when close by, else absolute."""
        try:
            rel = Path(os.path.relpath(path, self.root))
        except ValueError:  # different drive on Windows
            return path.as_posix()
        if rel.parts[:3] == ("..", "..", ".."):
            return path.as_posix()
        return rel.as_posix()

    def error(self, code: str, file: Path, line: int | None, message: str, fix: str) -> None:
        self.issues.append(Issue("ERROR", code, self.show(file), line, message, fix))

    def warn(self, code: str, file: Path, line: int | None, message: str, fix: str) -> None:
        self.issues.append(Issue("WARNING", code, self.show(file), line, message, fix))

    # -- loading -------------------------------------------------------------

    def load(self, path: Path) -> tuple[list[Node], list[Directive]] | None:
        self.files_checked += 1
        try:
            text = read_vdf_text(path)
        except OSError as exc:
            raise UsageProblem(f"{path}: cannot read file ({exc.strerror or exc})") from exc
        try:
            nodes, directives = parse_vdf(text)
        except VdfError as exc:
            self.error("vdf-parse", path, exc.line, f"VDF does not parse: {exc.message}",
                       "Fix the syntax at that line: every key needs a quoted value or a { } block,"
                       " and every quote and brace needs its partner.")
            return None
        for item in directives:
            self.warn("include-not-followed", path, item.line,
                      f'{item.name} "{item.target}" was not followed; keys from that file were not checked',
                      "Inline the included keys if you want them checked.")
        return nodes, directives

    def check_keys(self, block: Node, file: Path, allowed: set[str], where: str) -> None:
        seen: dict[str, Node] = {}
        for child in block.children or []:
            low = child.key.lower()
            if low not in allowed:
                self.warn("unknown-key", file, child.line,
                          f'"{child.key}" is not a documented {where} key, so steamcmd will likely ignore it',
                          f"Check the spelling. Documented keys: {', '.join(sorted(allowed))}.")
            elif low in seen and low not in REPEATABLE:
                self.warn("duplicate-key", file, child.line,
                          f'"{child.key}" is set twice in {where} (first on line {seen[low].line}); only one value is used',
                          "Keep a single copy of this key.")
            seen.setdefault(low, child)

    def flag(self, node: Node | None, file: Path) -> bool:
        """Read a 0/1 switch the way KeyValues does (whole number, non-zero = on)."""
        if node is None or node.is_block or node.value is None or not node.value.strip():
            return False
        value = node.value.strip()
        try:
            return int(value) != 0
        except ValueError:
            self.warn("flag-not-numeric", file, node.line,
                      f'{node.key} is "{value}"; steamcmd reads switches as numbers, so this is read as 0 (off)',
                      f'Use "{node.key}" "1" to turn it on or "0" to turn it off.')
            return False

    # -- main ----------------------------------------------------------------

    def run(self) -> None:
        if not self.app_file.is_file():
            raise UsageProblem(f"{self.app_file}: file not found")
        loaded = self.load(self.app_file)
        if loaded is None:
            return
        nodes, _ = loaded
        roots = [n for n in nodes if n.is_block]
        if not roots or roots[0].key.lower() != "appbuild":
            found = f'top-level block is "{roots[0].key}"' if roots else "no top-level block found"
            raise UsageProblem(
                f"{self.app_file}: not an AppBuild script ({found}). "
                "Pass the app build script (app_build_<appid>.vdf), not a depot script."
            )
        app = roots[0]
        self.check_keys(app, self.app_file, APP_KEYS, "AppBuild")
        self.check_app_fields(app)
        self.check_depots(app)

    def check_app_fields(self, app: Node) -> None:
        file = self.app_file
        appid = app.first("AppID")
        if appid is None or appid.is_block or not (appid.value or "").strip():
            self.error("appid-missing", file, app.line, "AppBuild has no AppID",
                       'Add "AppID" "<your app id>" (Steamworks home page lists it).')
        elif not NUMBER_RE.match(appid.value.strip()) or int(appid.value.strip()) == 0:
            self.error("appid-not-numeric", file, appid.line, f'AppID "{appid.value}" is not a positive whole number',
                       "Use the numeric App ID from Steamworks, with no spaces or letters.")

        desc = app.first("Desc")
        if desc is None or desc.is_block or not (desc.value or "").strip():
            self.warn("desc-missing", file, desc.line if desc else app.line,
                      "Desc is empty, so this build is hard to tell apart on the Builds page",
                      'Add "Desc" "<version or commit>".')

        self.preview = self.flag(app.first("Preview"), file)
        local = app.first("Local")
        if local is not None and not local.is_block and (local.value or "").strip():
            self.warn("local-content-server", file, local.line,
                      f'Local is set to "{local.value}", so the build goes to a Local Content Server and nothing is uploaded to Steam',
                      "Remove Local (or set it to \"\") for a real upload.")

        setlive = app.first("SetLive")
        branch = (setlive.value or "").strip() if setlive is not None and not setlive.is_block else ""
        if branch and not self.preview:
            if branch.lower() == "default":
                self.warn("setlive-default", file, setlive.line,
                          'SetLive is "default": the default branch is what every player gets. Valve\'s docs say a build'
                          " script cannot set the default branch live, so this step will not work as written; if it did,"
                          " this build would release to all players at once",
                          "Remove SetLive, or set a beta branch, and set the default branch live by hand on the Builds page.")
            else:
                self.warn("setlive-immediate", file, setlive.line,
                          f'SetLive is "{branch}" and Preview is off: this build goes live on branch "{branch}" as soon as the upload finishes',
                          f'Make sure "{branch}" is the branch you mean, or remove SetLive and set it live by hand.')

    def check_depots(self, app: Node) -> None:
        file = self.app_file
        depots = app.first("Depots")
        if depots is None or not depots.is_block or not depots.children:
            self.error("depots-missing", file, depots.line if depots else app.line,
                       "AppBuild has no depots, so nothing would be uploaded",
                       'Add a "Depots" block: "<DepotID>" "depot_build_<DepotID>.vdf" or "<DepotID>" { FileMapping ... }.')
            return

        app_root_node = app.first("ContentRoot")
        app_root_raw = (app_root_node.value or "").strip() if app_root_node and not app_root_node.is_block else ""
        app_root_reported = False
        buildoutput_node = app.first("BuildOutput")
        buildoutput_raw = (buildoutput_node.value or "").strip() if buildoutput_node and not buildoutput_node.is_block else ""
        buildoutput = resolve(self.root, buildoutput_raw) if buildoutput_raw else None
        buildoutput_hits: list[str] = []

        seen_ids: dict[str, int] = {}
        for entry in depots.children:
            depot_id = entry.key.strip()
            if not NUMBER_RE.match(depot_id):
                self.error("depotid-not-numeric", file, entry.line, f'depot ID "{entry.key}" in Depots is not a number',
                           "Use the numeric Depot ID from the Steamworks Depots page.")
            elif depot_id in seen_ids:
                self.error("depot-duplicate", file, entry.line,
                           f"depot {depot_id} is listed twice in Depots (first on line {seen_ids[depot_id]})",
                           "Keep one entry per depot; merge the FileMapping blocks into it.")
                continue
            else:
                seen_ids[depot_id] = entry.line

            # Find the DepotBuild block: inline, or in a separate script.
            if entry.is_block:
                depot_block, depot_file, script_shown = entry, file, None
            else:
                raw = (entry.value or "").strip()
                script = resolve(self.root, raw) if raw else None
                if script is None or not script.is_file():
                    where = "is a Windows drive path that cannot exist on this machine" if raw and script is None else "not found"
                    self.error("depot-script-missing", file, entry.line,
                               f'depot {depot_id} script "{raw}" {where}'
                               + (f" (looked for {script.as_posix()})" if script is not None else ""),
                               "Depot script paths are relative to the app build script's folder; fix the path or create the file.")
                    continue
                loaded = self.load(script)
                if loaded is None:
                    continue
                nodes, _ = loaded
                blocks = [n for n in nodes if n.is_block]
                if not blocks:
                    self.error("depot-script-missing", script, None, f"depot {depot_id} script has no DepotBuild block",
                               'Wrap the depot settings in "DepotBuild" { ... }.')
                    continue
                depot_block, depot_file, script_shown = blocks[0], script, self.show(script)
                if depot_block.key.lower() not in DEPOT_ROOT_NAMES:
                    self.warn("depot-script-root", script, depot_block.line,
                              f'depot script top-level block is "{depot_block.key}", expected "DepotBuild"',
                              'Name the block "DepotBuild" (Valve samples) or "DepotBuildConfig".')

            self.check_keys(depot_block, depot_file, DEPOT_KEYS, "DepotBuild")
            inner_id = depot_block.first("DepotID")
            if inner_id is not None and not inner_id.is_block:
                inner = (inner_id.value or "").strip()
                if not NUMBER_RE.match(inner):
                    self.error("depotid-not-numeric", depot_file, inner_id.line, f'DepotID "{inner_id.value}" is not a number',
                               "Use the numeric Depot ID from the Steamworks Depots page.")
                elif NUMBER_RE.match(depot_id) and inner != depot_id:
                    self.warn("depotid-mismatch", depot_file, inner_id.line,
                              f"DepotID {inner} does not match the Depots entry {depot_id} that points here",
                              "Make the Depots key and the DepotID the same number.")

            content_root, root_raw = self.depot_content_root(depot_block, depot_file, app_root_raw,
                                                             app_root_node, app_root_reported)
            if root_raw == "app" and content_root is None:
                app_root_reported = True
            summary = self.check_depot_files(depot_id, depot_block, depot_file, content_root)
            summary["script"] = script_shown
            summary["line"] = entry.line
            self.depots.append(summary)

            if buildoutput is not None and content_root is not None and is_inside(buildoutput, content_root):
                buildoutput_hits.append(depot_id)

        if buildoutput_hits and buildoutput is not None and buildoutput_node is not None:
            self.warn("buildoutput-in-contentroot", file, buildoutput_node.line,
                      f"BuildOutput ({self.show(buildoutput)}) is inside the content root of depot(s) {', '.join(buildoutput_hits)}:"
                      " build logs and chunk cache files written there can be uploaded with the game",
                      "Move BuildOutput outside ContentRoot (Valve's layout uses ..\\output\\), or exclude it with FileExclusion.")

    def depot_content_root(self, depot: Node, depot_file: Path, app_root_raw: str,
                           app_root_node: Node | None, app_root_reported: bool) -> tuple[Path | None, str]:
        own = depot.first("ContentRoot")
        own_raw = (own.value or "").strip() if own is not None and not own.is_block else ""
        if own_raw:
            path = resolve(depot_file.parent, own_raw)
            if path is not None and path.is_dir():
                return path, "depot"
            if depot_file.parent != self.root:
                other = resolve(self.root, own_raw)
                if other is not None and other.is_dir():
                    self.warn("contentroot-ambiguous", depot_file, own.line,
                              f'ContentRoot "{own_raw}" is not found next to this depot script but is found next to the app'
                              f" build script ({self.show(other)}); the check used that one",
                              "Use an absolute ContentRoot, or keep depot scripts in the same folder as the app build script.")
                    return other, "depot"
            self.report_missing_root(depot_file, own.line, own_raw, path)
            return None, "depot"
        if app_root_raw:
            path = resolve(self.root, app_root_raw)
            if path is not None and path.is_dir():
                return path, "app"
            if not app_root_reported and app_root_node is not None:
                self.report_missing_root(self.app_file, app_root_node.line, app_root_raw, path)
            return None, "app"
        self.warn("contentroot-not-set", depot_file, depot.line,
                  "no ContentRoot is set for this depot, so SteamPipe uses the folder of the script file "
                  f"({self.show(depot_file.parent)}) as the content root",
                  'Set "ContentRoot" in the AppBuild block (Valve\'s layout: "..\\content\\").')
        return depot_file.parent, "script"

    def report_missing_root(self, file: Path, line: int | None, raw: str, path: Path | None) -> None:
        if path is None:
            self.error("contentroot-missing", file, line,
                       f'ContentRoot "{raw}" is a Windows drive path, which cannot exist on this machine',
                       "Run this check on the machine that runs steamcmd, or use a path relative to the script.")
        else:
            what = "is a file, not a folder" if path.exists() else "does not exist"
            self.error("contentroot-missing", file, line, f'ContentRoot "{raw}" {what} (resolved to {path.as_posix()})',
                       "Relative ContentRoot paths start at the folder of the script file; point it at the folder"
                       " that holds the built game.")

    def check_depot_files(self, depot_id: str, depot: Node, depot_file: Path,
                          content_root: Path | None) -> dict[str, object]:
        summary: dict[str, object] = {
            "depot_id": depot_id,
            "content_root": content_root.as_posix() if content_root else None,
            "files": 0,
            "bytes": 0,
            "excluded": 0,
            "mappings": [],
        }
        mappings = depot.all("FileMapping")
        if content_root is None:
            return summary
        if not mappings:
            self.error("depot-empty", depot_file, depot.line, f"depot {depot_id} has no FileMapping, so it would upload zero files",
                       'Add a FileMapping: { "LocalPath" "*" "DepotPath" "." "Recursive" "1" }.')
            return summary

        exclusions = []
        for node in depot.all("FileExclusion"):
            if node.is_block or not (node.value or "").strip():
                continue
            pattern = slashes(node.value)
            while pattern.startswith("./"):
                pattern = pattern[2:]
            absolute = Path(pattern).is_absolute()
            exclusions.append((absolute, wildcard_regex(pattern, cross_folders=True, fold=FOLD_CASE_PLATFORM)))

        root_prefix = os.path.normcase(str(content_root)).rstrip(os.sep) + os.sep

        def excluded(path: Path) -> bool:
            text = str(path)
            if os.path.normcase(text).startswith(root_prefix):
                rel = text[len(root_prefix):].replace(os.sep, "/")
            else:
                rel = path.as_posix()
            for absolute, regex in exclusions:
                if regex.match(path.as_posix() if absolute else rel):
                    return True
            return False

        uploads: dict[str, Path] = {}
        excluded_count = 0
        all_mapping_matched = True
        for mapping in mappings:
            if not mapping.is_block:
                continue
            self.check_keys(mapping, depot_file, MAPPING_KEYS, "FileMapping")
            local = mapping.text("LocalPath")
            depot_path = mapping.text("DepotPath") or "."
            recursive = self.flag(mapping.first("Recursive"), depot_file)
            info = {"local_path": local, "depot_path": depot_path, "recursive": recursive, "files": 0}
            summary["mappings"].append(info)  # type: ignore[union-attr]
            if local is None or not local.strip():
                all_mapping_matched = False
                self.error("filemapping-no-localpath", depot_file, mapping.line, f"a FileMapping in depot {depot_id} has no LocalPath",
                           'Add "LocalPath" "*" (or the files you want) to this FileMapping.')
                continue
            result = match_local_path(content_root, local, recursive)
            if not result.matches:
                all_mapping_matched = False
                if result.names_folder:
                    hint = local.rstrip("\\/") + ("\\*" if "\\" in local else "/*")
                    self.error("localpath-is-folder", depot_file, mapping.line,
                               f'LocalPath "{local}" names a folder, and a folder path without a wildcard picks up no files',
                               f'Use "{hint}" with "Recursive" "1" to upload that folder.')
                else:
                    if is_foreign_windows_path(local):
                        message = f'LocalPath "{local}" is a Windows drive path, which cannot exist on this machine'
                    else:
                        message = f'LocalPath "{local}" matches no files under {self.show(content_root)}'
                    self.error("localpath-no-match", depot_file, mapping.line, message,
                               "LocalPath is relative to the content root; check the folder names, that the built"
                               " game is there, and Recursive \"1\" if the files are in subfolders.")
                continue
            loose_case = [m for m in result.matches if not m.exact_case]
            if loose_case and not FOLD_CASE_PLATFORM:
                self.warn("case-mismatch", depot_file, mapping.line,
                          f'{len(loose_case)} of {len(result.matches)} files matched by LocalPath "{local}" only match when letter'
                          f" case is ignored (e.g. {self.show(loose_case[0].path)}); file names are case-sensitive here",
                          "Match the letter case of the real folder and file names.")
            kept = 0
            for match in result.matches:
                if excluded(match.path):
                    excluded_count += 1
                    continue
                kept += 1
                uploads[join_depot_path(depot_path, match.rel)] = match.path
            info["files"] = kept

        sizes = 0
        for path in uploads.values():
            try:
                sizes += path.stat().st_size
            except OSError:
                pass
        summary.update(files=len(uploads), bytes=sizes, excluded=excluded_count)
        if not uploads and all_mapping_matched:
            self.error("depot-empty", depot_file, depot.line,
                       f"depot {depot_id} would upload zero files: FileExclusion removes every mapped file",
                       "Loosen the FileExclusion patterns; they are matched against paths relative to the content root.")

        install = depot.first("InstallScript")
        if install is not None and not install.is_block and (install.value or "").strip():
            raw = install.value.strip()
            path = resolve(content_root, raw)
            if path is None or not path.is_file():
                self.error("installscript-missing", depot_file, install.line,
                           f'InstallScript "{raw}" not found' + (f" (looked for {path.as_posix()})" if path else ""),
                           "InstallScript is relative to the depot's content root; fix the path or remove the line.")
            else:
                uploaded = {os.path.normcase(str(p)) for p in uploads.values()}
                if os.path.normcase(str(path)) not in uploaded:
                    self.warn("installscript-not-mapped", depot_file, install.line,
                              f'InstallScript "{raw}" exists but is not in this depot\'s upload (not mapped, or excluded)',
                              "Add a FileMapping for it and make sure no FileExclusion (such as *.vdf) drops it.")

        for prop in depot.all("FileProperties"):
            if prop.is_block:
                self.check_keys(prop, depot_file, PROPERTY_KEYS, "FileProperties")
        return summary


# --------------------------------------------------------------------------
# Output
# --------------------------------------------------------------------------


def human_size(size: int) -> str:
    value = float(size)
    for unit in ("B", "KiB", "MiB", "GiB"):
        if value < 1024 or unit == "GiB":
            return f"{int(value)} {unit}" if unit == "B" else f"{value:.1f} {unit}"
        value /= 1024
    return f"{size} B"


def ordered_issues(issues: list[Issue]) -> tuple[list[Issue], list[Issue]]:
    return [i for i in issues if i.level == "ERROR"], [i for i in issues if i.level == "WARNING"]


def render_text(checker: Checker, max_issues: int) -> str:
    errors, warnings = ordered_issues(checker.issues)
    combined = errors + warnings
    shown = combined if max_issues <= 0 else combined[:max_issues]
    lines = []
    for issue in shown:
        where = f"{issue.file}:{issue.line}" if issue.line is not None else issue.file
        lines.append(f"{issue.level} {where}: {issue.message}")
        lines.append(f"  fix: {issue.fix}")
    if len(shown) < len(combined):
        lines.append(f"... and {len(combined) - len(shown)} more")
    if checker.depots:
        if lines:
            lines.append("")
        mode = " (Preview: nothing is uploaded)" if checker.preview else ""
        lines.append(f"Depots{mode}:")
        for depot in checker.depots:
            source = f" [{depot['script']}]" if depot.get("script") else " [inline]"
            root = depot["content_root"]
            root_text = f"from {checker.show(Path(root))}" if root else "(content root missing)"
            excluded = f", {depot['excluded']} excluded" if depot["excluded"] else ""
            lines.append(
                f"  {depot['depot_id']}{source}: {depot['files']} files, {human_size(int(depot['bytes']))}"
                f"{excluded}, {root_text}"
            )
    lines.append(
        f"Summary: {len(errors)} errors, {len(warnings)} warnings in {checker.files_checked} files checked"
    )
    return "\n".join(lines)


def render_json(checker: Checker, max_issues: int) -> str:
    errors, warnings = ordered_issues(checker.issues)
    total = len(errors) + len(warnings)
    if max_issues > 0 and total > max_issues:
        errors_out = errors[:max_issues]
        warnings_out = warnings[: max(0, max_issues - len(errors_out))]
        truncated = True
    else:
        errors_out, warnings_out, truncated = errors, warnings, False
    payload = {
        "tool": TOOL,
        "schema": SCHEMA,
        "root": checker.root.as_posix(),
        "files_checked": checker.files_checked,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": [i.as_json() for i in errors_out],
        "warnings": [i.as_json() for i in warnings_out],
        "truncated": truncated,
        "depots": checker.depots,
    }
    return json.dumps(payload, indent=2)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="check_steam_build.py",
        description=(
            "Check a SteamPipe app build script (app_build_<appid>.vdf) and the depot scripts and content"
            " folders it points at, before running steamcmd +run_app_build. Read-only."
        ),
        epilog=(
            "example:\n"
            "  python scripts/check_steam_build.py tools/ContentBuilder/scripts/app_build_1000.vdf\n"
            "  python scripts/check_steam_build.py build/manifest.vdf --json --strict\n\n"
            "exit codes: 0 no errors, 1 errors (or warnings with --strict),\n"
            "            2 usage problem, file missing, or not an AppBuild script"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("app_build_vdf", metavar="APP_BUILD_VDF", help="path to the app build script")
    parser.add_argument("--json", action="store_true", help="print one JSON object instead of text")
    parser.add_argument("--strict", action="store_true", help="exit 1 on warnings too")
    parser.add_argument("--max-issues", type=int, default=50, metavar="N",
                        help="print at most N issues (default 50, 0 = no limit)")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.max_issues < 0:
        parser.error("--max-issues must be 0 or more")
    target = Path(args.app_build_vdf)
    if not target.is_file():
        print(f"check_steam_build: {target}: file not found", file=sys.stderr)
        return 2
    checker = Checker(target)
    try:
        checker.run()
    except UsageProblem as exc:
        print(f"check_steam_build: {exc}", file=sys.stderr)
        return 2
    print(render_json(checker, args.max_issues) if args.json else render_text(checker, args.max_issues))
    errors, warnings = ordered_issues(checker.issues)
    if errors or (args.strict and warnings):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
