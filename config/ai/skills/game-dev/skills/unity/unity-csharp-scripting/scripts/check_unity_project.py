#!/usr/bin/env python3
"""Check a Unity 6 project for broken .meta files and missing script references.

Run it after creating, moving, renaming or deleting files outside the Unity
Editor. Unity has not imported those changes yet, so this looks for the edits
that will break the project on the next import:

ERRORS (the project will really break)
  duplicate-guid       Two .meta files share a GUID (usually a copied .meta).
  moved-without-meta   A .meta was left behind while its asset moved or was
                       renamed. Unity would give the asset a new GUID and every
                       reference to it would break ("Missing script").
  malformed-meta       A .meta has no valid 32-hex-digit `guid:` line.
  missing-script       A text-serialized scene/prefab/asset has an
                       `m_Script: {fileID: 11500000, guid: X, type: 3}` reference
                       and no .meta in Assets/, Packages/ or the package cache
                       has GUID X. Reported as a warning instead when some
                       packages could not be read (for example when
                       Library/PackageCache does not exist yet).

WARNINGS
  missing-meta         An asset or folder has no .meta yet. This is normal for
                       a new file: Unity creates the .meta on the next import.
                       It does not make --strict fail.
  orphan-meta          A .meta whose asset or folder is gone.
  meta-name-case       A .meta matches its asset only when case is ignored.
  class-name-mismatch  A file declares a MonoBehaviour/ScriptableObject subclass
                       whose name differs from the file name, so Unity cannot
                       attach it.

Only Assets/ and the embedded packages in Packages/ are checked. Library/,
Temp/, Logs/ and similar folders are never walked, except that .meta GUIDs are
read from Library/PackageCache and from local `file:` packages so their scripts
count as present. Files Unity ignores during import (names starting with `.`
outside Assets/StreamingAssets, names ending with `~`, files and folders named
`cvs`, `.tmp` files, hidden folders) are skipped. Binary-serialized files (not
starting with `%YAML`) are skipped.

Standard library only. Read-only: nothing is ever written.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import stat
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable

TOOL = "check_unity_project"
SCHEMA = 1

# Text-serialized Unity files that can hold MonoBehaviour/ScriptableObject
# documents with an m_Script reference.
YAML_EXTENSIONS = frozenset({".unity", ".prefab", ".asset", ".controller", ".playable"})

# fileID Unity uses for the MonoScript inside a .cs script asset. Scripts that
# live in DLLs use other fileIDs, which are not checked.
MONO_SCRIPT_FILE_ID = "11500000"

# Built-in resources use GUIDs such as 0000000000000000e000000000000000 and
# 0000000000000000f000000000000000; they have no .meta in the project.
BUILTIN_GUID_PREFIX = "0" * 16

GUID_LINE_RE = re.compile(r"^guid:\s*(\S*)\s*$")
GUID_RE = re.compile(r"^[0-9a-fA-F]{32}$")
FOLDER_LINE_RE = re.compile(r"^folderAsset:\s*yes\s*$")
YAML_DOC_RE = re.compile(r"^--- !u!(\d+) &(-?\d+)")
YAML_NAME_RE = re.compile(r"^  m_Name:\s*(.*?)\s*$")
YAML_GAMEOBJECT_RE = re.compile(r"^  m_GameObject:\s*\{\s*fileID:\s*(-?\d+)")
YAML_SCRIPT_RE = re.compile(
    r"m_Script:\s*\{\s*fileID:\s*(-?\d+)\s*,\s*guid:\s*([0-9a-fA-F]{32})\s*,\s*type:\s*(\d+)\s*\}"
)
YAML_ANY_GUID_RE = re.compile(r"guid:\s*([0-9a-fA-F]{32})")
# Text assets can hold single lines of hundreds of MB (mesh or terrain data);
# they are read in pieces of this size so memory stays flat.
YAML_CHUNK_BYTES = 64 * 1024

# C# comments and string/char literals, removed before looking for classes.
CS_NOISE_RE = re.compile(
    r"//[^\n]*"
    r"|/\*.*?\*/"
    r"|@\"(?:[^\"]|\"\")*\""
    r"|\$?\"(?:\\.|[^\"\\\n])*\""
    r"|'(?:\\.|[^'\\\n])*'",
    re.S,
)
CS_CLASS_RE = re.compile(
    r"(?P<mods>(?:\b(?:public|internal|private|protected|sealed|abstract|static|partial|unsafe|new|file)\s+)*)"
    r"\bclass\s+@?(?P<name>[A-Za-z_]\w*)\s*(?P<generic><[^>{]*>)?\s*:\s*"
    r"(?:global::)?(?:UnityEngine\s*\.\s*)?(?P<base>MonoBehaviour|ScriptableObject)\b"
)
CS_BRACE_RE = re.compile(r"\bnamespace\s+[\w.]+\s*\{|\{|\}")
CS_MAX_BYTES = 2 * 1024 * 1024

WINDOWS_HIDDEN = getattr(stat, "FILE_ATTRIBUTE_HIDDEN", 2)


@dataclass
class Issue:
    level: str  # "error" or "warning"
    code: str
    file: str
    line: int | None
    message: str
    fix: str

    def as_json(self) -> dict:
        return {"code": self.code, "file": self.file, "line": self.line, "message": self.message, "fix": self.fix}


@dataclass
class Meta:
    rel: str  # posix path of the .meta, relative to the project root
    dir_rel: str
    asset_name: str
    guid: str | None
    guid_line: int | None
    is_folder: bool
    problem: str | None = None  # set when the .meta is malformed


@dataclass
class Missing:
    """An asset or folder that has no .meta next to it."""

    rel: str
    dir_rel: str
    name: str
    is_dir: bool
    reportable: bool  # False when it sits inside a folder that is itself new
    files_inside: int = 0
    paired: bool = False


@dataclass
class Scan:
    root: Path
    files_checked: int = 0
    metas: list[Meta] = field(default_factory=list)
    orphans: list[tuple[Meta, bool]] = field(default_factory=list)  # (meta, asset exists but is hidden)
    missing: list[Missing] = field(default_factory=list)
    yaml_files: list[Path] = field(default_factory=list)
    cs_files: list[Path] = field(default_factory=list)
    issues: list[Issue] = field(default_factory=list)

    def rel(self, path: Path) -> str:
        try:
            return path.relative_to(self.root).as_posix()
        except ValueError:
            return Path(os.path.relpath(path, self.root)).as_posix()

    def add(self, level: str, code: str, file: str, line: int | None, message: str, fix: str) -> None:
        self.issues.append(Issue(level, code, file, line, message, fix))


# ---------------------------------------------------------------- file walking


def is_hidden(entry: os.DirEntry, in_streaming_assets: bool) -> bool:
    """Apply Unity's import rules for files and folders it ignores."""
    name = entry.name
    try:
        is_dir = entry.is_dir()
    except OSError:
        return True
    if name.endswith("~") or name.lower() == "cvs":
        return True
    if name.startswith(".") and not in_streaming_assets:
        return True
    if not is_dir and name.lower().endswith(".tmp"):
        return True
    if is_dir and os.name == "nt":
        try:
            if entry.stat().st_file_attributes & WINDOWS_HIDDEN:  # type: ignore[attr-defined]
                return True
        except (OSError, AttributeError):
            pass
    return False


