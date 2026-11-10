import 'package:advent_calendar/challenges/oy_vey/mouth_camera.dart';
import 'package:advent_calendar/challenges/oy_vey/mouth_tracking.dart';
import 'package:advent_calendar/challenges/oy_vey/oy_vey_game.dart';
import 'package:advent_calendar/challenges/oy_vey/oy_vey_art.dart';
import 'package:advent_calendar/challenges/oy_vey/oy_vey_screen.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/games/game_preview_screen.dart';
import 'package:advent_calendar/content/calendar_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMouthCamera extends MouthCamera {
  @override
  MouthCameraState state = MouthCameraState.idle;
  @override
  MouthObservation? observation;
  @override
  bool multipleFaces = false;
  @override
  double get aspectRatio => .75;
  bool disposed = false;
  int starts = 0, stops = 0;
  MouthCameraState startState = MouthCameraState.ready;
  @override
  Widget preview() => const ColoredBox(color: Color(0xFFE8E9D7));
  @override
  Future<void> start() async {
    starts++;
    state = startState;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    stops++;
    state = MouthCameraState.idle;
    observation = null;
    notifyListeners();
  }

  void emit(MouthObservation? next) {
    observation = next;
    notifyListeners();
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

MouthObservation pose(double ratio, {double x = .5}) =>
    MouthObservation(x: x, y: .5, width: .22, gapRatio: ratio);
Future<void> calibrate(
  WidgetTester tester,
  FakeMouthCamera camera, {
  double x = .5,
}) async {
  await tester.tap(find.text('Kamera starten'));
  await tester.pump();
  for (var i = 0; i < 20; i++) {
    camera.emit(pose(.02, x: x));
  }
  await tester.pump();
  expect(find.text('Jetzt den Mund weit öffnen'), findsOneWidget);
  for (var i = 0; i < 12; i++) {
    camera.emit(pose(.3, x: x));
  }
  await tester.pump();
  expect(find.text('Bereit!'), findsOneWidget);
}

OyVeyPainter painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.byWidgetPredicate(
                (w) => w is CustomPaint && w.painter is OyVeyPainter,
              ),
            )
            .painter!
        as OyVeyPainter;
(int, double) firstSpawn(bool good) {
  for (var seed = 0; seed < 100; seed++) {
    final probe = OyVeyGame(
      OyVeyLevel(seed: seed, spawnSeconds: .1, startSpeed: 1),
    );
    for (var frame = 0; frame < 6; frame++) {
      probe.advance(.1, const CatchMouth(.5, .5, .1, false));
    }
    if (probe.objects.first.kind.correct == good) {
      return (seed, probe.objects.first.x);
    }
  }
  throw StateError('seed');
}

