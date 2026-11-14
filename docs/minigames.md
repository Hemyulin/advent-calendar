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
| 8 | Wichtelwerkstatt | Klassisch |
| 9 | Oy Vey, Weihnachten! | Klassisch |
| 10 | Ein Glühwein zu viel | Klassisch |
| 11 | Akku-Panik | Klassisch |

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
| Bells | Carol of the Bells hook, all notes shown | Last Christmas hook, first note shown | All I Want for Christmas Is You hook, audio only |
| Cookie cutting | Star, 6 points, 1.3 s window | Tree, 9 points, 0.8 s window | Snowflake, 12 points, 0.46 s window |
| Workshop | 5×5, 2 presents | 7×7, 3 presents | 8×8, 4 presents |
| Oy Vey | Slower falling objects | Standard falling objects | Faster falling objects |
| Shoe | Broad brush, light mud | Regular brush, thick mud | Smaller brush, stubborn mud |
| Walk home | 32 s, wide path, gentle wobble | 37 s, regular path and wobble | 42 s, narrow path, stronger wobble |
| Battery | 45 s, slower drain, fewer events | 45 s, standard drain and events | 45 s, lower initial charge, faster drain and events |

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

Listen to a recognizable 4–5 second hook played on recorded chimes and repeat
the note order at your own pace. Easy uses simple repeated-note patterns and
demonstrates every bell. Medium uses wider intervals and only shows the first
bell. Hard adds a chromatic pitch and varied intervals with no visual pitch hints.
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

The pastry wheel follows a closed, arc-length-measured outline. Small directional arrows sit directly on every checkpoint from the start.
The approaching arrow turns gold, then green during its timing window; press
the matching arrow then. Completed arrows fade into the cut. There is no
floating direction badge or countdown ring. Swipe across the dough in the arrow direction, or use the buttons. A swipe
registers as soon as its direction is clear, with one input per gesture. Button
input fires on pointer-down; arrow-key and screen-reader actions use the same
rules. Swipes obey the same direction and timing windows as the buttons. Held keys
do not repeat inputs. Correct inputs progressively reveal the cut groove.

Wrong directions, early inputs and missed windows each count as one mistake.
After a short feedback pause, the wheel approaches that same checkpoint again;
previous cuts remain complete. Input during recovery is ignored, so a burst of
taps cannot consume all attempts. Three mistakes end the attempt. Every
checkpoint must be cut successfully and the final outline closed to win.
The finished biscuit lifts from the dough before the shared completion overlay
appears. Replay keeps the day's saved completion.

`CookieLevel` configures shape, perimeter fractions per second, checkpoint count,
full timing-window duration and mistake limit. Defaults are star / 0.035 / 10 /
1.3 s, tree / 0.05 / 14 / 0.8 s and snowflake / 0.075 / 18 / 0.46 s, all with a
three-mistake limit. Windows must not overlap neighbouring checkpoints.
`CookieOutline` provides the same polygon, arc lengths, positions and tangents to
the pure Dart rules and native drawing code. Arrow directions are randomized independently of the outline on every new
attempt and stay fixed during recovery. A seeded random source can be injected
for repeatable tests. No engine is needed.

**Spiele ausprobieren** exposes all three shapes through the existing difficulty
selector. Help and backgrounding pause timing; **Weiter** explicitly resumes,
so returning never costs a missed window. Long stalled frames are capped at
100 ms to preserve a chance to react. Reduced motion removes shake, scale and
rotation and skips the lift animation. All UI remains German and fits without
vertical scrolling. No new dependencies, assets, audio or hardware calls.

Tests cover outline closure and sampling, randomized directions, all-level solvability,
exact timing boundaries, early/wrong/missed inputs, recovery, custom limits,
immediate pointer-down input, keyboard control, lift-before-save ordering,
completion/replay, pause/resume and every difficulty at small/large text sizes.

## Wichtelwerkstatt (Day 8)

Move the elf one tile with a swipe, a direction button or an arrow key. Push
presents onto all golden bow-marked target mats. Wooden crates are walls;
presents block each other and can only be pushed, never pulled. A goal mat
turns green and the present gains a checkmark when occupied. The short movement
and arrival animations respect reduced-motion settings. Completion uses the
shared foreground result and callback; replay never clears earlier completion.

The three boards are handcrafted 5×5 / 2-present, 7×7 / 3-present and 8×8 /
4-present layouts. Independently solved push-state searches found solutions
requiring 12 / 31 / 73 moves and 2 / 6 / 12 pushes. Witnesses in
`app/test/helpers/workshop_solutions.dart` are replayed against the real model.
The small board includes an ordering trap: filling one target too early blocks
access needed to place the other present. Undo makes this safe to explore.

`WorkshopLevel` parses reusable square ASCII boards with `#` walls, `.` targets,
`$` presents and `@` elf; `*` and `+` represent occupied targets. Board data is
immutable. `WorkshopGame` validates walking and pushing and records snapshots
only for legal moves. **Rückgängig** restores elf position, stable present IDs,
facing and move/push counters. The app-bar restart resets the same board. There
is no move limit, random puzzle generation or forced deadlock detection.

`WorkshopScreen` renders native vector art and animates stable pieces between
tiles. Each swipe produces exactly one move. **Spiele ausprobieren** exposes all
boards through the existing difficulty selector, independent of device date.
Tests cover every solution, illegal moves, pushing without pulling, target
occupancy, full undo histories, reset, gestures/keyboard, completion/replay and
small-screen layouts with enlarged text. No dependencies or hardware calls added.

