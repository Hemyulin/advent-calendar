# Oy Vey, Weihnachten!

Day 9 and **Spiele ausprobieren** contain the head-controlled catching game.
Collect 15 Sufganiyot, Sevivonim or Chanukkiot by moving the sack with the mouth position. Christmas trees,
Santa hats and candy canes count as mistakes; three end the attempt. Missed good
objects do not cost lives. Falling speed and spawn rate increase gradually.

## What was reused from Brush Buddies

Inspected repository: `/Users/danielbudiansky/development/better-brushing`
(the Flutter app title is Brush Buddies).

- `lib/screens/camera_game_screen.dart`: front-camera selection, medium resolution,
  disabled microphone, Android NV21 / iOS BGRA capture, orientation compensation,
  detector-to-mesh ROI processing, mirrored inference, frame throttling and 0.62
  smoothing response.
- `lib/utils/face_mesh_camera_image_adapter.dart`: copied and adapted stride-aware
  camera-frame conversion. The two-plane interleaved VU path was corrected to
  copy both bytes of each chroma pair; tests cover one-, two- and three-plane
  buffers, padding, pixel strides and malformed data.
- `pubspec.yaml`: the same `camera` and `mediapipe_face_mesh` packages. No Banuba
  effects, photo capture, audio recording, storage, gallery or upload code was copied.

Brush Buddies' dynamic mode measures the outer mouth bounds for overlay placement.
The game uses the same position-based approach with smoothed mouth coordinates;
opening or closing the mouth does not affect collection. The full face mesh and
detector remain local and bundled.

## Camera and position tracking

The camera starts only after **Kamera starten** and the native permission grant.
One valid face observation enables play. No open/closed-mouth calibration is needed.

The front preview is mirrored by the camera backend; inference uses the same
upright mirrored coordinate system. The overlay and simulation use the complete
preview rectangle at its native aspect ratio, without a separate cover crop or
second mirror. Rotation changes invalidate the previous mouth before reacquisition.
The sack's opening follows the mouth position and width; its body hangs below it.

Frames are throttled to at most 12.5 Hz with a processing guard. Low-confidence
or missing faces, multiple faces and stale samples (400 ms watchdog) hide the
sack and disable catches, while spawning and falling continue. Tracking resumes
automatically when a face returns. Earlier tracking positions are discarded, so
reacquisition cannot create a sweep across the whole screen. Repeated conversion/inference
errors stop the camera and offer a German retry state. Permission denial and
missing/unsupported cameras also have explanatory German states and retry.

Backgrounding releases the camera and resets tracking. Help pauses the game;
leaving the screen disposes the camera and native processors. Wins/losses stop
camera capture. Replay preserves the existing shared completion mechanism.

## Separation, privacy and preview

- `mouth_tracking.dart`: camera-independent measurements and position smoothing.
- `camera_image_adapter.dart`, `local_mouth_camera_native.dart`: adapted capture,
  conversion and MediaPipe lifetime. `mouth_camera.dart` is the injectable boundary;
  unsupported platforms use a safe stub rather than importing native FFI.
- `oy_vey_game.dart`: pure seeded spawning, difficulty, swept elliptical
  mouth/object collision, score and win/loss rules. Collection depends only on position, regardless of mouth opening.
- `oy_vey_art.dart`: native vector objects and open sack; the Chanukkiah
  has eight branches plus the raised shamash. No external illustrations.
- `oy_vey_screen.dart`: German camera states, lifecycle, preview mapping, HUD and
  shared result overlays.

Camera buffers are used only for local inference and are not recorded, saved,
logged or uploaded. No capture/recording/network methods are called. Microphone
capture is disabled, and the merged Android manifest removes RECORD_AUDIO and unused external-storage
permissions inherited from the camera package.
MediaPipe's model files may be copied to its local model cache; camera frames
are never written there. The initial page discloses local processing before opt-in.

The development preview includes an explicit **Ohne Kamera testen** driver. Drag
the sack around the stage to test the falling game without a face or permission. It is labelled **Vorschau ohne Kamera**
and is unavailable in normal daily play. Preview completion never updates a day.

The two new direct dependencies match Brush Buddies: `camera ^0.11.4` and pinned
`mediapipe_face_mesh 1.3.2`. The bundled runtime requires Android API 24+ and
supports ARM64/x86_64. The existing Android target is built and tested here.
The adapter includes the same iOS BGRA route; generating an iOS scaffold also
requires a German NSCameraUsageDescription before use. Other platforms can use
the explicit development driver.

Automated checks cover frame layouts, aspect-correct mouth geometry, position smoothing,
fast and lateral collisions, continued simulation during tracking loss, all six objects, wins and
losses, progress/replay, permissions, lifecycle and responsive layouts. A physical
phone check is still needed for live front-camera alignment, tracking stability
and frame latency; an emulator test driver is not a substitute for that.
