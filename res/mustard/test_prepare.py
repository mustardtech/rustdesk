import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("mustard_prepare", ROOT / "prepare.py")
PREPARE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PREPARE)


class PrepareTests(unittest.TestCase):
    def test_macos_and_linux_packages_show_each_edition_name(self):
        repository = ROOT.parent.parent
        for edition, name in PREPARE.NAMES.items():
            for platform in ["macos", "linux"]:
                with self.subTest(edition=edition, platform=platform), tempfile.TemporaryDirectory() as directory:
                    checkout = Path(directory)
                    (checkout / "flutter/assets").mkdir(parents=True)
                    (checkout / "res").mkdir()
                    files = (["flutter/macos/Runner/Configs/AppInfo.xcconfig", "build.py",
                              "flutter/macos/Runner.xcodeproj/project.pbxproj"]
                             if platform == "macos" else
                             ["res/rustdesk.desktop", "res/rustdesk-link.desktop", "flutter/linux/my_application.cc"])
                    for filename in files:
                        target = checkout / filename
                        target.parent.mkdir(parents=True, exist_ok=True)
                        target.write_bytes((repository / filename).read_bytes())
                    PREPARE.prepare_client(checkout, edition, platform)
                    if platform == "macos":
                        config = (checkout / files[0]).read_text()
                        self.assertIn(f"PRODUCT_NAME = {name}", config)
                        self.assertIn(f"PRODUCT_BUNDLE_IDENTIFIER = nz.co.mustard.{edition}", config)
                        self.assertEqual((checkout / "flutter/macos/Runner/AppIcon.icns").read_bytes(),
                                         (ROOT / "AppIcon.icns").read_bytes())
                    else:
                        self.assertIn(f"Name={name}", (checkout / files[0]).read_text())
                        self.assertEqual((checkout / "res/128x128@2x.png").read_bytes(),
                                         (ROOT / "linux-icon.png").read_bytes())

    def test_both_builds_receive_their_edition_and_branded_assets(self):
        for edition, name in PREPARE.NAMES.items():
            with self.subTest(edition=edition), tempfile.TemporaryDirectory() as directory:
                checkout = Path(directory)
                for folder in ["flutter/assets", "res", "flutter/windows/runner/resources"]:
                    (checkout / folder).mkdir(parents=True, exist_ok=True)
                resource = checkout / "flutter/windows/runner/Runner.rc"
                resource.write_text(
                    'VALUE "ProductName", "RustDesk"\n'
                    'VALUE "FileDescription", "RustDesk Remote Desktop"\n'
                )
                result = subprocess.run(
                    [sys.executable, str(ROOT / "prepare.py"), "--edition", edition,
                     "--checkout", directory, "--platform", "windows", "--", sys.executable, "-c",
                     'import os, json; print(json.dumps(os.environ["MUSTARD_EDITION"]))'],
                    env=dict(os.environ, RENDEZVOUS_SERVER="support.example.invalid",
                             RS_PUB_KEY="test-public-key"),
                    capture_output=True, text=True, check=True,
                )
                self.assertEqual(json.loads(result.stdout), edition)
                self.assertIn(f'"ProductName", "{name}"', resource.read_text())
                self.assertEqual((checkout / "flutter/assets/logo.png").read_bytes(),
                                 (ROOT / "logo_light.png").read_bytes())
                self.assertEqual((checkout / "res/icon.ico").read_bytes(),
                                 (ROOT / "icon.ico").read_bytes())

    def test_privacy_helper_receives_the_complete_branded_image(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)
            (source / "WindowInjection").mkdir()
            image_source = source / "WindowInjection/img.cpp"
            image_source.write_text("stock artwork")
            PREPARE.prepare_privacy(source)
            array = image_source.read_text().split("{", 1)[1].split("}", 1)[0]
            image = bytes(int(value.strip(), 16) for value in array.split(","))
            self.assertEqual(image, (ROOT / "privacy.png").read_bytes())


if __name__ == "__main__":
    unittest.main()