## Oy Vey, Weihnachten! (Day 9)

The mirrored front camera drives a sack at the mouth position. Catch 15
Hanukkah objects and avoid swallowing three Christmas objects; opening the mouth
is unnecessary. Tracking loss hides the sack while objects keep falling, and
collection resumes automatically when the face returns. Local capture, frame conversion and face-mesh
processing adapt Brush Buddies; game rules remain independent. The preview
includes an explicitly labelled camera-free test driver. See
[reuse, position tracking, privacy and device testing](oy-vey.md) for details.

## Ein Glühwein zu viel (Day 10)

Balance a scarf-wearing character on an automatically scrolling winter street.
Lean left/right to counter the sway and steer past snowmen, bicycles, bins,
sleeping revellers and ice. The protagonist has shoulder-length blonde hair.
Each attempt randomly starts in daylight or at night. A sun/moon button switches
between snowy daylight and a lantern-lit night scene. Collisions give a
recoverable shove; ice briefly reduces grip. Sustained
overbalancing or walking off the path causes a fall. Reach the warm house to win.
Falling and arrival animate before the shared foreground result card appears.

`walk_home/walk_game.dart` contains the Flutter-independent simulation and seeded
obstacle generation. `WalkLevel` configures duration, path width, wobble, obstacle
spacing, lean limit, recovery grace and an optional seed. Every obstacle leaves
a passing gap. Fixed small physics steps and smoothly varying disturbances keep
corrections responsive; long stalled frames are capped. The three difficulty
presets are available in **Spiele ausprobieren** without changing daily progress.

`walk_screen.dart` reuses the maze's injectable `TiltSource` and native adapter.
Eight stable readings calibrate the starting posture; the calibration icon pauses
the game and sets a new centre. Held touch arrows and keyboard arrows are the
fallback. Sensor errors or three seconds without readings pause play and offer
touch controls. Help and backgrounding freeze the simulation; returning requires
explicit resume, with fresh calibration for sensors. Replay preserves completion.
`walk_art.dart` draws the street, character, obstacles and ending animations using
Flutter painters, with reduced-motion support and no additional dependencies.

Tests cover recoverable collisions, ice, sustained falls, seeded route clearance,
successful controlled navigation at every difficulty, calibration, sensor loss,
held controls, lifecycle pauses, completion/replay and responsive layouts.

## Akku-Panik (Day 11)

Drag the loose plug onto the first device to start the round. There is no
start button and tapping devices does not change charging. Once plugged in,
drag from the connected device to another one; unplugged devices cannot act
as cable sources. The loose plug disappears from its initial position, and
the cord stays hidden until dragging or charging. Keep the smartphone, smartwatch, tablet, headphones and laptop alive
for 45 seconds. Five illustrated devices sit at slight angles on one ivory
desk with a few crumbs. The curved cable follows
the finger and snaps into a visible port. Charging lights and bolts mark the
connected device; percentages remain separate from the illustrated screens.
Red batteries warn below 5%. Devices never charge together.

Events appear on the devices themselves: message cards, a training trace,
a playing video, floating musical notes or an update bar. Faces look sleepy,
worried, relieved or switched off. The final ten seconds bring more urgent
expressions; a seven-segment countdown above the desk shows minutes, seconds
and hundredths. Its forest-green digits turn muted red in the last ten seconds. All screens light up together
before the shared victory card appears; a failed device closes its eyes.
Reduced-motion mode removes wobbling and pulses and shows results immediately.

`battery/battery_game.dart` contains the Flutter-independent model. `BatteryLevel`
configures duration, drain, charging rate, event interval/duration/boost, initial
charge range and an optional random seed. Defaults stay within 1–10% initially.
Drain and event frequency increase throughout the round. Collapsed batteries
lose immediately, including on the final frame; otherwise reaching 45 seconds
wins. Seeded retries repeat initial levels/events for testing; normal retries
randomize them. Switching requires a drag from the currently connected device.
Dragging temporarily unplugs the cable. Cancelling a drag returns it to its
previous device; a successful drop charges the new target.

`battery_screen.dart` provides plug drag targets, readouts for accessibility, visual
charging feedback and the shared completion/retry overlays. Help, explicit pause
and backgrounding freeze both charge and events. **Weiter** resumes without
catching up suspended time. Completion and replay use the existing callback;
no persistence, Pico calls or dependencies are added. Optional vibration gives
a small connection click and a distinct warning below 3%, with hysteresis and
a cooldown. Muting and vibration choices stay in place on replay. The optional
final-countdown tick uses Flutter's system click and follows device sound
settings. Vibration starts off; the ticking starts on. Feedback stops while
paused or backgrounded. All difficulties can be launched from
**Spiele ausprobieren**, without changing the device date.

Balance tests exercise 100 seeds per difficulty with cable decisions every
half-second and a 150 ms unplugged interval for each switch. Additional tests cover one-cable exclusivity, event consumption,
expiry, win/loss, bounds, drag-only controls, lifecycle, completion and layouts.

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
On the calendar, a left/right swipe across the main scene selects the next/previous
available door and keeps the carousel selection visible. The carousel itself
continues to scroll independently. Gestures do not wrap past days 1 and 24 or
bypass locked dates, and swiping does not open a challenge.

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