def list_dir(path: Path, in_streaming_assets: bool) -> tuple[list[str], list[str], set[str]]:
    """Return (visible files, visible folders, every name on disk), sorted."""
    files: list[str] = []
    dirs: list[str] = []
    every: set[str] = set()
    try:
        entries = list(os.scandir(path))
    except OSError:
        return files, dirs, every
    for entry in entries:
        every.add(entry.name)
        if is_hidden(entry, in_streaming_assets):
            continue
        try:
            if entry.is_dir():
                dirs.append(entry.name)
            elif entry.is_file():
                files.append(entry.name)
        except OSError:
            continue
    return sorted(files), sorted(dirs), every


def first_visit(folder: Path, seen: set[str]) -> bool:
    try:
        key = os.path.realpath(folder)
    except OSError:
        return False
    if key in seen:
        return False
    seen.add(key)
    return True


def read_meta(path: Path) -> tuple[str | None, int | None, bool, str | None]:
    """Return (guid, guid line, is folder, problem) for one .meta file."""
    guid = None
    guid_line = None
    is_folder = False
    problem = None
    try:
        with path.open("r", encoding="utf-8-sig", errors="replace") as handle:
            for number, raw in enumerate(handle, start=1):
                line = raw.rstrip("\r\n")
                if guid is None:
                    match = GUID_LINE_RE.match(line)
                    if match:
                        guid_line = number
                        value = match.group(1)
                        if not GUID_RE.match(value) or set(value) == {"0"}:
                            problem = f"invalid guid '{value}' (expected 32 hex digits)"
                        else:
                            guid = value.lower()
                if FOLDER_LINE_RE.match(line):
                    is_folder = True
                # The header (fileFormatVersion, guid, folderAsset) is at the top.
                if guid_line is not None and number >= 4:
                    break
                if number >= 40 and guid_line is None:
                    break
    except OSError as exc:
        return None, None, False, f"could not be read ({exc.strerror or exc})"
    if guid_line is None:
        problem = "has no 'guid:' line"
    return guid, guid_line, is_folder, problem


