import 'package:flutter/material.dart';

import '../../content/calendar_day.dart';
import '../../content/game_access_scope.dart';
import '../../content/calendar_schedule.dart';
import 'game_kind.dart';
export 'game_kind.dart';
import '../completion.dart';
import '../trash/trash_screen.dart';
import '../battery/battery_game.dart';
import '../battery/battery_screen.dart';
import '../walk_home/walk_game.dart';
import '../walk_home/walk_screen.dart';
import '../oy_vey/oy_vey_game.dart';
import '../oy_vey/oy_vey_screen.dart';
import '../workshop/workshop_game.dart';
import '../workshop/workshop_screen.dart';
import '../cookies/cookie_game.dart';
import '../cookies/cookie_screen.dart';
import '../bells/bells_game.dart';
import '../bells/bells_screen.dart';
import '../bells/bell_melodies.dart';
import '../chimney/chimney_game.dart';
import '../chimney/chimney_screen.dart';
import '../maze/maze_game.dart';
import '../maze/maze_screen.dart';
import '../memory/memory_game.dart';
import '../memory/memory_screen.dart';
import '../shoe/shoe_game.dart';
import '../shoe/shoe_screen.dart';
import 'difficulty.dart';
import '../seasonal/game_skin.dart';
import '../seasonal/game_skin_scope.dart';

Widget buildMinigame(
  Minigame kind,
  GameDifficulty difficulty,
  ChallengeCompletion onComplete, {
  bool alreadyCompleted = false,
  int? mazeSeed,
  bool developmentPreview = false,
  GameSkin? skin,
  String? melodyId,
  bool relaxedCookies = false,
}) {
  Widget build(GameSkin skin) => _buildMinigame(
    kind,
    difficulty,
    onComplete,
    alreadyCompleted: alreadyCompleted,
    mazeSeed: mazeSeed,
    developmentPreview: developmentPreview,
    skin: skin,
    melodyId: melodyId,
    relaxedCookies: relaxedCookies,
  );
  if (!supportsHanukkah(kind)) return build(GameSkin.christmas);
  return SkinnableGame(
    initialSkin: skin ?? GameSkin.christmas,
    builder: build,
    isReplay: alreadyCompleted,
    developmentPreview: developmentPreview,
    canSwitchTo: developmentPreview
        ? null
        : (context, nextSkin) => GameAccessScope.allow(
            context,
            kind,
            difficulty,
            skin: nextSkin,
            melodyId: kind == Minigame.bells
                ? _bellsLevel(
                    difficulty,
                    nextSkin,
                    melodyId,
                  ).rounds.single.melody.id
                : null,
          ),
  );
}

Widget _buildMinigame(
  Minigame kind,
  GameDifficulty difficulty,
  ChallengeCompletion onComplete, {
  required bool alreadyCompleted,
  required int? mazeSeed,
  required bool developmentPreview,
  required GameSkin skin,
  String? melodyId,
  required bool relaxedCookies,
}) => switch (kind) {
  Minigame.memory => MemoryScreen(
    level: MemoryLevel.forDifficulty(difficulty),
    onComplete: onComplete,
    alreadyCompleted: alreadyCompleted,
  ),
  Minigame.maze => MazeScreen(
    course: MazeCourse.forDifficulty(difficulty, seed: mazeSeed),
    onComplete: onComplete,
    alreadyCompleted: alreadyCompleted,
  ),
  Minigame.chimney => ChimneyScreen(
    level: ChimneyLevel.forDifficulty(difficulty),
    onComplete: onComplete,
    alreadyCompleted: alreadyCompleted,
  ),
  Minigame.bells => BellsScreen(
    level: _bellsLevel(difficulty, skin, melodyId),
    onComplete: onComplete,
    alreadyCompleted: alreadyCompleted,
    previewControls: developmentPreview,
  ),
  Minigame.cookies => CookieScreen(
    level: _cookieLevel(difficulty, skin, relaxedCookies),
    onComplete: onComplete,
    alreadyCompleted: alreadyCompleted,
  ),
  Minigame.workshop => WorkshopScreen(
    level: WorkshopLevel.forDifficulty(difficulty),
    onComplete: onComplete,
    alreadyCompleted: alreadyCompleted,
  ),
  Minigame.oyVey || Minigame.goyVey => OyVeyScreen(
    level: OyVeyLevel.forDifficulty(
      difficulty,
      christmasTargets: kind == Minigame.goyVey,
    ),
    onComplete: onComplete,
    alreadyCompleted: alreadyCompleted,
    developmentPreview: developmentPreview,
  ),
  Minigame.walkHome => WalkScreen(
    level: WalkLevel.forDifficulty(difficulty),
    onComplete: onComplete,
    alreadyCompleted: alreadyCompleted,
  ),
  Minigame.battery => BatteryScreen(
    level: BatteryLevel.forDifficulty(difficulty),
    onComplete: onComplete,
    alreadyCompleted: alreadyCompleted,
  ),
  Minigame.trash => TrashScreen(
    onComplete: onComplete,
    alreadyCompleted: alreadyCompleted,
  ),
  Minigame.shoe => ShoeScreen(
    level: ShoeLevel.forDifficulty(
      difficulty,
      hanukkah: skin == GameSkin.hanukkah,
    ),
    onComplete: onComplete,
    alreadyCompleted: alreadyCompleted,
  ),
};

/// Routing stays independent of game rules and completion storage.
Widget buildDailyChallenge(
  CalendarDay day,
  ChallengeCompletion onComplete, {
  DayAssignment? assignment,
}) {
  final selected = assignment ?? defaultAssignments[day.number - 1];
  return buildMinigame(
    selected.game,
    selected.difficulty,
    onComplete,
    alreadyCompleted: day.state == DayState.completed,
    skin: selected.skin,
    melodyId: selected.melodyId,
  );
}

BellsLevel _bellsLevel(
  GameDifficulty difficulty,
  GameSkin skin,
  String? melodyId,
) {
  final base = BellsLevel.forDifficulty(
    difficulty,
    hanukkah: skin == GameSkin.hanukkah,
  );
  final index = bellMelodies.indexWhere((m) => m.id == melodyId);
  if (index < 0 || (index >= 8) != (skin == GameSkin.hanukkah)) return base;
  return BellsLevel(
    rounds: [BellRound(index)],
    beatMilliseconds: base.beatMilliseconds,
    guidance: base.guidance,
  );
}

CookieLevel _cookieLevel(
  GameDifficulty difficulty,
  GameSkin skin,
  bool relaxed,
) {
  final base = CookieLevel.forDifficulty(
    difficulty,
    hanukkah: skin == GameSkin.hanukkah,
  );
  if (!relaxed) return base;
  return CookieLevel(
    shape: base.shape,
    speed: base.speed * .65,
    checkpoints: base.checkpoints,
    timingWindowSeconds: base.timingWindowSeconds * 1.5,
    mistakeLimit: base.mistakeLimit,
  );
}
