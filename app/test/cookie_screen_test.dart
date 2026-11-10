import 'package:advent_calendar/challenges/cookies/cookie_game.dart';
import 'package:advent_calendar/challenges/cookies/cookie_screen.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/games/game_preview_screen.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/content/calendar_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const fastLevel = CookieLevel(
  speed: .25,
  checkpoints: 1,
  timingWindowSeconds: 1,
);
Future<void> frames(WidgetTester tester, double seconds) async {
  for (var i = 0; i < (seconds / .05).ceil(); i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> start(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('cookie-start')));
  await tester.pump();
}

void main() {
  testWidgets(
    'touch-down cuts immediately; lift precedes completion; replay retains completion',
    (tester) async {
      var completions = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CookieScreen(
            level: fastLevel,
            alreadyCompleted: true,
            onComplete: () async {
              completions++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await start(tester);
      await frames(tester, 2);
      expect(find.text('Jetzt!'), findsOneWidget);
      final direction = CookieGame(fastLevel).target!.direction;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(ValueKey('cookie-${direction.name}'))),
      );
      await tester.pump();
      expect(
        find.text('1 / 1 · 0 / 3 Fehler'),
        findsOneWidget,
      ); // Before pointer up.
      await gesture.up();
      await frames(tester, 2.15);
      expect(find.text('Frisch ausgestochen!'), findsOneWidget);
      expect(find.text('Geschafft!'), findsNothing);
      expect(completions, 0);
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      expect(find.text('Geschafft!'), findsOneWidget);
      expect(completions, 1);
      await tester.tap(find.text('Noch einmal spielen'));
      await tester.pumpAndSettle();
      expect(find.text('Los geht’s'), findsOneWidget);
      expect(find.text('0 / 1 · 0 / 3 Fehler'), findsOneWidget);
      expect(find.byTooltip('Bereits geschafft'), findsOneWidget);
      expect(completions, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('three missed windows produce retry overlay without completion', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CookieScreen(
          level: fastLevel,
          onComplete: () async {
            completions++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await start(tester);
    await frames(tester, 10);
    expect(find.text('Fast geschafft'), findsOneWidget);
    expect(find.text('0 / 1 · 3 / 3 Fehler'), findsOneWidget);
    expect(completions, 0);
    await tester.tap(find.text('Noch einmal versuchen'));
    await tester.pumpAndSettle();
    expect(find.text('Los geht’s'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('help and background pause timing until explicitly resumed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CookieScreen(level: fastLevel, onComplete: () async {}),
      ),
    );
    await tester.pumpAndSettle();
    await start(tester);
    await frames(tester, .4);
    await tester.tap(find.byTooltip('Anleitung'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    await tester.tap(find.text('Verstanden'));
    await tester.pumpAndSettle();
    expect(find.text('Weiter'), findsOneWidget);
    expect(find.text('0 / 1 · 0 / 3 Fehler'), findsOneWidget);
    await start(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 30));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Weiter'), findsOneWidget);
    expect(find.text('0 / 1 · 0 / 3 Fehler'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('keyboard arrows use the same timing rules', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CookieScreen(level: fastLevel, onComplete: () async {}),
      ),
    );
    await tester.pumpAndSettle();
    await start(tester);
    await frames(tester, 2);
    final direction = CookieGame(fastLevel).target!.direction;
    final key = switch (direction) {
      CutDirection.up => LogicalKeyboardKey.arrowUp,
      CutDirection.down => LogicalKeyboardKey.arrowDown,
      CutDirection.left => LogicalKeyboardKey.arrowLeft,
      CutDirection.right => LogicalKeyboardKey.arrowRight,
    };
    await tester.sendKeyDownEvent(key);
    await tester.pump();
    expect(find.text('1 / 1 · 0 / 3 Fehler'), findsOneWidget);
    await tester.sendKeyUpEvent(key);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets('all shapes and preview fit without scrolling at $scenario', (
      tester,
    ) async {
      tester.view.physicalSize = scenario.$1;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final difficulty in GameDifficulty.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: CookieScreen(
              key: ValueKey(difficulty),
              level: CookieLevel.forDifficulty(difficulty),
              onComplete: () async {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const MaterialApp(home: GamePreviewScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  Offset swipeVector(CutDirection direction) => switch (direction) {
    CutDirection.up => const Offset(0, -40),
    CutDirection.down => const Offset(0, 40),
    CutDirection.left => const Offset(-40, 0),
    CutDirection.right => const Offset(40, 0),
  };

  for (final difficulty in GameDifficulty.values) {
    testWidgets(
      'swipe cuts in time before release, once per gesture at $difficulty',
      (tester) async {
        final level = CookieLevel.forDifficulty(difficulty);
        final reference = CookieGame(level);
        await tester.pumpWidget(
          MaterialApp(
            home: CookieScreen(level: level, onComplete: () async {}),
          ),
        );
        await tester.pumpAndSettle();
        await start(tester);
        await frames(tester, reference.target!.fraction / level.speed);
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('cookie-board'))),
        );
        await gesture.moveBy(swipeVector(reference.target!.direction));
        await tester.pump();
        expect(
          find.text('1 / ${level.checkpoints} · 0 / 3 Fehler'),
          findsOneWidget,
        );
        await gesture.moveBy(swipeVector(reference.target!.direction));
        await tester.pump();
        expect(
          find.text('1 / ${level.checkpoints} · 0 / 3 Fehler'),
          findsOneWidget,
        );
        await gesture.up();
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('early and wrong-direction swipes count as mistakes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CookieScreen(level: fastLevel, onComplete: () async {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('cookie-board')),
      const Offset(80, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 / 1 · 0 / 3 Fehler'), findsOneWidget); // Not started.
    await start(tester);
    await tester.drag(
      find.byKey(const ValueKey('cookie-board')),
      const Offset(80, 0),
    );
    await tester.pump();
    expect(find.text('0 / 1 · 1 / 3 Fehler'), findsOneWidget);
    await tester.tap(find.byTooltip('Neu starten'));
    await tester.pumpAndSettle();
    await start(tester);
    await frames(tester, 2);
    final direction = CookieGame(fastLevel).target!.direction;
    await tester.drag(
      find.byKey(const ValueKey('cookie-board')),
      -swipeVector(direction),
    );
    await tester.pump();
    expect(find.text('0 / 1 · 1 / 3 Fehler'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('development preview launches every difficulty', (tester) async {
    for (final difficulty in GameDifficulty.values) {
      await tester.pumpWidget(
        MaterialApp(key: ValueKey(difficulty), home: const GamePreviewScreen()),
      );
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<GameDifficulty>>(
            find.byType(DropdownButtonFormField<GameDifficulty>),
          )
          .onChanged!(difficulty);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plätzchen ausstechen'));
      await tester.pumpAndSettle();
      final screen = tester.widget<CookieScreen>(find.byType(CookieScreen));
      expect(screen.level.shape, CookieLevel.forDifficulty(difficulty).shape);
      expect(find.text(screen.level.shape.label), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('Day 7 shares completion and existing completion status', () {
    Future<void> complete() async {}
    final day = calendarDays(DateTime(2026, 12, 24), {'day-7'})[6];
    final screen = buildDailyChallenge(day, complete) as CookieScreen;
    expect(screen.onComplete, same(complete));
    expect(screen.alreadyCompleted, isTrue);
  });
}
