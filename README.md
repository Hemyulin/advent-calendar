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
Doors are **locked by date by default**. The hidden admin area has an explicit,
persisted **Alle Türchen freischalten** test override, off on a fresh install. Each door swings open before showing its
challenge screen; returning to the calendar closes it again. Reduced-motion
settings skip the opening animation. Previewing does not mark a day completed.
Screens fit the viewport without vertical scrolling. Success and failure messages
float above a dimmed game with visible return and replay controls. Only the
horizontal day carousel scrolls.

Run normally with `flutter run`. Availability follows the local date for December of the current year:
future days are locked, today and previous days are accessible, and completed
days can be revisited. Availability refreshes at midnight and on app resume.
Before December all doors are locked; after December 24 all are accessible.

Calendar completion, achievements and voucher claims are stored locally and
survive app restarts. Fresh installs start without sample completions. For
development and tests, `AdventCalendarApp(now: DateTime(2026, 12, 8))` provides a
fixed date; the normal entry point uses the device date. The old
`PREVIEW_ALL_DAYS` build define no longer unlocks doors. Locked taps show
**Heute noch nicht!**. Game practice follows the [shared unlock rules](docs/progression.md).

Appearance now belongs to each door, independently of the current date. The
Hanukkah appearances are deliberately scheduled on days 5, 7, 10 and 12;
day 4 is Oy Vey, day 6 stays Nikolaus, and days 8/11 use regular Christmas games.
Tap the David star to replay in the other appearance, including polishing a
shekel instead of the boot. See the [full sequence](docs/minigames.md) and
[appearance/replay details](docs/hanukkah.md).

The **Erfolge** button opens the achievement collection. Unearned badges are
muted, with requirements and progress visible. Individual achievements award
badges only, including collecting the labyrinth sweets. One final voucher stays
hidden until all 18 regular achievements are earned. Configure its text in **Advent-Verwaltung → Erfolge &
Gutscheine**. See [achievement rules and bonuses](docs/achievements.md).

Day 1 starts with **Paare finden** on easy difficulty. A first win saves progress
and shows an illustrated gift above the game. Tap the gift to lift its lid and
reveal the reward. Replay wins show a congratulations card with replay and calendar
actions instead; achievements still count. Development previews never open the physical box. Old present-only calendar assignments migrate to
easy Memory.

The shared gift action is separate from game completion and the Pico LED
acknowledgement. `PicoService` implements `LockGateway`: after a fresh DoorZero
health check, the gift tap sends one `POST /unlock` and validates `success: true`.
The firmware holds GPIO 15 HIGH for five seconds, then switches it LOW.
The gift screen offers **Box erneut öffnen** if you missed the opening window. Replay wins never offer another gift or
send another unlock, and ambiguous requests are never retried automatically.

Day 2 introduces **Plätzchen ausstechen** and Day 3 **Kugellabyrinth**. Day 4 has
**Oy Vey, Weihnachten!**, a local front-camera catching game adapted from Brush
Buddies. Day 6 celebrates Nikolaus with a muddy shoe to brush clean and polish.
Day 7's Chanukka cookie depicts the Second Temple with a zigzag spiked roof.
Day 8 introduces **Akku-Panik**, five devices and one charging cable.
Day 9 uses regular Santa in **Rettet den Weihnachtsmann!**; Day 10 plays the
corrected Maoz Tzur hook, and Day 11 is regular **Ein Glühwein zu viel**.
Day 14 introduces the present-pushing **Wichtelwerkstatt**. Day 15 plays
**Jingle Bells**. Day 22 is **GOY vey!**, catching Christmas objects instead of
Hanukkah objects. A clean run earns its own regular achievement.
See [the full sequence](docs/minigames.md) and [camera reuse and privacy](docs/oy-vey.md).
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
and the Pico hotspot share the same service. The development PIN protects the admin UI; the restored firmware accepts
commands on its local network without a device key. See the configuration below.
The bundled face runtime raises Android minimum SDK to 24. Audio credits, melody sources
and preview controls are documented in [Weihnachtsglocken](docs/bell-melodies.md).
Typography uses platform serif fallbacks without network font downloads. Development uses
`flutter_test` and `flutter_lints`. Keep `app/pubspec.lock` in version control for
reproducible dependency resolution.

