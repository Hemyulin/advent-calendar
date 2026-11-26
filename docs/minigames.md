# Minigames

Day 1 starts with easy Memory. The following daily assignments are defined in
`app/lib/content/calendar_schedule.dart`:

| Day | Game | Difficulty | Appearance |
| --- | --- | --- | --- |
| 1 | Paare finden | Leicht | Weihnachten |
| 2 | Plätzchen ausstechen | Leicht | Weihnachten |
| 3 | Kugellabyrinth | Leicht | Weihnachten |
| 4 | Oy Vey, Weihnachten! | Leicht | Original |
| 5 | Paare finden | Klassisch | Chanukka |
| 6 | Nikolausstiefel | Klassisch | Weihnachten |
| 7 | Plätzchen · Zweiter Tempel | Klassisch | Chanukka |
| 8 | Akku-Panik | Leicht | Weihnachten |
| 9 | Rettet den Weihnachtsmann! | Klassisch | Weihnachten |
| 10 | Chanukka-Klänge · Maoz Tzur | Leicht · alle Hinweise | Chanukka |
| 11 | Ein Glühwein zu viel | Klassisch | Weihnachten |
| 12 | Öl-Panik | Klassisch | Chanukka |
| 13 | Kugellabyrinth | Klassisch | Weihnachten |
| 14 | Wichtelwerkstatt | Leicht | Weihnachten |
| 15 | Weihnachtsglocken · Jingle Bells | Klassisch | Weihnachten |
| 16 | Paare finden | Knifflig | Weihnachten |
| 17 | Rettet den Weihnachtsmann! | Knifflig | Weihnachten |
| 18 | Wichtelwerkstatt | Klassisch | Weihnachten |
| 19 | Ein Glühwein zu viel | Knifflig | Weihnachten |
| 20 | Plätzchen ausstechen | Knifflig | Weihnachten |
| 21 | Kugellabyrinth | Knifflig | Weihnachten |
| 22 | GOY vey! | Knifflig | Weihnachten sammeln |
| 23 | Wichtelwerkstatt | Knifflig | Weihnachten |
| 24 | Weihnachtsglocken | Knifflig | Weihnachten |

Appearance is assigned per door, independently of the date. Early doors introduce
mechanics; later doors revisit them at higher difficulty. The ten original game types have
appeared by day 14; Day 22 introduces the reversed GOY vey variant. The final
five challenges are hard. Repeat appearances
leave at least three intervening games, including across different skins.
Difficulty never decreases on a later appearance. Explicit admin assignments
remain preserved. The editor can select
appearance and, for bells, a specific melody independently of guidance/difficulty.

Game assignments, calendar wins and achievement progress persist locally. A new
installation starts without sample completions. Replay can earn missing bonus
objectives without resetting completion or issuing another physical unlock.
See [achievements](achievements.md) for the 30 required bonus objectives, difficulty
practice routes, hidden voucher configuration and persistence details.

## Development preview

Open **Advent-Verwaltung → Spiele testen**, choose **Leicht**, **Klassisch** or
**Knifflig**, and launch any game. Open admin by tapping the homepage title five
times within three seconds, then entering the development PIN `0542`.
Preview victories do not change daily progress. The homepage has no preview controls.

Date restrictions are on by default with ordinary `flutter run`.
**Alle Türchen freischalten** in admin is the explicit persisted test override.
Turning it off restores date rules without clearing progress. Achievement
practice respects [game, difficulty and melody reservations](progression.md).

## Difficulty and reusable levels

| Game | Leicht | Klassisch | Knifflig |
| --- | --- | --- | --- |
| Memory | 26 attempts | 20 attempts | 15 attempts |
| Maze | 5×5, 3 candies, 3 pits, 6 lives | 6×6, 3 candies, 4 pits, 4 lives | 8×8, 7 candies, 13 pits, 4 lives |
| Chimney | 3×3, 12 s preparation, 1.5 s/tile | 4×4, 10 s preparation, 1.1 s/tile | 5×5, 10 s preparation, 0.9 s/tile |
| Bells | Carol of the Bells hook, all notes shown | Last Christmas hook, first note shown | All I Want for Christmas Is You hook, audio only |
| Cookie cutting | Star, 6 points, 1.3 s window | Tree, 9 points, 0.8 s window | Snowflake, 12 points, 0.46 s window |
| Workshop | 6×6, 2 presents | 7×7, 3 presents | 8×8, 4 presents |
| Oy Vey | Slower falling objects | Standard falling objects | Faster falling objects |
| Shoe | Broad brush, light mud | Regular brush, thick mud | Smaller brush, stubborn mud |
| Walk home | 32 s, wide path, gentle wobble | 37 s, regular path and wobble | 42 s, narrow path, stronger wobble |
| Battery | 45 s, slower drain, fewer events | 45 s, standard drain and events | 45 s, lower initial charge, faster drain and events |

