import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../challenges/games/difficulty.dart';
import '../challenges/games/game_kind.dart';
import '../challenges/seasonal/game_skin.dart';
import '../challenges/bells/bell_melodies.dart';

class DayAssignment {
  const DayAssignment(this.game, [this.difficulty = GameDifficulty.normal])
    : skin = GameSkin.christmas,
      melodyId = null;
  const DayAssignment.themed(
    this.game,
    this.difficulty, {
    this.skin = GameSkin.christmas,
    this.melodyId,
  });
  final Minigame game;
  final GameDifficulty difficulty;
  final GameSkin skin;
  final String? melodyId;
  String get title =>
      skin == GameSkin.hanukkah ? hanukkahTitle(game) : game.title;
}

// Introductions first, familiar mechanics in new costumes next, then mastery.
const defaultAssignments = <DayAssignment>[
  DayAssignment(Minigame.memory, GameDifficulty.easy),
  DayAssignment(Minigame.cookies, GameDifficulty.easy),
  DayAssignment(Minigame.maze, GameDifficulty.easy),
  DayAssignment(Minigame.oyVey, GameDifficulty.easy),
  DayAssignment.themed(
    Minigame.memory,
    GameDifficulty.normal,
    skin: GameSkin.hanukkah,
  ),
  DayAssignment(Minigame.shoe),
  DayAssignment.themed(
    Minigame.cookies,
    GameDifficulty.normal,
    skin: GameSkin.hanukkah,
  ),
  DayAssignment(Minigame.battery, GameDifficulty.easy),
  DayAssignment.themed(
    Minigame.chimney,
    GameDifficulty.normal,
    skin: GameSkin.hanukkah,
  ),
  DayAssignment.themed(
    Minigame.bells,
    GameDifficulty.easy,
    skin: GameSkin.hanukkah,
    melodyId: 'maoz-tzur',
  ),
  DayAssignment.themed(
    Minigame.walkHome,
    GameDifficulty.normal,
    skin: GameSkin.hanukkah,
  ),
  DayAssignment.themed(
    Minigame.battery,
    GameDifficulty.normal,
    skin: GameSkin.hanukkah,
  ),
  DayAssignment(Minigame.maze),
  DayAssignment(Minigame.workshop, GameDifficulty.easy),
  DayAssignment(Minigame.walkHome),
  DayAssignment(Minigame.memory, GameDifficulty.hard),
  DayAssignment(Minigame.chimney, GameDifficulty.hard),
  DayAssignment(Minigame.workshop),
  DayAssignment(Minigame.walkHome, GameDifficulty.hard),
  DayAssignment(Minigame.cookies, GameDifficulty.hard),
  DayAssignment(Minigame.maze, GameDifficulty.hard),
  DayAssignment(Minigame.battery, GameDifficulty.hard),
  DayAssignment(Minigame.workshop, GameDifficulty.hard),
  DayAssignment(Minigame.bells, GameDifficulty.hard),
];

// v2 stored full snapshots, so strip only entries matching its old defaults
// during migration. Real custom assignments and completion-by-door survive.
const _previousDefaultGames = [
  Minigame.memory,
  Minigame.cookies,
  Minigame.maze,
  Minigame.chimney,
  Minigame.bells,
  Minigame.shoe,
  Minigame.cookies,
  Minigame.workshop,
  Minigame.oyVey,
  Minigame.walkHome,
  Minigame.battery,
  Minigame.memory,
  Minigame.maze,
  Minigame.chimney,
  Minigame.bells,
  Minigame.cookies,
  Minigame.workshop,
  Minigame.walkHome,
  Minigame.battery,
  Minigame.maze,
  Minigame.memory,
  Minigame.cookies,
  Minigame.chimney,
  Minigame.bells,
];

