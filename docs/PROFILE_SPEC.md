# Home profile customization

## Confirmed scope

User-authorized Home feature (2026-11-20), outside the locked roadmap's unchanged phase order. Only Home gains profile editing and its requested header refinements. The main Home Nova video, other screen/player implementations, fonts, sounds, gameplay and campaign/daily saves are unchanged.

The top-left Nova tile opens a separate root modal with existing scale/fade presentation and reduced-motion support. The dialog contains a username, live avatar/frame preview, Avatar/Frame tabs, four-by-two choice grids, animated selection checks, Confirm and Close. All eight choices in each category are available from the start.

Default: username Nova, original Nova portrait, Classic Purple frame. Additional avatar choices: Panda, Fox, Bunny, Lion, Koala, Penguin, Bear. Frames: Classic Purple, Royal Gold, Rose, Mint, Cosmic, Frost, Sunshine, Rainbow. Frames are original vector decorations in `lib/features/home/profile/profile_avatar.dart`, using simple rounded colored strokes and a subtle paw print in frame-selection previews; no frame textures or extra dependencies are required.

## Drafts and saving

Dialog state is local. Avatar/frame selection updates the preview immediately; username editing supports 1-32 Unicode grapheme clusters. Names are trimmed on confirmation; blank/control-character input is rejected. Only Confirm calls ProfileController.save. Close, outside dismissal and Back discard the draft.

The existing ProgressJournal stores a separate version-1 `profile` record containing username and stable enum names. Writes are ordered, checksummed and use the journal's two-generation recovery. Confirm publishes the Home update only after a successful write. A failed write preserves the previous saved profile, leaves the dialog draft available and shows a localized retry message. Profile operations do not write campaign, daily or Settings records.

Home's profile card paints at 52 dp in the existing 48 dp header footprint, keeping other vertical geometry stable. The badge grows from a 132 dp to a 144 dp maximum width and from 11 to 12 dp text. The central hero's size calculation, position code, controller, assets, timing and playback logic are untouched. Home retains its existing safe viewport while the independent modal handles keyboard insets. A scroll hold prevents underlying motion. Profile dismissal preserves the selected replay level.

All new labels and validation/save/load messages use the seven existing Flutter localization resources. Usernames and the Nova brand are never translated. Existing offline fonts and fallback families are reused.

## Asset provenance

Built-in image_gen was used, not CLI/API fallback. Seven distinct original animal portraits were generated individually. The approved existing Nova portrait is reused directly as `assets/characters/nova/nova_portrait.webp` and was not regenerated. The generated transparent PNGs remain at their tool-provided source paths; optimized 256x256 WebP derivatives are bundled under `assets/characters/profile/`. Alpha is retained and characters are uniformly fit into a centered 224x224 area without stretching. The selected Penguin render includes a small decorative crown.

| Avatar | Runtime path | Bytes | Source PNG |
| --- | --- | ---: | --- |
| panda | `assets/characters/profile/panda.webp` | 18964 | `C:\Users\bhave\.codex\generated_images\01a1edf5-01b9-7d51-a1d6-2561b3b78a1b\exec-309a04e3-09e8-4d25-9cf9-fb04f469bec8.png` |
| fox | `assets/characters/profile/fox.webp` | 18886 | `C:\Users\bhave\.codex\generated_images\01a1edf5-01b9-7d51-a1d6-2561b3b78a1b\exec-59efb4b6-9049-4f5b-931e-afdbf7698078.png` |
| bunny | `assets/characters/profile/bunny.webp` | 14848 | `C:\Users\bhave\.codex\generated_images\01a1edf5-01b9-7d51-a1d6-2561b3b78a1b\exec-a0ca2a73-abab-49e3-9873-6d6c3d80f4ba.png` |
| lion | `assets/characters/profile/lion.webp` | 19664 | `C:\Users\bhave\.codex\generated_images\01a1edf5-01b9-7d51-a1d6-2561b3b78a1b\exec-8012af40-50e0-4d2b-8c91-04147fad235a.png` |
| koala | `assets/characters/profile/koala.webp` | 17240 | `C:\Users\bhave\.codex\generated_images\01a1edf5-01b9-7d51-a1d6-2561b3b78a1b\exec-cc5c7b8f-cc2e-4364-a1b7-eb1a95adb38d.png` |
| penguin | `assets/characters/profile/penguin.webp` | 21926 | `C:\Users\bhave\.codex\generated_images\01a1edf5-01b9-7d51-a1d6-2561b3b78a1b\exec-be2d5419-a5d8-4a88-8e55-05f04245fbfc.png` |
| bear | `assets/characters/profile/bear.webp` | 21456 | `C:\Users\bhave\.codex\generated_images\01a1edf5-01b9-7d51-a1d6-2561b3b78a1b\exec-bf4bb137-ee84-4f08-8804-4946cd474adb.png` |

