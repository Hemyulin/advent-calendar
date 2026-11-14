import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../challenges/games/difficulty.dart';
import '../challenges/games/game_kind.dart';

class DayAssignment {
  const DayAssignment(this.game, [this.difficulty = GameDifficulty.normal]);

  final Minigame game;
  final GameDifficulty difficulty;
  String get title => game.title;
}

const defaultAssignments = <DayAssignment>[
  DayAssignment(Minigame.memory, GameDifficulty.easy),
  DayAssignment(Minigame.cookies, GameDifficulty.easy),
  DayAssignment(Minigame.maze),
  DayAssignment(Minigame.chimney),
  DayAssignment(Minigame.bells),
  DayAssignment(Minigame.shoe),
  DayAssignment(Minigame.cookies),
  DayAssignment(Minigame.workshop),
  DayAssignment(Minigame.oyVey),
  DayAssignment(Minigame.walkHome),
  DayAssignment(Minigame.battery),
  DayAssignment(Minigame.memory),
  DayAssignment(Minigame.maze),
  DayAssignment(Minigame.chimney),
  DayAssignment(Minigame.bells),
  DayAssignment(Minigame.cookies),
  DayAssignment(Minigame.workshop),
  DayAssignment(Minigame.walkHome),
  DayAssignment(Minigame.battery),
  DayAssignment(Minigame.maze, GameDifficulty.hard),
  DayAssignment(Minigame.memory, GameDifficulty.hard),
  DayAssignment(Minigame.cookies, GameDifficulty.hard),
  DayAssignment(Minigame.chimney, GameDifficulty.hard),
  DayAssignment(Minigame.bells, GameDifficulty.hard),
];

/// Local calendar configuration only; completion remains attached to the door.
class CalendarSchedule extends ChangeNotifier {
  CalendarSchedule({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance {
    ready = _load();
  }
  static const storageKey = 'calendar.assignments.v2';
  static const legacyStorageKey = 'calendar.assignments.v1';
  final Future<SharedPreferences> Function() _preferences;
  late final Future<void> ready;
  List<DayAssignment> _days = List.of(defaultAssignments);
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
      final raw = current ?? preferences.getString(legacyStorageKey);
      final legacy = current == null;
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
          final games = Minigame.values.where((g) => g.name == gameName);
          final difficulties = GameDifficulty.values.where(
            (d) => d.name == value['difficulty'],
          );
          if ((gameName == 'tutorial' || games.isNotEmpty) &&
              difficulties.isNotEmpty) {
            _days[day - 1] = DayAssignment(
              gameName == 'tutorial' ? Minigame.memory : games.first,
              gameName == 'tutorial' ? GameDifficulty.easy : difficulties.first,
            );
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
    final next = List<DayAssignment>.of(_days)..[day - 1] = assignment;
    final data = <String, Object>{
      for (var i = 0; i < next.length; i++)
        '${i + 1}': {
          'game': next[i].game.name,
          'difficulty': next[i].difficulty.name,
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
    error = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
