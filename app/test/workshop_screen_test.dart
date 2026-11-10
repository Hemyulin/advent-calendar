import 'package:advent_calendar/challenges/workshop/workshop_game.dart';
import 'package:advent_calendar/challenges/workshop/workshop_screen.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/games/game_preview_screen.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/content/calendar_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/workshop_solutions.dart';

String name(String letter) => switch (letter) {
  'U' => 'up',
  'D' => 'down',
  'L' => 'left',
  'R' => 'right',
  _ => throw ArgumentError(letter),
};
Future<void> move(WidgetTester tester, String letter) async {
  await tester.tap(find.byKey(ValueKey('workshop-${name(letter)}')));
  await tester.pump(const Duration(milliseconds: 180));
}

void main() {
  testWidgets(
    'handcrafted level completes once and replay retains completion',
    (tester) async {
      var completions = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: WorkshopScreen(
            level: WorkshopLevel.forDifficulty(GameDifficulty.easy),
            alreadyCompleted: true,
            onComplete: () async {
              completions++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final letter in workshopSolutions[0].split('')) {
        await move(tester, letter);
      }
      await tester.pumpAndSettle();
      expect(find.text('Geschafft!'), findsOneWidget);
      expect(completions, 1);
      await tester.tap(find.text('Noch einmal spielen'));
      await tester.pumpAndSettle();
      expect(find.text('0 / 2 Geschenke · 0 Züge'), findsOneWidget);
      expect(find.byTooltip('Bereits geschafft'), findsOneWidget);
      expect(completions, 1);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const ValueKey('workshop-undo')))
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('a pushed present can be undone and the board restarted', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WorkshopScreen(
          level: WorkshopLevel.forDifficulty(GameDifficulty.easy),
          onComplete: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final letter in 'UURRD'.split('')) {
      await move(tester, letter);
    }
    expect(find.text('1 / 2 Geschenke · 5 Züge'), findsOneWidget);
    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 2 Geschenke · 4 Züge'), findsOneWidget);
    await tester.tap(find.byTooltip('Neu starten'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 2 Geschenke · 0 Züge'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'one long swipe means one move and keyboard uses the same rules',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkshopScreen(
            level: WorkshopLevel.forDifficulty(GameDifficulty.easy),
            onComplete: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('workshop-board')),
        const Offset(0, -180),
      );
      await tester.pumpAndSettle();
      expect(find.text('0 / 2 Geschenke · 1 Zug'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft); // Wall.
      await tester.pumpAndSettle();
      expect(find.text('0 / 2 Geschenke · 1 Zug'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('0 / 2 Geschenke · 2 Züge'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets('workshop and all previews fit at $scenario', (tester) async {
      tester.view.physicalSize = scenario.$1;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final difficulty in GameDifficulty.values) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(difficulty),
            home: WorkshopScreen(
              level: WorkshopLevel.forDifficulty(difficulty),
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

  testWidgets('each development difficulty opens its handcrafted board', (
    tester,
  ) async {
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
      await tester.tap(find.text('Wichtelwerkstatt'));
      await tester.pumpAndSettle();
      final screen = tester.widget<WorkshopScreen>(find.byType(WorkshopScreen));
      expect(screen.level!.size, [5, 7, 8][difficulty.index]);
      expect(screen.level!.presents.length, 2 + difficulty.index);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('Day 8 shares completion and replay state', () {
    Future<void> complete() async {}
    final screen =
        buildDailyChallenge(
              calendarDays(DateTime(2026, 12, 24), {'day-8'})[7],
              complete,
            )
            as WorkshopScreen;
    expect(screen.onComplete, same(complete));
    expect(screen.alreadyCompleted, isTrue);
  });
}