def walk_linted(scan: Scan, top: Path) -> None:
    """Walk Assets/ or one embedded package and record metas and assets."""
    streaming_root = (scan.root / "Assets" / "StreamingAssets").as_posix()
    # Stack of (folder, top-most new folder above it, or None).
    stack: list[tuple[Path, Missing | None]] = [(top, None)]
    seen: set[str] = set()
    while stack:
        folder, new_parent = stack.pop()
        if not first_visit(folder, seen):
            continue  # a symlink loop
        folder_posix = folder.as_posix()
        in_streaming = folder_posix == streaming_root or folder_posix.startswith(streaming_root + "/")
        files, dirs, every = list_dir(folder, in_streaming)
        dir_rel = scan.rel(folder)
        scan.files_checked += len(files)
        if new_parent is not None:
            new_parent.files_inside += sum(1 for name in files if not name.endswith(".meta"))

        metas = {name[: -len(".meta")]: name for name in files if name.endswith(".meta") and len(name) > 5}
        assets = [(name, False) for name in files if not name.endswith(".meta")] + [(name, True) for name in dirs]
        asset_names = {name for name, _ in assets}

        missing_here: dict[str, Missing] = {}
        for name, is_dir in assets:
            if name in metas:
                continue
            item = Missing(
                rel=f"{dir_rel}/{name}",
                dir_rel=dir_rel,
                name=name,
                is_dir=is_dir,
                reportable=new_parent is None,
            )
            missing_here[name] = item
            scan.missing.append(item)

        lowered_missing = {name.lower(): item for name, item in missing_here.items()}
        for asset_name, meta_name in metas.items():
            guid, guid_line, is_folder, problem = read_meta(folder / meta_name)
            meta = Meta(
                rel=f"{dir_rel}/{meta_name}",
                dir_rel=dir_rel,
                asset_name=asset_name,
                guid=guid,
                guid_line=guid_line,
                is_folder=is_folder,
                problem=problem,
            )
            scan.metas.append(meta)
            if asset_name in asset_names:
                continue
            case_match = lowered_missing.get(asset_name.lower())
            if case_match is not None and not case_match.paired:
                case_match.paired = True
                scan.add(
                    "warning",
                    "meta-name-case",
                    meta.rel,
                    None,
                    f"'{meta_name}' only matches '{case_match.name}' when case is ignored; "
                    "this works on Windows and macOS but the asset loses its GUID on case-sensitive file systems",
                    f"rename '{meta_name}' to '{case_match.name}.meta'",
                )
                continue
            scan.orphans.append((meta, asset_name in every))

        for name, path_name in ((n, folder / n) for n in files):
            suffix = Path(name).suffix.lower()
            if suffix in YAML_EXTENSIONS:
                scan.yaml_files.append(path_name)
            elif suffix == ".cs":
                scan.cs_files.append(path_name)

        for name in reversed(dirs):
            child_new = new_parent
            if child_new is None and name in missing_here:
                child_new = missing_here[name]
            stack.append((folder / name, child_new))