void main() {
  testWidgets(
    'camera requires opt-in, calibrates closed/open and completes through mouth tracking',
    (tester) async {
      final camera = FakeMouthCamera();
      final spawn = firstSpawn(true);
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: OyVeyScreen(
            camera: camera,
            alreadyCompleted: true,
            level: OyVeyLevel(
              seed: spawn.$1,
              target: 1,
              spawnSeconds: .1,
              startSpeed: 1,
            ),
            onComplete: () async {
              completed++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(camera.starts, 0);
      await calibrate(tester, camera, x: spawn.$2);
      await tester.tap(find.byKey(const ValueKey('oy-vey-play')));
      await tester.pump();
      for (var i = 0; i < 40 && completed == 0; i++) {
        camera.emit(pose(.3, x: spawn.$2));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
      expect(find.text('Geschafft!'), findsOneWidget);
      expect(completed, 1);
      expect(camera.stops, greaterThanOrEqualTo(1));
      await tester.tap(find.text('Noch einmal spielen'));
      await tester.pump();
      expect(find.text('0 / 1 gesammelt · 0 / 3 Fehler'), findsOneWidget);
      expect(completed, 1);
      expect(find.byTooltip('Bereits geschafft'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(camera.disposed, isTrue);
    },
  );
  testWidgets('a Christmas catch loses without recording completion', (
    tester,
  ) async {
    final camera = FakeMouthCamera();
    final spawn = firstSpawn(false);
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: OyVeyScreen(
          camera: camera,
          level: OyVeyLevel(
            seed: spawn.$1,
            mistakeLimit: 1,
            spawnSeconds: .1,
            startSpeed: 1,
          ),
          onComplete: () async {
            completed++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await calibrate(tester, camera, x: spawn.$2);
    await tester.tap(find.byKey(const ValueKey('oy-vey-play')));
    await tester.pump();
    for (
      var i = 0;
      i < 40 && find.text('Fast geschafft').evaluate().isEmpty;
      i++
    ) {
      camera.emit(pose(.3, x: spawn.$2));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    expect(find.text('Fast geschafft'), findsOneWidget);
    expect(completed, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'missing/stale faces freeze the world and require a fresh frame to resume',
    (tester) async {
      final camera = FakeMouthCamera();
      await tester.pumpWidget(
        MaterialApp(
          home: OyVeyScreen(camera: camera, onComplete: () async {}),
        ),
      );
      await tester.pumpAndSettle();
      await calibrate(tester, camera);
      await tester.tap(find.byKey(const ValueKey('oy-vey-play')));
      await tester.pump();
      camera.emit(pose(.3));
      await tester.pump(const Duration(milliseconds: 50));
      camera.emit(null);
      await tester.pump();
      final elapsed = painter(tester).game.elapsed;
      await tester.pump(const Duration(seconds: 3));
      expect(painter(tester).game.elapsed, elapsed);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('oy-vey-play')))
            .onPressed,
        isNull,
      );
      camera.emit(pose(.3));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('oy-vey-play')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(painter(tester).visible, isFalse);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('oy-vey-play')))
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'permission, missing-camera and initialization failures are German and retryable',
    (tester) async {
      for (final failure in [
        MouthCameraState.permissionDenied,
        MouthCameraState.unavailable,
        MouthCameraState.failed,
      ]) {
        final camera = FakeMouthCamera()..startState = failure;
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(failure),
            home: OyVeyScreen(camera: camera, onComplete: () async {}),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kamera starten'));
        await tester.pumpAndSettle();
        expect(find.text('Erneut versuchen'), findsOneWidget);
        expect(painter(tester).visible, isFalse);
        camera.startState = MouthCameraState.ready;
        await tester.tap(find.text('Erneut versuchen'));
        await tester.pump();
        expect(camera.starts, 2);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('backgrounding releases the camera; help pauses gameplay', (
    tester,
  ) async {
    final camera = FakeMouthCamera();
    await tester.pumpWidget(
      MaterialApp(
        home: OyVeyScreen(camera: camera, onComplete: () async {}),
      ),
    );
    await tester.pumpAndSettle();
    await calibrate(tester, camera);
    await tester.tap(find.byKey(const ValueKey('oy-vey-play')));
    await tester.pump();
    await tester.tap(find.byTooltip('Anleitung'));
    await tester.pumpAndSettle();
    final elapsed = painter(tester).game.elapsed;
    await tester.pump(const Duration(seconds: 3));
    expect(painter(tester).game.elapsed, elapsed);
    await tester.tap(find.text('Verstanden'));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(camera.stops, greaterThanOrEqualTo(1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Kamera starten'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('development driver is explicit and does not request a camera', (
    tester,
  ) async {
    final camera = FakeMouthCamera();
    await tester.pumpWidget(
      MaterialApp(
        home: OyVeyScreen(
          camera: camera,
          developmentPreview: true,
          onComplete: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ohne Kamera testen'));
    await tester.pumpAndSettle();
    expect(camera.starts, 0);
    expect(find.text('Vorschau ohne Kamera'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('oy-vey-mouth')));
    await tester.pump();
    expect(painter(tester).mouth!.open, isTrue);
    final board = tester.getRect(find.byKey(const ValueKey('oy-vey-stage')));
    await tester.dragFrom(board.center, const Offset(30, -30));
    await tester.pump();
    expect(painter(tester).mouth!.x, greaterThan(.5));
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets(
      'camera scenes and game previews fit without scrolling at $scenario',
      (tester) async {
        tester.view.physicalSize = scenario.$1;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          MaterialApp(
            home: OyVeyScreen(
              camera: FakeMouthCamera(),
              developmentPreview: true,
              onComplete: () async {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const MaterialApp(home: GamePreviewScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  test('Day 9 shares the completion interface and replay state', () {
    Future<void> complete() async {}
    final screen =
        buildDailyChallenge(
              calendarDays(DateTime(2026, 12, 24), {'day-9'})[8],
              complete,
            )
            as OyVeyScreen;
    expect(screen.onComplete, same(complete));
    expect(screen.alreadyCompleted, isTrue);
  });
}
