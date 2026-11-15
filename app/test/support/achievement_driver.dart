import 'package:advent_calendar/achievements/achievement_store.dart';
import 'package:advent_calendar/challenges/bells/bell_melodies.dart';
import 'package:advent_calendar/achievements/run_facts.dart';
import 'package:advent_calendar/challenges/games/game_kind.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';

/// Complete every independent rule, with distinct runs for incompatible goals.
Future<void> earnAllAchievements(AchievementStore store) async {
  for (var day = 1; day <= 24; day++) {
    await store.record(
      AchievementRun(
        day: day,
        game: Minigame.memory,
        difficulty: GameDifficulty.normal,
        facts: const RunFacts(feats: {RunFeat.perfectMemory}),
      ),
    );
  }
  for (final game in Minigame.values) {
    final feats = switch (game) {
      Minigame.maze => {RunFeat.allCandy},
      Minigame.chimney => {RunFeat.santaEscaped},
      Minigame.oyVey => {RunFeat.onlyMenorahs, RunFeat.cleanOyVey},
      Minigame.walkHome => {RunFeat.cleanWalk},
      Minigame.battery => {RunFeat.safeBattery, RunFeat.halfCharged},
      _ => <RunFeat>{},
    };
    await store.record(
      AchievementRun(
        day: game == Minigame.shoe ? 6 : 1,
        game: game,
        difficulty: GameDifficulty.normal,
        facts: RunFacts(feats: feats, hanukkahMode: game != Minigame.shoe),
      ),
    );
  }
  await store.record(
    const AchievementRun(
      day: null,
      game: Minigame.shoe,
      difficulty: GameDifficulty.easy,
      facts: RunFacts(hanukkahMode: true),
    ),
  );
  await store.record(
    const AchievementRun(
      day: 1,
      game: Minigame.walkHome,
      difficulty: GameDifficulty.normal,
      facts: RunFacts(feats: {RunFeat.roughWalk}),
    ),
  );
  for (final difficulty in GameDifficulty.values) {
    await store.record(
      AchievementRun(
        day: null,
        game: Minigame.maze,
        difficulty: difficulty,
        facts: const RunFacts(feats: {RunFeat.allCandy}),
      ),
    );
    await store.record(
      AchievementRun(
        day: null,
        game: Minigame.workshop,
        difficulty: difficulty,
        facts: const RunFacts(feats: {RunFeat.efficientWorkshop}),
      ),
    );
    await store.record(
      AchievementRun(
        day: null,
        game: Minigame.cookies,
        difficulty: difficulty,
        facts: const RunFacts(feats: {RunFeat.perfectCookie}),
      ),
    );
  }
  await store.record(
    AchievementRun(
      day: null,
      game: Minigame.bells,
      difficulty: GameDifficulty.easy,
      facts: RunFacts(
        completedBellSongs: bellMelodies.map((m) => m.id).toSet(),
      ),
    ),
  );
}
