"""Prepare compact, pitched chimes from CC0 VSCO 2 CE recordings.
Run from any directory with Python 3; no external audio tools are required.
"""
import io
from pathlib import Path
import struct
import urllib.request
import wave

ROOT = Path(__file__).resolve().parents[1] / 'assets/audio/bells'
ROOT.mkdir(parents=True, exist_ok=True)
repo = 'sgossner/VSCO-2-CE'
commit = '440300901dfe9275fd84e0b7763af1f8443ae62e'
base = f'https://raw.githubusercontent.com/{repo}/{commit}/'
license_text = urllib.request.urlopen(base + 'LICENSE').read().decode()
(ROOT / 'LICENSE-VSCO.txt').write_text(license_text)
sources = {}
for midi, name in [(72, 'C5'), (79, 'G5'), (84, 'C6')]:
    url = base + f'Percussion/Glock/glock_medium_{name}.wav'
    data = urllib.request.urlopen(url).read()
    with wave.open(io.BytesIO(data)) as source:
        rate, channels, width = source.getframerate(), source.getnchannels(), source.getsampwidth()
        raw = source.readframes(source.getnframes())
    if width not in (2, 3, 4):
        raise ValueError(f'Unsupported PCM format: {width}')
    frames = []
    for i in range(0, len(raw), channels * width):
        frames.append(sum(int.from_bytes(raw[i+c*width:i+(c+1)*width], 'little', signed=True)
                          for c in range(channels)) / channels / (2 ** (width * 8 - 1)))
    # Trim the recorder's leading silence, retaining a short attack lead-in.
    first = next((i for i, v in enumerate(frames) if abs(v) > .002), 0)
    sources[midi] = (rate, frames[max(0, first - int(rate * .003)):])

for midi, name in [(72,'c5'), (74,'d5'), (75,'ds5'), (76,'e5'), (77,'f5'), (78,'fs5'), (79,'g5'), (81,'a5'), (82,'bb5'), (83,'b5'), (84,'c6'), (86,'d6')]:
    source_midi = min(sources, key=lambda n: abs(n-midi))
    rate, frames = sources[source_midi]
    ratio = 2 ** ((midi - source_midi) / 12)
    target_rate = 32000
    length = min(int(2.4 * target_rate), int(len(frames) / rate / ratio * target_rate))
    output = []
    for i in range(length):
        position = i * rate * ratio / target_rate
        left = min(int(position), len(frames)-2)
        fraction = position-left
        value = frames[left]*(1-fraction) + frames[left+1]*fraction
        value *= min(1, i / (target_rate * .002), (length-1-i) / (target_rate * .18))
        output.append(value)
    gain = .65 / max(abs(v) for v in output)
    pcm = b''.join(struct.pack('<h', round(v * gain * 32767)) for v in output)
    with wave.open(str(ROOT / (name+'.wav')), 'wb') as target:
        target.setparams((1, 2, target_rate, 0, 'NONE', 'not compressed'))
        target.writeframes(pcm)
    print(name, len(pcm))
(ROOT / 'SOURCES.md').write_text(f'''# Bell recordings

Source: [VSCO 2 Community Edition](https://github.com/{repo}),
revision `{commit}`, `Percussion/Glock/glock_medium_C5.wav`,
`glock_medium_G5.wav`, and `glock_medium_C6.wav`.
License: CC0 1.0 Universal (full text in LICENSE-VSCO.txt).
Credit: Versilian Studios / Sam Gossner and VSCO contributors.

These are recorded glockenspiel chimes, repitched by at most three semitones
for the per-song C5–D6 bell sets, including D-sharp, F-sharp and B-flat. Mono 32 kHz PCM, trimmed leading silence,
2.4-second maximum decay, gentle edge fades, normalized to 0.65 peak.
Regenerate with `python3 app/tool/prepare_bells.py` (network required).
No recording or network access is needed at runtime.
''')
