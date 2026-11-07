import 'package:flutter/material.dart';

import '../../content/calendar_day.dart';
import '../../presentation/challenge_screen.dart';
import '../completion.dart';
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
import '../tutorial/first_day_screen.dart';
import 'difficulty.dart';

enum Minigame {
  memory(
    'Paare finden',
    'Acht Paare, ein gutes Gedächtnis.',
    Icons.grid_view_rounded,
  ),
  maze(
    'Kugellabyrinth',
    'Ein Labyrinth für eine ruhige Hand.',
    Icons.sports_baseball_outlined,
  ),
  chimney(
    'Rettet den Weihnachtsmann!',
    'Dreh die Rohre und mach den Weg zum Kamin frei.',
    Icons.fireplace_outlined,
  ),
  bells(
    'Weihnachtsglocken',
    'Lausche und lass die Glocken erklingen.',
    Icons.notifications_active_outlined,
  ),
  cookies(
    'Plätzchen ausstechen',
    'Folge der Form und triff den richtigen Moment.',
    Icons.cookie_outlined,
  ),
  shoe(
    'Nikolausstiefel',
    'Ein schmutziger Schuh wartet auf deine Bürste.',
    Icons.cleaning_services_rounded,
  );

  const Minigame(this.title, this.description, this.icon);
  final String title, description;
  final IconData icon;
}

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
  Minigame.shoe => ShoeScreen(
    level: ShoeLevel.forDifficulty(difficulty),
    onComplete: onComplete,
    alreadyCompleted: alreadyCompleted,
  ),
};

/// Day assignments live here, separately from mechanics, storage, and hardware.
Widget buildDailyChallenge(CalendarDay day, ChallengeCompletion onComplete) {
  if (day.number == 1) {
    return FirstDayScreen(
      onComplete: onComplete,
      alreadyCompleted: day.state == DayState.completed,
    );
  }
  final game = switch (day.number) {
    2 => Minigame.memory,
    3 => Minigame.maze,
    4 => Minigame.chimney,
    5 => Minigame.bells,
    6 => Minigame.shoe,
    7 => Minigame.cookies,
    _ => null,
  };
  return game == null
      ? ChallengeScreen(day: day)
      : buildMinigame(
          game,
          GameDifficulty.normal,
          onComplete,
          alreadyCompleted: day.state == DayState.completed,
          mazeSeed: 1221 + day.number,
        );
}
