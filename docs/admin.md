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
- **Box-Steuerung**: verified Pico health and automatic recovery; no manual hardware actions.
- **Diagnose & Fortschritt**: structure only, no completion overrides yet.

`lib/admin/admin_authenticator.dart` isolates the authentication interface and
initial development implementation. `CalendarScreen.adminAuthenticator` can
receive a replacement provider; the dialog already supports asynchronous checks.
No entered PIN is logged or persisted. Provider failures show a German retryable
error without exposing provider details.

This check grants access to the administration **UI** only. The hidden gesture
and client-side development PIN are not authorization for physical unlocking.
The admin code does not import the lock gateway. The Pico service checks `/health` and can send a completion LED acknowledgement
to `/game/completed`; it cannot unlock the box. Future
physical controls must obtain real device authorization independently, and the
development credential should be replaced with the appropriate secure storage
and authentication flow.

## Pico health and automatic recovery

Open **Box-Steuerung** to start monitoring. Status is **Verbinde…** while trying
addresses, **Verbunden** only after a valid health response, or **Nicht verbunden**.
**Erneut verbinden** starts an immediate retry. The connection type and reported
IP appear after verification. The screen does not join or change Wi-Fi networks.
Join home Wi-Fi or the Pico hotspot manually as needed.

The existing `lib/hardware/pico_service.dart` owns health checks and completion
acknowledgements; there is no second Pico service. `/health` must return HTTP 2xx
and JSON with exact `device: DoorZero`, `status: ready`, a nonempty `mode` and a
valid IPv4 `ip`. Malformed JSON, wrong identities and incomplete/not-ready
responses cannot mark the device connected. The reported IP
is metadata; requests use a configured, verified candidate URL.

Default candidates are `http://192.168.178.68` and `http://192.168.4.1`. The last
working candidate is tried first on later checks. If it fails, the other is
checked. Each request has a 1.5-second whole-request deadline; checking two
unreachable candidates takes at most roughly three seconds. Response bodies
are capped at 8 KiB and redirects are not followed.

Healthy connections are checked 15 seconds after the preceding probe completes.
Failures retry after 5, 10, 20, then at most 30 seconds. Successful verification
resets backoff. Manual retry bypasses the wait, overlapping checks share the
same request sequence. Monitoring
stops on backgrounding, hiding/leaving the page or disposal. Returning checks
again; late responses from an earlier monitoring session are ignored.

Constructor `baseUrls` accepts a candidate list for custom addresses or a future
discovery component; `baseUrl` explicitly configures a single candidate for tests.
No subnet scanning, platform network permissions beyond existing native HTTP,
new dependencies or automatic Wi-Fi switching are introduced. Environment
settings configure the two application candidates:

```sh
cd app
flutter run --profile \
  --dart-define=PICO_BASE_URL=http://192.168.178.68 \
  --dart-define=PICO_HOTSPOT_URL=http://192.168.4.1
```

The service publishes verified connection status and health. Manual LED controls
and LED requests have been removed because the firmware uses the onboard LED
as a network-status indicator. There is no manual lock-unlock operation, and the
development PIN/device-name check is not physical-device authorization.

Native Android debug/profile manifests already allow local cleartext HTTP;
release retains its default policy. The web fallback reports unsupported native
HTTP gracefully. Automated tests cover local-server JSON/GETs, identity/schema
rejection, timeout/body bounds, both candidates, failover, backoff, manual retry,
single-flight checks, stale results, lifecycle and responsive UI.

## Physical completion acknowledgement

The calendar owns one `PicoService`, shared with **Box-Steuerung**. It does not
poll while games are running. The central `ChallengeCompletionHandler` checks
existing progress, saves a genuinely new completion, then launches an unawaited
acknowledgement. Games themselves remain independent of hardware. Game previews
keep their isolated completion callbacks and never notify the Pico.

The service reuses cached verified health, or performs one normal candidate
health-check sequence before sending an empty `POST /game/completed` to the
verified Pico. This endpoint triggers only the onboard completion blink; it is
separate from physical unlocking and grants no unlock authorization.

Concurrent callbacks for one challenge share a single completion operation.
Already saved challenges and repeated callbacks do not send another notification.
Storage failures remain retryable, and no acknowledgement is sent until storage
succeeds. Deduplication follows the existing progress repository; the current
mock progress still resets when the application restarts.

Network availability, health checks and POST results are never awaited by the
completion UI. Offline events are not queued. Failed or timed-out POSTs are not
retried, including after reconnecting, because an ambiguous timeout may follow
a blink that already happened. Redirects are disabled for POST as well as GET.
The client therefore makes at most one POST attempt per newly recorded challenge
completion, without delaying replay or changing an already saved result.

Tests cover concurrent/repeated callbacks, completed replays, preview isolation,
storage failure, offline completion, POST failure/timeout, non-blocking result
and replay controls, shared manager ownership, and actual empty native HTTP POSTs.
