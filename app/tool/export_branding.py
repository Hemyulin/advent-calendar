"""Export native icons/splash sizes from the committed artwork (macOS sips)."""
import json
from pathlib import Path
import struct
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/branding/advent-icon.png'


def resize(destination, size, source=SOURCE):
    destination.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['sips', '-z', str(size), str(size), str(source), '--out', str(destination)],
                   check=True, stdout=subprocess.DEVNULL)


for density, size, scale in [('mdpi', 48, 1), ('hdpi', 72, 1.5), ('xhdpi', 96, 2),
                              ('xxhdpi', 144, 3), ('xxxhdpi', 192, 4)]:
    res = ROOT / 'android/app/src/main/res'
    resize(res / ('mipmap-' + density) / 'ic_launcher.png', size)
    resize(res / ('drawable-' + density) / 'splash_mark.png', int(192 * scale))

# Adaptive icons show only their inner safe zone; keep the complete chest inside it.
with tempfile.TemporaryDirectory() as folder:
    padded = Path(folder) / 'padded.png'
    subprocess.run(['sips', '--padToHeightWidth', '1536', '1536', '--padColor', 'FFF8EE',
                    str(SOURCE), '--out', str(padded)], check=True, stdout=subprocess.DEVNULL)
    resize(ROOT / 'android/app/src/main/res/drawable-nodpi/advent_icon_foreground.png', 432, padded)
    web_padded = Path(folder) / 'web-maskable.png'
    subprocess.run(['sips', '--padToHeightWidth', '1280', '1280', '--padColor', 'FFF8EE',
                    str(SOURCE), '--out', str(web_padded)], check=True, stdout=subprocess.DEVNULL)
    for size in (192, 512):
        resize(ROOT / 'web/icons' / ('Icon-maskable-' + str(size) + '.png'), size, web_padded)

for platform in ['ios', 'macos']:
    directory = ROOT / platform / 'Runner/Assets.xcassets/AppIcon.appiconset'
    for item in json.loads((directory / 'Contents.json').read_text())['images']:
        resize(directory / item['filename'], round(float(item['size'].split('x')[0]) *
                                                   float(item['scale'].removesuffix('x'))))

launch = ROOT / 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
for suffix, size in [('', 192), ('@2x', 384), ('@3x', 576)]:
    resize(launch / ('LaunchImage' + suffix + '.png'), size)
for name, size in [('Icon-192', 192), ('Icon-512', 512)]:
    resize(ROOT / 'web/icons' / (name + '.png'), size)
resize(ROOT / 'web/favicon.png', 32)

# ICO supports PNG-compressed entries; no image library is required.
with tempfile.TemporaryDirectory() as folder:
    entries = []
    for size in [16, 32, 48, 64, 128, 256]:
        path = Path(folder) / (str(size) + '.png')
        resize(path, size)
        entries.append((size, path.read_bytes()))
    offset = 6 + len(entries) * 16
    data = struct.pack('<HHH', 0, 1, len(entries))
    for size, image in entries:
        dimension = size if size < 256 else 0
        data += struct.pack('<BBBBHHII', dimension, dimension, 0, 0, 1, 32, len(image), offset)
        offset += len(image)
    (ROOT / 'windows/runner/resources/app_icon.ico').write_bytes(
        data + b''.join(image for _, image in entries))
print('Exported Android, iOS, macOS, web and Windows branding assets.')