/// Local calendar configuration only; completion remains attached to the door.
class CalendarSchedule extends ChangeNotifier {
  CalendarSchedule({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance {
    ready = _load();
  }
  static const storageKey = 'calendar.assignments.v3';
  static const previousStorageKey = 'calendar.assignments.v2';
  static const legacyStorageKey = 'calendar.assignments.v1';
  final Future<SharedPreferences> Function() _preferences;
  late final Future<void> ready;
  List<DayAssignment> _days = List.of(defaultAssignments);
  Map<int, DayAssignment> _overrides = {};
  bool loaded = false;
  String? error;
  bool _disposed = false;

  DayAssignment forDay(int day) {
    RangeError.checkValueInInterval(day, 1, 24, 'day');
    return _days[day - 1];
  }

  Future<void> _load() async {
    try {
      final preferences = await _preferences();
      final current = preferences.getString(storageKey);
      final previous = preferences.getString(previousStorageKey);
      final raw =
          current ?? previous ?? preferences.getString(legacyStorageKey);
      final legacy = current == null && previous == null;
      if (raw != null) {
        final data = jsonDecode(raw);
        if (data is! Map<String, dynamic>) throw const FormatException();
        for (var day = 1; day <= 24; day++) {
          final value = data['$day'];
          if (value is! Map) continue;
          final gameName = value['game'];
          // Earlier saves contained all defaults, including the duplicate
          // day-two Memory. Upgrade that old default while retaining custom
          // games and difficulties. New explicit Memory assignments are valid.
          if (legacy &&
              day == 2 &&
              gameName == 'memory' &&
              value['difficulty'] == 'normal') {
            continue;
          }
          final oldDifficulty = day <= 2
              ? 'easy'
              : day >= 20
              ? 'hard'
              : 'normal';
          if (current == null &&
              data.length == 24 &&
              gameName == _previousDefaultGames[day - 1].name &&
              value['difficulty'] == oldDifficulty) {
            continue;
          }
          final games = Minigame.values.where((g) => g.name == gameName);
          final difficulties = GameDifficulty.values.where(
            (d) => d.name == value['difficulty'],
          );
          if ((gameName == 'tutorial' || games.isNotEmpty) &&
              difficulties.isNotEmpty) {
            final game = gameName == 'tutorial' ? Minigame.memory : games.first;
            final skin = supportsHanukkah(game) && value['skin'] == 'hanukkah'
                ? GameSkin.hanukkah
                : GameSkin.christmas;
            final melody = value['melody'];
            final melodyIndex = bellMelodies.indexWhere((m) => m.id == melody);
            final assignment = DayAssignment.themed(
              game,
              gameName == 'tutorial' ? GameDifficulty.easy : difficulties.first,
              skin: skin,
              melodyId:
                  game == Minigame.bells &&
                      melodyIndex >= 0 &&
                      (melodyIndex >= 8) == (skin == GameSkin.hanukkah)
                  ? melody as String
                  : null,
            );
            _days[day - 1] = assignment;
            _overrides[day] = assignment;
          }
        }
      }
    } catch (_) {
      error = 'Gespeicherter Kalender konnte nicht geladen werden.';
    }
    loaded = true;
    if (!_disposed) notifyListeners();
  }

  Future<void> assign(int day, DayAssignment assignment) async {
    RangeError.checkValueInInterval(day, 1, 24, 'day');
    await ready;
    if (assignment.skin == GameSkin.hanukkah &&
        !supportsHanukkah(assignment.game)) {
      throw ArgumentError('Dieses Spiel hat keine zusätzliche Gestaltung.');
    }
    final next = List<DayAssignment>.of(_days)..[day - 1] = assignment;
    final overrides = {..._overrides, day: assignment};
    final data = <String, Object>{
      for (final entry in overrides.entries)
        '${entry.key}': {
          'game': entry.value.game.name,
          'difficulty': entry.value.difficulty.name,
          'skin': entry.value.skin.name,
          if (entry.value.melodyId != null) 'melody': entry.value.melodyId,
        },
    };
    try {
      final saved = await (await _preferences()).setString(
        storageKey,
        jsonEncode(data),
      );
      if (!saved) throw StateError('Storage write failed');
    } catch (_) {
      throw StateError('Änderung konnte nicht gespeichert werden.');
    }
    _days = next;
    _overrides = overrides;
    error = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
