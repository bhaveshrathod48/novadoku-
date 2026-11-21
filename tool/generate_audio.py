"""Render the original Novadoku score and cues to signed 16-bit PCM WAV."""
from array import array
from math import cos, exp, pi, sin, tau
from pathlib import Path
from random import Random
from sys import byteorder
from wave import open as wave_open

RATE = 44_100
ASSETS = Path(__file__).resolve().parents[1] / "assets"


def frequency(note):
    return 440.0 * 2 ** ((note - 69) / 12)


def voice(note, length, instrument):
    pitch = frequency(note)
    for index in range(round(length * RATE)):
        time = index / RATE
        phase = tau * pitch * time
        if instrument == "pad":
            gate = min(time / 0.5, (length - time) / 0.9, 1)
            amp = (0.5 - 0.5 * cos(pi * gate)) * (0.93 + 0.07 * sin(tau * 0.42 * time))
            value = (
                sin(phase) + 0.32 * sin(phase * 1.0015 + 0.4)
                + 0.18 * sin(phase * 2 + 0.36 * sin(tau * 1.8 * time))
                + 0.08 * sin(phase * 3)
            )
        elif instrument == "felt":
            amp = min(1, time / 0.014) * exp(-2.65 * time)
            value = (
                sin(phase + 0.14 * exp(-6 * time) * sin(phase * 2))
                + 0.22 * exp(-2.4 * time) * sin(phase * 2.001 + .4)
                + 0.09 * exp(-4 * time) * sin(phase * 3.005)
            )
        elif instrument == "glass":
            amp = min(1, time / 0.011) * exp(-5.1 * time)
            value = (
                sin(phase) + 0.26 * exp(-6 * time) * sin(phase * 2.01)
                + 0.11 * exp(-11 * time) * sin(phase * 4.18)
            )
        else:
            raise ValueError(instrument)
        release = min(1, (length - time) / 0.09)
        yield amp * value * release * release


def mix(track, samples, start, gain, pan=0, wrap=False):
    left, right = track
    length = len(left)
    offset = round(start * RATE)
    left_gain = gain * cos((1 + pan) * pi / 4)
    right_gain = gain * sin((1 + pan) * pi / 4)
    for index, sample in enumerate(samples):
        position = offset + index
        if wrap:
            position %= length
        elif position >= length:
            break
        left[position] += sample * left_gain
        right[position] += sample * right_gain


def track(seconds):
    return tuple(array("f", [0]) * round(RATE * seconds) for _ in range(2))


