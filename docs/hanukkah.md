# Chanukka-Modus

Skins are **assigned per calendar door**, never switched automatically by the
current date. Days 5, 7, 9, 10 and 12 have Hanukkah variants; day 4 is Oy Vey.
Day 6 keeps the Nikolaus boot, and days 8/11 remain regular Christmas games.
The [complete sequence](minigames.md) introduces all mechanics by day 15 and
increases difficulty on later revisits, ending with five hard challenges.

Nine games support both appearances. Only **Oy Vey** has no alternate skin.
The David-star button switches appearance and starts a fresh attempt, in real
replays and isolated admin previews. Standalone games default to Christmas;
calendar routes pass the saved door appearance explicitly. No date manipulation
is needed. Admin also supports an optional melody choice, separate from guidance:
day 10 introduces **Maoz Tzur** with all demonstration bells highlighted.

| Game | Chanukka appearance |
| --- | --- |
| Paare finden | Eight illustrated pairs: sufganiyah, chanukkiah, dreidel, shekel, oil jug, David star, Temple and candle. |
| Kugellabyrinth | Existing golden ball, shekel collectibles; identical maze physics and bonus conditions. |
| Rettet den Weihnachtsmann | Eliyahu HaNavi with a long black coat, broad-brimmed hat, sidecurls and spectacles. A plain bank facade with a clearly marked entrance replaces the fireplace. Pipe connections, route validation and rooftop exit stay the same. |
| Wichtelwerkstatt | A mischievous leaf-eared fantasy workshop sprite; same planning puzzles and move budgets. |
| Weihnachtsglocken | Blue ribbons/David-star decorations and three traditional melody hooks. |
| Ein Glühwein zu viel | Ein Kiddusch-Wein zu viel; the blonde protagonist wears a kippa and arrives at a synagogue. |
| Akku-Panik | Öl-Panik: five oil-fed lights, one draggable oil jug, percentage gauges, gust events and identical survival/refill rules. |
| Plätzchen ausstechen | Geographically proportioned combined Israel/Gaza/West Bank/Golan outer silhouette, with the same randomized arrows, timing and difficulty. |
| Nikolausstiefel | Optional Schekel polieren replay: a round dirty coin, followed by a polishing stage. Day 6 defaults to the original boot. |

No additional dependencies, recordings, network calls or Pico commands are used.
The shared `SkinnableGame` recreates its child when switching; it therefore cleans
up the old game's audio, tickers, gestures and sensors normally. Presentation
lives in `challenges/seasonal`; the game models retain their existing rules.
Cookie outlines, bell melodies and the cleaning-surface mask vary as model configuration; the rules stay shared.

## Completion and achievements

The central `CompletionPanel` snapshots the skin together with the won attempt's
facts. `AchievementStore` records one set token per supported game. Switching
appearance, starting a game, losing or repeating an already counted win cannot
inflate progress. Admin previews still have no achievement writer.

**Neun Spiele, ein Lichterfest** requires a win in all nine supported modes at
any difficulty. Its detail page offers real, calendar-independent replays. These
can earn achievements but never complete a calendar door or request a physical
box action. Existing daily completion and the LED acknowledgement retain their
normal shared, once-per-new-completion behavior.

The overall bonus now requires 17 achievements. All 11 curated bell hooks count
for the song collection, bringing the bonus-objective checklist to 29. Rule
version 5 reevaluates only the affected aggregates/song collection; existing
individual badges, daily completion, voucher text and previous voucher claims
remain intact. A previously claimed physical voucher is never offered twice.

## Music data and verification

All melodies use the existing recorded bell samples. The first eight Christmas
hooks stay unchanged. Only note order is judged; rhythm remains demonstration
information, and replaying the hook never plays a full song.

| Difficulty | Hook | Source pitches / adaptation | Guidance |
| --- | --- | --- | --- |
| Leicht | Sevivon, sov sov sov | D D E F F E; opening six notes, 4 beats. | All bells shown. |
| Klassisch | Maoz Tzur | Opening two phrases, D major transposed up a minor third to F major so its low fifth fits existing samples. 15 notes, 16 beats. | First bell only. |
| Knifflig | Hanerot Halalu | The leaping, repeated refrain figure at source beats 20–28, D major. 12 notes, 8 beats. | No demonstration highlights. |

The traditional melody pitches and durations were checked against published
score/MIDI lead voices: [Sevivon](https://www.flutetunes.com/tunes.php?id=670),
[Maoz Tzur](https://www.flutetunes.com/tunes.php?id=4428), and
[Hanerot Halalu](https://www.flutetunes.com/tunes.php?id=676).
The app uses its own bell playback, with no downloaded performances or score
assets bundled. The song library is paged to preserve readable cards.

## Persistence and migration

Calendar schema v3 saves explicit admin overrides (game, difficulty, skin and
optional melody) instead of full snapshots. On loading old 24-entry snapshots,
entries matching the old defaults are replaced by the new sequence. Different
custom games/difficulties are retained. An old edit identical to a previous
default is indistinguishable from a saved default and upgrades with it. Current
v3 edits always stay explicit, even when they match a default. Completion remains
keyed to door IDs and is never reset by this migration.

Achievement rules v6 require the new ninth mode, shekel cleaning, for the seasonal
badge. Previously earned individual badges and voucher claims remain intact;
only the seasonal aggregate/final bonus are reevaluated. Polishing a coin on day
6 does not earn the boot-specific Nikolaus achievement.

## Map source

`cookies/israel_outline.dart` stores 41 simplified, geographically proportioned
points, derived from the outer union of Natural Earth's ISR, GAZ and WEB map
units. Shared internal edges are removed. Longitude is scaled by the cosine of
mean latitude to preserve aspect rather than stretching it to the board width.
The source is the public-domain [Natural Earth 1:50m map-unit data](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_50m_admin_0_map_units.geojson).
Only this static outline is bundled; there is no runtime map/network dependency.
