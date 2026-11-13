# Advent-Verwaltung

Tap **Dein Adventskalender** five times within a single three-second window.
The title keeps its normal appearance. Slow tap sequences, backgrounding, closing
the PIN dialog and leaving the page reset entry. While the dialog or admin page
is open, further title taps cannot open another instance.

Enter the initial development PIN **`0542`**. It is a four-character string,
including the leading zero. The dialog uses the numeric keyboard and obscures
input. An incorrect entry displays **Falscher PIN** and allows another attempt.
Cancelling returns to the calendar. Re-entering administration requires the PIN
again; nothing is saved as an authenticated session.

The initial screen provides these sections:

- **Kalender bearbeiten**: structure for future game/difficulty assignments.
- **Spiele testen**: reuses `GamePreviewScreen`, with all games and difficulty
  settings, regardless of device date or homepage preview visibility. Preview
  completions do not change calendar progress.
- **Box-Steuerung**: temporary Pico LED connection test (see below); no unlock action.
- **Diagnose & Fortschritt**: structure only, no completion overrides yet.

`lib/admin/admin_authenticator.dart` isolates the authentication interface and
initial development implementation. `CalendarScreen.adminAuthenticator` can
receive a replacement provider; the dialog already supports asynchronous checks.
No entered PIN is logged or persisted. Provider failures show a German retryable
error without exposing provider details.

This check grants access to the administration **UI** only. The hidden gesture
and client-side development PIN are not authorization for physical unlocking.
The admin code does not import the lock gateway. The LED diagnostic only calls
`/led/on` and `/led/off`; it cannot unlock the box. Future
physical controls must obtain real device authorization independently, and the
development credential should be replaced with the appropriate secure storage
and authentication flow.

## Temporary Pico W LED test

Open **Box-Steuerung**, then press **LED einschalten** or **LED ausschalten**.
The initial status is **Noch nicht geprüft**; opening the page sends no requests.
Each button issues exactly one HTTP GET. Both controls are disabled until the
request finishes, so commands cannot overtake each other. A 2xx response reports
**Verbunden** and the accepted LED state; no separate LED-state sensor is read.
Errors show HTTP status, timeout or a connection hint in German, and permit retry.
No automatic retries or redirects are performed.

`lib/hardware/pico_led_service.dart` owns the configurable base URL and default
three-second request deadline. The native transport bounds connection, headers
and response-body waiting, and closes the client afterward. This service is
separate from `LockGateway`, daily challenge rules and progress tracking.
No new dependencies and no firmware changes are needed.

The default URL is `http://192.168.178.68`. Change it at construction for tests,
or configure the application when launching:

```sh
cd app
flutter run --profile --dart-define=PICO_BASE_URL=http://192.168.178.68
```

Use the phone and Pico on the same local Wi-Fi network, with the Pico HTTP server
running at that address. There is no discovery or pairing implementation yet.
The test uses native HTTP; the web build displays an unsupported-platform message.

Android declares `INTERNET`. The debug and profile manifest overlays permit
cleartext HTTP for this temporary development test; release keeps its default
cleartext policy. A full rebuild/reinstall is needed for manifest changes.
See Android's [cleartext application setting](https://developer.android.com/guide/topics/manifest/application-element#usesCleartextTraffic).

Automated tests exercise GET paths against a real local HTTP server, redirects,
HTTP errors, connection failure, stalled headers/body, configuration, serialized
button actions, retry, leaving the screen during requests and responsive layouts.