## Firmware

`main.py` uses the restored `old_main.py` architecture, with network credentials
loaded from private `config.py`. Unlocking is synchronous: GPIO 15 stays HIGH for
**five seconds**, then `finally` switches it LOW, including if the wait raises an
exception. The HTTP success response is sent after the pulse finishes. The app
allows seven seconds for this request; health checks retain their short timeout.
`boot.py` initializes GP15 LOW before the main program starts.

Verify the solenoid's five-second ON-time and duty-cycle rating. Software does not
prove the MOSFET is off during power-up or establish whether the door is physically
open; there is no position sensor. The restored firmware has no timer-based cutoff,
unlock-token validation or cooldown.

Run the firmware tests without networking or physical actuation:

```sh
python3 -m unittest discover -s firmware/tests -v
```

## Pico network configuration

Copy `firmware/config.example.py` to ignored `firmware/config.py` and fill in
`WIFI_NAME`, `WIFI_PASSWORD`, `AP_NAME` and `AP_PASSWORD`. Preserve your existing
private settings. Copy `boot.py`, `main.py` and `config.py` to the Pico and restart.
The restored firmware does not use the additional unlock settings in older configs.

The app matches the restored firmware: no device key or token build define is
required. Run normally with `flutter run` from `app/`. Optional address overrides
can still be supplied with `--dart-define-from-file=pico.local.json`.

The firmware exposes `/health` with the `DoorZero` identity and falls back to a
hotspot if home Wi-Fi is unavailable. The LED indicates network status; the
completion acknowledgement remains separate from unlocking.

Calendar challenges now offer **Zu schwer?** for a gentler attempt or the optional
**Müll rausbringen** alternative. Carry the full bag out, then fit a fresh bag to
complete the door and earn a secret achievement. The trash game can also be
launched in admin previews. See [minigames](docs/minigames.md).

### XY-MOS unexpected activation diagnosis

The lock control is **GP15 / physical pin 20**; Pico GND on physical pin 18 goes
to the module's signal GND. `TRIG/PWM` is a control input, not the 12 V supply.
Never connect VIN+ or OUT+ to a Pico GPIO. Check the actual module's terminal
labels; variant boards need their own documentation.

If the load energizes unexpectedly, disconnect the solenoid supply before moving
wires. Thonny can run `firmware/diagnose_lock_off.py` after stopping the normal
application. This script only drives GP15 LOW repeatedly; it never enables the
output or starts networking. Measure GP15–Pico GND and TRIG/PWM–module GND with a
multimeter. Both should be near 0 V for the active-high XY-MOS setup. A software
flag or module LED alone does not verify the electrical output state.

For an isolation test, remove both power sources first, disconnect the Pico's
GP15 lead from TRIG/PWM, and connect the module's TRIG/PWM directly to its own GND.
The Pico GPIO must not remain attached to that jumper. Briefly test with a
suitable low-power 12 V test load instead of holding the solenoid energized:
if switching remains on with TRIG grounded and the Pico isolated, inspect the
module, reversed VIN/OUT terminals or a load path bypassing the switch. If it is
off, investigate the GPIO, trigger lead and shared ground reference. Do not leave
a trigger input floating for this test.

With all power removed, verify the common-ground path and that OUT− is not being
used as the Pico ground: it is the switched load return on the usual low-side
XY-MOS topology. Verify the flyback diode across the coil: striped/cathode end to
OUT+, other end to OUT−. Establish the actual input behavior before considering
an additional pull-down resistor or reversing software polarity.

## Icon and first launch

The app has a matching chest icon, ivory splash screens and a one-time German
welcome introducing Auszeichnungen and the bonus gift. Secret awards are explained
as optional. See [branding and first-launch setup](docs/branding.md).