def collect_external_guids(path: Path, into: dict[str, str], root: Path) -> None:
    """Read GUIDs from a package that is not checked itself (cache or local folder)."""
    stack = [path]
    seen: set[str] = set()
    while stack:
        folder = stack.pop()
        if not first_visit(folder, seen):
            continue
        files, dirs, _ = list_dir(folder, False)
        for name in files:
            if name.endswith(".meta"):
                guid, _, _, _ = read_meta(folder / name)
                if guid and guid not in into:
                    meta_path = folder / name
                    try:
                        into[guid] = meta_path.relative_to(root).as_posix()
                    except ValueError:
                        into[guid] = Path(os.path.relpath(meta_path, root)).as_posix()
        stack.extend(folder / name for name in dirs)


# ------------------------------------------------------------------- packages


def load_json(path: Path) -> dict | None:
    try:
        with path.open("r", encoding="utf-8-sig") as handle:
            data = json.load(handle)
    except (OSError, ValueError):
        return None
    return data if isinstance(data, dict) else None


@dataclass
class Packages:
    embedded: dict[str, Path] = field(default_factory=dict)  # package name -> folder in Packages/
    external_guids: dict[str, str] = field(default_factory=dict)  # guid -> .meta path
    unscanned: list[str] = field(default_factory=list)
    note: str = ""


def find_packages(root: Path) -> Packages:
    result = Packages()
    packages_dir = root / "Packages"
    if packages_dir.is_dir():
        _, dirs, _ = list_dir(packages_dir, False)
        for name in dirs:
            package_json = packages_dir / name / "package.json"
            if package_json.is_file():
                data = load_json(package_json) or {}
                package_name = data.get("name") if isinstance(data.get("name"), str) else name
                result.embedded[package_name] = packages_dir / name

    manifest = load_json(packages_dir / "manifest.json")
    lock = load_json(packages_dir / "packages-lock.json")
    wanted: dict[str, str] = {}  # package name -> version or file: reference
    if lock and isinstance(lock.get("dependencies"), dict):
        for name, info in lock["dependencies"].items():
            if isinstance(info, dict):
                version = str(info.get("version", ""))
                if info.get("source") == "embedded":
                    version = "embedded"
                wanted[name] = version
    if manifest and isinstance(manifest.get("dependencies"), dict):
        for name, version in manifest["dependencies"].items():
            wanted.setdefault(name, str(version))
    if manifest is None:
        result.note = "Packages/manifest.json is missing or unreadable, so package scripts could not be checked"

    cache_dir = root / "Library" / "PackageCache"
    cache_by_name: dict[str, list[Path]] = {}
    if cache_dir.is_dir():
        _, dirs, _ = list_dir(cache_dir, False)
        for name in dirs:
            cache_by_name.setdefault(name.split("@", 1)[0], []).append(cache_dir / name)

    local_dirs: dict[str, Path] = {}
    for name, version in sorted(wanted.items()):
        if name.startswith("com.unity.modules."):
            continue  # built-in engine modules ship no script assets
        if name in result.embedded or version == "embedded":
            if name not in result.embedded:
                result.unscanned.append(name)
            continue
        if version.startswith("file:"):
            target = Path(version[len("file:"):])
            if not target.is_absolute():
                target = packages_dir / target
            if target.is_dir() and (target / "package.json").is_file():
                local_dirs[name] = target
                continue
            # A file: tarball (.tgz) is unpacked into Library/PackageCache.
        if name not in cache_by_name:
            result.unscanned.append(name)

    for name, folders in sorted(cache_by_name.items()):
        if name in result.embedded or name in local_dirs:
            continue  # a stale cache copy of an embedded or local package
        for folder in folders:
            collect_external_guids(folder, result.external_guids, root)
    embedded_dirs = {os.path.realpath(folder) for folder in result.embedded.values()}
    for name, folder in sorted(local_dirs.items()):
        if os.path.realpath(folder) in embedded_dirs:
            continue  # already checked as an embedded package
        collect_external_guids(folder, result.external_guids, root)

    if result.unscanned and not result.note:
        shown = ", ".join(result.unscanned[:5]) + (", ..." if len(result.unscanned) > 5 else "")
        where = "Library/PackageCache is missing" if not cache_dir.is_dir() else "they are not in Library/PackageCache"
        result.note = f"could not read packages {shown} ({where})"
    return result


