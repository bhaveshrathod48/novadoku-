# Novadoku audio

The score and original WAV cues were composed and synthesized for Novadoku. They use original note sequences, envelopes and generated waveforms. Those WAV files contain no imported recordings, samples or third-party music. The later user-supplied X-mark MP3 is documented separately below.

All ten files are bundled stereo, 44.1 kHz, 16-bit PCM WAV. Run `python tool/generate_audio.py` from the project root to re-render them with Python's standard library.

| Asset | Duration | Sound |
| --- | ---: | --- |
| `assets/music/pastel_orbit.wav` | 25.60 s | Eight bars at 75 BPM. Soft pads, felt keys and stereo echoes. Notes and tails wrap across the loop boundary. |
| `assets/sounds/button.wav` | 0.10 s | Soft tap |
| `assets/sounds/place_nova.wav` | 0.31 s | Rising two-note glass accent |
| `assets/sounds/mark_x.wav` | 0.14 s | Legacy dry tick, retained but no longer used for X playback |
| `assets/sounds/wrong_placement.wav` | 0.24 s | Muted descending tone |
| `assets/sounds/heart_loss.wav` | 0.26 s | Soft downward pair |
| `assets/sounds/hint.wav` | 0.58 s | Three-note chime |
| `assets/sounds/level_complete.wav` | 1.42 s | Rising cadential phrase |
| `assets/sounds/level_failure.wav` | 0.79 s | Gentle resolving phrase |
| `assets/sounds/nova_tap.wav` | 0.43 s | Playful ascending chirp |

The game uses a dedicated looping music player at gain 0.31 and one effects player with cue gains from 0.20 to 0.49. The effect assets warm into the device's temporary audio cache. The score prepares when Music is enabled. Music pauses when turned off or when the app leaves its resumed state, and resumes at its saved playback position during that app run. Muting effects or leaving the foreground clears queued tails and stops the effects channel. New events of sufficient priority replace an in-flight cue. Wrong placement, heart loss, and failure play as consecutive sounds through that channel.

Flutter tests validate the bundled PCM files, sample continuity at the loop seam, the cue schedule, muting during preparation, and lifecycle and settings behavior. Device verification covers audible loop continuity, relative loudness on real speakers, Bluetooth and interruption behavior, and physical haptic response.

## User-supplied X sound (2026-11-20)

`assets/music/swaip.mp3` replaces only normal Gameplay X audio. It is the existing
42,855-byte user-supplied file, unchanged. MPEG frame inspection found 30 frames
at 44.1 kHz, approximately 784 ms including encoded padding. Its authorship is
not attributed to the original synthesized score/cues above.

Tap add/remove uses a 180 ms excerpt; swipe add/remove uses a 780 ms swish, both
at gain 0.28. Events are emitted only after a real mark edit, immediately rather
than after the double-tap window. The existing provisional-X/double-tap rollback,
protected cells, saved edits and puzzle rules remain intact. A first tap that
visibly draws an X now gives X feedback even if followed by a Nova double tap.

The asset cache deduplicates the shared source. An X-only retained player warms
the source when effects are enabled; Android uses low-latency SoundPool. Other
players, sound assets, gains, priorities and music playback are unchanged.
There remains at most one audible effect: repeated X events while the X cue is
pending/playing are dropped, not queued or repeatedly restarted. Cue-end stops
the excerpt; subsequent changed cells can start a fresh swish. Existing higher
priority reactions interrupt it. Muting, backgrounding and disposal cancel it
and dispose the retained player through the existing service lifecycle.

Verification: flutter analyze reported no issues. All 79 combined feedback,
Gameplay, Gameplay Nova and Gameplay motion tests passed. Coverage includes all
four X interactions, immediate event timing, protected/no-op cells, 200-event
coalescing, preload bursts, tap/swipe tail lengths, peak single-effect playback,
priority interruption, muting and disposal. Gameplay stress covers 840 taps and
140 swipe strokes over sizes 4–10. These are host scheduling/input checks;
physical-device audibility, perceived latency, loudness, Bluetooth behavior and
native audio/frame pacing remain unverified. No production build was created.

## Short X excerpts and per-edit synchronization (2026-11-20)

This supersedes the 180/780 ms busy-lockout behavior described above. The
original swaip.mp3 remains unchanged (SHA-256
24a769525adbc84ce552cfc78968a9aac0d0d43b8c8753ee65096e1bd2760072).
The reproducible Blender/Audaspace script tool/extract_x_audio.py exports:

- assets/sounds/x_tap.wav: source 28-180 ms, 152 ms stereo PCM at 44.1 kHz.
  It retains the previous tap excerpt's character and removes leading silence.
- assets/sounds/x_swipe.wav: source 70-145 ms, 75 ms stereo PCM at 44.1 kHz.
  It isolates the prominent burst without replaying subsequent MP3 transients.

Both use a 2 ms attack and 6 ms release to avoid boundary clicks, with no
pitch, gain or synthesized-content changes. Playback remains at gain 0.28.
The full MP3 is no longer loaded into the X player. Each small PCM excerpt is
preloaded into a retained low-latency player; the previously active effect is
stopped before the selected excerpt restarts. At most one effect is audible.
All retained players are released by the existing disposal path.

The X busy lockout is removed: a newly changed cell can restart its cue while
an earlier X is playing. Request identities cancel superseded starts; edits
within the same scheduling batch collapse to the latest event rather than
producing an audible backlog. Events during initial audio warmup are not queued.
An X start stalled more than 80 ms is discarded instead of sounding after its
cell change. Playing excerpts naturally end after 75/152 ms, without MP3 loops
or long swipe tails. Existing successful-edit emission, protected/no-op cells,
other cues, music, priority rules, settings, UI and Nova players are unchanged.

Verification: flutter analyze reported no issues. All 83 combined feedback,
Gameplay input/stress, Gameplay Nova and Gameplay motion tests passed. Tests
cover 100 ready X restarts each at 0/12/50/200 ms spacing, single audible effect,
same-frame bursts, warmup/stalled-request rejection, clean PCM boundaries,
short tails, muting/disposal, actual tap/swipe add/remove and protected cells.
Gameplay stress covers 840 taps plus 140 swipe strokes across sizes 4-10.
Sampled frames from the supplied recording were inspected. Real speaker and
Bluetooth synchronization, native audio latency and perceived loudness were
not verified on a device. No production build was created.
