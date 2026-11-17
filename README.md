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

On macOS, the iOS scaffold can run with `flutter run -d "iPhone 17 Pro"` after
installing Xcode and a simulator runtime. CocoaPods 1.16.2+ is recommended.
The face-tracking dependency is pinned to 2.9.0 for its simulator-capable
XCFramework; iOS camera access has a German permission description.

The app displays a German Advent calendar with an illustrated door and a
horizontal day carousel. Swipe left or right across the main door to select the
next or previous available day; the carousel also remains independently scrollable. All 24 doors contain playable challenges. The sequence is defined in
`app/lib/content/calendar_schedule.dart`.
Each day has a festive paper door with a storybook ornament, a rotating warm
colour palette, and fairy lights. Locked doors keep their colour and show a lock
badge. All artwork is drawn in Flutter without image assets or new dependencies.
For design testing, **all 24 doors are currently unlocked by default**. The homepage keeps development controls in the hidden admin area. Each door swings open before showing its
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

Calendar completion, achievements and voucher claims are stored locally and
survive app restarts. Fresh installs start without sample completions. For
development and tests, `AdventCalendarApp(now: DateTime(2026, 12, 8))` provides a
fixed date; the normal entry point uses the device date with the preview override.

Appearance now belongs to each door, independently of the current date. The
Hanukkah appearances are deliberately scheduled on days 5, 7, 9, 10 and 12;
day 4 is Oy Vey, day 6 stays Nikolaus, and days 8/11 use regular Christmas games.
Tap the David star to replay in the other appearance, including polishing a
shekel instead of the boot. See the [full sequence](docs/minigames.md) and
[appearance/replay details](docs/hanukkah.md).

The **Erfolge** button opens the achievement collection. Unearned badges are
muted, with requirements and progress visible. Individual achievements award
badges only, including collecting the labyrinth sweets. One final voucher stays
hidden until all 17 achievements are earned. Configure its text in **Advent-Verwaltung → Erfolge &
Gutscheine**. See [achievement rules and bonuses](docs/achievements.md).

Day 1 starts with **Paare finden** on easy difficulty. A first win saves progress
and shows an illustrated gift above the game. Tap the gift to lift its lid and
reveal the reward. Replay wins show a congratulations card with replay and calendar
actions instead; achievements still count. Development previews never open the physical box. Old present-only calendar assignments migrate to
easy Memory.

The shared gift action is separate from game completion and the Pico LED
acknowledgement. `PicoService` implements `LockGateway`: after a fresh DoorZero
health check, the gift tap sends one `POST /unlock` and validates `success: true`.
The firmware pulses GPIO 15 for 200 ms. Replay wins never offer another gift or
send another unlock, and ambiguous requests are never retried automatically.

Day 2 has **Plätzchen ausstechen** on easy difficulty and Day 3 **Kugellabyrinth** (one sensor-
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
**Advent-Verwaltung → Spiele testen** opens all games at configurable difficulty,
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
game testing, box and diagnostics sections. Game testing and Pico connection monitoring are active;
the PIN does not authorize physical unlocking. **Box-Steuerung** validates
DoorZero through `/health`, tries home Wi-Fi and the fallback hotspot, and
recovers automatically. Addresses are configurable with `PICO_BASE_URL` and
`PICO_HOTSPOT_URL`. Run a debug/profile build for local HTTP. The firmware uses
the LED as a network-status indicator, so the app has no manual LED controls.
New daily completions send a best-effort `POST /game/completed` for a brief LED
acknowledgement. Replays and previews do not notify; network failures never block
game completion. This acknowledgement is separate from physical unlocking. See [admin setup and authentication
boundary](docs/admin.md).

## App structure

- `lib/main.dart`: entry point.
- `lib/app.dart`: theme, German localization, and root widget.
- `lib/presentation/`: calendar screen, vector door illustration, day carousel,
  and challenge placeholder. Reduced-motion preferences are respected.
- `lib/challenges/`: challenge identities and types (puzzles, quizzes,
  questionnaires, interactive minigames), shared gift rewards, and the playable
  games. Pure Dart mechanics are separate from screens and motion input.
- `lib/content/`: daily content, calendar assignments and local storage.
- `lib/progress/`: persistent calendar checkmarks and an injectable test mock.
- `lib/achievements/`: reusable achievement rules, persistent progress, voucher claims and the collection.
- `lib/hardware/`: verified Pico communication and the `LockGateway` contract.

Daily assignments, progress and achievements are stored locally. `PicoService` verifies connectivity and acknowledges new completions
over Wi-Fi. An explicit gift/admin action can send `POST /unlock`. Game logic stays
independent of hardware.

Runtime dependencies are Flutter, its SDK localization package, and
`audioplayers` for offline recorded bell sounds, plus the same `camera` and
`mediapipe_face_mesh` packages used by Brush Buddies for local mouth tracking,
and `shared_preferences` for saved calendar assignments.

**Box öffnen** in admin sends a deliberate, health-verified `POST /unlock` to the
connected Pico. The button is disabled while disconnected or opening. Home Wi-Fi
and the Pico hotspot share the same service. The current firmware accepts local
network requests without a token; the development PIN only protects the admin UI.
The bundled face runtime raises Android minimum SDK to 24. Audio credits, melody sources
and preview controls are documented in [Weihnachtsglocken](docs/bell-melodies.md).
Typography uses platform serif fallbacks without network font downloads. Development uses
`flutter_test` and `flutter_lints`. Keep `app/pubspec.lock` in version control for
reproducible dependency resolution.

## Firmware

`firmware/main.py` is the existing MicroPython entry point and currently blinks
the Pico's onboard LED. App setup does not change the firmware. Flashing and
future lock control will be designed separately.

## Pico network configuration

Copy `firmware/config.example.py` to `firmware/config.py` and fill in your Wi-Fi
and fallback hotspot credentials. `config.py` is ignored by Git. Copy both
`main.py` and `config.py` to the Pico's filesystem before restarting it.
The firmware exposes `/health` with the `DoorZero` identity and falls back to a
hotspot if home Wi-Fi is unavailable. The LED now indicates network status;
manual LED endpoints return HTTP 410. `old_main.py` preserves the earlier LED
server for reference and also reads credentials from the local config.

Calendar challenges now offer **Zu schwer?** for a gentler attempt or the optional
**Müll rausbringen** alternative. Carry the full bag out, then fit a fresh bag to
complete the door and earn a secret achievement. The trash game can also be
launched in admin previews. See [minigames](docs/minigames.md).