# --------------------------------------------------------------------- checks


def check_metas(scan: Scan, packages: Packages) -> tuple[set[str], dict[str, str]]:
    """Report malformed, duplicate, orphaned and moved metas.

    Returns (GUIDs whose asset exists, orphan GUID -> orphan .meta path).
    """
    live: dict[str, list[Meta]] = {}
    orphan_metas = {meta.rel for meta, _ in scan.orphans}
    for meta in scan.metas:
        if meta.problem:
            scan.add(
                "error",
                "malformed-meta",
                meta.rel,
                meta.guid_line,
                f"'{Path(meta.rel).name}' {meta.problem}",
                "restore this .meta from version control; if there is no good copy, delete it and Unity "
                "creates a new one (references to the old GUID stay broken)",
            )
            continue
        if meta.rel not in orphan_metas and meta.guid:
            live.setdefault(meta.guid, []).append(meta)

    for guid, group in sorted(live.items()):
        group.sort(key=lambda m: m.rel)
        first = group[0]
        for other in group[1:]:
            scan.add(
                "error",
                "duplicate-guid",
                other.rel,
                other.guid_line,
                f"GUID {guid} is also used by '{first.rel}'; one of the two .meta files is a copy",
                "delete the .meta of the asset that is the copy (keep the original's) so Unity gives the copy "
                "a new GUID on import",
            )
        external = packages.external_guids.get(guid)
        if external:
            scan.add(
                "error",
                "duplicate-guid",
                first.rel,
                first.guid_line,
                f"GUID {guid} is also used by package file '{external}'",
                "this .meta was copied from the package; delete it so Unity gives the asset a new GUID",
            )

    by_dir: dict[str, list[Missing]] = {}
    by_name: dict[str, list[Missing]] = {}
    for item in scan.missing:
        if item.paired:
            continue
        by_dir.setdefault(item.dir_rel, []).append(item)
        by_name.setdefault(item.name, []).append(item)

    orphan_guids: dict[str, str] = {}
    for meta, asset_hidden in scan.orphans:
        if meta.problem:
            continue
        if meta.guid:
            orphan_guids.setdefault(meta.guid, meta.rel)
        asset_rel = f"{meta.dir_rel}/{meta.asset_name}"
        if asset_hidden:
            scan.add(
                "warning",
                "orphan-meta",
                meta.rel,
                None,
                f"'{meta.asset_name}' exists but Unity ignores it (hidden name), so this .meta is unused",
                "delete this .meta, or rename the asset so Unity imports it",
            )
            continue

        candidates = [
            item
            for item in by_dir.get(meta.dir_rel, [])
            if item.is_dir == meta.is_folder
            and (item.is_dir or Path(item.name).suffix.lower() == Path(meta.asset_name).suffix.lower())
        ]
        candidates += [
            item
            for item in by_name.get(meta.asset_name, [])
            if item.dir_rel != meta.dir_rel and item.is_dir == meta.is_folder
        ]
        kind = "folder" if meta.is_folder else "asset"
        if len(candidates) == 1:
            target = candidates[0]
            target.paired = True
            scan.add(
                "error",
                "moved-without-meta",
                target.rel,
                None,
                f"'{target.rel}' has no .meta, and '{meta.rel}' (GUID {meta.guid}) was left behind; "
                f"this {kind} looks moved or renamed without its .meta, so Unity would give it a new GUID "
                "and break every reference to it",
                f"move '{meta.rel}' to '{target.rel}.meta' (do not create a new .meta)",
            )
            continue
        if candidates:
            names = ", ".join(f"'{item.rel}'" for item in candidates[:3])
            more = f" and {len(candidates) - 3} more" if len(candidates) > 3 else ""
            scan.add(
                "error",
                "moved-without-meta",
                meta.rel,
                None,
                f"'{meta.rel}' (GUID {meta.guid}) has lost its {kind}, and {names}{more} have no .meta; "
                "one of them looks moved or renamed without this .meta",
                "move this .meta next to the file it belongs to and rename it to '<file name>.meta'; "
                "if the old asset was deleted on purpose, delete this .meta",
            )
            continue

        twin = live.get(meta.guid or "")
        if twin:
            scan.add(
                "warning",
                "orphan-meta",
                meta.rel,
                None,
                f"'{meta.asset_name}' is gone and GUID {meta.guid} already belongs to '{twin[0].rel}'",
                "delete this leftover .meta",
            )
        elif meta.is_folder:
            scan.add(
                "warning",
                "orphan-meta",
                meta.rel,
                None,
                f"folder '{asset_rel}' is gone but its .meta remains; Unity will recreate the folder empty",
                "if you deleted the folder on purpose, delete this .meta too; if you moved or renamed it, "
                "move this .meta next to the folder and rename it to match",
            )
        else:
            scan.add(
                "warning",
                "orphan-meta",
                meta.rel,
                None,
                f"asset '{asset_rel}' is gone but its .meta remains (GUID {meta.guid}); "
                "Unity deletes it on the next import",
                "if you deleted the asset on purpose, delete this .meta too; if you moved or renamed it, "
                "move this .meta next to the asset and rename it to match",
            )

    for item in scan.missing:
        if item.paired or not item.reportable:
            continue
        if item.is_dir:
            count = item.files_inside
            inside = f" ({count} file{'' if count == 1 else 's'} inside)" if count else ""
            scan.add(
                "warning",
                "missing-meta",
                item.rel,
                None,
                f"folder has no .meta yet{inside}; this is normal for a new folder, "
                "Unity creates the .meta files on the next import",
                "nothing to do for a new folder; if it was moved or renamed, move its old .meta next to it instead",
            )
        else:
            scan.add(
                "warning",
                "missing-meta",
                item.rel,
                None,
                "no .meta yet; this is normal for a new file, Unity creates it on the next import",
                "nothing to do for a new file; if it was moved or renamed, move its old .meta next to it instead",
            )

    return set(live), orphan_guids


