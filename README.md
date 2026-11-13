# Advent Calendar

A monorepo for an Advent Calendar companion app and Raspberry Pi Pico W
firmware controlling an electronic lock.

## Repository layout

- `app/`: Flutter companion app, initially targeting Android.
- `firmware/`: existing MicroPython code for the Pico W.
- `docs/`: project documentation.

## Run the app

Install Flutter (including Dart 3.10.7 or newer compatible with the pubspec),
the Android SDK, and an Android emulator or connected Android device.
Run `flutter doctor` to check your local setup.
If it reports unaccepted Android SDK licenses, review and accept them with
`flutter doctor --android-licenses` before building.

```sh
cd app
flutter pub get
flutter run
```

The app displays a German Advent calendar with an illustrated door and a
horizontal day carousel. Swipe left or right across the main door to select the
next or previous available day; the carousel also remains independently scrollable. Days 1–11 contain playable challenges; the remaining
days lead to a placeholder challenge screen.
Each day has a festive paper door with a storybook ornament, a rotating warm
colour palette, and fairy lights. Locked doors keep their colour and show a lock
badge. All artwork is drawn in Flutter without image assets or new dependencies.
For design testing, **all 24 doors are currently unlocked by default**. A German
preview label identifies this mode. Each door swings open before showing its
challenge screen; returning to the calendar closes it again. Reduced-motion
settings skip the opening animation. Previewing does not mark a day completed.
Screens fit the viewport without vertical scrolling. Success and failure messages
float above a dimmed game with visible return and replay controls. Only the
horizontal day carousel scrolls.

To restore date-based availability, run from `app/`:

```sh
flutter run --dart-define=PREVIEW_ALL_DAYS=false
```

With preview disabled, availability follows the local date for December of the current year:
future days are locked, today and previous days are accessible, and completed
days can be revisited. Availability refreshes at midnight and on app resume.
Before December all doors are locked; after December 24 all are accessible.

Sample progress marks days 3 and 5 as completed. With preview disabled these
completions only appear once their dates become available. Progress is held in
memory and resets on restart. For development
and tests, `AdventCalendarApp(now: DateTime(2026, 12, 8))` provides a fixed date;
the normal entry point uses the actual device date with the preview override above.

Day 1 contains the one-button tutorial **„Dein erster Weihnachtszauber“**:
go to the calendar, tap **„Überraschung öffnen“**, and watch the illustrated
present unwrap. The opening is simulated; no physical lock or sound is triggered.
Completion is recorded through the progress repository after the reveal and
updates the calendar checkmark on return. Leaving before the reveal finishes
does not complete the day. Completed tutorials can be replayed.

Day 2 has **Paare finden** (4×4 Memory) and Day 3 **Kugellabyrinth** (one sensor-
or touch-controlled maze per day). Day 4 has **Rettet den Weihnachtsmann!**, a rotating
chimney-pipe puzzle with a ten-second head start.
Day 5 has **Weihnachtsglocken**, a melody-memory game using short, recognizable
hooks from eight Christmas songs, including Carol of the Bells, Last Christmas
and All I Want for Christmas Is You. Difficulty uses trickier pitch patterns and
reduces visual help from every note to the first note to audio only.
Day 6 celebrates Nikolaus with a muddy shoe to brush clean and polish.
Day 7 has **Plätzchen ausstechen**: timed arrow inputs guide a moving pastry
wheel around a cookie, followed by an illustrated lift out of the dough.
Day 8 has **Wichtelwerkstatt**, a Sokoban-style present-pushing puzzle with
handcrafted boards, undo, restart and swipe/button controls.
Day 9 has **Oy Vey, Weihnachten!**, a locally processed front-camera mouth game
adapted from Brush Buddies. See [camera reuse, privacy and testing](docs/oy-vey.md).
Day 10 has **Ein Glühwein zu viel**, a 32–42 second walk home with tilt balance,
winter obstacles, calibration and held touch controls.
Day 11 has **Akku-Panik**: keep five low-battery devices alive for 45 seconds
with one cable, visible power-hungry events and plug-dragging controls on an illustrated
Christmas desk. Optional vibration and a ticking final countdown add feedback.
**Spiele ausprobieren** opens all games at configurable difficulty,
independent of the device date and without changing daily progress. See
[Minigame setup, controls and architecture](docs/minigames.md) for details.

If Android reports `INSTALL_FAILED_INSUFFICIENT_STORAGE`, free emulator storage
or use the smaller profile build for previewing (without hot reload):

```sh
flutter run --profile -d emulator-5554
```

```sh
cd app
flutter analyze
flutter test
flutter build apk --debug
```

Only the Android platform scaffold is included initially. App code uses Flutter
and platform-independent Dart for game rules and UI. Android has a small native
motion-sensor adapter; other platforms use touch/keyboard maze controls.
Additional platforms can be generated from `app/` with `flutter create
--platforms=ios,web,macos,windows,linux .` when needed, on a supported host.

## Administration

Tap **Dein Adventskalender** five times within three seconds, then enter the
initial development PIN **`0542`**. **Advent-Verwaltung** contains calendar,
game testing, box and diagnostics sections. Game testing and the temporary Pico LED test are active;
the PIN does not authorize physical unlocking. **Box-Steuerung** sends LED on/off
commands to the configurable Pico URL (default `http://192.168.178.68`). Rebuild in
debug/profile mode for local HTTP testing. See [admin setup and authentication
boundary](docs/admin.md).

## App structure

- `lib/main.dart`: entry point.
- `lib/app.dart`: theme, German localization, and root widget.
- `lib/presentation/`: calendar screen, vector door illustration, day carousel,
  and challenge placeholder. Reduced-motion preferences are respected.
- `lib/challenges/`: challenge identities and types (puzzles, quizzes,
  questionnaires, interactive minigames), Day 1's tutorial, and the ten playable
  games. Pure Dart mechanics are separate from screens and motion input.
- `lib/content/`: daily content and its association with challenge IDs.
- `lib/progress/`: progress contract and in-memory mock implementation.
- `lib/hardware/`: lock communication contract. A future Wi-Fi adapter for the
  Pico W will implement `LockGateway` here.

Daily assignments use local configuration and sample progress. The app does not
persist progress or communicate with lock hardware yet. There is no Wi-Fi protocol
or lock adapter at this stage. Future application
flows can coordinate progress and the lock through their interfaces without
coupling challenge logic to hardware.

Runtime dependencies are Flutter, its SDK localization package, and
`audioplayers` for offline recorded bell sounds, plus the same `camera` and
`mediapipe_face_mesh` packages used by Brush Buddies for local mouth tracking.
The bundled face runtime raises Android minimum SDK to 24. Audio credits, melody sources
and preview controls are documented in [Weihnachtsglocken](docs/bell-melodies.md).
Typography uses platform serif fallbacks without network font downloads. Development uses
`flutter_test` and `flutter_lints`. Keep `app/pubspec.lock` in version control for
reproducible dependency resolution.

## Firmware

`firmware/main.py` is the existing MicroPython entry point and currently blinks
the Pico's onboard LED. App setup does not change the firmware. Flashing and
future lock control will be designed separately.
