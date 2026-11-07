# Minigames

Day 1 is the one-button tutorial. The following daily assignments are defined in
`app/lib/challenges/games/game_catalog.dart`:

| Day | Game | Default difficulty |
| --- | --- | --- |
| 2 | Paare finden | Klassisch |
| 3 | Kugellabyrinth | Klassisch |
| 4 | Rettet den Weihnachtsmann! | Klassisch |
| 5 | Weihnachtsglocken | Klassisch |
| 6 | Nikolausstiefel | Klassisch |
| 7 | Plätzchen ausstechen | Klassisch |

All other days keep their placeholders. The sample repository still marks days
3 and 5 as complete so replay can be tried. Progress stays in memory and resets
with an app restart; this change does not introduce persistence or hardware calls.

## Development preview

Tap **Spiele ausprobieren** on the calendar, choose **Leicht**, **Klassisch** or
**Knifflig**, and launch any game. Preview victories do not change daily progress.
The menu is available in debug/profile builds independently of the date and the
all-doors override. In release builds it is hidden unless explicitly enabled:

```sh
cd app
flutter run --profile --dart-define=SHOW_GAME_PREVIEW=true
```

Date restrictions can be tested while keeping the preview menu:

```sh
flutter run --dart-define=PREVIEW_ALL_DAYS=false
```

To hide the menu, use `--dart-define=SHOW_GAME_PREVIEW=false`.

## Difficulty and reusable levels

| Game | Leicht | Klassisch | Knifflig |
| --- | --- | --- | --- |
| Memory | 26 attempts | 20 attempts | 15 attempts |
| Maze | 4×4, 1 pit, 8 lives | 5×5, 2 pits, 6 lives | 6×6, 3 pits, 4 lives |
| Chimney | 3×3, 12 s preparation, 1.5 s/tile | 4×4, 10 s preparation, 1.1 s/tile | 5×5, 10 s preparation, 0.9 s/tile |
| Bells | 4–8 notes, five melodies | 4–10 notes, six rounds | 4–10 notes, seven rounds |
| Cookie cutting | Star, 6 points, 1.3 s window | Tree, 9 points, 0.8 s window | Snowflake, 12 points, 0.46 s window |
| Shoe | Broad brush, light mud | Regular brush, thick mud | Smaller brush, stubborn mud |

`MemoryLevel`, `MazeCourse`, `ChimneyLevel`, `BellsLevel` and `ShoeLevel` can also be passed directly into their
screens. Optional random seeds reproduce card shuffles; maze
layouts are seeded by default. Custom `MazeLayout` objects can be supplied as a
course. Normal retries create a new shuffled deck; a configured seed repeats
the same level. Each maze challenge contains exactly one board. Retries restart that board and
restore lives. Daily maze seeds derive from the day number, so future maze days
can use distinct, repeatable layouts. `buildMinigame` also accepts `mazeSeed`
for development previews or explicit configuration.

Memory always has sixteen cards and eight pairs. An attempt means selecting two
cards. Mismatches remain visible for a second, during which extra card input is
blocked. A final successful pair can win on the final attempt.

The maze uses acceleration, drag, capped velocity, collision response and small
physics substeps in normalized coordinates. Seeded spanning-tree candidates are scored for substantial route length, turns
and forks. Raised green rails make the walls easier to read. A checkered flag
on a square green finish pad marks the goal; entering that zone completes the
day at any speed. Hazards are ragged black pits with muted crosses and small
cracks, without a reward-like border or glow. Hazards are on straight sections of the actual start-to-flag route, offset
slightly to alternating sides. Following the corridor centre encounters them;
steering into the opposite passing lane avoids them. Hazards are spaced apart
and stay clear of the start, finish and tight corners. Falling resets the
ball and consumes one life. Reaching the flag completes the day immediately; there is no stage transition.

## Rettet den Weihnachtsmann! (Day 4)

