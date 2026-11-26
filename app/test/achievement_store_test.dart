import 'dart:convert';
import 'package:advent_calendar/challenges/bells/bell_melodies.dart';
import 'support/achievement_driver.dart';
import 'package:advent_calendar/achievements/achievement_store.dart';
import 'package:advent_calendar/achievements/run_facts.dart';
import 'package:advent_calendar/challenges/games/game_kind.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:advent_calendar/progress/local_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Achievement achievement(String id) =>
    achievementCatalog.firstWhere((a) => a.id == id);
AchievementRun run(
  Minigame game, {
  int? day = 1,
  GameDifficulty difficulty = GameDifficulty.normal,
  Set<RunFeat> feats = const {},
}) => AchievementRun(
  day: day,
  game: game,
  difficulty: difficulty,
  facts: RunFacts(feats: feats),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'GOY vey award is earned only by a clean winning Christmas run',
    () async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await store.record(run(Minigame.oyVey, feats: {RunFeat.cleanGoyVey}));
      expect(store.earned(achievement('goyVey')), isFalse);
      await store.record(run(Minigame.goyVey));
      expect(store.earned(achievement('goyVey')), isFalse);
      await store.record(
        const AchievementRun(
          day: 22,
          game: Minigame.goyVey,
          difficulty: GameDifficulty.hard,
          facts: RunFacts(won: false, feats: {RunFeat.cleanGoyVey}),
        ),
      );
      expect(store.earned(achievement('goyVey')), isFalse);
      final earned = await store.record(
        run(Minigame.goyVey, feats: {RunFeat.cleanGoyVey}),
      );
      expect(earned.map((a) => a.id), contains('goyVey'));
      expect(store.tokenComplete('bonus:cleanOy'), isFalse);
      expect(store.tokenComplete('bonus:noJewishMisses'), isFalse);
      final reloaded = AchievementStore();
      await reloaded.ready;
      addTearDown(reloaded.dispose);
      expect(reloaded.earned(achievement('goyVey')), isTrue);
    },
  );

  test(
    'existing awards and claimed rewards survive the new GOY vey requirement',
    () async {
      SharedPreferences.setMockInitialValues({
        AchievementStore.storageKey: jsonEncode({
          'rulesVersion': 9,
          'tokens': ['bonus:memory'],
          'earned': ['memory', 'allGames', 'allExtras', 'allAchievements'],
          'claimed': ['allAchievements'],
          'rewards': {},
        }),
      });
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      expect(store.earned(achievement('memory')), isTrue);
      expect(store.earned(achievement('allGames')), isFalse);
      expect(store.earned(finalReward), isFalse);
      expect(store.claimed(finalReward), isTrue);
    },
  );

  test(
    'all rules have a finite checklist and all extras cover the complete finite checklist',
    () {
      expect(achievements.map((a) => a.id).toSet().length, achievements.length);
      expect(
        achievement('allExtras').requirements.length,
        19 + bellMelodies.length,
      );
      final individual = achievements
          .skip(3)
          .where((a) => a.id != 'hanukkah')
          .expand((a) => a.requirements)
          .toSet();
      expect(individual, achievement('allExtras').requirements);
    },
  );

  test(
    '80% persists immediately without granting a win or other run bonuses',
    () async {
      final store = AchievementStore();
      await store.ready;
      const facts = RunFacts(
        won: false,
        hanukkahMode: true,
        feats: {RunFeat.fullyCharged, RunFeat.halfCharged, RunFeat.safeBattery},
      );
      const milestone = AchievementRun(
        day: 8,
        game: Minigame.battery,
        difficulty: GameDifficulty.normal,
        facts: facts,
      );
      expect((await store.record(milestone)).map((a) => a.id), [
        'fullyCharged',
      ]);
      expect(store.progress(achievement('allDays')), 0);
      expect(store.progress(achievement('allGames')), 0);
      expect(store.progress(achievement('hanukkah')), 0);
      expect(store.earned(achievement('halfCharged')), isFalse);
      expect(store.earned(achievement('safeBattery')), isFalse);
      expect(await store.record(milestone), isEmpty);
      final reloaded = AchievementStore();
      await reloaded.ready;
      expect(reloaded.earned(achievement('fullyCharged')), isTrue);
      expect(
        reloaded.earned(
          secretAchievements.firstWhere((a) => a.id == 'hundredPercent'),
        ),
        isFalse,
      );
      expect(
        await reloaded.record(
          const AchievementRun(
            day: 9,
            game: Minigame.chimney,
            difficulty: GameDifficulty.normal,
            facts: facts,
          ),
        ),
        isEmpty,
      );
      store.dispose();
      reloaded.dispose();
    },
  );

  test(
    'v6 migration retains individual awards and claims but requires the new milestone',
    () async {
      final oldTokens = <String>{
        for (final a in achievements)
          if (a.id != 'fullyCharged')
            ...a.requirements.where((t) => t != 'bonus:fullyCharged'),
      };
      SharedPreferences.setMockInitialValues({
        AchievementStore.storageKey: jsonEncode({
          'rulesVersion': 6,
          'tokens': oldTokens.toList(),
          'earned': [
            ...achievements
                .where((a) => a.id != 'fullyCharged')
                .map((a) => a.id),
            finalReward.id,
          ],
          'claimed': [finalReward.id],
          'rewards': {},
        }),
      });
      final store = AchievementStore();
      await store.ready;
      expect(store.earned(achievement('safeBattery')), isTrue);
      expect(store.earned(achievement('fullyCharged')), isFalse);
      expect(store.earned(achievement('allExtras')), isFalse);
      expect(store.earned(finalReward), isFalse);
      await store.record(
        const AchievementRun(
          day: null,
          game: Minigame.battery,
          difficulty: GameDifficulty.easy,
          facts: RunFacts(won: false, feats: {RunFeat.fullyCharged}),
        ),
      );
      expect(store.earned(achievement('allExtras')), isTrue);
      expect(store.earned(finalReward), isTrue);
      expect(store.claimed(finalReward), isTrue);
      store.dispose();
    },
  );

  test(
    'all required achievements and the voucher are attainable without 100%',
    () async {
      final store = AchievementStore();
      await store.ready;
      addTearDown(store.dispose);
      await earnAllAchievements(store);
      expect(secretAchievements.every((a) => !store.earned(a)), isTrue);
      expect(store.earned(finalReward), isTrue);
      expect(store.progress(finalReward), achievements.length);
      expect(store.earned(achievement('allExtras')), isTrue);
      expect(
        store.earned(
          secretAchievements.firstWhere((a) => a.id == 'hundredPercent'),
        ),
        isFalse,
      );
      expect(
        finalReward.requirements,
        isNot(contains('achievement:hundredPercent')),
      );
      expect(bonusObjectives, isNot(contains('hundredPercent')));
      expect(store.earned(achievement('santaUp')), isFalse);
      expect(bonusObjectives, isNot(contains('santaUp')));
      expect(finalReward.requirements, isNot(contains('achievement:santaUp')));
      final earned = await store.record(
        const AchievementRun(
          day: null,
          game: Minigame.battery,
          difficulty: GameDifficulty.normal,
          facts: RunFacts(won: false, feats: {RunFeat.hundredPercent}),
        ),
      );
      expect(earned.map((a) => a.id), ['hundredPercent']);
      expect(store.progress(finalReward), achievements.length);
      final reloaded = AchievementStore();
      await reloaded.ready;
      expect(
        reloaded.earned(
          secretAchievements.firstWhere((a) => a.id == 'hundredPercent'),
        ),
        isTrue,
      );
      expect(reloaded.earned(finalReward), isTrue);
      reloaded.dispose();
    },
  );

  test(
    'a prior 100% award migrates to both thresholds without losing voucher claims',
    () async {
      for (final tokens in [
        <String>['bonus:fullyCharged'],
        <String>[],
      ]) {
        SharedPreferences.setMockInitialValues({
          AchievementStore.storageKey: jsonEncode({
            'rulesVersion': 7,
            'tokens': tokens,
            'earned': ['fullyCharged'],
            'claimed': [finalReward.id],
            'rewards': {finalReward.id: 'Gutschein'},
          }),
        });
        final store = AchievementStore();
        await store.ready;
        expect(store.earned(achievement('fullyCharged')), isTrue);
        expect(
          store.earned(
            secretAchievements.firstWhere((a) => a.id == 'hundredPercent'),
          ),
          isTrue,
        );
        expect(store.claimed(finalReward), isTrue);
        expect(store.reward(finalReward), 'Gutschein');
        store.dispose();
      }
    },
  );

  test(
    'a previously earned Santa return stays earned as an optional secret',
    () async {
      SharedPreferences.setMockInitialValues({
        AchievementStore.storageKey: jsonEncode({
          'rulesVersion': 8,
          'tokens': ['bonus:santaUp'],
          'earned': ['santaUp'],
          'claimed': [],
          'rewards': {},
        }),
      });
      final store = AchievementStore();
      await store.ready;
      expect(store.earned(achievement('santaUp')), isTrue);
      expect(store.progress(achievement('allExtras')), 0);
      expect(achievements.any((a) => a.id == 'santaUp'), isFalse);
      expect(secretAchievements.any((a) => a.id == 'santaUp'), isTrue);
      store.dispose();
    },
  );

  test(
    'the no-miss Oy Vey secret is win-only, persistent and outside required progress',
    () async {
      final store = AchievementStore();
      await store.ready;
      final secret = achievementCatalog.firstWhere(
        (a) => a.id == 'noJewishMisses',
      );
      await store.record(run(Minigame.memory, feats: {RunFeat.noJewishMisses}));
      expect(store.earned(secret), isFalse);
      await store.record(
        const AchievementRun(
          day: null,
          game: Minigame.oyVey,
          difficulty: GameDifficulty.normal,
          facts: RunFacts(won: false, feats: {RunFeat.noJewishMisses}),
        ),
      );
      expect(store.earned(secret), isFalse);
      final victory = run(
        Minigame.oyVey,
        day: null,
        feats: {RunFeat.noJewishMisses},
      );
      expect((await store.record(victory)).map((a) => a.id), [
        'noJewishMisses',
      ]);
      expect(await store.record(victory), isEmpty);
      expect(bonusObjectives, isNot(contains('noJewishMisses')));
      expect(
        finalReward.requirements,
        isNot(contains('achievement:noJewishMisses')),
      );
      expect(store.progress(achievement('allExtras')), 0);
      final reloaded = AchievementStore();
      await reloaded.ready;
      expect(reloaded.earned(secret), isTrue);
      store.dispose();
      reloaded.dispose();
    },
  );

  test(
    '24 distinct days and all distinct games; repeats never inflate progress',
    () async {
      final store = AchievementStore();
      await store.ready;
      for (var day = 1; day <= 24; day++) {
        await store.record(
          run(Minigame.values[(day - 1) % Minigame.values.length], day: day),
        );
      }
      expect(store.earned(achievement('allDays')), isTrue);
      expect(store.earned(achievement('allGames')), isTrue);
      expect(await store.record(run(Minigame.memory)), isEmpty);
      final reloaded = AchievementStore();
      await reloaded.ready;
      expect(reloaded.progress(achievement('allDays')), 24);
      expect(
        reloaded.progress(achievement('allGames')),
        Minigame.values.length - 1,
      );
      store.dispose();
      reloaded.dispose();
    },
  );

  test(
    'bonus goals only accept facts from the relevant game and Nikolaus door',
    () async {
      final store = AchievementStore();
      await store.ready;
      await store.record(run(Minigame.bells, feats: RunFeat.values.toSet()));
      expect(store.progress(achievement('allExtras')), 0);
      await store.record(run(Minigame.shoe, day: 5));
      expect(store.earned(achievement('shoe')), isFalse);
      expect(
        (await store.record(run(Minigame.shoe, day: 6))).map((a) => a.id),
        contains('shoe'),
      );
      await store.record(run(Minigame.memory, feats: {RunFeat.perfectMemory}));
      await store.record(
        run(Minigame.oyVey, feats: {RunFeat.onlyMenorahs, RunFeat.cleanOyVey}),
      );
      await store.record(run(Minigame.goyVey, feats: {RunFeat.cleanGoyVey}));
      await store.record(run(Minigame.walkHome, feats: {RunFeat.cleanWalk}));
      await store.record(run(Minigame.walkHome, feats: {RunFeat.roughWalk}));
      await store.record(
        run(
          Minigame.battery,
          feats: {
            RunFeat.safeBattery,
            RunFeat.halfCharged,
            RunFeat.fullyCharged,
          },
        ),
      );
      await store.record(run(Minigame.maze, feats: {RunFeat.allCandy}));
      await store.record(run(Minigame.chimney, feats: {RunFeat.santaEscaped}));
      for (final difficulty in GameDifficulty.values) {
        await store.record(
          run(Minigame.maze, difficulty: difficulty, feats: {RunFeat.allCandy}),
        );
        await store.record(
          run(
            Minigame.cookies,
            difficulty: difficulty,
            feats: {RunFeat.perfectCookie},
          ),
        );
        await store.record(
          run(
            Minigame.workshop,
            difficulty: difficulty,
            feats: {RunFeat.efficientWorkshop},
          ),
        );
      }
      await store.record(
        AchievementRun(
          day: null,
          game: Minigame.bells,
          difficulty: GameDifficulty.normal,
          facts: RunFacts(
            completedBellSongs: bellMelodies.map((m) => m.id).toSet(),
          ),
        ),
      );
      expect(store.earned(achievement('allExtras')), isTrue);
      expect(
        store.progress(achievement('allExtras')),
        19 + bellMelodies.length,
      );
      store.dispose();
    },
  );

  test(
    'perfect cookies and efficient workshop each require all three difficulties',
    () async {
      final store = AchievementStore();
      await store.ready;
      for (final difficulty in GameDifficulty.values) {
        await store.record(
          run(Minigame.cookies, day: null, difficulty: difficulty),
        );
        expect(store.progress(achievement('cookies')), difficulty.index);
        await store.record(
          run(
            Minigame.cookies,
            day: null,
            difficulty: difficulty,
            feats: {RunFeat.perfectCookie},
          ),
        );
        await store.record(
          run(
            Minigame.workshop,
            day: null,
            difficulty: difficulty,
            feats: {RunFeat.efficientWorkshop},
          ),
        );
        expect(
          store.earned(achievement('cookies')),
          difficulty == GameDifficulty.hard,
        );
        expect(
          store.earned(achievement('workshop')),
          difficulty == GameDifficulty.hard,
        );
      }
      expect(store.progress(achievement('allDays')), 0);
      store.dispose();
    },
  );

  test(
    'replays earn missing bonuses and simultaneous writes retain every goal',
    () async {
      final store = AchievementStore();
      await store.ready;
      await store.record(run(Minigame.memory));
      final newlyEarned = await store.record(
        run(Minigame.memory, feats: {RunFeat.perfectMemory}),
      );
      expect(newlyEarned.map((a) => a.id), ['memory']);
      await Future.wait([
        for (var day = 2; day <= 24; day++)
          store.record(run(Minigame.memory, day: day)),
      ]);
      expect(store.progress(achievement('allDays')), 24);
      store.dispose();
    },
  );

  test(
    'voucher contents and single claim survive restarts; locked vouchers cannot be claimed',
    () async {
      final store = AchievementStore();
      await store.ready;
      final a = finalReward;
      await store.setReward(a, 'Dein persönlicher Gutschein');
      await store.claim(a);
      expect(store.claimed(a), isFalse);
      await store.record(run(Minigame.maze, feats: {RunFeat.allCandy}));
      expect(store.earned(a), isFalse);
      await store.claim(a);
      expect(store.claimed(a), isFalse);
      await earnAllAchievements(store);
      expect(store.earned(a), isTrue);
      await Future.wait([store.claim(a), store.claim(a)]);
      final reloaded = AchievementStore();
      await reloaded.ready;
      expect(reloaded.reward(a), 'Dein persönlicher Gutschein');
      expect(reloaded.claimed(a), isTrue);
      expect(
        await reloaded.record(run(Minigame.maze, feats: {RunFeat.allCandy})),
        isEmpty,
      );
      await reloaded.setReward(a, '');
      expect(reloaded.reward(a), isNull);
      store.dispose();
      reloaded.dispose();
    },
  );

  test(
    'individual badges cannot have vouchers, including legacy candy rewards',
    () async {
      SharedPreferences.setMockInitialValues({
        AchievementStore.storageKey: jsonEncode({
          'tokens': ['bonus:candy'],
          'earned': ['candy', 'allExtras', 'allAchievements', 'memory'],
          'claimed': ['candy'],
          'rewards': {'candy': 'Old massage voucher'},
        }),
      });
      final store = AchievementStore();
      await store.ready;
      expect(store.earned(achievement('candy')), isFalse);
      expect(store.earned(achievement('memory')), isTrue);
      expect(store.earned(achievement('allExtras')), isFalse);
      expect(store.reward(achievement('candy')), isNull);
      expect(store.claimed(achievement('candy')), isFalse);
      expect(store.earned(finalReward), isFalse);
      await expectLater(
        store.setReward(achievement('candy'), 'No'),
        throwsArgumentError,
      );
      await store.claim(achievement('candy'));
      expect(store.claimed(achievement('candy')), isFalse);
      store.dispose();
    },
  );

  test('Naschkatze needs a complete candy win at every difficulty', () async {
    final store = AchievementStore();
    await store.ready;
    for (final difficulty in GameDifficulty.values) {
      await store.record(
        run(Minigame.maze, difficulty: difficulty, feats: {RunFeat.allCandy}),
      );
      expect(store.progress(achievement('candy')), difficulty.index + 1);
      expect(
        store.earned(achievement('candy')),
        difficulty == GameDifficulty.hard,
      );
      await store.record(
        run(Minigame.maze, difficulty: difficulty, feats: {RunFeat.allCandy}),
      );
      expect(store.progress(achievement('candy')), difficulty.index + 1);
    }
    final reloaded = AchievementStore();
    await reloaded.ready;
    expect(reloaded.earned(achievement('candy')), isTrue);
    store.dispose();
    reloaded.dispose();
  });

  test(
    'Santa bonus requires the rooftop-exit fact from the chimney game',
    () async {
      final store = AchievementStore();
      await store.ready;
      await store.record(run(Minigame.bells, feats: {RunFeat.santaEscaped}));
      expect(store.earned(achievement('santaUp')), isFalse);
      await store.record(run(Minigame.chimney));
      expect(store.earned(achievement('santaUp')), isFalse);
      await store.record(run(Minigame.chimney, feats: {RunFeat.santaEscaped}));
      expect(store.earned(achievement('santaUp')), isTrue);
      store.dispose();
    },
  );

  test(
    'old upward-movement awards are re-evaluated without clearing other progress or voucher receipts',
    () async {
      SharedPreferences.setMockInitialValues({
        AchievementStore.storageKey: jsonEncode({
          'rulesVersion': 2,
          'tokens': ['bonus:santaUp', 'bonus:candy:easy', 'day:4'],
          'earned': ['santaUp', 'allExtras', 'allAchievements', 'memory'],
          'claimed': ['allAchievements'],
          'rewards': {'allAchievements': 'Dein Bonus'},
        }),
      });
      final store = AchievementStore();
      await store.ready;
      expect(store.earned(achievement('santaUp')), isFalse);
      expect(store.tokenComplete('bonus:santaUp'), isFalse);
      expect(store.earned(achievement('memory')), isTrue);
      expect(store.progress(achievement('candy')), 1);
      expect(store.progress(achievement('allDays')), 1);
      expect(store.earned(finalReward), isFalse);
      expect(store.claimed(finalReward), isTrue);
      await store.record(run(Minigame.chimney, feats: {RunFeat.santaEscaped}));
      expect(store.earned(achievement('santaUp')), isTrue);
      store.dispose();
    },
  );

  test(
    'storage failure awards nothing and corrupt progress is reported',
    () async {
      final store = AchievementStore(
        preferences: () async => throw StateError('storage'),
      );
      await store.ready;
      expect(store.error, isNotNull);
      await expectLater(
        store.record(run(Minigame.memory, feats: {RunFeat.perfectMemory})),
        throwsStateError,
      );
      expect(store.earned(achievement('memory')), isFalse);
      store.dispose();
      SharedPreferences.setMockInitialValues({
        AchievementStore.storageKey: '{broken',
      });
      final corrupt = AchievementStore();
      await corrupt.ready;
      expect(corrupt.error, isNotNull);
      expect(corrupt.progress(achievement('allExtras')), 0);
      corrupt.dispose();
    },
  );

  test(
    'calendar wins persist, and imported days do not invent game-specific feats',
    () async {
      final progress = LocalProgressRepository();
      await Future.wait([
        for (var day = 1; day <= 24; day++) progress.markCompleted('day-$day'),
      ]);
      final stored = await LocalProgressRepository().completedChallengeIds();
      expect(stored.length, 24);
      final store = AchievementStore();
      await store.ready;
      await store.importCompletedDays(stored);
      expect(store.earned(achievement('allDays')), isTrue);
      expect(store.progress(achievement('allGames')), 0);
      expect(store.progress(achievement('allExtras')), 0);
      store.dispose();
    },
  );
}
