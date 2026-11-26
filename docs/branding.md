# Icon, splash and welcome

The source artwork is `app/assets/branding/advent-icon.png`: an ivory background,
a large, centered forest-green chest with a slightly lifted lid and warm gold light. There is no star or lettering.
It is shared by the Flutter loading/welcome view and native launch screens.

Android has density-specific launcher icons, adaptive-icon safe padding and native
launch resources for pre-Android 12 and Android 12+. iOS has its complete icon set
and centered launch image. macOS, Windows and web icons use the same source. The
web loading screen disappears on Flutter's first frame. No splash delay or new
runtime dependency was added.

Regenerate all image sizes on macOS after replacing the source:

```sh
python3 app/tool/export_branding.py
```

Fully rebuild/relaunch the app to see native icon or splash changes; hot reload
only updates Flutter content. Launchers may cache icons until reinstallation.

## First launch

`WelcomeGate` reads `welcome.seen.v1` from the existing shared preferences store.
The German welcome greets Schlizi personally and is signed
“Dein Lieblingsmann, ps ich dich auch”. It introduces daily puzzles, **Auszeichnungen**, the extra gift
for all regular awards, and secret awards excluded from that requirement.
**Türchen entdecken** dismisses it and persists that choice. Preferences failures
do not prevent opening the app. Calendar progress and award rules are unchanged.
The layout never scrolls vertically and keeps the continue button outside its
fitted copy. Short screens and large text use three short horizontal pages,
with **Weiter** navigation, instead of shrinking the entire welcome into a column.

## Artwork provenance and prompts

Generated and edited with the built-in imagegen tool, then resized for platform
requirements using macOS `sips`. No image-generation API credentials or extra app
dependencies are needed.

Initial prompt:

> A minimal Scandinavian Christmas app icon: one slightly open forest-green
> Advent door revealing muted-gold light, with a small gold four-point star above.
> Warm ivory #FFF8EE, green #315F50, gold #AB762C. Clean, restrained, generous
> negative space; no text, numbers, border, mockup or extra ornaments. Square.

Final edit prompt:

> Remove ONLY the gold four-point star above the door, replacing the star area
> with the same warm ivory background. Preserve the green door illustration,
> gold light, gold knob, colors, subtle texture, size and composition exactly.
> Do not add anything. No star, no text. Keep the image square and opaque.

Chest redesign prompt (built-in imagegen, using the previous icon as a style reference):

> Replace the door with one minimalist forest-green treasure chest, muted-gold
> trim and latch, its lid slightly lifted to reveal a thin warm golden glow.
> Keep the Scandinavian aesthetic and ivory #FFF8EE, green #315F50, gold #AB762C
> palette. Center the full silhouette horizontally and vertically, occupying
> about 76–80% of the square's width and 60–65% of its height. Balanced modest
> whitespace above and below; simple crisp shapes, subtle handcrafted finish,
> slight three-quarter perspective. No wood grain, pirate symbols, coins, stars,
> sparkles, text, numbers, border or mockup. Square opaque artwork.
