import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../challenges/games/game_kind.dart';
import '../challenges/games/difficulty.dart';
import 'run_facts.dart';
import '../challenges/seasonal/game_skin.dart';
import '../challenges/bells/bell_melodies.dart';
import '../challenges/workshop/workshop_game.dart';

class Achievement {
  const Achievement(this.id, this.title, this.description, this.requirements);
  final String id, title, description;
  final Set<String> requirements;
}

final bonusObjectives = <String>{
  'shoe',
  'menorahs',
  'cleanOy',
  'memory',
  'workshop:easy',
  'workshop:normal',
  'workshop:hard',
  'cleanWalk',
  'roughWalk',
  'safeBattery',
  'halfCharged',
  'fullyCharged',
  'cookies:easy',
  'cookies:normal',
  'cookies:hard',
  'candy:easy',
  'candy:normal',
  'candy:hard',
  for (final melody in bellMelodies) 'bells:${melody.id}',
};

final achievements = <Achievement>[
  Achievement(
    'allDays',
    '24 kleine Weihnachtswunder',
    'Schließe alle 24 Türchen ab.',
    {for (var i = 1; i <= 24; i++) 'day:$i'},
  ),
  Achievement(
    'allGames',
    'Weihnachts-Alleskönnerin',
    'Meistere jede der zehn Spielarten mindestens einmal.',
    {for (final game in Minigame.values) 'game:${game.name}'},
  ),
  Achievement(
    'allExtras',
    'Mit Liebe zum Detail',
    'Erfülle alle ${bonusObjectives.length} Bonusziele. Wiederholungen zählen mit.',
    {for (final token in bonusObjectives) 'bonus:$token'},
  ),
  const Achievement(
    'shoe',
    'Blank für den Nikolaus',
    'Reinige und poliere den Nikolausstiefel.',
    {'bonus:shoe'},
  ),
  const Achievement(
    'menorahs',
    'Lichterfest',
    'Gewinne Oy Vey und sammle dabei ausschließlich Chanukkiot.',
    {'bonus:menorahs'},
  ),
  const Achievement(
    'cleanOy',
    'Koscher durch Weihnachten',
    'Gewinne Oy Vey ohne einen Weihnachtsgegenstand einzusammeln.',
    {'bonus:cleanOy'},
  ),
  const Achievement(
    'memory',
    'Einmal gesehen, nie vergessen',
    'Gewinne Memory. Ist der Zwilling deiner ersten Karte bereits bekannt, finde ihn sofort.',
    {'bonus:memory'},
  ),
  Achievement(
    'workshop',
    'Wichtel mit Köpfchen',
    'Löse alle Werkstatt-Puzzles: Leicht in ${WorkshopLevel.bonusMoveLimits[GameDifficulty.easy]}, Klassisch in ${WorkshopLevel.bonusMoveLimits[GameDifficulty.normal]} und Knifflig in ${WorkshopLevel.bonusMoveLimits[GameDifficulty.hard]} Zügen. Rückgängig ist erlaubt.',
    {'bonus:workshop:easy', 'bonus:workshop:normal', 'bonus:workshop:hard'},
  ),
  const Achievement(
    'cleanWalk',
    'Sicher nach Hause',
    'Erreiche dein Ziel ohne einen einzigen Zusammenstoß.',
    {'bonus:cleanWalk'},
  ),
  const Achievement(
    'roughWalk',
    'Unkaputtbar',
    'Überstehe mindestens fünf verschiedene Hindernisse und erreiche trotzdem dein Ziel.',
    {'bonus:roughWalk'},
  ),
  const Achievement(
    'safeBattery',
    'Keine roten Balken',
    'Gewinne Akku-Panik oder Öl-Panik, ohne dass ein Füllstand unter 3 % fällt.',
    {'bonus:safeBattery'},
  ),
  const Achievement(
    'halfCharged',
    'Halb voll, ganz geschafft',
    'Bringe einen Akku oder Ölstand auf mindestens 50 % und gewinne denselben Durchlauf.',
    {'bonus:halfCharged'},
  ),
  const Achievement(
    'fullyCharged',
    'Volle Ladung!',
    'Bringe einen Akku oder Ölstand auf mindestens 80 %. Du musst den Durchlauf nicht gewinnen.',
    {'bonus:fullyCharged'},
  ),
  const Achievement(
    'cookies',
    'Wie ausgestochen',
    'Schaffe je einen fehlerfreien Durchlauf auf Leicht, Klassisch und Knifflig.',
    {'bonus:cookies:easy', 'bonus:cookies:normal', 'bonus:cookies:hard'},
  ),
  const Achievement(
    'candy',
    'Naschkatze',
    'Sammle auf Leicht, Klassisch und Knifflig jeweils alle Süßigkeiten oder Schekel und erreiche die Flagge.',
    {'bonus:candy:easy', 'bonus:candy:normal', 'bonus:candy:hard'},
  ),
  Achievement(
    'bells',
    'Ein ganzes Festtagskonzert',
    'Spiele jeden der ${bellMelodies.length} Liedausschnitte einmal vollständig nach. Die Schwierigkeit kannst du frei wählen.',
    {for (final melody in bellMelodies) 'bonus:bells:${melody.id}'},
  ),
  Achievement(
    'hanukkah',
    'Neun Spiele, ein Lichterfest',
    'Gewinne jedes der neun Spiele im Chanukka-Modus mindestens einmal. Die Schwierigkeit ist frei wählbar.',
    {for (final game in hanukkahGames) 'skin:${game.name}'},
  ),
];