### Final generation prompts

The exact prompts sent to the built-in tool were:

#### Panda

Create ONE original premium mobile puzzle game profile avatar: baby giant panda, plush ivory fur, soft charcoal eye patches, tiny round black ears, glossy warm violet eyes. Cute polished 3D character render matching Novadoku's existing Nova mascot style: oversized expressive head, subtly fluffy sculpted fur (penguin soft down), luminous expressive eyes with clean white catchlights, tiny nose, joyful gentle smile, premium soft studio lighting with a faint lavender rim. Front-facing centered isolated head and small upper-chest bust, character fills about 80% of square canvas, at least 8% transparent margin beyond all ears/fur. True transparent RGBA background; no scene, ground, circle, frame, text, letters, logo, symbols, props, confetti, watermark or extra animals. Distinct recognizable panda anatomy, consistent cute proportions and level of finish with the white/purple Nova character. This is a new panda avatar, do not reproduce or alter Nova. Production game icon with crisp silhouette and natural friendly expression.

#### Fox

Create ONE original premium mobile puzzle game profile avatar: baby red fox, warm orange fur, ivory cheek ruff and muzzle, dark brown ear tips, oversized glossy amber eyes. Cute polished 3D character render matching Novadoku's existing Nova mascot style: oversized expressive head, subtly fluffy sculpted fur (penguin soft down), luminous expressive eyes with clean white catchlights, tiny nose, joyful gentle smile, premium soft studio lighting with a faint lavender rim. Front-facing centered isolated head and small upper-chest bust, character fills about 80% of square canvas, at least 8% transparent margin beyond all ears/fur. True transparent RGBA background; no scene, ground, circle, frame, text, letters, logo, symbols, props, confetti, watermark or extra animals. Distinct recognizable fox anatomy, consistent cute proportions and level of finish with the white/purple Nova character. This is a new fox avatar, do not reproduce or alter Nova. Production game icon with crisp silhouette and natural friendly expression.

#### Bunny

Create ONE original premium mobile puzzle game profile avatar: baby bunny rabbit, fluffy ivory and light lavender fur, two long upright ears with soft pink centers, glossy lilac eyes. Cute polished 3D character render matching Novadoku's existing Nova mascot style: oversized expressive head, subtly fluffy sculpted fur (penguin soft down), luminous expressive eyes with clean white catchlights, tiny nose, joyful gentle smile, premium soft studio lighting with a faint lavender rim. Front-facing centered isolated head and small upper-chest bust, character fills about 80% of square canvas, at least 8% transparent margin beyond all ears/fur. True transparent RGBA background; no scene, ground, circle, frame, text, letters, logo, symbols, props, confetti, watermark or extra animals. Distinct recognizable bunny anatomy, consistent cute proportions and level of finish with the white/purple Nova character. This is a new bunny avatar, do not reproduce or alter Nova. Production game icon with crisp silhouette and natural friendly expression.

#### Lion

Create ONE original premium mobile puzzle game profile avatar: baby lion cub, soft honey-gold fur, small rounded fluffy caramel mane, rounded ears, glossy amber eyes. Cute polished 3D character render matching Novadoku's existing Nova mascot style: oversized expressive head, subtly fluffy sculpted fur (penguin soft down), luminous expressive eyes with clean white catchlights, tiny nose, joyful gentle smile, premium soft studio lighting with a faint lavender rim. Front-facing centered isolated head and small upper-chest bust, character fills about 80% of square canvas, at least 8% transparent margin beyond all ears/fur. True transparent RGBA background; no scene, ground, circle, frame, text, letters, logo, symbols, props, confetti, watermark or extra animals. Distinct recognizable lion anatomy, consistent cute proportions and level of finish with the white/purple Nova character. This is a new lion avatar, do not reproduce or alter Nova. Production game icon with crisp silhouette and natural friendly expression.

#### Koala

Create ONE original premium mobile puzzle game profile avatar: baby koala, soft silvery-gray fluffy fur, large rounded tufted ears, velvety charcoal oval nose, glossy violet eyes. Cute polished 3D character render matching Novadoku's existing Nova mascot style: oversized expressive head, subtly fluffy sculpted fur (penguin soft down), luminous expressive eyes with clean white catchlights, tiny nose, joyful gentle smile, premium soft studio lighting with a faint lavender rim. Front-facing centered isolated head and small upper-chest bust, character fills about 80% of square canvas, at least 8% transparent margin beyond all ears/fur. True transparent RGBA background; no scene, ground, circle, frame, text, letters, logo, symbols, props, confetti, watermark or extra animals. Distinct recognizable koala anatomy, consistent cute proportions and level of finish with the white/purple Nova character. This is a new koala avatar, do not reproduce or alter Nova. Production game icon with crisp silhouette and natural friendly expression.

