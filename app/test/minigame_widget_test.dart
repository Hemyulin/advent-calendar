import 'dart:async';

import 'package:advent_calendar/app.dart';
import 'package:advent_calendar/presentation/challenge_screen.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/games/game_widgets.dart';
import 'package:advent_calendar/challenges/games/game_preview_screen.dart';
import 'package:advent_calendar/challenges/maze/maze_game.dart';
import 'package:advent_calendar/challenges/maze/maze_screen.dart';
import 'package:advent_calendar/challenges/maze/tilt_source.dart';
import 'package:advent_calendar/challenges/memory/memory_game.dart';
import 'package:advent_calendar/challenges/memory/memory_screen.dart';
import 'package:advent_calendar/content/calendar_day.dart';
import 'package:advent_calendar/progress/mock_progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTiltSource implements TiltSource {
  final controller = StreamController<Vec2>.broadcast();
  @override
  Stream<Vec2> get events => controller.stream;
}

class NoTiltSource implements TiltSource {
  @override
  Stream<Vec2> get events => Stream.error(UnsupportedError('test'));
}

void main() {
  void phone(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
  }) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> solveMemory(WidgetTester tester, MemoryLevel level) async {
    final reference = MemoryGame(level);
    for (var symbol = 0; symbol < 8; symbol++) {
      for (var i = 0; i < 16; i++) {
        if (reference.cards[i] == symbol) {
          await tapVisible(tester, find.byKey(ValueKey('memory-card-$i')));
        }
      }
    }
  }

  testWidgets(
    'Memory can be won, reports completion, and replay preserves progress',
    (tester) async {
      phone(tester);
      const level = MemoryLevel(seed: 23, attempts: 8);
      final repository = MockProgressRepository(completedIds: {});
      await tester.pumpWidget(
        MaterialApp(
          home: MemoryScreen(
            level: level,
            onComplete: () => repository.markCompleted('day-2'),
          ),
        ),
      );
      await solveMemory(tester, level);
      expect(find.text('Geschafft!'), findsOneWidget);
      expect(await repository.completedChallengeIds(), {'day-2'});
      await tapVisible(tester, find.text('Noch einmal spielen'));
      expect(find.text('0 / 8 Paare · 8 Versuche'), findsOneWidget);
      expect(await repository.completedChallengeIds(), {'day-2'});
    },
  );

  testWidgets(
    'Memory mismatches animate, block input, and lose without completion',
    (tester) async {
      phone(tester);
      const level = MemoryLevel(seed: 3, attempts: 8);
      final reference = MemoryGame(level);
      final other = reference.cards.indexWhere(
        (v) => v != reference.cards.first,
      );
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MemoryScreen(
            level: level,
            onComplete: () async {
              completed = true;
            },
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.byKey(const ValueKey('memory-card-0')));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.tap(find.byKey(ValueKey('memory-card-$other')));
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('0 / 8 Paare · ${7 - i} Versuche'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('memory-card-15')));
        await tester.pump(const Duration(milliseconds: 1100));
        await tester.pumpAndSettle();
      }
      expect(find.text('Fast geschafft'), findsOneWidget);
      expect(completed, isFalse);
      await tapVisible(tester, find.text('Noch einmal versuchen'));
      expect(find.text('0 / 8 Paare · 8 Versuche'), findsOneWidget);
    },
  );

  testWidgets(
    'maze completes the day after one flag and replay keeps completion',
    (tester) async {
      phone(tester);
      final source = FakeTiltSource();
      const board = MazeLayout(
        cells: 4,
        walls: [],
        start: Vec2(0.2, 0.5),
        goal: Vec2(0.8, 0.5),
        pits: [],
      );
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MazeScreen(
            course: const MazeCourse(layouts: [board]),
            tiltSource: source,
            onComplete: () async {
              completed++;
            },
          ),
        ),
      );
      source.controller.add(Vec2.zero);
      await tester.pump();
      for (var i = 0; i < 250; i++) {
        source.controller.add(const Vec2(0.1, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();
      expect(find.text('Geschafft!'), findsOneWidget);
      expect(completed, 1);
      expect(find.text('Nächstes Labyrinth'), findsNothing);
      await tester.tap(find.text('Noch einmal spielen'));
      await tester.pumpAndSettle();
      expect(find.text('6 Leben'), findsOneWidget);
      expect(find.text('Geschafft!'), findsNothing);
      expect(completed, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(source.controller.hasListener, isFalse);
      await source.controller.close();
    },
  );

  testWidgets(
    'sensor silence falls back safely and leaving releases the stream',
    (tester) async {
      phone(tester);
      final source = FakeTiltSource();
      await tester.pumpWidget(
        MaterialApp(
          home: MazeScreen(tiltSource: source, onComplete: () async {}),
        ),
      );
      source.controller.add(Vec2.zero);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Zum Steuern sanft neigen'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(
        find.byTooltip(
          'Keine Sensordaten verfügbar. Nutze die Pfeile oder die Tastatur.',
        ),
        findsOneWidget,
      );
      expect(source.controller.hasListener, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await source.controller.close();
    },
  );

  testWidgets('backgrounding pauses sensor input and resume reconnects it', (
    tester,
  ) async {
    phone(tester);
    final source = FakeTiltSource();
    await tester.pumpWidget(
      MaterialApp(
        home: MazeScreen(tiltSource: source, onComplete: () async {}),
      ),
    );
    source.controller.add(Vec2.zero);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(source.controller.hasListener, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    source.controller.add(Vec2.zero);
    await tester.pumpAndSettle();
    expect(source.controller.hasListener, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await source.controller.close();
  });

  testWidgets(
    'missing sensors fall back to touch controls, which accept a held press',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: MazeScreen(tiltSource: NoTiltSource(), onComplete: () async {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byTooltip(
          'Keine Sensordaten verfügbar. Nutze die Pfeile oder die Tastatur.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.bySemanticsLabel('Rechts'));
      final gesture = await tester.startGesture(
        tester.getCenter(find.bySemanticsLabel('Rechts')),
      );
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'completion save failures are retryable without repeating the game',
    (tester) async {
      phone(tester);
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionPanel(
              onComplete: () async {
                if (++attempts == 1) throw StateError('test');
              },
              onReplay: () {},
              message: 'Alle Paare gefunden.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Speichern fehlgeschlagen.'), findsOneWidget);
      await tapVisible(tester, find.text('Erneut speichern'));
      expect(find.text('Speichern fehlgeschlagen.'), findsNothing);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Noch einmal spielen'),
            )
            .onPressed,
        isNotNull,
      );
      expect(attempts, 2);
    },
  );

  test('daily games receive the same completion interface', () {
    Future<void> complete() async {}
    final days = calendarDays(DateTime(2026, 12, 7), {});
    expect(buildDailyChallenge(days[6], complete), isA<ChallengeScreen>());
    expect(
      (buildDailyChallenge(days[1], complete) as MemoryScreen).onComplete,
      same(complete),
    );
    expect(
      (buildDailyChallenge(days[2], complete) as MazeScreen).onComplete,
      same(complete),
    );
  });

  testWidgets(
    'preview opens each game before December without changing daily progress',
    (tester) async {
      phone(tester);
      final repository = MockProgressRepository(completedIds: {'day-1'});
      await tester.pumpWidget(
        AdventCalendarApp(
          now: DateTime(2026, 11, 6),
          progressRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byTooltip('Spiele ausprobieren'));
      expect(find.byType(GamePreviewScreen), findsOneWidget);
      for (final title in [
        'Paare finden',
        'Kugellabyrinth',
        'Nikolausstiefel',
      ]) {
        await tapVisible(tester, find.text(title));
        expect(find.text(title), findsOneWidget);
        await tapVisible(tester, find.byType(BackButton));
      }
      expect(await repository.completedChallengeIds(), {'day-1'});
    },
  );

  testWidgets('game layouts work on small screens with large type', (
    tester,
  ) async {
    phone(tester, size: const Size(320, 568), scale: 2);
    for (final screen in <Widget>[
      MemoryScreen(onComplete: () async {}),
      MazeScreen(tiltSource: NoTiltSource(), onComplete: () async {}),
    ]) {
      await tester.pumpWidget(MaterialApp(home: screen));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