Tap copper pipes to rotate them clockwise. Join the snowy rooftop entrance at
the upper left to the fireplace at the lower right. A countdown bar shows the
preparation time. Santa then moves visibly from edge to centre to exit in each
pipe; pipes ahead can still be rotated, while his occupied pipe is locked.
Disconnected entrances and exits off the board lose the round. Only
exiting the final tile toward the fireplace wins. Results use the shared modal
completion/retry cards. Retry generates a fresh solvable puzzle.

`ChimneyLevel` configures grid size (3–6), preparation seconds, seconds per tile,
and an optional reproducible seed. The screen increments a configured seed on
retry. `ChimneyPuzzle` carves a route first, assigns matching straight/corner
shapes, then scrambles every route tile. Decorative tiles can also form alternate
routes: `ChimneyGame` follows actual reciprocal connections rather than the
stored generating solution. Two-port pipes keep Santa's next direction unambiguous.
The model consumes elapsed time across boundaries and checks connections as
Santa enters each tile. The UI pauses time under help or in the background,
disposes its ticker on exit, and caps long stalled frames to preserve reaction time.
All illustrations are native vector drawings; no dependencies were added.

## Weihnachtsglocken (Day 5)

Listen to the recorded chimes and repeat the note order at your own pace.
Mistakes allow unlimited attempts; replay and repeat-listening are always
available. See [melodies, sample sources and preview controls](bell-melodies.md).

## Nikolausstiefel (Day 6)

Rub over the illustrated muddy boot with a finger or mouse. Dirt clears locally
along each stroke; stationary taps and scrubbing outside the shoe do nothing.
All dirty areas must be brushed before the polishing stage starts. Rub across
the whole boot again to finish polishing and reveal Nikolaus treats. There is
no countdown or failure penalty. Completion uses the same callback and progress
repository as the other games, and replay never removes a previous completion.

The pure Dart `ShoeGame` owns a normalized shoe mask, seeded mud patches, brush
radius, dirt strength, and polishing coverage. `ShoeScreen` draws the boot and
maps pan gestures into normalized strokes, including fast initial swipes. A
screen-reader action can brush the next remaining area using the same rules.
Day 6 also has a boot illustration on its calendar door. All art is vector code;
there are no additional assets, packages, hardware calls or permissions.

## Plätzchen ausstechen (Day 7)

The pastry wheel follows a closed, arc-length-measured outline. A direction cue
appears before each marked checkpoint. Its ring and marker turn green during
the timing window; press the matching arrow then. Touch input fires on pointer
down, with arrow-key and screen-reader actions using the same rules. Held keys
do not repeat inputs. Correct inputs progressively reveal the cut groove.

Wrong directions, early inputs and missed windows each count as one mistake.
After a short feedback pause, the wheel approaches that same checkpoint again;
previous cuts remain complete. Input during recovery is ignored, so a burst of
taps cannot consume all attempts. Three mistakes end the attempt. Every
checkpoint must be cut successfully and the final outline closed to win.
The finished biscuit lifts from the dough before the shared completion overlay
appears. Replay keeps the day's saved completion.

`CookieLevel` configures shape, perimeter fractions per second, checkpoint count,
full timing-window duration and mistake limit. Defaults are star / 0.035 / 6 /
1.3 s, tree / 0.05 / 9 / 0.8 s and snowflake / 0.075 / 12 / 0.46 s, all with a
three-mistake limit. Windows must not overlap neighbouring checkpoints.
`CookieOutline` provides the same polygon, arc lengths, positions and tangents to
the pure Dart rules and native drawing code. Directions follow the dominant
component of the tangent at each checkpoint. No randomness or engine is needed.

**Spiele ausprobieren** exposes all three shapes through the existing difficulty
selector. Help and backgrounding pause timing; **Weiter** explicitly resumes,
so returning never costs a missed window. Long stalled frames are capped at
100 ms to preserve a chance to react. Reduced motion removes shake, scale and
rotation and skips the lift animation. All UI remains German and fits without
vertical scrolling. No new dependencies, assets, audio or hardware calls.