#### Penguin

Create ONE original premium mobile puzzle game profile avatar: baby penguin chick, fluffy charcoal and ivory face, small orange beak, glossy dark violet eyes, rounded little crown. Cute polished 3D character render matching Novadoku's existing Nova mascot style: oversized expressive head, subtly fluffy sculpted fur (penguin soft down), luminous expressive eyes with clean white catchlights, tiny nose, joyful gentle smile, premium soft studio lighting with a faint lavender rim. Front-facing centered isolated head and small upper-chest bust, character fills about 80% of square canvas, at least 8% transparent margin beyond all ears/fur. True transparent RGBA background; no scene, ground, circle, frame, text, letters, logo, symbols, props, confetti, watermark or extra animals. Distinct recognizable penguin anatomy, consistent cute proportions and level of finish with the white/purple Nova character. This is a new penguin avatar, do not reproduce or alter Nova. Production game icon with crisp silhouette and natural friendly expression.

#### Bear

Create ONE original premium mobile puzzle game profile avatar: baby brown bear cub, warm cocoa fluffy fur, cream muzzle, small round ears, glossy hazel eyes. Cute polished 3D character render matching Novadoku's existing Nova mascot style: oversized expressive head, subtly fluffy sculpted fur (penguin soft down), luminous expressive eyes with clean white catchlights, tiny nose, joyful gentle smile, premium soft studio lighting with a faint lavender rim. Front-facing centered isolated head and small upper-chest bust, character fills about 80% of square canvas, at least 8% transparent margin beyond all ears/fur. True transparent RGBA background; no scene, ground, circle, frame, text, letters, logo, symbols, props, confetti, watermark or extra animals. Distinct recognizable bear anatomy, consistent cute proportions and level of finish with the white/purple Nova character. This is a new bear avatar, do not reproduce or alter Nova. Production game icon with crisp silhouette and natural friendly expression.

## Verification

`flutter analyze`: no issues. The final focused run passed all 52 Profile, existing Home, level-selection, Nova-video and UI-audit tests. Profile coverage includes all 64 avatar/frame serialization combinations, Unicode names, offline alpha assets, restoration after a fresh provider/journal instance, corrupt-generation fallback, failed-write recovery, ordered writes, preview-only drafts, Close/Back/outside cancellation, duplicate Confirm guards, all choices, seven compact language layouts, replay-selection preservation and exact Home geometry during keyboard appearance/dismissal. Rendered modal/frame/Home previews were reviewed with the real fonts and icon font loaded.

All requested artwork is present. Physical-device frame pacing and perceived keyboard/startup latency are unverified. No production build was created.

## Profile visual refinement (2026-11-20)

Only the existing Profile modal and Home profile icon were changed. Avatar selection tiles are frameless; only the selected avatar has a purple selection border and checkmark. Each animal retains its original offline artwork on its own reference color:

| Nova | Panda | Fox | Bunny | Lion | Koala | Penguin | Bear |
| --- | --- | --- | --- | --- | --- | --- | --- |
| #E9DDFB | #D5EDD2 | #FFE0AD | #FAD6E6 | #FFE8A3 | #D6E3F5 | #CDEDEC | #EFD6BE |

Frame tiles contain only a clean rounded frame and a quiet custom vector Nova paw; no animal images are rendered in that grid. Only the selected frame has a checkmark. The live profile preview still combines the draft avatar and frame. Previous enum IDs, defaults, serialization and journal saves remain valid.

The name field keeps an assistive username label but no visible floating label. A custom shaded game-style edit tool replaces the stock pencil glyph. Home paints the avatar's individual background and chosen frame directly in the existing icon footprint, without the outer white card or backing shadow; the frame stroke defines its outer boundary. Profile layout, press/selection animations, fonts, sound feedback, central Nova and all video players are unchanged.

Verification: flutter analyze reports no issues. All 52 focused Profile, Home, replay-selection, Nova-video and UI-audit tests passed, including avatar-grid absence of permanent frames, eight unique backgrounds, paw-only frame-grid composition, hidden username label, custom edit glyph, preview/cancel/Confirm/persistence, keyboard-stable Home geometry and seven compact language layouts. Avatar/frame/Home captures were visually reviewed against the supplied reference. No artwork was regenerated and no production build was created. Physical-device frame pacing remains unverified.
