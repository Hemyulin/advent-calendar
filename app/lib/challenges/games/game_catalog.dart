import 'package:flutter/material.dart';

import '../../content/calendar_day.dart';
import '../../content/calendar_schedule.dart';
import 'game_kind.dart';
export 'game_kind.dart';
import '../completion.dart';
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
import '../chimney/chimney_game.dart';
import '../chimney/chimney_screen.dart';
import '../maze/maze_game.dart';
import '../maze/maze_screen.dart';
import '../memory/memory_game.dart';
import '../memory/memory_screen.dart';
import '../shoe/shoe_game.dart';
import '../shoe/shoe_screen.dart';
import 'difficulty.dart';

Widget buildMinigame(
  Minigame kind,
  GameDifficulty difficulty,
  ChallengeCompletion onComplete, {
  bool alreadyCompleted = false,
  int mazeSeed = 1224,
  bool developmentPreview = false,
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
    level: BellsLevel.forDifficulty(difficulty),
    onComplete: onComplete,
    alreadyCompleted: alreadyCompleted,
    previewControls: developmentPreview,
  ),
  Minigame.cookies => CookieScreen(
    level: CookieLevel.forDifficulty(difficulty),
    onComplete: onComplete,
    alreadyCompleted: alreadyCompleted,
  ),
  Minigame.workshop => WorkshopScreen(
    level: WorkshopLevel.forDifficulty(difficulty),
    onComplete: onComplete,
    alreadyCompleted: alreadyCompleted,
  ),
  Minigame.oyVey => OyVeyScreen(
    level: OyVeyLevel.forDifficulty(difficulty),
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
  Minigame.shoe => ShoeScreen(
    level: ShoeLevel.forDifficulty(difficulty),
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
    mazeSeed: 1221 + day.number,
  );
}