Tests cover outline closure and sampling, tangent directions, all-level solvability,
exact timing boundaries, early/wrong/missed inputs, recovery, custom limits,
immediate pointer-down input, keyboard control, lift-before-save ordering,
completion/replay, pause/resume and every difficulty at small/large text sizes.

## Motion input

Android streams the gravity sensor, or a filtered accelerometer when gravity is
unavailable, through `advent_calendar/tilt`. The small Kotlin adapter maps readings
into the display orientation. No extra package, motion permission or internet
access is needed. The first reading establishes a neutral posture; **Diese
Haltung als Mitte setzen** recalibrates it. Tilt gently from that position.

Choose **Pfeile** for held touch controls or use keyboard arrow keys. Devices
without the Android adapter, missing sensors, and streams that stop producing
readings automatically fall back to these controls. The pure Dart physics does
not know where input comes from. Physics and subscriptions pause when the app
leaves the foreground, and are disposed when leaving the game. A stopped game
does not retain movement accumulated while in the background.

Sensor behaviour follows the Android [motion sensor documentation](https://developer.android.com/develop/sensors-and-location/sensors/sensors_motion).
The Flutter boundary uses [platform channels](https://docs.flutter.dev/platform-integration/platform-channels).
Actual tilt feel should be checked on a physical Android phone; automated tests
exercise injected sensor streams, orientation handling is implemented natively,
and the emulator can be played with touch controls.

## Visual guidance

Games show their board, essential counters and direct controls. Full rules are
available through the **Anleitung** question-mark button rather than a default
paragraph. Restart is an icon in the app bar; previous completion is a checkmark.
The shoe demonstrates rubbing with a brief swipe cue, which disappears after a
drag and returns for the polishing stage. Maze arrow controls visibly highlight
while held. Calibration and missing-sensor information use icons with German
tooltips. Full instructions remain available in optional help. Success cards show a short celebration
and actions, with save details visible only if an error needs attention.

## Fixed-screen layout and results

Pages are fixed game scenes, with no vertical scrolling. `ViewportFit` scales a
scene down only when its content exceeds the available space. The calendar's
horizontal day carousel remains scrollable; the preview uses a fixed card grid.

Success and failure cards use `GameResultLayer`: a foreground card over a dimmed,
input-blocked game, including the app bar. The card contains replay/retry and
**Zurück zum Kalender** controls. Result content also fits the viewport and does
not require a swipe to reach its buttons. Background controls are excluded from
interaction while the result is visible. Day 1 uses this same result layer while
retaining its existing completion-write flow.

## Completion and separation

All implemented challenges accept the same `ChallengeCompletion` callback.
Only the calendar flow supplies a callback to `ProgressRepository.markCompleted`.
The preview supplies an isolated callback. No game imports the Pico/lock boundary.
A win reports completion once; failed saves can be retried without solving again.
Replays, losses and resets never clear a previous completion.

- `memory/memory_game.dart`, `maze/maze_game.dart`, and
  `shoe/shoe_game.dart`, and `chimney/chimney_game.dart`: Flutter-independent rules and simulation.
- `*_screen.dart`: German game UI, controls and animations.
- `maze/tilt_source.dart`: injectable sensor interface and platform adapter.
- `games/game_widgets.dart`: shared completion/save feedback and screen styling.
- `games/game_catalog.dart`: daily assignments and configured game factories.

Tests cover game limits, final-attempt victories, mismatches, maze walls and hazards,
physically traversable generated routes at every difficulty, route-relevant
hazards and passing clearances across multiple seeds, sensor input,
replay, save retry, preview isolation and small-screen layouts with large text.

Chimney tests traverse 400 seeded solutions across all supported grid sizes,
check reciprocal ports and boundary failures, timing and live repairs, completion,
replay, paused help, daily routing, preview and fixed-screen layouts.
