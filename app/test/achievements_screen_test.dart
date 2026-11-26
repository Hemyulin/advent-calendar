import 'support/achievement_driver.dart';
import 'package:advent_calendar/achievements/achievement_store.dart';
import 'package:advent_calendar/achievements/achievements_screen.dart';
import 'package:advent_calendar/achievements/achievement_scope.dart';
import 'package:advent_calendar/achievements/run_facts.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/games/game_widgets.dart';
import 'package:advent_calendar/challenges/cookies/cookie_game.dart';
import 'package:advent_calendar/challenges/cookies/cookie_screen.dart';
import 'package:advent_calendar/challenges/workshop/workshop_screen.dart';
import 'package:advent_calendar/challenges/maze/maze_screen.dart';
import 'package:advent_calendar/challenges/oy_vey/oy_vey_screen.dart';
import 'package:advent_calendar/admin/achievement_rewards_screen.dart';
import 'package:advent_calendar/presentation/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Achievement item(String id) => achievements.firstWhere((a) => a.id == id);
Future<void> lastPage(WidgetTester tester, {String id = 'candy'}) async {
  final index = [...achievements, finalReward].indexWhere((a) => a.id == id);
  tester
      .widget<PageView>(find.byType(PageView))
      .controller!
      .jumpToPage(index ~/ 4);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the GOY vey award launches the Christmas-catching variant', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = AchievementStore();
    await store.ready;
    addTearDown(store.dispose);
    await store.record(
      const AchievementRun(
        day: 22,
        game: Minigame.goyVey,
        difficulty: GameDifficulty.hard,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: AchievementsScreen(store: store)),
    );
    await tester.pumpAndSettle();
    await lastPage(tester, id: 'goyVey');
    await tester.tap(find.byKey(const ValueKey('achievement-goyVey')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('achievement-play-christmas-normal')),
    );
    await tester.pumpAndSettle();
    final screen = tester.widget<OyVeyScreen>(find.byType(OyVeyScreen));
    expect(screen.level.christmasTargets, isTrue);
    expect(screen.alreadyCompleted, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'secret 100% is hidden until earned and stays outside the required counter',
    (t) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await t.pumpWidget(MaterialApp(home: AchievementsScreen(store: store)));
      await t.pumpAndSettle();
      t.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(4);
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('achievement-hundredPercent')),
        findsNothing,
      );
      expect(
        find.text('0 / ${achievements.length} freigeschaltet'),
        findsOneWidget,
      );
      await store.record(
        const AchievementRun(
          day: null,
          game: Minigame.battery,
          difficulty: GameDifficulty.normal,
          facts: RunFacts(won: false, feats: {RunFeat.hundredPercent}),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('achievement-hundredPercent')),
        findsOneWidget,
      );
      expect(find.text('GEHEIMER ZUSATZERFOLG'), findsOneWidget);
      expect(
        find.text('1 / ${achievements.length} freigeschaltet'),
        findsOneWidget,
      );
      await t.tap(find.byKey(const ValueKey('achievement-hundredPercent')));
      await t.pumpAndSettle();
      expect(
        find.textContaining('für den Weihnachtsbonus nicht nötig'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('achievement-play-christmas-normal')),
        findsOneWidget,
      );
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'locked achievements explain goals but never reveal configured rewards',
    (tester) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await store.setReward(finalReward, 'Dein geheimer Massage-Gutschein');
      await tester.pumpWidget(
        MaterialApp(home: AchievementsScreen(store: store)),
      );
      await tester.pumpAndSettle();
      await lastPage(tester);
      await tester.tap(find.byKey(const ValueKey('achievement-candy')));
      await tester.pumpAndSettle();
      expect(find.text('Dein geheimer Massage-Gutschein'), findsNothing);
      expect(find.text('Als erhalten markieren'), findsNothing);
      expect(find.textContaining('Süßigkeiten'), findsOneWidget);
      await store.record(
        const AchievementRun(
          day: 3,
          game: Minigame.maze,
          difficulty: GameDifficulty.normal,
          facts: RunFacts(feats: {RunFeat.allCandy}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Noch zu entdecken.'), findsOneWidget);
      expect(store.progress(item('candy')), 1);
      expect(store.earned(item('candy')), isFalse);
      expect(find.text('Dein geheimer Massage-Gutschein'), findsNothing);
      expect(find.text('Als erhalten markieren'), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await lastPage(tester, id: finalReward.id);
      expect(find.text('ZUSÄTZLICHER BONUS'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('achievement-allAchievements')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dein geheimer Massage-Gutschein'), findsNothing);
      expect(
        find.text('Der Extra-Bonus bleibt bis zum letzten Erfolg geheim.'),
        findsOneWidget,
      );
      expect(
        find.text('ZUSÄTZLICH ZU DEINEN TÄGLICHEN GESCHENKEN'),
        findsOneWidget,
      );
      await earnAllAchievements(store);
      await tester.pumpAndSettle();
      expect(find.text('Dein geheimer Massage-Gutschein'), findsOneWidget);
      await tester.tap(find.text('Als erhalten markieren'));
      await tester.pumpAndSettle();
      expect(find.text('Gutschein erhalten'), findsOneWidget);
      expect(store.claimed(finalReward), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'victory records live facts once and displays newly unlocked achievements',
    (tester) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      var records = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementScope(
            record: (facts) {
              records++;
              return store.record(
                AchievementRun(
                  day: 2,
                  game: Minigame.cookies,
                  difficulty: GameDifficulty.easy,
                  facts: facts,
                ),
              );
            },
            child: GameResultLayer(
              result: CompletionPanel(
                facts: const RunFacts(feats: {RunFeat.perfectCookie}),
                onComplete: () async {},
                onReplay: () {},
                message: 'Fertig!',
              ),
              child: const Scaffold(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(records, 1);
      expect(store.progress(item('cookies')), 1);
      expect(store.progress(item('allDays')), 1);
      await tester.tap(find.byKey(const ValueKey('completion-gift')));
      await tester.pumpAndSettle();
      expect(records, 1);
      await tester.pumpWidget(
        const MaterialApp(
          home: GameResultLayer(
            result: CompletionPanel(
              facts: RunFacts(feats: {RunFeat.perfectCookie}),
              onComplete: noop,
              onReplay: replay,
              message: 'Vorschau',
            ),
            child: Scaffold(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(records, 1);
      expect(store.progress(item('cookies')), 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'all workshop difficulties can be practiced after the game is unlocked',
    (tester) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await store.record(
        const AchievementRun(
          day: 8,
          game: Minigame.workshop,
          difficulty: GameDifficulty.normal,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: AchievementsScreen(store: store)),
      );
      await tester.pumpAndSettle();
      await lastPage(tester, id: 'workshop');
      await tester.tap(find.byKey(const ValueKey('achievement-workshop')));
      await tester.pumpAndSettle();
      for (final difficulty in GameDifficulty.values) {
        await tester.tap(
          find.byKey(ValueKey('achievement-play-christmas-${difficulty.name}')),
        );
        await tester.pumpAndSettle();
        final introduction = find.byKey(
          const ValueKey('hanukkah-unlock-understood'),
        );
        if (introduction.evaluate().isNotEmpty) {
          await tester.tap(introduction);
          await tester.pumpAndSettle();
        }
        expect(
          tester
              .widget<WorkshopScreen>(find.byType(WorkshopScreen))
              .level!
              .size,
          [6, 7, 8][difficulty.index],
        );
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      expect(store.progress(item('allDays')), 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Naschkatze offers each maze difficulty without changing calendar progress',
    (tester) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await store.record(
        const AchievementRun(
          day: 3,
          game: Minigame.maze,
          difficulty: GameDifficulty.normal,
          facts: RunFacts(feats: {RunFeat.allCandy}),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: AchievementsScreen(store: store)),
      );
      await tester.pumpAndSettle();
      await lastPage(tester);
      await tester.tap(find.byKey(const ValueKey('achievement-candy')));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
      for (final difficulty in GameDifficulty.values) {
        await tester.tap(
          find.byKey(ValueKey('achievement-play-christmas-${difficulty.name}')),
        );
        await tester.pumpAndSettle();
        final introduction = find.byKey(
          const ValueKey('hanukkah-unlock-understood'),
        );
        if (introduction.evaluate().isNotEmpty) {
          await tester.tap(introduction);
          await tester.pumpAndSettle();
        }
        final screen = tester.widget<MazeScreen>(find.byType(MazeScreen));
        expect(
          screen.course!.layouts.single.cells,
          [5, 6, 8][difficulty.index],
        );
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      expect(store.progress(item('allDays')), 1);
      expect(store.progress(item('candy')), 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'real cookie results award only flawless attempts, including replay',
    (tester) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementScope(
            record: (facts) => store.record(
              AchievementRun(
                day: 2,
                game: Minigame.cookies,
                difficulty: GameDifficulty.easy,
                facts: facts,
              ),
            ),
            child: CookieScreen(
              level: const CookieLevel(
                speed: .25,
                checkpoints: 1,
                timingWindowSeconds: 1,
              ),
              onComplete: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final dynamic painter = tester
          .widget<CustomPaint>(find.byKey(const ValueKey('cookie-board')))
          .painter;
      final game = painter.game as CookieGame;
      await tester.tap(find.text('Los geht’s'));
      await tester.pump();
      while (game.secondsToTarget > .025) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.drag(
        find.byKey(const ValueKey('cookie-swipe-area')),
        switch (game.target!.direction) {
          CutDirection.up => const Offset(0, -60),
          CutDirection.down => const Offset(0, 60),
          CutDirection.left => const Offset(-60, 0),
          CutDirection.right => const Offset(60, 0),
        },
      );
      for (var i = 0; i < 70; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
      expect(store.progress(item('cookies')), 1);
      expect(store.progress(item('allExtras')), 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
    (const Size(844, 390), 2.0),
  ]) {
    testWidgets(
      'achievement collection, detail and voucher editor fit at $scenario',
      (tester) async {
        tester.view.physicalSize = scenario.$1;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = AchievementStore();
        await store.ready;
        addTearDown(store.dispose);
        await tester.pumpWidget(
          MaterialApp(home: AchievementsScreen(store: store)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('achievement-allExtras')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.text('Teilziele ansehen'), findsNothing);
        expect(find.byType(FittedBox), findsNothing);
        for (final token in item('allExtras').requirements) {
          final objective = find.byKey(ValueKey('objective-$token'));
          expect(objective, findsOneWidget);
          final text = find.descendant(
            of: objective,
            matching: find.byType(Text),
          );
          expect(tester.widget<Text>(text).style!.fontSize, 16);
        }
        final last = find.byKey(
          ValueKey('objective-${item('allExtras').requirements.last}'),
        );
        await tester.ensureVisible(last);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(last).bottom,
          lessThanOrEqualTo(scenario.$1.height),
        );
        await tester.pumpWidget(
          MaterialApp(home: AchievementRewardsScreen(store: store)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'objective checklist filters completed goals and opens their explanation',
    (tester) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await store.record(
        const AchievementRun(
          day: 6,
          game: Minigame.shoe,
          difficulty: GameDifficulty.easy,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: AchievementsScreen(store: store)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('achievement-allExtras')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('objective-bonus:menorahs')),
      );
      await tester.tap(find.byKey(const ValueKey('objective-bonus:menorahs')));
      await tester.pumpAndSettle();
      expect(find.text(item('menorahs').description), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Nur offene'));
      await tester.tap(find.text('Nur offene'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('objective-bonus:shoe')), findsNothing);
      await earnAllAchievements(store);
      await tester.pumpAndSettle();
      expect(find.text('Alle Teilziele geschafft!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('homepage exposes the player achievement collection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: CalendarScreen(now: DateTime(2026, 12, 1))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Erfolge'));
    await tester.pumpAndSettle();
    expect(find.byType(AchievementsScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> noop() async {}
void replay() {}
