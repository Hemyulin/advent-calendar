import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../challenges/bells/bells_game.dart';
import '../challenges/games/difficulty.dart';
import '../challenges/games/game_kind.dart';
import '../challenges/seasonal/game_skin.dart';
import 'calendar_schedule.dart';

/// One policy for doors and every non-admin practice entry point.
/// Dates introduce games; completed doors release reserved difficulties/songs.
class CalendarAccess extends ChangeNotifier {
  CalendarAccess({
    required this.schedule,
    required this.now,
    this.designPreview = false,
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance {
    ready = _load();
  }
  static const overrideKey = 'calendar.unlockAll.v1';
  static const playedKey = 'calendar.playedGames.v1';
  final CalendarSchedule schedule;
  final DateTime Function() now;
  final bool designPreview;
  final Future<SharedPreferences> Function() _preferences;
  late final Future<void> ready;
  bool _override = false, _disposed = false;
  Set<String> _completed = {}, _played = {};
  bool get unlockAll => designPreview || _override;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _load() async {
    await schedule.ready;
    try {
      final prefs = await _preferences();
      _override = prefs.getBool(overrideKey) ?? false;
      _played = {...?prefs.getStringList(playedKey)};
    } catch (_) {
      // Missing preferences must never enable the override.
    }
    _changed();
  }

  void updateCompleted(Set<String> ids) {
    if (setEquals(_completed, ids)) return;
    _completed = {...ids};
    _changed();
  }

  void refreshDate() => _changed();

  Future<void> setUnlockAll(bool value) async {
    await ready;
    if (!await (await _preferences()).setBool(overrideKey, value)) {
      throw StateError('Die Einstellung konnte nicht gespeichert werden.');
    }
    _override = value;
    _changed();
  }

  bool dayAvailable(int day) {
    final date = now();
    return unlockAll ||
        !DateTime(
          date.year,
          12,
          day,
        ).isAfter(DateTime(date.year, date.month, date.day));
  }

  bool _finished(int day) =>
      dayAvailable(day) && _completed.contains('day-$day');
  Iterable<int> _daysFor(Minigame game) sync* {
    for (var day = 1; day <= 24; day++) {
      if (schedule.forDay(day).game == game) yield day;
    }
  }

  bool hasPlayed(Minigame game) =>
      _played.contains(game.name) || _daysFor(game).any(_finished);

  Future<void> markPlayed(Minigame game) async {
    await ready;
    if (!_played.add(game.name)) return;
    _changed();
    try {
      await (await _preferences()).setStringList(playedKey, _played.toList());
    } catch (_) {
      // A failed optional first-play save must not prevent the daily game.
    }
  }

  static String melodyFor(DayAssignment assignment) =>
      assignment.melodyId ??
      BellsLevel.forDifficulty(
        assignment.difficulty,
        hanukkah: assignment.skin == GameSkin.hanukkah,
      ).rounds.single.melody.id;

  /// A calendar route may play its own assignment before completing it. Practice
  /// routes never carry [activeDay]; no future assignment can borrow that grant.
  String? reason(
    Minigame game,
    GameDifficulty difficulty, {
    GameSkin skin = GameSkin.christmas,
    String? melodyId,
    int? activeDay,
  }) {
    if (unlockAll) return null;
    final days = _daysFor(game).toList();
    if (days.isEmpty) {
      // The optional trash alternative is introduced by an available door.
      if (game == Minigame.trash && _played.isNotEmpty && dayAvailable(1)) {
        return null;
      }
      return 'Dieses Spiel ist noch gesperrt.';
    }
    if (!dayAvailable(days.first)) return 'Ab dem ${days.first}. Dezember.';
    if (!hasPlayed(game)) return 'Spiele zuerst Türchen ${days.first}.';
    bool released(Iterable<int> reserved) =>
        reserved.isEmpty ||
        reserved.any(
          (day) => _finished(day) || (day == activeDay && dayAvailable(day)),
        );
    final reservedDifficulty = days
        .where((day) => schedule.forDay(day).difficulty == difficulty)
        .toList();
    if (!released(reservedDifficulty)) {
      return 'Schließe zuerst Türchen ${reservedDifficulty.first} ab.';
    }
    if (game == Minigame.bells) {
      final song =
          melodyId ??
          melodyFor(DayAssignment.themed(game, difficulty, skin: skin));
      final reservedSong = days
          .where((day) => melodyFor(schedule.forDay(day)) == song)
          .toList();
      if (!released(reservedSong)) {
        return 'Schließe zuerst Türchen ${reservedSong.first} ab.';
      }
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