def is_yaml(path: Path) -> bool:
    try:
        with path.open("rb") as handle:
            head = handle.read(8)
    except OSError:
        return False
    if head.startswith(b"\xef\xbb\xbf"):
        head = head[3:]
    return head.startswith(b"%YAML")


def check_scripts(scan: Scan, known: set[str], orphan_guids: dict[str, str], packages: Packages) -> None:
    """Report m_Script references to MonoScript GUIDs that no .meta provides."""
    for path in scan.yaml_files:
        if not is_yaml(path):
            continue  # binary serialization
        rel = scan.rel(path)
        names: dict[str, str] = {}  # GameObject fileID -> m_Name
        found: dict[str, list] = {}  # guid -> [first line, count, set of GameObject ids]
        doc_class = ""
        doc_id = ""
        doc_gameobject = ""
        try:
            with path.open("rb") as handle:
                number = 0
                at_line_start = True
                while True:
                    chunk = handle.readline(YAML_CHUNK_BYTES)
                    if not chunk:
                        break
                    starts_line = at_line_start
                    at_line_start = chunk.endswith(b"\n")
                    if not starts_line:
                        continue  # the rest of a very long line, such as a mesh data blob
                    number += 1
                    raw = chunk.decode("utf-8", errors="replace")
                    if number == 1:
                        raw = raw.lstrip("\ufeff")
                    if raw.startswith("---"):
                        header = YAML_DOC_RE.match(raw)
                        doc_class, doc_id = (header.group(1), header.group(2)) if header else ("", "")
                        doc_gameobject = ""
                        continue
                    if doc_class == "1":
                        match = YAML_NAME_RE.match(raw.rstrip("\r\n"))
                        if match:
                            names[doc_id] = match.group(1).strip("'\"")
                        continue
                    if "m_GameObject:" in raw:
                        match = YAML_GAMEOBJECT_RE.match(raw)
                        if match:
                            doc_gameobject = match.group(1)
                        continue
                    if "m_Script:" not in raw:
                        continue
                    match = YAML_SCRIPT_RE.search(raw)
                    if not match:
                        continue
                    file_id, guid, ref_type = match.group(1), match.group(2).lower(), match.group(3)
                    if file_id != MONO_SCRIPT_FILE_ID or ref_type != "3":
                        continue
                    if guid.startswith(BUILTIN_GUID_PREFIX) or guid in known:
                        continue
                    entry = found.setdefault(guid, [number, 0, set()])
                    entry[1] += 1
                    if doc_gameobject and doc_gameobject != "0":
                        entry[2].add(doc_gameobject)
        except OSError:
            continue

        for guid, (line, count, objects) in found.items():
            owners = {names[o] for o in objects if o in names}
            where = ""
            if owners:
                shown = ", ".join(f"'{n}'" for n in sorted(owners)[:3])
                where = f" on {shown}"
            times = f" ({count} components)" if count > 1 else ""
            message = f"script reference{where}{times} points to GUID {guid}, which no .meta in the project has"
            orphan = orphan_guids.get(guid)
            if orphan:
                message += f"; its .meta '{orphan}' is left over while the script file is gone"
            fix = (
                f"if the .cs file was moved or renamed, put its original .meta (guid: {guid}) back next to it; "
                "otherwise restore the script, or remove the missing component in the Unity Editor"
            )
            if packages.note:
                scan.add(
                    "warning",
                    "missing-script",
                    rel,
                    line,
                    f"{message} (unconfirmed: {packages.note})",
                    "open the project in Unity once so the packages are downloaded, then run this again; " + fix,
                )
            else:
                scan.add("error", "missing-script", rel, line, message, fix)


