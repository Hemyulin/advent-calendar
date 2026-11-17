import 'dart:async';
import 'package:advent_calendar/challenges/maze/maze_game.dart';
import 'package:advent_calendar/challenges/maze/tilt_source.dart';
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

Future<void> takeTrashOutside(WidgetTester t) async {
  await dragBag(t, const Offset(.46, .6), const Offset(.86, .22));
  final outside =
      t
              .widget<CustomPaint>(
                find.byWidgetPredicate(
                  (w) => w is CustomPaint && w.painter is TrashKitchenPainter,
                ),
              )
              .painter
          as TrashKitchenPainter;
  expect(outside.phase.name, 'outside');
  expect(find.byType(CompletionPanel), findsNothing);
  await dragBag(t, const Offset(.44, .75), const Offset(.8, .5));
}

class _TrashTilt implements TiltSource {
  final controller = StreamController<Vec2>.broadcast();
  @override
  Stream<Vec2> get events => controller.stream;
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
      await takeTrashOutside(t);
      expect(find.text('Frischen Beutel einsetzen.'), findsNothing);
      expect(find.byType(GameStats), findsNothing);
      expect(
        t.widget<GameScaffold>(find.byType(GameScaffold)).instructions,
        isNot(contains('frischen')),
      );
      expect(find.byType(CompletionPanel), findsNothing);
      expect(await progress.completedChallengeIds(), isEmpty);
      expect(
        store.earned(secretAchievements.firstWhere((a) => a.id == 'freshBag')),
        isFalse,
      );
      await dragBag(t, const Offset(.53, .25), const Offset(.46, .6));
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
      await takeTrashOutside(t);
      await dragBag(t, const Offset(.53, .25), const Offset(.46, .6));
      expect(
        find.byKey(const ValueKey('completion-congratulations')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('completion-gift')), findsNothing);
      expect(await progress.completedChallengeIds(), {'day-20'});
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'the unlabelled counter roll uses sensor input and releases sensors when hidden',
    (t) async {
      final tilt = _TrashTilt();
      await t.pumpWidget(
        MaterialApp(
          home: TrashScreen(tiltSource: tilt, onComplete: () async {}),
        ),
      );
      await t.pumpAndSettle();
      expect(tilt.controller.hasListener, isTrue);
      await takeTrashOutside(t);
      expect(tilt.controller.hasListener, isTrue);
      TrashKitchenPainter scene() =>
          t
                  .widget<CustomPaint>(
                    find.byWidgetPredicate(
                      (w) =>
                          w is CustomPaint && w.painter is TrashKitchenPainter,
                    ),
                  )
                  .painter
              as TrashKitchenPainter;
      tilt.controller.add(Vec2.zero);
      await t.pump();
      tilt.controller.add(const Vec2(-.5, 0));
      for (var i = 0; i < 40; i++) {
        await t.pump(const Duration(milliseconds: 20));
      }
      final x = scene().rollX;
      expect(x, lessThan(.5));
      expect(scene().rollAngle.abs(), greaterThan(.1));
      expect(find.byType(GameStats), findsNothing);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      expect(tilt.controller.hasListener, isFalse);
      await t.pump(const Duration(seconds: 2));
      expect(scene().rollX, x);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(tilt.controller.hasListener, isTrue);
      await dragBag(t, Offset(x, .25), const Offset(.46, .6));
      expect(find.byType(CompletionPanel), findsOneWidget);
      expect(tilt.controller.hasListener, isFalse);
      await t.pumpWidget(const SizedBox());
      await tilt.controller.close();
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'releasing the lifted bag spills rubbish; retry restores a full bin',
    (t) async {
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
      final r = t.getRect(find.byKey(const ValueKey('trash-kitchen')));
      Offset at(double x, double y) =>
          Offset(r.left + r.width * x, r.top + r.height * y);
      final gesture = await t.startGesture(at(.46, .6));
      await gesture.moveTo(at(.46, .38));
      await gesture.moveTo(at(.46, .38));
      await t.pump();
      TrashKitchenPainter scene() =>
          t
                  .widget<CustomPaint>(
                    find.byWidgetPredicate(
                      (w) =>
                          w is CustomPaint && w.painter is TrashKitchenPainter,
                    ),
                  )
                  .painter
              as TrashKitchenPainter;
      expect(scene().lifted, isTrue);
      await gesture.up();
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().phase.name, 'spilled');
      expect(scene().spillProgress, greaterThan(0));
      expect(find.byType(CompletionPanel), findsNothing);
      await t.pumpAndSettle();
      expect(find.text('Alles eingesaut!'), findsOneWidget);
      expect(wins, 0);
      await t.tap(find.text('Noch einmal versuchen'));
      await t.pumpAndSettle();
      expect(scene().phase.name, 'takeOut');
      expect(scene().lifted, isFalse);
      expect(scene().rollX, .53);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'the door opens while still holding the bag, before pointer release',
    (t) async {
      await t.pumpWidget(
        MaterialApp(home: TrashScreen(onComplete: () async {})),
      );
      await t.pumpAndSettle();
      final r = t.getRect(find.byKey(const ValueKey('trash-kitchen')));
      Offset at(double x, double y) =>
          Offset(r.left + r.width * x, r.top + r.height * y);
      final gesture = await t.startGesture(at(.46, .6));
      await gesture.moveTo(at(.46, .4));
      await gesture.moveTo(at(.86, .4));
      await t.pump(const Duration(milliseconds: 120));
      TrashKitchenPainter scene() =>
          t
                  .widget<CustomPaint>(
                    find.byWidgetPredicate(
                      (w) =>
                          w is CustomPaint && w.painter is TrashKitchenPainter,
                    ),
                  )
                  .painter
              as TrashKitchenPainter;
      expect(scene().openingDoor, isTrue);
      await t.pump(const Duration(milliseconds: 700));
      expect(scene().phase.name, 'outside');
      await gesture.up();
      await t.pumpAndSettle();
      expect(scene().phase.name, 'outside');
      expect(find.byType(DefeatPanel), findsNothing);
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
        await takeTrashOutside(t);
        expect(wins, 0);
        await dragBag(t, const Offset(.53, .25), const Offset(.46, .6));
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