`MemoryLevel`, `MazeCourse`, `ChimneyLevel`, `BellsLevel` and `ShoeLevel` can also be passed directly into their
screens. Optional random seeds reproduce card shuffles; maze
layouts are seeded by default. Custom `MazeLayout` objects can be supplied as a
course. Normal retries create a new shuffled deck; a configured seed repeats
the same level. Each maze challenge contains exactly one board. Retries restart that board and
restore lives. Each difficulty resolves one shared curated layout everywhere:
Leicht uses seed 1224, Klassisch 1234 and Knifflig 1242. Calendar doors, admin
previews and achievement replays therefore show the same distinct 5×5 / 6×6 /
8×8 maps. `buildMinigame` still accepts an explicit `mazeSeed` for custom layouts.

Memory always has sixteen cards and eight pairs. An attempt means selecting two
cards. Mismatches remain visible for a second, during which extra card input is
blocked. A final successful pair can win on the final attempt.

The maze uses acceleration, drag, capped velocity, collision response and small
physics substeps in normalized coordinates. Seeded spanning-tree candidates are scored for substantial route length, turns
and forks. Raised green rails make the walls easier to read. A checkered flag
on a square green finish pad marks the goal; entering that zone completes the
day at any speed. Hazards are ragged black pits with muted crosses and small
cracks, without a reward-like border or glow. The three curated layouts use the
manually marked candy/hole positions. Leicht and Klassisch each have three
candies, with three and four holes respectively. Knifflig uses the final marked
8×8 layout, with seven candies and thirteen holes. Every candy is required for
that difficulty's optional candy objective, including all seven on Knifflig.
Other seeds retain procedural placements appropriate to their different walls
(two/three/four holes). The hand-positioned boards are checked for wall clearance
and continuous ball-sized paths to every collectible and the flag.
Procedural hazards are on straight sections of the actual start-to-flag route, offset
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
The approaching arrow turns gold, then green during its timing window; swipe
in the matching direction then. Completed arrows fade into the cut. There is no
floating direction badge, countdown ring or direction-button row. Swipe across
the dough in the arrow direction, or use keyboard arrow keys. A swipe registers
as soon as its direction is clear, with one input per gesture. Both inputs obey
the same timing windows. Held keys
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

Move the elf one tile with a swipe or a keyboard arrow key. Push
presents onto all golden bow-marked target mats. Wooden crates are walls;
presents block each other and can only be pushed, never pulled. A goal mat
turns green and the present gains a checkmark when occupied. The short movement
and arrival animations respect reduced-motion settings. Completion uses the
shared foreground result and callback; replay never clears earlier completion.

The three curated boards have 6×6 / 2-present, 7×7 / 3-present and 8×8 /
4-present layouts. Independently solved move-optimal push-state searches found
solutions requiring 18 / 38 / 65 moves and 5 / 13 / 21 pushes. Witnesses in
`app/test/helpers/workshop_solutions.dart` are replayed against the real model.
The easy board requires circling an internal wall; simply pushing a box toward
the boundary deadlocks it. The larger boards require staging presents outside a
shared storage chamber and planning the filling order. Undo makes this safe to explore.

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

## Oy Vey, Weihnachten! (Day 4)

The mirrored front camera drives a narrow-necked sack using mouth position.
Horizontal head movement is amplified 1.7×, so the player can reach the edges
without leaving the frame. The opening uses 4.2–6.5% of the frame width as its
half-width, matching the collision ellipse. The burlap sack has a crossed-out
“Weihnachten” label with handwritten Hebrew “חנוכה” underneath. Catch 15
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
the game and sets a new centre. Dragging left/right directly on the street
(hold the displacement to keep steering) and keyboard arrows are the fallback. Sensor errors or three seconds without readings pause play and offer
touch controls. Help and backgrounding freeze the simulation; returning requires
explicit resume, with fresh calibration for sensors. Replay preserves completion.
`walk_art.dart` draws the street, character, obstacles and ending animations using
Flutter painters, with reduced-motion support and no additional dependencies.

Tests cover recoverable collisions, ice, sustained falls, seeded route clearance,
successful controlled navigation at every difficulty, calibration, sensor loss,
held controls, lifecycle pauses, completion/replay and responsive layouts.

## Akku-Panik (Day 8)

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

Choose **Touch** and drag directly on the maze to steer; hold the displacement
to keep rolling and release to return to neutral. Keyboard arrow keys also work. Devices
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
paragraph. Every game title is written in bundled Grenze Gotisch lettering on a subtly curled,
vector-drawn parchment in a safe-area footer below the play area,
leaving the app bar for navigation, restart, help and completion
status. Long titles wrap rather than competing with those actions.
The shoe demonstrates rubbing with a brief swipe cue, which disappears after a
drag and returns for the polishing stage. Workshop and cookie controls use
swipes; maze and walking touch controls use direct dragging, without visible
direction buttons. Calibration and missing-sensor information use icons with German
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
interaction while the result is visible. First victories show a tappable illustrated
gift. The shared lid-lift animation runs on tap, with reduced-motion support.
Saving progress happens on victory; tapping the gift is a separate reward action.
The victory card is present-first: a large illustrated gift and **Zum Öffnen
tippen** form one tappable area. A small **Noch einmal spielen** text control
sits at the top right; **Zurück zum Kalender** is a muted text link below.
Game messages appear after the gift reveal. Newly earned achievements use an
automatic illustrated toast and stay visible inside the modal with their own
art and title. Multiple badges use a horizontal pager without vertical scrolling.
Every win also gets a finite, pointer-transparent confetti burst, including wins
without a new badge; reduced-motion settings skip flying particles. The present
remains the main action. Save/retry and duplicate-opening protection
remain shared by every game.

