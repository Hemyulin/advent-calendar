import 'package:advent_calendar/achievements/achievement_store.dart';
import 'package:advent_calendar/achievements/achievement_scope.dart';
import 'package:advent_calendar/achievements/run_facts.dart';
import 'package:advent_calendar/challenges/cookies/cookie_screen.dart';
import 'package:advent_calendar/challenges/games/challenge_assistance.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/games/game_widgets.dart';
import 'package:advent_calendar/challenges/trash/trash_screen.dart';
import 'package:advent_calendar/content/calendar_schedule.dart';
import 'package:advent_calendar/presentation/calendar_screen.dart';
import 'package:advent_calendar/presentation/illustrated_door.dart';
import 'package:advent_calendar/progress/mock_progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> dragBag(WidgetTester t, Offset from, Offset to) async {
  final r = t.getRect(find.byKey(const ValueKey('trash-kitchen')));
  Offset at(Offset p) =>
      Offset(r.left + r.width * p.dx, r.top + r.height * p.dy);
  final gesture = await t.startGesture(at(from));
  await gesture.moveTo(at(to));
  await gesture.moveTo(at(to));
  await gesture.up();
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'an actual calendar fallback requires a fresh bag and preserves completion on replay',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final progress = MockProgressRepository(completedIds: {});
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: CalendarScreen(
            now: DateTime(2026, 12, 20),
            progressRepository: progress,
            achievementStore: store,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byType(IllustratedDoor));
      await t.pumpAndSettle();
      expect(find.byType(CookieScreen), findsOneWidget);
      await t.tap(find.byTooltip('Zu schwer?'));
      await t.pumpAndSettle();
      await t.tap(find.text('Lieber Müll rausbringen'));
      await t.pumpAndSettle();
      expect(find.byType(TrashScreen), findsOneWidget);
      await dragBag(t, const Offset(.46, .6), const Offset(.86, .22));
      expect(find.text('Frischen Beutel einsetzen.'), findsOneWidget);
      expect(find.byType(CompletionPanel), findsNothing);
      expect(await progress.completedChallengeIds(), isEmpty);
      expect(
        store.earned(secretAchievements.firstWhere((a) => a.id == 'freshBag')),
        isFalse,
      );
      await dragBag(t, const Offset(.84, .8), const Offset(.46, .6));
      expect(find.byKey(const ValueKey('completion-gift')), findsOneWidget);
      expect(await progress.completedChallengeIds(), {'day-20'});
      expect(store.tokenComplete('game:trash'), isTrue);
      expect(store.tokenComplete('game:cookies'), isFalse);
      expect(store.tokenComplete('bonus:cookies:hard'), isFalse);
      expect(
        store.earned(secretAchievements.firstWhere((a) => a.id == 'freshBag')),
        isTrue,
      );
      await t.pump(const Duration(seconds: 6));
      await t.tap(find.byKey(const ValueKey('completion-replay')));
      await t.pumpAndSettle();
      expect(await progress.completedChallengeIds(), {'day-20'});
      expect(find.byType(CompletionPanel), findsNothing);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'slowing the final cookie keeps its shape and excludes strict bonus feats',
    (t) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: FlexibleChallenge(
            assignment: defaultAssignments[19],
            onComplete: () async {},
            record: (game, difficulty, facts) => store.record(
              AchievementRun(
                day: 20,
                game: game,
                difficulty: difficulty,
                facts: facts,
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final original = t.widget<CookieScreen>(find.byType(CookieScreen)).level;
      await t.tap(find.byTooltip('Zu schwer?'));
      await t.pumpAndSettle();
      await t.tap(find.text('Etwas leichter'));
      await t.pumpAndSettle();
      final slower = t.widget<CookieScreen>(find.byType(CookieScreen)).level;
      expect(slower.shape, original.shape);
      expect(slower.speed, lessThan(original.speed));
      expect(
        slower.timingWindowSeconds,
        greaterThan(original.timingWindowSeconds),
      );
      expect(slower.checkpoints, original.checkpoints);
      // Exercise the same scoped writer used by completion and mid-run feats.
      final context = t.element(find.byType(CookieScreen));
      await AchievementScope.maybeOf(
        context,
      )!.record(const RunFacts(feats: {RunFeat.perfectCookie}));
      expect(store.tokenComplete('day:20'), isTrue);
      expect(store.tokenComplete('bonus:cookies:hard'), isFalse);
      await t.pumpWidget(const SizedBox());
    },
  );

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('assistance choices stay usable at $size with large text', (
      t,
    ) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(
        MaterialApp(
          home: FlexibleChallenge(
            assignment: defaultAssignments[19],
            onComplete: () async {},
            record: (_, _, _) async => [],
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Zu schwer?'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.tap(find.text('Lieber Müll rausbringen'));
      await t.pumpAndSettle();
      expect(find.byType(TrashScreen), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets(
      'trash game fits and remains playable at $size with large text',
      (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        var wins = 0;
        await t.pumpWidget(
          MaterialApp(
            home: TrashScreen(
              onComplete: () async {
                wins++;
              },
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await dragBag(t, const Offset(.46, .6), const Offset(.86, .22));
        expect(wins, 0);
        await dragBag(t, const Offset(.84, .8), const Offset(.46, .6));
        expect(wins, 1);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }

  test(
    'fresh bag secret cannot be awarded by another game or by an unfinished chore',
    () async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      Future<void> record(Minigame game, {bool won = true}) async {
        await store.record(
          AchievementRun(
            day: null,
            game: game,
            difficulty: GameDifficulty.easy,
            facts: RunFacts(won: won, feats: {RunFeat.freshBag}),
          ),
        );
      }

      await record(Minigame.cookies);
      await record(Minigame.trash, won: false);
      expect(store.tokenComplete('bonus:freshBag'), isFalse);
      await record(Minigame.trash);
      expect(store.tokenComplete('bonus:freshBag'), isTrue);
      final reloaded = AchievementStore();
      await reloaded.ready;
      expect(reloaded.tokenComplete('bonus:freshBag'), isTrue);
      reloaded.dispose();
      expect(
        achievements.expand((a) => a.requirements),
        isNot(contains('bonus:freshBag')),
      );
      expect(
        achievements.firstWhere((a) => a.id == 'allGames').requirements,
        isNot(contains('game:trash')),
      );
    },
  );
}
