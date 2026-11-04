#!/usr/bin/env python3
"""Assemble a macOS .app bundle from Ebitengine (Go) binaries.

Builds Name.app/Contents/{Info.plist, MacOS/<exe>, Resources/<icon>.icns}.
With both --amd64 and --arm64 the binaries are merged into one universal
binary with `lipo` (macOS) or `llvm-lipo` (Linux, from LLVM). With one
binary the app supports only that architecture.

This script does not sign or notarise. On a Mac, after it runs:
  codesign --force --options runtime --timestamp --sign "Developer ID Application: ..." Name.app
  then notarise (xcrun notarytool or github.com/hajimehoshi/notarize), staple,
  and zip with `ditto -c -k --keepParent Name.app name_darwin.zip`.

Build the inputs first, for example:
  CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -trimpath -o build/game_amd64 .
  CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -trimpath -o build/game_arm64 .

Exit codes: 0 success, 1 tool failure, 2 bad arguments or inputs.
"""

from __future__ import annotations

import argparse
import plistlib
import re
import shutil
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

MACHO_CPUS = {"amd64": 0x01000007, "arm64": 0x0100000C}


def fail(msg: str, code: int = 2) -> None:
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(code)


def find_lipo() -> str | None:
    for name in ("lipo", "llvm-lipo"):
        if shutil.which(name):
            return shutil.which(name)
    for p in sorted(Path("/usr/bin").glob("llvm-lipo-*"), reverse=True):
        return str(p)
    return None


def check_macho(path: Path, arch: str) -> tuple[int, int, int] | None:
    if not path.is_file():
        fail(f"{path}: not a file")
    with path.open("rb") as f:
        header = f.read(32)
        if len(header) != 32 or header[:4] != b"\xcf\xfa\xed\xfe":
            fail(f"{path}: not a thin 64-bit Mach-O binary (build with GOOS=darwin GOARCH={arch})")
        _, cpu, _, filetype, count, size, _, _ = struct.unpack("<8I", header)
        if cpu != MACHO_CPUS[arch] or filetype != 2:  # MH_EXECUTE
            fail(f"{path}: expected a darwin/{arch} executable")
        if size > path.stat().st_size - 32:
            fail(f"{path}: truncated Mach-O load commands")
        commands = f.read(size)
    offset, minimum = 0, None
    for _ in range(count):
        if offset+8 > len(commands):
            fail(f"{path}: truncated Mach-O load command")
        cmd, length = struct.unpack_from("<2I", commands, offset)
        if length < 8 or offset+length > len(commands):
            fail(f"{path}: invalid Mach-O load command size")
        if cmd == 0x32 and length >= 24:  # LC_BUILD_VERSION
            platform, version = struct.unpack_from("<2I", commands, offset+8)
            if platform != 1:  # PLATFORM_MACOS
                fail(f"{path}: build platform is not macOS")
            minimum = (version >> 16, (version >> 8) & 255, version & 255)
        elif cmd == 0x24 and length >= 16:  # LC_VERSION_MIN_MACOSX
            version = struct.unpack_from("<I", commands, offset+8)[0]
            minimum = (version >> 16, (version >> 8) & 255, version & 255)
        offset += length
    return minimum


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("--name", required=True, help="display name, e.g. 'Coin Run' (Coin Run.app)")
    ap.add_argument("--exe", help="executable name inside the bundle (default: name without spaces, lower case)")
    ap.add_argument("--bundle-id", required=True, help="reverse-DNS identifier, e.g. com.example.coinrun")
    ap.add_argument("--version", default="1.0.0", help="CFBundleShortVersionString (default 1.0.0)")
    ap.add_argument("--build", help="CFBundleVersion (default: same as --version)")
    ap.add_argument("--amd64", type=Path, help="darwin/amd64 binary")
    ap.add_argument("--arm64", type=Path, help="darwin/arm64 binary")
    ap.add_argument("--icon", type=Path, help=".icns file (optional)")
    ap.add_argument("--min-macos", help="LSMinimumSystemVersion (default: highest deployment target in the input binaries)")
    ap.add_argument("--out", type=Path, default=Path("build"), help="output directory (default: build)")
    ap.add_argument("--force", action="store_true", help="replace an existing bundle")
    args = ap.parse_args()

    if not args.amd64 and not args.arm64:
        fail("give --amd64, --arm64 or both")
    if (not args.name.strip() or args.name in (".", "..")
            or any(c in args.name for c in "/\\")
            or any(ord(c) < 32 or ord(c) == 127 for c in args.name)):
        fail("--name must be a nonempty file name without path separators or control characters")
    if not re.fullmatch(r"[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+", args.bundle_id):
        fail(f"--bundle-id {args.bundle_id!r} is not reverse-DNS (letters, digits, hyphens, dots)")
    if not re.fullmatch(r"\d+(\.\d+){0,2}", args.version):
        fail(f"--version {args.version!r} must be like 1.2.3")
    if args.build and not re.fullmatch(r"\d+(\.\d+){0,2}", args.build):
        fail(f"--build {args.build!r} must be numeric, like 42 or 1.2.3")
    if args.min_macos and not re.fullmatch(r"\d+(\.\d+){1,2}", args.min_macos):
        fail(f"--min-macos {args.min_macos!r} must be like 12.0")
    exe = args.exe or re.sub(r"[^A-Za-z0-9_-]", "", args.name).lower()
    if not re.fullmatch(r"[A-Za-z0-9_-]+", exe):
        fail("--exe must contain only letters, digits, underscores and hyphens")
    bins = [p for p in (args.amd64, args.arm64) if p]
    minimums = []
    for arch in ("amd64", "arm64"):
        if b := getattr(args, arch):
            if minimum := check_macho(b, arch):
                minimums.append(minimum)
    if args.min_macos:
        chosen = tuple(map(int, args.min_macos.split(".")))
        chosen += (0,) * (3-len(chosen))
        if minimums and chosen < max(minimums):
            fail("--min-macos is below the deployment target required by an input binary")
    elif len(minimums) == len(bins):
        args.min_macos = ".".join(map(str, max(minimums)))
    else:
        fail("cannot determine minimum macOS from an input; pass --min-macos explicitly")
    if args.icon and (not args.icon.is_file() or args.icon.suffix != ".icns"):
        fail(f"--icon {args.icon} must be an existing .icns file")

    app = args.out / f"{args.name}.app"
    if app.is_symlink():
        fail(f"{app} is a symlink; choose another output path")
    if app.exists():
        if not args.force:
            fail(f"{app} exists; pass --force to replace it")
        if not app.is_dir():
            fail(f"{app} exists and is not a directory")
    lipo = find_lipo() if len(bins) == 2 else None
    if len(bins) == 2 and not lipo:
        fail("lipo or llvm-lipo not found (install Xcode command line tools or LLVM)", 1)
    args.out.mkdir(parents=True, exist_ok=True)
    # Build away from the final name: a failed lipo must preserve a previous app.
    with tempfile.TemporaryDirectory(prefix=".macos-app-", dir=args.out) as tmp:
        staged = Path(tmp) / app.name
        assemble(args, bins, exe, staged, lipo)
        if app.exists():
            shutil.rmtree(app)
        staged.rename(app)

    archs = "universal (amd64+arm64)" if len(bins) == 2 else ("amd64" if args.amd64 else "arm64")
    print(f"wrote {app} [{archs}]")
    print("next (on a Mac): codesign --options runtime, notarise, staple, then ditto -c -k --keepParent")
    return 0