Replay wins show **Großartig!** with the game's success message, replay and calendar
actions. They have no gift to tap and never call the gift/box action. This applies
to reopened completed doors, successive attempts in the same visit and seasonal
replays. First victories retain the gift reveal; replay achievements still save
and celebrate normally.

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


## Gift and box handoff

`CompletionPanel` shows the shared gift after every win, with no changes inside
individual games. `GiftRewardScope` supplies a daily reward action from the
calendar route; absent that scope, standalone tests and development previews
reveal a virtual gift only. A gift cannot be tapped while progress is saving or
if saving failed. Once saved, repeated taps start only one reveal.

`ChallengeCompletionHandler.openGift` is separate from its completion LED
acknowledgement. Only a newly completed door can request physical opening;
replays show congratulations without a gift. `PicoService` implements
`LockGateway` and is shared with admin controls. A fresh DoorZero health check
precedes a bodyless `POST /unlock`; JSON `success: true` confirms that the
five-second GPIO 15 pulse completed. The restored firmware waits synchronously
and switches LOW in `finally`. The app allows seven seconds for its reply.
See [configuration](../README.md#pico-network-configuration).

**Box erneut öffnen** on this result screen explicitly requests another pulse if
the opening window was missed, or the previous attempt was unconfirmed. It does
not replay the gift animation, save progress again or issue another LED ack.
Concurrent taps share one request. Replays of completed games cannot unlock.
Leaving, errors and reconnecting do not automatically resend a command.
Calendar assignments saved with the retired `tutorial` identifier load
as easy Memory without clearing completion state.

## Gentler attempts and Müll rausbringen

Calendar challenges offer **Zu schwer?** in the app bar and on defeat. **Etwas
leichter** restarts only the current attempt at the next easier difficulty. At
Leicht, the trash alternative remains available. For cookies, the same shape and
checkpoint count stay in place: speed becomes 65% and timing windows 150% of the
original. It can be relaxed once per attempt. Gentler wins complete their door,
but do not report strict bonus feats or completed-song milestones.

**Lieber Müll rausbringen** replaces this attempt with a kitchen chore. The
kitchen bin visibly contains loose rubbish and an open liner. Swipe upward to
lift it, then keep holding while carrying it to the door. Entering the doorway
opens the door and carries the bag outside without requiring a release. Outside,
drag/swipe the carried bag into the outdoor wheelie bin. Letting go of a lifted
bag elsewhere makes it fall, scatter rubbish and leave dirty splashes before the
normal retry card appears. Sideways swipes do not lift the rubbish, and OS
interruptions restore the carried item without penalizing the player.

The spare roll is already on the kitchen counter at the start. Tilting the phone
rolls it along the counter with damped momentum and rotation; it stays within the
counter edges. After throwing the rubbish away, the kitchen returns without
instructions, progress text, highlights or help explaining the remaining task.
Discover the roll and drag a fresh liner into the empty bin to finish. Removing
the rubbish alone never finishes the game. The fresh liner animates into place
before the normal result appears. Replay preserves prior completion.

The original calendar sequence is unchanged. Alternative wins count for that
day and for the trash game, never for the replaced game's bonuses. Trash is also
available through **Spiele testen**. It has no time limit, theme toggle, new
dependencies or Pico code. Motion reuses the shared tilt channel (Android gravity
sensor / iOS Core Motion); missing sensors leave the roll draggable in place.
Subscriptions and motion stop on backgrounding, covering the route, completion
and disposal. Physics are suspended while the roll is grabbed. Pure rules live in
`trash_game.dart`; sensors, gestures, rendering and finite throw/finish animations
live in `trash_screen.dart`.

## GOY vey! (Day 22)

The Christmas-only counterpart reuses Oy Vey's local camera, head-position
tracking, collision checks and difficulty settings. Trees, Santa hats and candy
canes are targets; Sufganiyot, Sevivonim and Chanukkiot are mistakes. Collect 15
targets to win; three mistakes lose. Seventy percent of generated items come
from the current target pool in either version, and the outstanding-target cap
still prevents spawning more than needed. Mouth opening is never required.

The sack crosses out חנוכה and labels itself Weihnachten. Wins report through the
shared completion mechanism and replay preserves the variant. The regular
**Ganz schön weihnachtlich** achievement requires a win without catching any
Hanukkah object and has its own illustrated catching scene. Its launch button
starts GOY vey, not the original Oy Vey. Both are available in development preview.

The Chanukka cookie's medium outline now depicts the Second Temple, with eight
shallow roof points with 90-degree tips, a raised sanctuary, broad wings and stepped foundation.
The cutter follows the actual zigzag polygon; gameplay settings remain unchanged.
