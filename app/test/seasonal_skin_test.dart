import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advent_calendar/achievements/achievement_scope.dart';
import 'package:advent_calendar/achievements/achievement_store.dart';
import 'package:advent_calendar/achievements/run_facts.dart';
import 'package:advent_calendar/achievements/hanukkah_games_screen.dart';
import 'package:advent_calendar/challenges/games/game_catalog.dart';
import 'package:advent_calendar/challenges/games/game_widgets.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/challenges/seasonal/game_skin.dart';
import 'package:advent_calendar/challenges/seasonal/game_skin_scope.dart';
import 'package:advent_calendar/challenges/bells/bells_game.dart';
import 'package:advent_calendar/challenges/cookies/cookie_game.dart';
import 'package:advent_calendar/challenges/memory/memory_screen.dart';
import 'package:advent_calendar/challenges/memory/memory_game.dart';
import 'package:advent_calendar/challenges/battery/battery_screen.dart';
import 'package:advent_calendar/challenges/battery/battery_art.dart';
import 'package:advent_calendar/challenges/seasonal/hanukkah_art.dart';
import 'support/memory_driver.dart';

Achievement get festival => achievements.firstWhere((a) => a.id == 'hanukkah');
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('appearance is explicit and does not follow the date', () {
    expect(hanukkahGames.length, 9);
    for (final game in Minigame.values) {
      final normal = buildMinigame(game, GameDifficulty.easy, () async {});
      final themed = buildMinigame(
        game,
        GameDifficulty.easy,
        () async {},
        skin: GameSkin.hanukkah,
      );
      if (supportsHanukkah(game)) {
        expect((normal as SkinnableGame).initialSkin, GameSkin.christmas);
        expect((themed as SkinnableGame).initialSkin, GameSkin.hanukkah);
      } else {
        expect(themed, isNot(isA<SkinnableGame>()));
      }
    }
  });
  test(
    'the three song hooks fit the sampled bells and retain difficulty guidance',
    () {
      for (final difficulty in GameDifficulty.values) {
        final level = BellsLevel.forDifficulty(difficulty, hanukkah: true);
        expect(level.guidance, BellGuidance.values[difficulty.index]);
        expect(
          level.rounds.single.melody.id,
          ['sevivon', 'maoz-tzur', 'hanerot'][difficulty.index],
        );
        final game = BellsGame(level)
          ..listen()
          ..finishListening();
        for (final note in game.current.notes) {
          expect(game.tap(note.pitch), isTrue);
        }
        expect(game.phase, BellsPhase.won);
        expect(game.completedMelodyIds, {game.current.melody.id});
      }
    },
  );
  test(
    'cookie silhouette changes while difficulty and randomized checkpoints stay intact',
    () {
      for (final difficulty in GameDifficulty.values) {
        final base = CookieLevel.forDifficulty(difficulty);
        final variant = CookieLevel.forDifficulty(difficulty, hanukkah: true);
        expect(
          variant.shape,
          [
            CookieShape.davidStar,
            CookieShape.temple,
            CookieShape.hanukkiah,
          ][difficulty.index],
        );
        expect(variant.speed, base.speed);
        expect(variant.checkpoints, base.checkpoints);
        expect(variant.timingWindowSeconds, base.timingWindowSeconds);
        final game = CookieGame(variant)..start();
        while (game.target != null) {
          game.advance(game.secondsToTarget);
          expect(game.press(game.target!.direction), CutInput.correct);
        }
        game.advance(100);
        expect(game.phase, CookiePhase.won);
      }
    },
  );
  test(
    'all nine distinct seasonal wins are required and persist, repeats never inflate',
    () async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      Future<void> win(Minigame game, bool mode) async {
        await store.record(
          AchievementRun(
            day: null,
            game: game,
            difficulty: GameDifficulty.easy,
            facts: RunFacts(hanukkahMode: mode),
          ),
        );
      }

      for (final game in Minigame.values) {
        await win(game, false);
      }
      await win(Minigame.oyVey, true);
      expect(store.progress(festival), 0);
      for (var i = 0; i < hanukkahGames.length; i++) {
        await win(hanukkahGames[i], true);
        await win(hanukkahGames[i], true);
        expect(store.progress(festival), i + 1);
        expect(store.earned(festival), i == hanukkahGames.length - 1);
      }
      final reloaded = AchievementStore();
      await reloaded.ready;
      addTearDown(reloaded.dispose);
      expect(reloaded.earned(festival), isTrue);
    },
  );
  test(
    'older progress keeps badges and voucher claims but reevaluates the expanded final bonus',
    () async {
      SharedPreferences.setMockInitialValues({
        AchievementStore.storageKey: jsonEncode({
          'rulesVersion': 4,
          'tokens': ['bonus:memory'],
          'earned': ['memory', 'allAchievements'],
          'claimed': ['allAchievements'],
          'rewards': {'allAchievements': 'Ein Gutschein'},
        }),
      });
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      expect(
        store.earned(achievements.firstWhere((a) => a.id == 'memory')),
        isTrue,
      );
      expect(store.earned(finalReward), isFalse);
      expect(store.claimed(finalReward), isTrue);
      expect(store.reward(finalReward), 'Ein Gutschein');
    },
  );
  testWidgets(
    'explicit Chanukka launch and replay keep their theme and record the shared fact once',
    (tester) async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await store.record(
        const AchievementRun(
          day: 1,
          game: Minigame.memory,
          difficulty: GameDifficulty.easy,
        ),
      );
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementScope(
            record: (facts) => store.record(
              AchievementRun(
                day: 1,
                game: Minigame.memory,
                difficulty: GameDifficulty.easy,
                facts: facts,
              ),
            ),
            child: SkinnableGame(
              initialSkin: GameSkin.hanukkah,
              builder: (_) => MemoryScreen(
                level: const MemoryLevel(seed: 42),
                alreadyCompleted: true,
                onComplete: () async {
                  completed++;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('hanukkah-skin-switch')), findsNothing);
      expect(find.bySemanticsLabel('Karte 1, verdeckt'), findsOneWidget);
      expect(store.progress(festival), 0);
      await solveVisibleMemory(tester);
      await tester.pumpAndSettle();
      expect(completed, 1);
      expect(store.progress(festival), 1);
      final dayAchievement = achievements.firstWhere((a) => a.id == 'allDays');
      expect(store.progress(dayAchievement), 1);
      expect(find.byKey(const ValueKey('hanukkah-skin-switch')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('completion-replay')));
      await tester.pumpAndSettle();
      expect(find.byType(CompletionPanel), findsNothing);
      expect(store.progress(festival), 1);
      expect(
        GameSkinScope.maybeOf(tester.element(find.byType(MemoryScreen)))!.skin,
        GameSkin.hanukkah,
      );
      await tester.tap(find.byKey(const ValueKey('hanukkah-replay')));
      await tester.pumpAndSettle();
      expect(
        GameSkinScope.isHanukkah(tester.element(find.byType(MemoryScreen))),
        isFalse,
      );
      expect(store.progress(festival), 1);
      await tester.tap(find.byKey(const ValueKey('hanukkah-replay')));
      await tester.pumpAndSettle();
      expect(
        GameSkinScope.isHanukkah(tester.element(find.byType(MemoryScreen))),
        isTrue,
      );
      expect(store.progress(festival), 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'oil mode retains drag controls and has five candles without devices or cable art',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: buildMinigame(
            Minigame.battery,
            GameDifficulty.easy,
            () async {},
            skin: GameSkin.hanukkah,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Öl-Panik'), findsOneWidget);
      expect(find.text('Smartphone'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is OilCandlePainter,
        ),
        findsNWidgets(5),
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is CablePainter,
        ),
        findsNothing,
      );
      await tester.dragFrom(
        tester.getCenter(find.byKey(const ValueKey('battery-cable'))),
        tester.getCenter(find.byKey(const ValueKey('battery-device-0'))) -
            tester.getCenter(find.byKey(const ValueKey('battery-cable'))),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 250));
      final supply =
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('battery-cord')),
                  )
                  .painter
              as OilSupplyPainter;
      expect(
        supply.end.dy,
        lessThan(
          tester.getSize(find.byKey(const ValueKey('battery-cord'))).height *
              .35,
        ),
      );
      expect(
        tester
            .widget<BatteryDeviceTile>(
              find.byKey(const ValueKey('battery-device-0')),
            )
            .charging,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final scenario in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets(
      'all seasonal games and their replay collection fit at $scenario',
      (tester) async {
        tester.view.physicalSize = scenario.$1;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        try {
          for (final game in hanukkahGames) {
            await tester.pumpWidget(
              MaterialApp(
                home: buildMinigame(
                  game,
                  GameDifficulty.hard,
                  () async {},
                  skin: GameSkin.hanukkah,
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 300));
            await tester.pump();
            expect(tester.takeException(), isNull, reason: game.name);
            expect(find.byType(SingleChildScrollView), findsNothing);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          }
          final store = AchievementStore();
          await store.ready;
          addTearDown(store.dispose);
          await tester.pumpWidget(
            MaterialApp(home: HanukkahGamesScreen(store: store)),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (var i = 0; i < hanukkahGames.length; i++) {
            if (i > 0 && i % 8 == 0) {
              await tester.tap(
                find.byKey(const ValueKey('hanukkah-games-next')),
              );
              await tester.pumpAndSettle();
            }
            final game = hanukkahGames[i];
            expect(
              find.byKey(ValueKey('hanukkah-game-${game.name}')),
              findsOneWidget,
            );
          }
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  }
}