def render(path, channels, peak):
    maximum = max(abs(sample) for channel in channels for sample in channel)
    scale = 32767 * peak / maximum
    samples = array("h", (
        round(value * scale) for frame in zip(*channels) for value in frame
    ))
    if byteorder == "big":
        samples.byteswap()
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave_open(str(path), "wb") as output:
        output.setparams((2, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(samples.tobytes())


def score():
    beat = 0.8
    phrase = track(32 * beat)
    chords = [
        (50, 57, 61, 64, 66), (49, 57, 59, 64, 69),
        (47, 54, 57, 61, 62), (43, 54, 57, 59, 62),
        (50, 57, 61, 64, 66), (49, 57, 59, 64, 69),
        (52, 55, 59, 62, 66), (45, 55, 59, 62, 64),
    ]
    melodies = [
        ((0.5, 74), (1.5, 76), (2.75, 78)),
        ((0.75, 76), (1.75, 71), (3.0, 73)),
        ((0.5, 74), (2.0, 78), (3.0, 76)),
        ((0.75, 71), (2.25, 69), (3.25, 66)),
        ((0.5, 69), (1.5, 74), (2.75, 81)),
        ((0.75, 76), (2.25, 73)),
        ((0.5, 71), (1.5, 76), (2.75, 78)),
        ((1.0, 76), (2.75, 74)),
    ]
    rng = Random(407)
    for bar, (chord, melody) in enumerate(zip(chords, melodies)):
        start = bar * 4 * beat
        for index, note in enumerate(chord):
            mix(phrase, voice(note, 4.8 * beat, "pad"), start - 0.32,
                (0.087, .046, .04, .033, .024)[index], (index - 2) * .21, True)
        for index, subdivision in enumerate((0, .75, 1.5, 2.5, 3.25)):
            note = chord[(0, 2, 3, 1, 4)[index]] + (12 if index > 0 else 0)
            when = start + subdivision * beat + rng.uniform(0, .024)
            mix(phrase, voice(note, 1.26, "felt"), when, .16 if index == 0 else .072,
                (index - 2) * .13, True)
        for subdivision, note in melody:
            when = start + subdivision * beat + rng.uniform(0, .021)
            pan = rng.uniform(-.24, .24)
            tone = tuple(voice(note, 1.36, "felt"))
            for delay, gain, side in ((0, .14, pan), (.32, .029, -.6), (.64, .013, .6)):
                mix(phrase, tone, when + delay, gain, side, True)
    render(ASSETS / "music/pastel_orbit.wav", phrase, .72)


def sweep(start_pitch, end_pitch, length, noise):
    rng = Random(83)
    phase = 0.0
    filtered = 0.0
    for index in range(round(length * RATE)):
        time = index / RATE
        progress = time / length
        phase += tau * (end_pitch + (start_pitch - end_pitch) * exp(-4 * progress)) / RATE
        filtered = 0.83 * filtered + 0.17 * rng.uniform(-1, 1)
        envelope = min(time / .004, 1) * (1 - progress) ** 2 * exp(-3.4 * progress)
        yield envelope * (sin(phase) + .24 * sin(2 * phase) + noise * filtered)


def cue(name, length, notes=(), glide=None):
    channels = track(length)
    if glide:
        mix(channels, sweep(*glide), 0, .42)
    for start, note, sustain, tone, volume, pan in notes:
        mix(channels, voice(note, sustain, tone), start, volume, pan)
    render(ASSETS / "sounds" / f"{name}.wav", channels, .75)


def effects():
    cue("mark_x", .140, glide=(1450, 310, .140, .72))
    cue("place_nova", .310, [
        (0, 74, .29, "glass", .63, -.11), (.055, 81, .25, "glass", .38, .19),
    ], (430, 245, .16, .10))
    cue("wrong_placement", .240, [
        (0, 57, .21, "felt", .4, 0),
    ], (340, 155, .23, .38))
    cue("heart_loss", .260, [
        (0, 66, .24, "felt", .25, -.08), (.06, 61, .18, "felt", .22, .13),
    ], (510, 236, .22, .29))
    cue("hint", .580, [
        (0, 69, .42, "glass", .51, -.18), (.08, 74, .43, "glass", .39, .08),
        (.16, 78, .40, "glass", .31, .24),
    ])
    cue("level_complete", 1.420, [
        (0, 62, 1.1, "felt", .41, -.10), (.08, 69, .92, "felt", .37, .05),
        (.18, 74, .76, "glass", .46, -.20), (.29, 78, .74, "glass", .42, .16),
        (.40, 81, .82, "glass", .39, -.06), (.53, 86, .85, "glass", .28, .20),
        (.57, 76, .82, "felt", .25, .06),
    ])
    cue("level_failure", .790, [
        (0, 74, .38, "felt", .46, -.15), (.14, 71, .43, "felt", .40, .11),
        (.29, 69, .49, "felt", .36, 0), (.29, 62, .48, "felt", .21, .09),
    ])
    cue("nova_tap", .430, [
        (0, 76, .25, "felt", .36, -.15), (.07, 81, .33, "glass", .44, .08),
        (.15, 83, .27, "glass", .25, .19),
    ], (290, 550, .19, .13))


if __name__ == "__main__":
    score()
    effects()
