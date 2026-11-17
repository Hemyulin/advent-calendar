import 'support/game_configuration.dart';
import 'helpers/chimney_rooftop.dart';
import 'package:advent_calendar/achievements/achievement_scope.dart';
import 'package:advent_calendar/achievements/achievement_store.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/chimney/chimney_game.dart';
import 'package:advent_calendar/challenges/chimney/chimney_screen.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/games/game_preview_screen.dart';
import 'package:advent_calendar/content/calendar_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(844, 390),
  ]) {
    testWidgets('pipe puzzle fits without scrolling at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(home: ChimneyScreen(onComplete: () async {})),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('chimney-tile-15')), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
      final grid = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(grid.position.maxScrollExtent, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('solve, animate, report completion once, and replay fresh', (
    tester,
  ) async {
    const level = ChimneyLevel(
      size: 3,
      seed: 12,
      preparationSeconds: 10,
      secondsPerTile: .1,
    );
    final reference = ChimneyGame(level);
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ChimneyScreen(
          level: level,
          alreadyCompleted: true,
          onComplete: () async {
            completions++;
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.byTooltip('Bereits geschafft'), findsOneWidget);
    for (final entry in reference.puzzle.solution.entries) {
      final tile = reference.puzzle.tiles[entry.key];
      while (!tile.ports.containsAll(
        ChimneyTile(tile.shape, entry.value).ports,
      )) {
        await tester.tap(find.byKey(ValueKey('chimney-tile-${entry.key}')));
        reference.rotate(entry.key);
      }
    }
    await frames(tester, 250);
    expect(
      find.byKey(const ValueKey('completion-congratulations')),
      findsOneWidget,
    );
    expect(completions, 1);
    await frames(tester, 10);
    expect(completions, 1);
    await tester.tap(find.text('Noch einmal spielen'));
    await tester.pump();
    expect(find.byKey(const ValueKey('completion-gift')), findsNothing);
    expect(find.text('Start in 10 s'), findsOneWidget);
    expect(completions, 1);
    expect(find.byTooltip('Bereits geschafft'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'exiting through the rooftop entrance earns the secret achievement and completes the day',
    (tester) async {
      const level = ChimneyLevel(
        size: 3,
        seed: 9,
        preparationSeconds: 5,
        secondsPerTile: .5,
      );
      final reference = ChimneyGame(level);
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      var completions = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementScope(
            record: (facts) => store.record(
              AchievementRun(
                day: 4,
                game: Minigame.chimney,
                difficulty: GameDifficulty.easy,
                facts: facts,
              ),
            ),
            child: ChimneyScreen(
              level: level,
              onComplete: () async {
                completions++;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      Future<void> rotateTo(int cell, int turns) async {
        final target = ChimneyTile(
          reference.puzzle.tiles[cell].shape,
          turns,
        ).ports;
        while (!reference.puzzle.tiles[cell].ports.containsAll(target)) {
          await tester.tap(find.byKey(ValueKey('chimney-tile-$cell')));
          reference.rotate(cell);
        }
      }

      for (final entry in rooftopTurns.entries) {
        await rotateTo(entry.key, entry.value);
      }
      await frames(tester, 132);
      await rotateTo(4, 3);
      await frames(tester, 200);
      await tester.pumpAndSettle();
      expect(
        store.earned(achievementCatalog.firstWhere((a) => a.id == 'santaUp')),
        isTrue,
      );
      expect(completions, 1);
      expect(find.text('Zum Öffnen tippen'), findsOneWidget);
      await tester.tap(find.text('Zum Öffnen tippen'));
      await tester.pumpAndSettle();
      expect(
        find.text('Zurück auf dem Dach – was für ein Umweg!'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('help pauses preparation; retry restores countdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChimneyScreen(
          level: const ChimneyLevel(
            size: 3,
            seed: 12,
            preparationSeconds: 1,
            secondsPerTile: .1,
          ),
          onComplete: () async {},
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Anleitung'));
    await frames(tester, 60);
    expect(find.text('Verstanden'), findsOneWidget);
    expect(find.text('Start in 1 s'), findsOneWidget);
    await tester.tap(find.text('Verstanden'));
    await frames(tester, 80);
    expect(find.text('Der Weg ist versperrt.'), findsOneWidget);
    await tester.tap(find.text('Noch einmal versuchen'));
    await tester.pump();
    expect(find.text('Start in 1 s'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('background time does not consume preparation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChimneyScreen(
          level: const ChimneyLevel(seed: 9),
          onComplete: () async {},
        ),
      ),
    );
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await frames(tester, 250);
    expect(find.text('Start in 10 s'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await frames(tester, 24);
    expect(find.text('Start in 9 s'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Day 9 and development preview expose the new game', (
    tester,
  ) async {
    final days = calendarDays(DateTime(2026, 12, 24), {});
    expect(
      configuredGame(buildDailyChallenge(days[8], () async {})),
      isA<ChimneyScreen>(),
    );
    await tester.pumpWidget(const MaterialApp(home: GamePreviewScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rettet den Weihnachtsmann!'));
    await frames(tester, 10);
    expect(find.byType(ChimneyScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