/// Secret extras never contribute to required objectives or the final voucher.
const secretAchievements = [
  Achievement(
    'noJewishMisses',
    'Nichts kommt weg!',
    'Gewinne Oy Vey und fange alle 15 jüdischen Gegenstände, ohne einen unten vorbeifallen zu lassen. Ein geheimer Zusatzerfolg, der für den Weihnachtsbonus nicht nötig ist.',
    {'bonus:noJewishMisses'},
  ),
  Achievement(
    'santaUp',
    'Feierabend, Weihnachtsmann!',
    'Schick den Weihnachtsmann zurück nach Hause. Ein geheimer Zusatzerfolg, der für den Weihnachtsbonus nicht nötig ist.',
    {'bonus:santaUp'},
  ),

  Achievement(
    'hundredPercent',
    'Bis unter die Mütze!',
    'Bringe einen Akku oder Ölstand auf 100 %. Ein geheimer Zusatzerfolg, der für den Weihnachtsbonus nicht nötig ist. Du musst den Durchlauf nicht gewinnen.',
    {'bonus:hundredPercent'},
  ),
];
final achievementCatalog = [...achievements, ...secretAchievements];

/// A reward milestone outside the badge list, so it cannot depend on itself.
final finalReward = Achievement(
  'allAchievements',
  'Dein Weihnachtsbonus',
  'Schalte alle ${achievements.length} Erfolge frei. Zusätzlich zu deinen täglichen Geschenken wartet dann ein Bonus auf dich.',
  {for (final a in achievements) 'achievement:${a.id}'},
);

class AchievementRun {
  const AchievementRun({
    required this.day,
    required this.game,
    required this.difficulty,
    this.facts = const RunFacts(),
  });
  final int? day;
  final Minigame game;
  final GameDifficulty difficulty;
  final RunFacts facts;
}

