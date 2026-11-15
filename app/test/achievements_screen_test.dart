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
      tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(1);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('achievement-workshop')));
      await tester.pumpAndSettle();
      for (final difficulty in GameDifficulty.values) {
        await tester.tap(find.widgetWithText(OutlinedButton, difficulty.label));
        await tester.pumpAndSettle();
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
        await tester.tap(find.widgetWithText(OutlinedButton, difficulty.label));
        await tester.pumpAndSettle();
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
      await tester.tap(
        find.byKey(ValueKey('cookie-${game.target!.direction.name}')),
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
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.byType(Chip), findsNothing);
        await tester.tap(find.text('Teilziele ansehen'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(FittedBox), findsNothing);
        expect(find.byType(Scrollable), findsNothing);
        final seen = <String>{};
        for (var page = 0; page < 30; page++) {
          for (final token in item('allExtras').requirements) {
            final objective = find.byKey(ValueKey('objective-$token'));
            if (objective.evaluate().isNotEmpty) {
              seen.add(token);
              expect(
                tester.getRect(objective).bottom,
                lessThanOrEqualTo(scenario.$1.height),
              );
              final text = find.descendant(
                of: objective,
                matching: find.byType(Text),
              );
              expect(tester.widget<Text>(text).style!.fontSize, 16);
            }
          }
          final next = find.byWidgetPredicate(
            (w) => w is IconButton && w.tooltip == 'Weitere Teilziele',
          );
          if (tester.widget<IconButton>(next).onPressed == null) break;
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(seen, item('allExtras').requirements);
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
      await tester.tap(find.text('Teilziele ansehen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('objective-bonus:menorahs')));
      await tester.pumpAndSettle();
      expect(find.text(item('menorahs').description), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Offen'));
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
