"""Run with Blender --background --python tool/extract_x_audio.py.

Derive offline PCM excerpts from the supplied MP3; no synthesis or gain changes.
"""
from pathlib import Path
import wave
import aud
import numpy as np

root = Path(__file__).resolve().parents[1]
source = aud.Sound(str(root / 'assets/music/swaip.mp3'))
samples = source.data()
rate = int(source.specs[0])
print('X source', rate, samples.shape)
# Tap preserves the existing first 180 ms, minus its initial 28 ms of silence.
# Swipe isolates the same prominent burst without subsequent MP3 transients.
for name, start_ms, end_ms in [('x_tap.wav', 28, 180), ('x_swipe.wav', 70, 145)]:
    clip = samples[round(rate * start_ms / 1000):round(rate * end_ms / 1000)].copy()
    # Tiny boundary ramps avoid clicks while preserving the original timbre.
    attack, release = round(rate * .002), round(rate * .006)
    clip[:attack] *= np.linspace(0, 1, attack)[:, None]
    clip[-release:] *= np.linspace(1, 0, release)[:, None]
    pcm = np.rint(np.clip(clip, -1, 1) * 32767).astype('<i2')
    with wave.open(str(root / 'assets/sounds' / name), 'wb') as out:
        out.setnchannels(pcm.shape[1])
        out.setsampwidth(2)
        out.setframerate(rate)
        out.writeframes(pcm.tobytes())
    print('Wrote', name, end_ms - start_ms, 'ms')