/// Set-based, serialized local progress. Preview routes never receive a writer.
/// Voucher claims are local acknowledgements, never authorization to open a box.
class AchievementStore extends ChangeNotifier {
  AchievementStore({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance {
    ready = _load();
  }
  static const storageKey = 'achievements.v1';
  final Future<SharedPreferences> Function() _preferences;
  late final Future<void> ready;
  Future<void> _queue = Future.value();
  Set<String> _tokens = {}, _claimed = {}, _earned = {};
  Map<String, String> _rewards = {};
  bool loaded = false, _disposed = false;
  String? error;
  int progress(Achievement achievement) => achievement.id == finalReward.id
      ? achievements.where(earned).length
      : achievement.requirements.intersection(_tokens).length;
  bool earned(Achievement achievement) =>
      _earned.contains(achievement.id) ||
      (achievement.id == finalReward.id
          ? achievements.every(earned)
          : progress(achievement) == achievement.requirements.length);
  bool claimed(Achievement achievement) => _claimed.contains(achievement.id);
  String? reward(Achievement achievement) =>
      achievement.id == finalReward.id ? _rewards[finalReward.id] : null;
  bool tokenComplete(String token) => _tokens.contains(token);

  Future<void> _load() async {
    try {
      final raw = (await _preferences()).getString(storageKey);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final allowed = achievementCatalog
            .expand((a) => a.requirements)
            .toSet();
        _tokens = (json['tokens'] as List)
            .whereType<String>()
            .where(allowed.contains)
            .toSet();
        _earned = (json['earned'] as List? ?? [])
            .whereType<String>()
            .where(
              (id) =>
                  id == finalReward.id ||
                  achievementCatalog.any((a) => a.id == id),
            )
            .toSet();
        if ((json['rulesVersion'] as int? ?? 1) < 2) {
          // These objectives now require three candy runs plus the new Santa
          // goal. Older single-run candy tokens contain no difficulty data.
          _earned.removeAll({'candy', 'allExtras', finalReward.id});
        }
        if ((json['rulesVersion'] as int? ?? 1) < 3) {
          // Earlier versions only observed an upward move, not a rooftop exit.
          _tokens.remove('bonus:santaUp');
          _earned.removeAll({'santaUp', 'allExtras', finalReward.id});
        }
        if ((json['rulesVersion'] as int? ?? 1) < 4) {
          // The overall bonus now includes the complete bell-song collection.
          _earned.removeAll({'allExtras', finalReward.id});
        }
        if ((json['rulesVersion'] as int? ?? 1) < 5) {
          _earned.removeAll({'bells', 'allExtras', finalReward.id});
        }
        if ((json['rulesVersion'] as int? ?? 1) < 6) {
          _earned.removeAll({'hanukkah', finalReward.id});
        }
        if ((json['rulesVersion'] as int? ?? 1) < 7) {
          _earned.removeAll({'allExtras', finalReward.id});
        }
        if ((json['rulesVersion'] as int? ?? 1) < 8 &&
            (_tokens.contains('bonus:fullyCharged') ||
                _earned.contains('fullyCharged'))) {
          // Before v8, this token certified 100%, so preserve that accomplishment.
          _tokens.addAll({'bonus:fullyCharged', 'bonus:hundredPercent'});
        }
        _claimed = (json['claimed'] as List)
            .whereType<String>()
            .where((id) => id == finalReward.id)
            .toSet();
        // Old per-badge rewards are intentionally discarded. Completing a
        // single game objective must never entitle the player to a voucher.
        final rewards = Map<String, String>.from(json['rewards'] as Map);
        _rewards = {
          if (rewards.containsKey(finalReward.id))
            finalReward.id: rewards[finalReward.id]!,
        };
      }
    } catch (_) {
      _tokens = {};
      _claimed = {};
      _earned = {};
      _rewards = {};
      error = 'Erfolge konnten nicht geladen werden.';
    }
    loaded = true;
    if (!_disposed) notifyListeners();
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _write(
    Set<String> tokens,
    Set<String> claims,
    Map<String, String> rewards,
  ) async {
    final earned = {
      ..._earned,
      for (final a in achievementCatalog)
        if (a.requirements.every(tokens.contains)) a.id,
    };
    if (achievements.every((a) => earned.contains(a.id))) {
      earned.add(finalReward.id);
    }
    final saved = await (await _preferences()).setString(
      storageKey,
      jsonEncode({
        'rulesVersion': 9,
        'tokens': tokens.toList(),
        'earned': earned.toList(),
        'claimed': claims.toList(),
        'rewards': rewards,
      }),
    );
    if (!saved) throw StateError('Erfolge konnten nicht gespeichert werden.');
    _tokens = tokens;
    _earned = earned;
    _claimed = claims;
    _rewards = rewards;
    error = null;
    if (!_disposed) notifyListeners();
  }

  Future<void> importCompletedDays(Set<String> ids) => _serialize(() async {
    await ready;
    final tokens = {..._tokens};
    for (var day = 1; day <= 24; day++) {
      if (ids.contains('day-$day')) tokens.add('day:$day');
    }
    if (tokens.length != _tokens.length) {
      await _write(tokens, {..._claimed}, {..._rewards});
    }
  });

  Future<List<Achievement>> record(AchievementRun run) => _serialize(() async {
    await ready;
    if (run.day != null) {
      RangeError.checkValueInInterval(run.day!, 1, 24, 'day');
    }
    final before = achievementCatalog.where(earned).map((a) => a.id).toSet();
    final tokens = {
      ..._tokens,
      if (run.facts.won && run.day != null) 'day:${run.day}',
      if (run.facts.won) 'game:${run.game.name}',
      if (run.facts.won && run.facts.hanukkahMode && supportsHanukkah(run.game))
        'skin:${run.game.name}',
    };
    void bonus(String token) => tokens.add('bonus:$token');
    final feats = run.facts.feats;
    // Both charging milestones are earned immediately, independently of a win.
    if (run.game == Minigame.battery) {
      if (feats.contains(RunFeat.fullyCharged) ||
          feats.contains(RunFeat.hundredPercent)) {
        bonus('fullyCharged');
      }
      if (feats.contains(RunFeat.hundredPercent)) bonus('hundredPercent');
    }
    if (run.facts.won) {
      switch (run.game) {
        case Minigame.shoe:
          if ((run.day == 6 || run.day == null) && !run.facts.hanukkahMode) {
            bonus('shoe');
          }
        case Minigame.memory:
          if (feats.contains(RunFeat.perfectMemory)) bonus('memory');
        case Minigame.maze:
          if (feats.contains(RunFeat.allCandy)) {
            bonus('candy:${run.difficulty.name}');
          }
        case Minigame.oyVey:
          if (feats.contains(RunFeat.onlyMenorahs)) bonus('menorahs');
          if (feats.contains(RunFeat.cleanOyVey)) bonus('cleanOy');
          if (feats.contains(RunFeat.noJewishMisses)) bonus('noJewishMisses');
        case Minigame.workshop:
          if (feats.contains(RunFeat.efficientWorkshop)) {
            bonus('workshop:${run.difficulty.name}');
          }
        case Minigame.cookies:
          if (feats.contains(RunFeat.perfectCookie)) {
            bonus('cookies:${run.difficulty.name}');
          }
        case Minigame.walkHome:
          if (feats.contains(RunFeat.cleanWalk)) bonus('cleanWalk');
          if (feats.contains(RunFeat.roughWalk)) bonus('roughWalk');
        case Minigame.battery:
          if (feats.contains(RunFeat.safeBattery)) bonus('safeBattery');
          if (feats.contains(RunFeat.halfCharged)) bonus('halfCharged');
        case Minigame.chimney:
          if (feats.contains(RunFeat.santaEscaped)) bonus('santaUp');
        case Minigame.bells:
          for (final melody in bellMelodies) {
            if (run.facts.completedBellSongs.contains(melody.id)) {
              bonus('bells:${melody.id}');
            }
          }
      }
    }
    await _write(tokens, {..._claimed}, {..._rewards});
    return achievementCatalog
        .where((a) => earned(a) && !before.contains(a.id))
        .toList();
  });

  Future<void> setReward(Achievement achievement, String text) =>
      _serialize(() async {
        await ready;
        if (achievement.id != finalReward.id) {
          throw ArgumentError(
            'Gutscheine gibt es nur für alle Erfolge zusammen.',
          );
        }
        final rewards = {..._rewards};
        final value = text.trim();
        if (value.length > 240) throw ArgumentError('Belohnung ist zu lang.');
        if (value.isEmpty) {
          rewards.remove(achievement.id);
        } else {
          rewards[achievement.id] = value;
        }
        await _write({..._tokens}, {..._claimed}, rewards);
      });

  Future<void> claim(Achievement achievement) => _serialize(() async {
    await ready;
    if (achievement.id != finalReward.id ||
        !earned(finalReward) ||
        reward(achievement) == null ||
        claimed(achievement)) {
      return;
    }
    await _write({..._tokens}, {..._claimed, achievement.id}, {..._rewards});
  });

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