def strip_cs_noise(text: str) -> str:
    """Blank out comments and string literals, keeping line numbers."""
    return CS_NOISE_RE.sub(lambda m: "\n" * m.group(0).count("\n") + " ", text)


def top_level_positions(code: str) -> Callable[[int], bool]:
    """Return a function telling whether an offset is outside every class body."""
    events: list[tuple[int, str]] = []
    for match in CS_BRACE_RE.finditer(code):
        token = match.group(0)
        events.append((match.start(), "ns" if token.startswith("namespace") else token))

    def is_top_level(offset: int) -> bool:
        stack: list[str] = []
        for position, token in events:
            if position >= offset:
                break
            if token == "}":
                if stack:
                    stack.pop()
            else:
                stack.append(token)
        return all(item == "ns" for item in stack)

    return is_top_level


def check_class_names(scan: Scan) -> None:
    """Warn when a MonoBehaviour/ScriptableObject class does not match its file name."""
    for path in scan.cs_files:
        try:
            if path.stat().st_size > CS_MAX_BYTES:
                continue
            text = path.read_text(encoding="utf-8-sig", errors="replace")
        except OSError:
            continue
        code = strip_cs_noise(text.replace("\r\n", "\n"))
        stem = path.stem
        is_top_level = top_level_positions(code)
        candidates = []
        matched = False
        for match in CS_CLASS_RE.finditer(code):
            if not is_top_level(match.start("name")):
                continue
            if match.group("name") == stem:
                matched = True
                break
            mods = match.group("mods").split()
            if "abstract" in mods or "partial" in mods or "static" in mods or match.group("generic"):
                continue  # cannot be attached, or may be split across files
            candidates.append(match)
        if matched or not candidates:
            continue
        match = candidates[0]
        name, base = match.group("name"), match.group("base")
        line = code.count("\n", 0, match.start("name")) + 1
        scan.add(
            "warning",
            "class-name-mismatch",
            scan.rel(path),
            line,
            f"class '{name}' derives from {base} but the file is '{path.name}'; "
            "Unity only links the script to a class with the same name as the file",
            f"rename the file to '{name}.cs' (and its .meta to '{name}.cs.meta'), or rename the class to '{stem}'",
        )


