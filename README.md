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
horizontal day carousel. Available doors lead to a placeholder challenge screen.
Each day has a festive paper door with a storybook ornament, a rotating warm
colour palette, and fairy lights. Locked doors keep their colour and show a lock
badge. All artwork is drawn in Flutter without image assets or new dependencies.
Availability follows the device's local date for December of the current year:
future days are locked, today and previous days are accessible, and completed
days can be revisited. Availability refreshes at midnight and on app resume.
Before December all doors are locked; after December 24 all are accessible.

Sample progress marks days 1, 3, and 5 as completed, but only once those dates
become available. It is held in memory and resets on restart. For development
and tests, `AdventCalendarApp(now: DateTime(2026, 12, 8))` provides a fixed date;
the normal entry point always uses the actual device date.

```sh
cd app
flutter analyze
flutter test
flutter build apk --debug
```

Only the Android platform scaffold is included initially. App code uses Flutter
and platform-independent Dart, with no Android-specific application logic.
Additional platforms can be generated from `app/` with `flutter create
--platforms=ios,web,macos,windows,linux .` when needed, on a supported host.

## App structure

- `lib/main.dart`: entry point.
- `lib/app.dart`: theme, German localization, and root widget.
- `lib/presentation/`: calendar screen, vector door illustration, day carousel,
  and challenge placeholder. Reduced-motion preferences are respected.
- `lib/challenges/`: challenge identities and types (puzzles, quizzes,
  questionnaires, interactive minigames); future challenge logic belongs here.
- `lib/content/`: daily content and its association with challenge IDs.
- `lib/progress/`: progress contract and in-memory mock implementation.
- `lib/hardware/`: lock communication contract. A future Wi-Fi adapter for the
  Pico W will implement `LockGateway` here.

Daily assignments and progress are mock data. The app does not run puzzles,
persist progress, or communicate with hardware yet. There is no Wi-Fi protocol
or lock adapter at this stage. Future application
flows can coordinate progress and the lock through their interfaces without
coupling challenge logic to hardware.

Runtime dependencies are limited to Flutter and its SDK localization package.
Typography uses platform serif fallbacks without network font downloads. Development uses
`flutter_test` and `flutter_lints`. Keep `app/pubspec.lock` in version control for
reproducible dependency resolution.

## Firmware

`firmware/main.py` is the existing MicroPython entry point and currently blinks
the Pico's onboard LED. App setup does not change the firmware. Flashing and
future lock control will be designed separately.
