import 'package:advent_calendar/app.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/games/game_widgets.dart';
import 'package:advent_calendar/challenges/shoe/shoe_game.dart';
import 'package:advent_calendar/challenges/shoe/shoe_screen.dart';
import 'package:advent_calendar/content/calendar_day.dart';
import 'package:advent_calendar/presentation/festive_art.dart';
import 'package:advent_calendar/presentation/illustrated_door.dart';
import 'package:advent_calendar/progress/mock_progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all dirt belongs to the shoe; levels are repeatable', () {
    for (final difficulty in GameDifficulty.values) {
      final a = ShoeGame(ShoeLevel.forDifficulty(difficulty));
      final b = ShoeGame(ShoeLevel.forDifficulty(difficulty));
      expect(a.patches, isNotEmpty);
      expect(a.patches.every((p) => insideShoe(p.center)), isTrue);
      expect(a.patches.map((p) => p.dirt), b.patches.map((p) => p.dirt));
      expect(a.progress, 0);
    }
  });

  test(
    'stationary taps, invalid coordinates, and wiping away from the shoe do nothing',
    () {
      final game = ShoeGame(const ShoeLevel());
      final point = game.patches.first.center;
      for (var i = 0; i < 50; i++) {
        expect(game.stroke(point, point), isFalse);
      }
      expect(game.stroke(const ShoePoint(double.nan, 0), point), isFalse);
      expect(
        game.stroke(const ShoePoint(-0.5, -0.5), const ShoePoint(0, 0)),
        isFalse,
      );
      expect(game.cleanProgress, 0);
    },
  );

  test('repeatedly rubbing one spot cannot clean the whole shoe', () {
    final game = ShoeGame(const ShoeLevel());
    final center = game.patches.first.center;
    for (var i = 0; i < 100; i++) {
      game.stroke(
        ShoePoint(center.x - 0.02, center.y),
        ShoePoint(center.x + 0.02, center.y),
      );
    }
    expect(game.cleanProgress, greaterThan(0));
    expect(game.phase, ShoePhase.cleaning);
    expect(game.won, isFalse);
  });

  test('every difficulty is solvable by sweeping and requires both stages', () {
    for (final difficulty in GameDifficulty.values) {
      final game = ShoeGame(ShoeLevel.forDifficulty(difficulty));
      var sawPolishing = false;
      for (var pass = 0; pass < 20 && !game.won; pass++) {
        for (var y = 0.10; y < 0.94; y += 0.05) {
          final previous = game.phase;
          game.stroke(ShoePoint(0.1, y), ShoePoint(0.96, y));
          if (previous == ShoePhase.cleaning &&
              game.phase == ShoePhase.polishing) {
            sawPolishing = true;
            expect(game.cleanProgress, 1);
            expect(game.polishProgress, 0);
            expect(game.won, isFalse);
          }
        }
      }
      expect(sawPolishing, isTrue);
      expect(game.won, isTrue);
      expect(game.progress, 1);
      expect(
        game.stroke(const ShoePoint(0.1, 0.5), const ShoePoint(0.9, 0.5)),
        isFalse,
      );
    }
  });

  test('assistive brush action uses the same rules and reaches completion', () {
    final game = ShoeGame(const ShoeLevel());
    for (var i = 0; i < 1000 && !game.won; i++) {
      game.brushNextPatch();
    }
    expect(game.won, isTrue);
  });

  test('day six uses the shoe game and a boot on its calendar door', () {
    Future<void> complete() async {}
    final day = calendarDays(DateTime(2026, 12, 6), {})[5];
    final screen = buildDailyChallenge(day, complete) as ShoeScreen;
    expect(screen.onComplete, same(complete));
    expect(DoorDesign.forDay(6).motif, DoorMotif.boot);
  });

  void phone(
    WidgetTester tester, {
    double scale = 1,
    Size size = const Size(390, 844),
  }) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> scrubShoe(WidgetTester tester) async {
    final canvas = find.byKey(const ValueKey('shoe-canvas'));
    await tester.ensureVisible(canvas);
    await tester.pumpAndSettle();
    for (
      var pass = 0;
      pass < 15 && find.byType(CompletionPanel).evaluate().isEmpty;
      pass++
    ) {
      for (
        var row = 0;
        row < 12 && find.byType(CompletionPanel).evaluate().isEmpty;
        row++
      ) {
        final rect = tester.getRect(canvas);
        final y = rect.top + rect.height * (0.12 + row * 0.065);
        await tester.dragFrom(
          Offset(rect.left + rect.width * 0.10, y),
          Offset(rect.width * 0.85, 0),
        );
        await tester.pump();
      }
    }
    await tester.pumpAndSettle();
  }

  testWidgets(
    'rubbing cleans and polishes the shoe; replay keeps the completion',
    (tester) async {
      phone(tester);
      final repository = MockProgressRepository(completedIds: {});
      await tester.pumpWidget(
        MaterialApp(
          home: ShoeScreen(
            level: ShoeLevel.forDifficulty(GameDifficulty.easy),
            onComplete: () => repository.markCompleted('day-6'),
          ),
        ),
      );
      expect(find.text('Bürsten · 0 %'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('shoe-canvas')));
      await tester.pumpAndSettle();
      expect(await repository.completedChallengeIds(), isEmpty);
      await scrubShoe(tester);
      expect(
        find.text('Geschafft!'),
        findsOneWidget,
        reason: tester.widget<GameStats>(find.byType(GameStats)).text,
      );
      expect(await repository.completedChallengeIds(), {'day-6'});
      await tester.ensureVisible(find.text('Noch einmal spielen'));
      await tester.tap(find.text('Noch einmal spielen'));
      await tester.pumpAndSettle();
      expect(find.text('Bürsten · 0 %'), findsOneWidget);
      expect(await repository.completedChallengeIds(), {'day-6'});
    },
  );

  testWidgets('day six updates the actual calendar checkmark after cleaning', (
    tester,
  ) async {
    phone(tester);
    final repository = MockProgressRepository(completedIds: {});
    await tester.pumpWidget(
      AdventCalendarApp(
        now: DateTime(2026, 12, 6),
        progressRepository: repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(IllustratedDoor));
    await tester.pumpAndSettle();
    expect(find.byType(ShoeScreen), findsOneWidget);
    await scrubShoe(tester);
    expect(await repository.completedChallengeIds(), {'day-6'});
    await tester.ensureVisible(find.text('Zurück zum Kalender'));
    await tester.tap(find.text('Zurück zum Kalender'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('6. Dezember, Heute, geschafft'),
      findsOneWidget,
    );
  });

  testWidgets('shoe instructions fit a small screen with large type', (
    tester,
  ) async {
    phone(tester, size: const Size(320, 568), scale: 2);
    await tester.pumpWidget(
      MaterialApp(home: ShoeScreen(onComplete: () async {})),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('shoe-canvas')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
