# Welcome splash

## Confirmed implementation

- `assets/images/splash/welcome.png` is an unchanged copy of the user-supplied
  **Novadoku Welcome Cat Splash Screen.png** (941 × 1670). Its SHA-256 is
  `cd1cea144cf64573cfc063729b8dbbc063acf24244d6d337dc5b6a4a93c9cd1b`.
- The original waving Nova, ribbon, lettering and tagline are retained as
  artwork. No character generation, video-player changes or new fonts are used.
- A native Canvas composition animates feathered source bands: ribbon entrance,
  logo fade/scale, gentle Nova entrance and subtle corner decoration motion.
  It converges to the complete original image. No video decoding is required.
- Artwork is uniformly contained and centered. Background edge pixels extend
  into extra-tall or wide viewports; the character and lettering are neither
  stretched nor cropped. Transparent system bars remain real system UI.
- Saved or system reduced motion displays the final composition immediately
  and removes the Home crossfade. Lifecycle suspension stops the ticker.
- Real `main()` enables `launchSplashProvider`. Already-initialized embedded
  and widget-test hosts retain their existing direct-router entry by default.
- Campaign restoration, existing settings and profile loading run concurrently
  through the existing journal/providers. Startup does not rewrite saves.
- Home appears after both initialization and a 2500 ms minimum starting at the
  first artwork paint. Slow initialization does not start a second delay.
  Completion is latched for the root app lifetime; locale changes, navigation
  and foreground resume cannot replay the splash.
- Splash is outside GoRouter history. The existing Home route is mounted after
  startup, so Back cannot return to Splash. Corrupt/unavailable data retains
  the existing providers' recovery/error behavior rather than trapping startup.
- Image listeners, image handles, animation controller, lifecycle listener and
  minimum timer are disposed when their owners close.

## Validation

Focused tests cover persisted campaign/settings/profile restoration without
writes, minimum timing, delayed initialization, the real app launch integration,
absence of a Splash back-stack entry, resume, early disposal and responsive
rendering at 360 × 640, 390 × 844 and 800 × 1280. Render captures are generated
under `build/splash_review/` for visual inspection.

Executed validation: `flutter analyze` reported no issues. The combined
`splash_test`, `widget_test`, `profile_test`, `home_selection_test` and
`home_nova_video_test` run passed all 48 tests. All three responsive render
captures were inspected against the supplied reference.

Physical-device cold-start timing, GPU frame timing and OS launch-window
appearance require device verification. No production build is part of this
change.

## Splash-to-Home handoff refinement (2026-11-20)

Home now mounts beneath the outgoing Splash, whose opacity eases away over
460 ms. Its opaque background stays present throughout. A single Home-only
1100 ms clock coordinates paint-only fade/scale transitions: header at 0 ms,
branding at 120 ms, Nova at 240 ms, level selection at 400 ms, Play at 520 ms,
Daily at 620 ms and How to play at 700 ms. Each group settles over 400 ms;
the overall body scale settles from 99.2% over 460 ms. No layout metrics,
assets, video-player implementation, playback speeds, input gating, sounds or
route configuration are changed. Normal non-launch branding arrival remains.
The clock remains completed across subsequent navigation; reduced motion
finishes it immediately without restarting when the preference changes back.

Verification: flutter analyze reported no issues; all 50 combined Splash,
Home, profile, level-selection, navigation and Home Nova playback tests passed.
New checks verify stagger order, the 1100 ms finish, stable Nova widget state
and size, no replay after returning Home, no per-frame child rebuilds, reduced
motion and controller disposal. Actual device GPU frame pacing remains
unverified. No production build was created.
