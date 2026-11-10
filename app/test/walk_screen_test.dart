import 'dart:async';
import 'package:advent_calendar/challenges/walk_home/walk_game.dart';
import 'package:advent_calendar/challenges/walk_home/walk_screen.dart';
import 'package:advent_calendar/challenges/walk_home/walk_art.dart';
import 'package:advent_calendar/challenges/maze/maze_game.dart';
import 'package:advent_calendar/challenges/maze/tilt_source.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/games/game_preview_screen.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/content/calendar_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class NoTilt implements TiltSource {
  @override
  Stream<Vec2> get events => Stream.error(UnsupportedError('test'));
}

class FakeTilt implements TiltSource {
  final controller = StreamController<Vec2>.broadcast(sync: true);
  @override
  Stream<Vec2> get events => controller.stream;
}

WinterStreetPainter scene(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(find.byKey(const ValueKey('walk-street')))
            .painter!
        as WinterStreetPainter;
Future<void> frames(WidgetTester tester, double seconds) async {
  for (var i = 0; i < (seconds / .05).ceil(); i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('day and night toggle preserves the current walk', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WalkScreen(tiltSource: NoTilt(), onComplete: () async {}),
      ),
    );
    await tester.pumpAndSettle();
    final game = scene(tester).game;
    final initialNightMode = scene(tester).nightMode;
    await tester.tap(find.byKey(const ValueKey('walk-lighting')));
    await tester.pump();
    expect(scene(tester).nightMode, !initialNightMode);
    expect(scene(tester).game, same(game));
    await tester.tap(find.byKey(const ValueKey('walk-lighting')));
    await tester.pump();
    expect(scene(tester).nightMode, initialNightMode);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('held touch corrects balance and a fall animates before retry', (
    tester,
  ) async {
    var complete = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: WalkScreen(
          tiltSource: NoTilt(),
          level: const WalkLevel(seed: 5),
          onComplete: () async {
            complete++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('walk-start')));
    await tester.pump();
    final press = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('walk-left'))),
    );
    await frames(tester, .5);
    expect(scene(tester).game.x, lessThan(0));
    expect(scene(tester).game.lean, lessThan(0));
    await press.up();
    await tester.pumpWidget(
      MaterialApp(
        home: WalkScreen(
          key: const ValueKey('fall'),
          tiltSource: NoTilt(),
          level: const WalkLevel(seed: 5, leanLimit: .0001, fallGrace: .04),
          onComplete: () async {
            complete++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('walk-start')));
    await tester.pump();
    await frames(tester, .2);
    expect(scene(tester).game.phase, WalkPhase.fallen);
    expect(find.text('Fast geschafft'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    expect(find.text('Fast geschafft'), findsOneWidget);
    expect(complete, 0);
    await tester.tap(find.text('Noch einmal versuchen'));
    await tester.pumpAndSettle();
    expect(scene(tester).game.phase, WalkPhase.ready);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('arrival animates, saves once and replay keeps completion', (
    tester,
  ) async {
    var complete = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: WalkScreen(
          tiltSource: NoTilt(),
          alreadyCompleted: true,
          level: const WalkLevel(seconds: .3, wobble: .001, seed: 10),
          onComplete: () async {
            complete++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('walk-start')));
    await tester.pump();
    await frames(tester, .5);
    expect(scene(tester).game.phase, WalkPhase.home);
    expect(find.text('Geschafft!'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    expect(find.text('Geschafft!'), findsOneWidget);
    expect(complete, 1);
    await tester.tap(find.text('Noch einmal spielen'));
    await tester.pumpAndSettle();
    expect(scene(tester).game.phase, WalkPhase.ready);
    expect(find.byTooltip('Bereits geschafft'), findsOneWidget);
    expect(complete, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'sensor baseline, tilt direction and silence fallback use existing tilt source',
    (tester) async {
      final source = FakeTilt();
      await tester.pumpWidget(
        MaterialApp(
          home: WalkScreen(
            tiltSource: source,
            level: const WalkLevel(seed: 1),
            onComplete: () async {},
          ),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('walk-start')))
            .onPressed,
        isNull,
      );
      for (var i = 0; i < 8; i++) {
        source.controller.add(const Vec2(.25, 0));
      }
      await tester.pump();
      expect(find.byTooltip('Diese Haltung als Mitte setzen'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('walk-start')));
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        source.controller.add(const Vec2(.5, 0));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(scene(tester).game.lean, greaterThan(0));
      await tester.tap(find.byTooltip('Diese Haltung als Mitte setzen'));
      await tester.pump();
      expect(find.text('Weiter'), findsOneWidget);
      final elapsed = scene(tester).game.elapsed;
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('walk-left')), findsOneWidget);
      expect(scene(tester).game.elapsed, elapsed);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(source.controller.hasListener, isFalse);
      await source.controller.close();
    },
  );
  testWidgets('help and background pause without accumulating movement', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WalkScreen(tiltSource: NoTilt(), onComplete: () async {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('walk-start')));
    await tester.pump();
    await frames(tester, .2);
    await tester.tap(find.byTooltip('Anleitung'));
    await tester.pumpAndSettle();
    final elapsed = scene(tester).game.elapsed;
    await tester.pump(const Duration(seconds: 10));
    expect(scene(tester).game.elapsed, elapsed);
    await tester.tap(find.text('Verstanden'));
    await tester.pumpAndSettle();
    expect(find.text('Weiter'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(scene(tester).game.elapsed, elapsed);
    expect(find.text('Weiter'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets('all routes and development preview fit at $scenario', (
      tester,
    ) async {
      tester.view.physicalSize = scenario.$1;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final d in GameDifficulty.values) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(d),
            home: WalkScreen(
              tiltSource: NoTilt(),
              level: WalkLevel.forDifficulty(d),
              onComplete: () async {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const MaterialApp(home: GamePreviewScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('preview difficulty launches the matching route', (tester) async {
    for (final d in GameDifficulty.values) {
      await tester.pumpWidget(
        MaterialApp(key: ValueKey(d), home: const GamePreviewScreen()),
      );
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<GameDifficulty>>(
            find.byType(DropdownButtonFormField<GameDifficulty>),
          )
          .onChanged!(d);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ein Glühwein zu viel'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<WalkScreen>(find.byType(WalkScreen)).level.seconds,
        WalkLevel.forDifficulty(d).seconds,
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test('Day 10 shares completion and replay state', () {
    Future<void> complete() async {}
    final screen =
        buildDailyChallenge(
              calendarDays(DateTime(2026, 12, 24), {'day-10'})[9],
              complete,
            )
            as WalkScreen;
    expect(screen.onComplete, same(complete));
    expect(screen.alreadyCompleted, isTrue);
  });
}
