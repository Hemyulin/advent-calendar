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
    achievements.firstWhere((a) => a.id == id);
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
    'all rules have a finite checklist and all extras cover the complete finite checklist',
    () {
      expect(achievements.map((a) => a.id).toSet().length, achievements.length);
      expect(
        achievement('allExtras').requirements.length,
        18 + bellMelodies.length,
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
    '24 distinct days and ten distinct games; repeats never inflate progress',
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
      expect(reloaded.progress(achievement('allGames')), 10);
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
      await store.record(run(Minigame.walkHome, feats: {RunFeat.cleanWalk}));
      await store.record(run(Minigame.walkHome, feats: {RunFeat.roughWalk}));
      await store.record(
        run(
          Minigame.battery,
          feats: {RunFeat.safeBattery, RunFeat.halfCharged},
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
        18 + bellMelodies.length,
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