# ------------------------------------------------------------------------ CLI


def find_project_root(start: Path) -> Path | None:
    for candidate in (start, *start.parents):
        if (candidate / "Assets").is_dir() and (candidate / "ProjectSettings").is_dir():
            return candidate
    return None


def run(root: Path) -> Scan:
    scan = Scan(root=root)
    packages = find_packages(root)
    walk_linted(scan, root / "Assets")
    for folder in sorted(packages.embedded.values()):
        walk_linted(scan, folder)
    known, orphan_guids = check_metas(scan, packages)
    known |= set(packages.external_guids)
    check_scripts(scan, known, orphan_guids, packages)
    check_class_names(scan)
    return scan


def sort_key(issue: Issue) -> tuple:
    return (0 if issue.level == "error" else 1, issue.file, issue.line or 0, issue.code)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="check_unity_project.py",
        description=(
            "Read-only check of a Unity 6 project for .meta mistakes made outside the Editor:\n"
            "duplicate or malformed GUIDs, assets moved or renamed without their .meta, leftover\n"
            ".meta files, missing script references in text scenes/prefabs/assets, and\n"
            "MonoBehaviour/ScriptableObject classes whose name differs from the file name."
        ),
        epilog=(
            "example:\n"
            "  python scripts/check_unity_project.py path/to/MyGame\n"
            "  python scripts/check_unity_project.py . --json --max-issues 200\n\n"
            "exit codes: 0 no errors (warnings allowed), 1 errors found (or warnings with --strict),\n"
            "            2 usage problem or not a Unity project"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "project_dir",
        nargs="?",
        default=".",
        metavar="PROJECT_DIR",
        help="Unity project folder (the one holding Assets/ and ProjectSettings/), or any folder inside it. "
        "Default: current folder.",
    )
    parser.add_argument("--json", action="store_true", help="print one JSON object instead of text")
    parser.add_argument(
        "--strict",
        action="store_true",
        help="exit 1 when there are warnings too (a new file's missing .meta does not count)",
    )
    parser.add_argument(
        "--max-issues",
        type=int,
        default=50,
        metavar="N",
        help="print at most N issues, errors first (default: 50; 0 = no limit)",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(errors="replace")  # non-ASCII paths on a legacy Windows console
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.max_issues < 0:
        parser.error("--max-issues must be 0 or more")

    start = Path(args.project_dir).expanduser()
    if not start.is_dir():
        print(f"error: '{args.project_dir}' is not a folder", file=sys.stderr)
        return 2
    root = find_project_root(start.resolve())
    if root is None:
        print(
            f"error: '{args.project_dir}' is not inside a Unity project "
            "(no folder with both Assets/ and ProjectSettings/ found)",
            file=sys.stderr,
        )
        return 2

    scan = run(root)
    issues = sorted(scan.issues, key=sort_key)
    errors = [i for i in issues if i.level == "error"]
    warnings = [i for i in issues if i.level == "warning"]
    limit = args.max_issues or len(issues)
    shown = issues[:limit]
    truncated = len(shown) < len(issues)

    if args.json:
        payload = {
            "tool": TOOL,
            "schema": SCHEMA,
            "root": root.as_posix(),
            "files_checked": scan.files_checked,
            "error_count": len(errors),
            "warning_count": len(warnings),
            "errors": [i.as_json() for i in shown if i.level == "error"],
            "warnings": [i.as_json() for i in shown if i.level == "warning"],
            "truncated": truncated,
        }
        print(json.dumps(payload, indent=2))
    else:
        for issue in shown:
            location = f"{issue.file}:{issue.line}" if issue.line else issue.file
            print(f"{issue.level.upper()} {location}: {issue.message}")
            print(f"  fix: {issue.fix}")
        if truncated:
            print(f"... and {len(issues) - len(shown)} more")
        print(f"Summary: {len(errors)} errors, {len(warnings)} warnings in {scan.files_checked} files checked")

    # A new file's missing .meta needs no action (Unity creates it), so it never fails --strict.
    if errors or (args.strict and any(w.code != "missing-meta" for w in warnings)):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