def assemble(args, bins, exe: str, app: Path, lipo: str | None) -> None:
    macos = app / "Contents" / "MacOS"
    res = app / "Contents" / "Resources"
    macos.mkdir(parents=True)
    res.mkdir(parents=True)
    target = macos / exe

    if len(bins) == 2:
        r = subprocess.run([lipo, "-create", str(bins[0]), str(bins[1]), "-output", str(target)],
                           capture_output=True, text=True)
        if r.returncode != 0:
            fail(f"lipo failed: {r.stderr.strip()}", 1)
    else:
        shutil.copyfile(bins[0], target)
    target.chmod(0o755)

    plist = {
        "CFBundlePackageType": "APPL",
        "CFBundleName": args.name,
        "CFBundleDisplayName": args.name,
        "CFBundleExecutable": exe,
        "CFBundleIdentifier": args.bundle_id,
        "CFBundleShortVersionString": args.version,
        "CFBundleVersion": args.build or args.version,
        "CFBundleInfoDictionaryVersion": "6.0",
        "LSMinimumSystemVersion": args.min_macos,
        "NSHighResolutionCapable": True,
        "LSApplicationCategoryType": "public.app-category.games",
    }
    if args.icon:
        shutil.copyfile(args.icon, res / args.icon.name)
        plist["CFBundleIconFile"] = args.icon.name
    with (app / "Contents" / "Info.plist").open("wb") as f:
        plistlib.dump(plist, f)



if __name__ == "__main__":
    sys.exit(main())
