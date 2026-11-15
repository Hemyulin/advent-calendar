import 'package:flutter/material.dart';
import '../presentation/calendar_style.dart';
import '../presentation/viewport_fit.dart';
import '../challenges/games/difficulty.dart';
import 'achievement_store.dart';
import 'bell_songs_screen.dart';
import 'hanukkah_games_screen.dart';
import '../challenges/seasonal/game_skin.dart';
import '../challenges/bells/bell_melodies.dart';
import 'achievement_art.dart';
import 'achievement_scope.dart';
import 'achievement_objectives_screen.dart';
import '../challenges/games/game_catalog.dart';
import '../challenges/games/gift_reward_scope.dart';
import '../challenges/gift_reward.dart';

final _collection = [...achievements, finalReward];

String objectiveLabel(String token) {
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

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key, required this.store});
  final AchievementStore store;
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
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
  const _AchievementDetail({required this.store, required this.achievement});
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

  Future<void> _practice(Minigame game, GameDifficulty difficulty) async {
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
            child: buildMinigame(game, difficulty, () async {}),
          ),
        ),
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
          child: ViewportFit(
            maxWidth: 480,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AchievementIllustration(
                  achievementId: a.id,
                  earned: earned,
                  width: 220,
                  height: 154,
                ),
                if (a.id == finalReward.id) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'ZUSÄTZLICH ZU DEINEN TÄGLICHEN GESCHENKEN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CalendarStyle.green,
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
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
                  style: const TextStyle(
                    color: CalendarStyle.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (a.requirements.length > 6 && a.id != finalReward.id) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 240,
                    child: LinearProgressIndicator(
                      value: widget.store.progress(a) / a.requirements.length,
                      color: CalendarStyle.green,
                      backgroundColor: CalendarStyle.green.withValues(
                        alpha: .1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AchievementObjectivesScreen(
                          store: widget.store,
                          achievement: a,
                          label: objectiveLabel,
                          onOpenAchievement: (achievement) =>
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _AchievementDetail(
                                    store: widget.store,
                                    achievement: achievement,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.checklist_rounded),
                    label: const Text('Teilziele ansehen'),
                  ),
                ] else if (a.requirements.length > 1 &&
                    a.id != finalReward.id) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final token in a.requirements)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(
                            widget.store.tokenComplete(token)
                                ? Icons.check_circle_outline
                                : Icons.circle_outlined,
                            size: 16,
                          ),
                          label: Text(
                            objectiveLabel(token),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ],
                if (a.id == 'cookies' ||
                    a.id == 'workshop' ||
                    a.id == 'candy') ...[
                  const SizedBox(height: 12),
                  if (widget.store.tokenComplete(
                    'game:${a.id == 'candy' ? 'maze' : a.id}',
                  ))
                    Wrap(
                      spacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final difficulty in GameDifficulty.values)
                          OutlinedButton(
                            onPressed: () => _practice(
                              a.id == 'cookies'
                                  ? Minigame.cookies
                                  : a.id == 'candy'
                                  ? Minigame.maze
                                  : Minigame.workshop,
                              difficulty,
                            ),
                            child: Text(difficulty.label),
                          ),
                      ],
                    )
                  else
                    const Text(
                      'Schließe zuerst ein Türchen mit diesem Spiel ab.',
                      textAlign: TextAlign.center,
                    ),
                ],
                if (a.id == 'hanukkah') ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            HanukkahGamesScreen(store: widget.store),
                      ),
                    ),
                    icon: const Icon(Icons.celebration_outlined),
                    label: const Text('Chanukka-Spiele spielen'),
                  ),
                ],
                if (a.id == 'bells') ...[
                  const SizedBox(height: 12),
                  if (widget.store.tokenComplete('game:bells'))
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BellSongsScreen(store: widget.store),
                        ),
                      ),
                      icon: const Icon(Icons.music_note_outlined),
                      label: const Text('Lieder spielen'),
                    )
                  else
                    const Text(
                      'Schließe zuerst ein Türchen mit Weihnachtsglocken ab.',
                      textAlign: TextAlign.center,
                    ),
                ],
                const SizedBox(height: 22),
                if (a.id == finalReward.id) ...[
                  Icon(
                    earned ? Icons.card_giftcard : Icons.lock_outline,
                    color: CalendarStyle.gold,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    !earned
                        ? 'Der Extra-Bonus bleibt bis zum letzten Erfolg geheim.'
                        : widget.store.reward(a) ??
                              'Alle Erfolge geschafft! Dein Extra-Bonus wird noch vorbereitet.',
                    textAlign: TextAlign.center,
                  ),
                  if (earned && widget.store.reward(a) != null) ...[
                    const SizedBox(height: 16),
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
                ] else
                  Text(
                    earned ? 'Erfolg freigeschaltet!' : 'Noch zu entdecken.',
                    textAlign: TextAlign.center,
                  ),
                if (_error != null) Text(_error!, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    },
  );
}
