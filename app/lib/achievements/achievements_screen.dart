import 'package:flutter/material.dart';
import '../presentation/calendar_style.dart';
import '../presentation/viewport_fit.dart';
import '../challenges/games/difficulty.dart';
import 'achievement_store.dart';
import '../challenges/seasonal/game_skin.dart';
import '../challenges/bells/bell_melodies.dart';
import 'achievement_art.dart';
import 'achievement_scope.dart';
import '../content/calendar_day.dart';
import '../challenges/games/game_catalog.dart';
import '../challenges/games/gift_reward_scope.dart';
import '../challenges/gift_reward.dart';

// Individual goals launch the relevant game; aggregate goals use collections.
Minigame? gameForAchievement(String id) => switch (id) {
  'shoe' => Minigame.shoe,
  'menorahs' || 'cleanOy' || 'noJewishMisses' => Minigame.oyVey,
  'memory' => Minigame.memory,
  'workshop' => Minigame.workshop,
  'cleanWalk' || 'roughWalk' => Minigame.walkHome,
  'safeBattery' ||
  'halfCharged' ||
  'fullyCharged' ||
  'hundredPercent' => Minigame.battery,
  'cookies' => Minigame.cookies,
  'candy' => Minigame.maze,
  'santaUp' => Minigame.chimney,
  _ => null,
};

String objectiveLabel(String token) {
  if (token.startsWith('achievement:')) {
    return achievementCatalog
        .firstWhere((a) => a.id == token.substring(12))
        .title;
  }
  if (token.startsWith('day:')) return '${token.split(':').last}. Dezember';
  if (token.startsWith('skin:')) {
    return hanukkahTitle(Minigame.values.byName(token.split(':').last));
  }
  if (token.startsWith('game:')) {
    return Minigame.values.byName(token.split(':').last).title;
  }
  final id = token.replaceFirst('bonus:', '');
  if (id.startsWith('bells:')) {
    return bellMelodies.firstWhere((m) => m.id == id.substring(6)).title;
  }
  if (id.startsWith('cookies:') ||
      id.startsWith('workshop:') ||
      id.startsWith('candy:')) {
    return '${id.startsWith('cookies')
        ? 'Plätzchen'
        : id.startsWith('candy')
        ? 'Labyrinth'
        : 'Werkstatt'} · ${GameDifficulty.values.byName(id.split(':').last).label}';
  }
  return achievements.firstWhere((a) => a.id == id).title;
}

