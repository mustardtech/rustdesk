"""Prepare Mustard branding in a build checkout or its Windows privacy helper."""

import argparse
import os
import re
from pathlib import Path
import shutil
import subprocess
import sys


ASSETS = Path(__file__).resolve().parent
ROOT = ASSETS.parent.parent
NAMES = {"support": "Mustard Support", "remote": "Mustard Remote"}


def prepare_client(root, edition, platform="windows"):
    assets = root / "flutter/assets"
    if not assets.is_dir():
        raise ValueError("The build checkout must contain flutter/assets")
    for source, destination in [
        ("logo_light.png", assets / "logo.png"),
        ("logo_light.png", assets / "logo_light.png"),
        ("logo_dark.png", assets / "logo_dark.png"),
        ("icon.png", assets / "icon.png"),
        ("mark.svg", assets / "icon.svg"),
        ("icon.ico", assets / "icon.ico"),
        ("icon.png", root / "res/icon.png"),
        ("icon.png", root / "res/mac-icon.png"),
        ("icon.ico", root / "res/icon.ico"),
        ("icon.ico", root / "res/tray-icon.ico"),
    ]:
        shutil.copyfile(ASSETS / source, destination)

    if platform == "macos":
        prepare_macos(root, edition)
        return
    if platform == "linux":
        prepare_linux(root, edition)
        return
    shutil.copyfile(ASSETS / "icon.ico", root / "flutter/windows/runner/resources/app_icon.ico")
    resource = root / "flutter/windows/runner/Runner.rc"
    text = resource.read_bytes().decode("utf-8")
    for old_name in ["RustDesk", *NAMES.values()]:
        text = text.replace(
            f'VALUE "ProductName", "{old_name}"',
            f'VALUE "ProductName", "{NAMES[edition]}"',
        ).replace(
            f'VALUE "FileDescription", "{old_name} Remote Desktop"',
            f'VALUE "FileDescription", "{NAMES[edition]} Remote Desktop"',
        )
    resource.write_bytes(text.encode("utf-8"))


def prepare_macos(root, edition):
    shutil.copyfile(ASSETS / "AppIcon.icns", root / "flutter/macos/Runner/AppIcon.icns")
    config = root / "flutter/macos/Runner/Configs/AppInfo.xcconfig"
    text = config.read_text()
    text = re.sub(r"(?m)^PRODUCT_NAME = .*", f"PRODUCT_NAME = {NAMES[edition]}", text)
    text = re.sub(r"(?m)^PRODUCT_BUNDLE_IDENTIFIER = .*",
                  f"PRODUCT_BUNDLE_IDENTIFIER = nz.co.mustard.{edition}", text)
    config.write_text(text)
    project = root / "flutter/macos/Runner.xcodeproj/project.pbxproj"
    project.write_text(project.read_text().replace(
        "PRODUCT_BUNDLE_IDENTIFIER = com.carriez.rustdesk;",
        f"PRODUCT_BUNDLE_IDENTIFIER = nz.co.mustard.{edition};",
    ))
    build = root / "build.py"
    text = build.read_text()
    for name in ["RustDesk", *NAMES.values()]:
        text = text.replace(f"Products/Release/{name}.app/", f"Products/Release/{NAMES[edition]}.app/")
    build.write_text(text)


def prepare_linux(root, edition):
    shutil.copyfile(ASSETS / "linux-icon.png", root / "res/128x128@2x.png")
    shutil.copyfile(ASSETS / "mark.svg", root / "res/scalable.svg")
    for filename in ["rustdesk.desktop", "rustdesk-link.desktop"]:
        desktop = root / "res" / filename
        text = re.sub(r"(?m)^Name=(?:RustDesk|Mustard Support|Mustard Remote)$",
                      f"Name={NAMES[edition]}", desktop.read_text())
        desktop.write_text(text)
    runner = root / "flutter/linux/my_application.cc"
    text = runner.read_text().replace('set_title(header_bar, "rustdesk")',
                                      f'set_title(header_bar, "{NAMES[edition]}")')
    text = text.replace('set_title(window, "rustdesk")',
                        f'set_title(window, "{NAMES[edition]}")')
    runner.write_text(text)


def prepare_privacy(source):
    destination = source / "WindowInjection/img.cpp"
    if not destination.is_file():
        raise ValueError("Expected the privacy helper's WindowInjection/img.cpp")
    image = (ASSETS / "privacy.png").read_bytes()
    rows = [
        ", ".join(f"0x{byte:02x}" for byte in image[offset:offset + 20])
        for offset in range(0, len(image), 20)
    ]
    destination.write_text(
        '#include "pch.h"\n#include "img.h"\n\n'
        'const unsigned char g_img[] = {\n'
        + ",\n".join(rows)
        + '\n};\nconst long long g_imgLen = sizeof(g_img);\n'
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--edition", choices=NAMES)
    mode.add_argument("--privacy-source", type=Path)
    parser.add_argument("--checkout", type=Path, default=ROOT)
    parser.add_argument("--platform", choices=["windows", "macos", "linux"],
                        default={"win32": "windows", "darwin": "macos"}.get(sys.platform, "linux"))
    parser.add_argument("--prepare-only", action="store_true")
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if args.privacy_source:
        if args.command:
            parser.error("--privacy-source does not run a client build command")
        prepare_privacy(args.privacy_source)
        return 0

    command = args.command
    if command and command[0] == "--":
        command = command[1:]
    if args.prepare_only and command:
        parser.error("--prepare-only does not run a build command")
    if not args.prepare_only:
        for key in ["RENDEZVOUS_SERVER", "RS_PUB_KEY"]:
            if not os.environ.get(key, "").strip():
                parser.error(f"Set {key} in the build environment")
    prepare_client(args.checkout, args.edition, args.platform)
    if args.prepare_only:
        print(f"Prepared {NAMES[args.edition]}; compile with MUSTARD_EDITION={args.edition}")
        return 0
    environment = dict(os.environ, MUSTARD_EDITION=args.edition)
    return subprocess.call(
        command or [sys.executable, "build.py", "--flutter"],
        cwd=args.checkout,
        env=environment,
    )


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError) as error:
        print(f"Mustard build preparation failed: {error}", file=sys.stderr)
        sys.exit(1)
