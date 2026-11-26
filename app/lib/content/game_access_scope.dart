import 'package:flutter/material.dart';
import '../challenges/games/difficulty.dart';
import '../challenges/games/game_kind.dart';
import '../challenges/seasonal/game_skin.dart';
import 'calendar_access.dart';

class GameAccessScope extends InheritedNotifier<CalendarAccess> {
  const GameAccessScope({
    super.key,
    required CalendarAccess access,
    this.activeDay,
    required super.child,
  }) : super(notifier: access);
  CalendarAccess get access => notifier!;
  final int? activeDay;
  static GameAccessScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameAccessScope>();

  /// Navigator routes are siblings, so explicitly forward the same live policy.
  static Widget Function(Widget) capture(BuildContext context) {
    final scope = maybeOf(context);
    // Capture while navigating, before the source route can be deactivated.
    return (child) => scope == null
        ? child
        : GameAccessScope(
            access: scope.access,
            activeDay: scope.activeDay,
            child: child,
          );
  }

  static String? reason(
    BuildContext context,
    Minigame game,
    GameDifficulty difficulty, {
    GameSkin skin = GameSkin.christmas,
    String? melodyId,
  }) {
    final scope = maybeOf(context);
    return scope?.access.reason(
      game,
      difficulty,
      skin: skin,
      melodyId: melodyId,
      activeDay: scope.activeDay,
    );
  }

  static bool allow(
    BuildContext context,
    Minigame game,
    GameDifficulty difficulty, {
    GameSkin skin = GameSkin.christmas,
    String? melodyId,
  }) {
    final locked = reason(
      context,
      game,
      difficulty,
      skin: skin,
      melodyId: melodyId,
    );
    if (locked == null) return true;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(locked)));
    return false;
  }
}