/// Connects award day links to the live calendar's availability and completion.
class AchievementCalendar {
  const AchievementCalendar({
    required this.days,
    required this.openDay,
    required this.titleForDay,
  });
  final List<CalendarDay> Function() days;
  final Future<void> Function(int day) openDay;
  final String Function(int day) titleForDay;
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key, required this.store, this.calendar});
  final AchievementCalendar? calendar;
  final AchievementStore store;
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Achievement> get _collection => [
    ...achievements,
    finalReward,
    ...secretAchievements.where(widget.store.earned),
  ];
  final _pages = PageController();
  int _page = 0;
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Erfolge')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${achievements.where(widget.store.earned).length} / ${achievements.length} freigeschaltet',
                style: const TextStyle(color: CalendarStyle.green),
              ),
            ),
            if (widget.store.error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(widget.store.error!),
              ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: (_collection.length / 4).ceil(),
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, page) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (var row = 0; row < 2; row++)
                        Expanded(
                          child: Row(
                            children: [
                              for (var col = 0; col < 2; col++)
                                Expanded(
                                  child:
                                      page * 4 + row * 2 + col >=
                                          _collection.length
                                      ? const SizedBox.shrink()
                                      : _card(
                                          _collection[page * 4 + row * 2 + col],
                                        ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Vorherige Erfolge',
                  onPressed: _page == 0
                      ? null
                      : () => _pages.previousPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        ),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${_page + 1} / ${(_collection.length / 4).ceil()}'),
                IconButton(
                  tooltip: 'Weitere Erfolge',
                  onPressed: _page == (_collection.length / 4).ceil() - 1
                      ? null
                      : () => _pages.nextPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _card(Achievement achievement) {
    final earned = widget.store.earned(achievement);
    final color = earned ? CalendarStyle.green : const Color(0xFF8C8B84);
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Material(
        color: earned ? const Color(0xFFF5E6C9) : const Color(0xFFECEAE4),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('achievement-${achievement.id}'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _AchievementDetail(
                store: widget.store,
                achievement: achievement,
                calendar: widget.calendar,
              ),
            ),
          ),
          child: ViewportFit(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AchievementIllustration(
                  achievementId: achievement.id,
                  earned: earned,
                  width: 156,
                  height: 110,
                ),
                if (secretAchievements.contains(achievement)) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'GEHEIMER ZUSATZERFOLG',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CalendarStyle.gold,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (achievement.id == finalReward.id) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'ZUSÄTZLICHER BONUS',
                    style: TextStyle(
                      color: CalendarStyle.green,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.store.progress(achievement)} / ${achievement.requirements.length}',
                  style: TextStyle(color: color),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    value:
                        widget.store.progress(achievement) /
                        achievement.requirements.length,
                    color: color,
                    backgroundColor: color.withValues(alpha: .12),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  earned ? 'Freigeschaltet' : 'Noch zu entdecken',
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementDetail extends StatefulWidget {
  const _AchievementDetail({
    required this.store,
    required this.achievement,
    this.calendar,
  });
  final AchievementCalendar? calendar;
  final AchievementStore store;
  final Achievement achievement;
  @override
  State<_AchievementDetail> createState() => _AchievementDetailState();
}

class _AchievementDetailState extends State<_AchievementDetail> {
  bool _saving = false;
  String? _error;
  Future<void> _claim() async {
    setState(() => _saving = true);
    try {
      await widget.store.claim(widget.achievement);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Konnte nicht gespeichert werden. Bitte erneut versuchen.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _practice(
    Minigame game,
    GameDifficulty difficulty, {
    GameSkin skin = GameSkin.christmas,
    String? melodyId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AchievementScope(
          record: (facts) => widget.store.record(
            AchievementRun(
              day: null,
              game: game,
              difficulty: difficulty,
              facts: facts,
            ),
          ),
          child: GiftRewardScope(
            openGift: () async => GiftOpenResult.replay,
            child: buildMinigame(
              game,
              difficulty,
              () async {},
              skin: skin,
              melodyId: melodyId,
              alreadyCompleted: widget.store.tokenComplete(
                '${skin == GameSkin.hanukkah ? 'skin' : 'game'}:${game.name}',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _launchOptions(Minigame game) {
    final multiple = {
      'cookies',
      'workshop',
      'candy',
    }.contains(widget.achievement.id);
    final difficulties = multiple
        ? GameDifficulty.values
        : [GameDifficulty.normal];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final skin in [
          GameSkin.christmas,
          if (supportsHanukkah(game)) GameSkin.hanukkah,
        ]) ...[
          if (multiple) ...[
            Text(
              skin == GameSkin.hanukkah ? 'Chanukka' : 'Weihnachten',
              style: const TextStyle(color: CalendarStyle.muted),
            ),
            const SizedBox(height: 4),
          ],
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final difficulty in difficulties)
                OutlinedButton(
                  key: ValueKey(
                    'achievement-play-${skin.name}-${difficulty.name}',
                  ),
                  onPressed: () => _practice(game, difficulty, skin: skin),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (multiple) ...[
                        Icon(
                          widget.store.tokenComplete(
                                'bonus:${game == Minigame.maze ? 'candy' : game.name}:${difficulty.name}',
                              )
                              ? Icons.check_circle_outline
                              : Icons.circle_outlined,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        multiple
                            ? difficulty.label
                            : skin == GameSkin.hanukkah
                            ? 'Chanukka · ${difficulty.label}'
                            : 'Jetzt ausprobieren',
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  bool _onlyOpen = false;

  void _openAward(Achievement award) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _AchievementDetail(
        store: widget.store,
        achievement: award,
        calendar: widget.calendar,
      ),
    ),
  );

  Achievement? _related(String token) {
    if (token.startsWith('achievement:')) {
      return achievementCatalog
          .where((a) => a.id == token.substring(12))
          .firstOrNull;
    }
    return achievements
        .skip(3)
        .where((a) => a.requirements.contains(token))
        .firstOrNull;
  }

  VoidCallback? _openObjective(String token) {
    if (token.startsWith('game:') || token.startsWith('skin:')) {
      final game = Minigame.values.byName(token.split(':').last);
      return () => _practice(
        game,
        GameDifficulty.normal,
        skin: token.startsWith('skin:')
            ? GameSkin.hanukkah
            : GameSkin.christmas,
      );
    }
    if (token.startsWith('bonus:bells:')) {
      final id = token.substring(12);
      final index = bellMelodies.indexWhere((m) => m.id == id);
      return () => _practice(
        Minigame.bells,
        GameDifficulty.normal,
        melodyId: id,
        skin: index >= 8 ? GameSkin.hanukkah : GameSkin.christmas,
      );
    }
    final related = _related(token);
    return related == null ? null : () => _openAward(related);
  }

  bool _complete(String token) => token.startsWith('achievement:')
      ? widget.store.earned(
          achievementCatalog.firstWhere((a) => a.id == token.substring(12)),
        )
      : widget.store.tokenComplete(token);

  Widget _objectives(Achievement a) {
    final tokens = a.requirements
        .where((t) => !_onlyOpen || !_complete(t))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (a.requirements.length > 6)
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              label: const Text('Nur offene'),
              selected: _onlyOpen,
              onSelected: (value) => setState(() => _onlyOpen = value),
            ),
          ),
        for (final token in tokens)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
              color: _complete(token)
                  ? const Color(0xFFE5EEE5)
                  : const Color(0xFFF3E9D8),
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                key: ValueKey('objective-$token'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                leading: Icon(
                  _complete(token)
                      ? Icons.check_circle_outline
                      : Icons.circle_outlined,
                  color: CalendarStyle.green,
                ),
                title: Text(
                  objectiveLabel(token),
                  style: const TextStyle(
                    fontSize: 16,
                    color: CalendarStyle.green,
                  ),
                ),
                trailing: _openObjective(token) == null
                    ? null
                    : const Icon(Icons.chevron_right),
                onTap: _openObjective(token),
              ),
            ),
          ),
        if (tokens.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Alle Teilziele geschafft!',
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _days() {
    final days =
        widget.calendar?.days() ??
        calendarDays(DateTime.now(), {
          for (var n = 1; n <= 24; n++)
            if (widget.store.tokenComplete('day:$n')) 'day-$n',
        });
    return Column(
      children: [
        for (var row = 0; row < 12; row++)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var col = 0; col < 2; col++) ...[
                    if (col == 1) const SizedBox(width: 10),
                    Expanded(child: _day(days[row * 2 + col])),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _day(CalendarDay day) {
    final enabled = day.isAvailable && widget.calendar != null;
    final done =
        day.state == DayState.completed ||
        widget.store.tokenComplete('day:${day.number}');
    final color = enabled ? CalendarStyle.green : CalendarStyle.muted;
    return OutlinedButton(
      key: ValueKey('award-day-${day.number}'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(14),
        backgroundColor: !day.isAvailable
            ? const Color(0xFFE8E6E1)
            : done
            ? const Color(0xFFE5EEE5)
            : const Color(0xFFF3E9D8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: enabled
          ? () async {
              await widget.calendar!.openDay(day.number);
              if (mounted) setState(() {});
            }
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                day.number.toString().padLeft(2, '0'),
                style: TextStyle(fontSize: 24, color: color),
              ),
              const Spacer(),
              Icon(
                !day.isAvailable
                    ? Icons.lock_outline
                    : done
                    ? Icons.check_circle_outline
                    : Icons.lock_open_outlined,
                size: 20,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.calendar?.titleForDay(day.number) ??
                '${day.number}. Dezember',
            style: TextStyle(fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final a = widget.achievement,
          earned = widget.store.earned(widget.achievement);
      return Scaffold(
        appBar: AppBar(
          title: Text(
            a.id == finalReward.id ? 'Dein Extra-Bonus' : 'Dein Erfolg',
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            key: const ValueKey('award-progress-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: AchievementIllustration(
                        achievementId: a.id,
                        earned: earned,
                        width: 200,
                        height: 140,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      a.title,
                      textAlign: TextAlign.center,
                      style: CalendarStyle.heading.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: 12),
                    Text(a.description, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text(
                      '${widget.store.progress(a)} / ${a.requirements.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CalendarStyle.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: widget.store.progress(a) / a.requirements.length,
                      backgroundColor: CalendarStyle.line,
                      color: CalendarStyle.green,
                      minHeight: 5,
                    ),
                    const SizedBox(height: 16),
                    if (a.id == finalReward.id) ...[
                      const Text(
                        'ZUSÄTZLICH ZU DEINEN TÄGLICHEN GESCHENKEN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CalendarStyle.green,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        !earned
                            ? 'Der Extra-Bonus bleibt bis zum letzten Erfolg geheim.'
                            : widget.store.reward(a) ??
                                  'Alle Erfolge geschafft! Dein Extra-Bonus wird noch vorbereitet.',
                        textAlign: TextAlign.center,
                      ),
                      if (earned && widget.store.reward(a) != null)
                        FilledButton(
                          onPressed: _saving || widget.store.claimed(a)
                              ? null
                              : _claim,
                          child: Text(
                            widget.store.claimed(a)
                                ? 'Gutschein erhalten'
                                : _saving
                                ? 'Speichert…'
                                : 'Als erhalten markieren',
                          ),
                        ),
                    ],
                    if (a.id == 'allDays')
                      _days()
                    else if (gameForAchievement(a.id) case final game?)
                      _launchOptions(game)
                    else if (a.requirements.length > 1)
                      _objectives(a),
                    const SizedBox(height: 20),
                    Text(
                      earned ? 'Erfolg freigeschaltet!' : 'Noch zu entdecken.',
                      textAlign: TextAlign.center,
                    ),
                    if (_error != null)
                      Text(_error!, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
