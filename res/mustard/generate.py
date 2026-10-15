"""Regenerate the committed artwork with ImageMagick's convert command."""

from pathlib import Path
import struct
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parent


def convert(*arguments):
    subprocess.run(["convert", *map(str, arguments)], cwd=ROOT, check=True)


def main():
    with tempfile.TemporaryDirectory() as directory:
        mark = Path(directory) / "mark.png"
        convert("-background", "none", "mark.svg", "-resize", "280x150", mark)
        for theme, color in [("light", "#535B4D"), ("dark", "#F4EFD7")]:
            convert(
                "-size", "900x180", "xc:none", mark,
                "-geometry", "210x112+24+34", "-composite",
                "-font", "Zain-Bold.ttf", "-fill", color, "-pointsize", "136",
                "-gravity", "northwest", "-annotate", "+263+8", "mustard",
                f"logo_{theme}.png",
            )
        convert(
            "-size", "512x512", "xc:#F4EFD7", mark,
            "-geometry", "360x192+0+0", "-gravity", "center", "-composite",
            "-depth", "8", "icon.png",
        )
        convert("icon.png", "-define", "icon:auto-resize=256,128,64,48,32,16", "icon.ico")
        convert("icon.png", "-resize", "256x256", "linux-icon.png")
        chunks = []
        for tag, size in [(b"ic07", 128), (b"ic08", 256), (b"ic09", 512), (b"ic10", 1024)]:
            image = Path(directory) / f"icon-{size}.png"
            convert("icon.png", "-resize", f"{size}x{size}", image)
            data = image.read_bytes()
            chunks.append(tag + struct.pack(">I", len(data) + 8) + data)
        data = b"".join(chunks)
        (ROOT / "AppIcon.icns").write_bytes(b"icns" + struct.pack(">I", len(data) + 8) + data)
        convert(
            "-size", "1920x1080", "xc:#181C16", mark,
            "-geometry", "320x170+800+230", "-composite",
            "-font", "Zain-Bold.ttf", "-fill", "#F4EFD7", "-pointsize", "118",
            "-gravity", "north", "-annotate", "+0+400", "mustard",
            "-font", "Zain-Regular.ttf", "-pointsize", "48",
            "-annotate", "+0+550", "Support session in progress",
            "-fill", "#F4EFD7", "-pointsize", "32",
            "-annotate", "+0+660", "Please leave this computer on while we assist you.",
            "-fill", "#DDAC5B", "-pointsize", "26",
            "-annotate", "+0+925", "mustard.co.nz  |  help@mustard.co.nz  |  07 855 6424",
            "-depth", "8", "privacy.png",
        )


if __name__ == "__main__":
    main()
