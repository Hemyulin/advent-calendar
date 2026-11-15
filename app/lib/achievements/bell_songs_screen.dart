import 'package:flutter/material.dart';
import '../challenges/bells/bell_melodies.dart';
import '../challenges/bells/bells_game.dart';
import '../challenges/bells/bells_screen.dart';
import '../challenges/games/difficulty.dart';
import '../challenges/games/game_kind.dart';
import '../challenges/games/gift_reward_scope.dart';
import '../challenges/gift_reward.dart';
import '../challenges/seasonal/game_skin.dart';
import '../challenges/seasonal/game_skin_scope.dart';
import '../presentation/calendar_style.dart';
import '../presentation/viewport_fit.dart';
import 'achievement_scope.dart';
import 'achievement_store.dart';

/// Real bonus attempts, separate from date assignments and development previews.
class BellSongsScreen extends StatefulWidget {
  const BellSongsScreen({super.key, required this.store});
  final AchievementStore store;
  @override
  State<BellSongsScreen> createState() => _BellSongsScreenState();
}

class _BellSongsScreenState extends State<BellSongsScreen> {
  GameDifficulty _difficulty = GameDifficulty.normal;
  int _page = 0;
  void _play(int index) {
    final difficulty = _difficulty;
    final base = BellsLevel.forDifficulty(difficulty);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AchievementScope(
          record: (facts) => widget.store.record(
            AchievementRun(
              day: null,
              game: Minigame.bells,
              difficulty: difficulty,
              facts: facts,
            ),
          ),
          child: GiftRewardScope(
            openGift: () async => GiftOpenResult.replay,
            child: SkinnableGame(
              initialSkin: index >= 8 ? GameSkin.hanukkah : GameSkin.christmas,
              builder: (skin) {
                final selected = (skin == GameSkin.hanukkah) == (index >= 8);
                final level = selected
                    ? BellsLevel(
                        rounds: [BellRound(index)],
                        beatMilliseconds: base.beatMilliseconds,
                        guidance: base.guidance,
                      )
                    : BellsLevel.forDifficulty(
                        difficulty,
                        hanukkah: skin == GameSkin.hanukkah,
                      );
                return BellsScreen(
                  level: level,
                  alreadyCompleted: widget.store.tokenComplete(
                    'bonus:bells:${level.rounds.single.melody.id}',
                  ),
                  onComplete: () async {},
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Dein Festtagskonzert')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      constraints.maxWidth > 500 && constraints.maxHeight < 500
                      ? 4
                      : 2;
                  final visibleCount = (bellMelodies.length - _page * 8).clamp(
                    0,
                    8,
                  );
                  return Column(
                    children: [
                      Text(
                        '${bellMelodies.where((m) => widget.store.tokenComplete('bonus:bells:${m.id}')).length} / ${bellMelodies.length} Lieder gemeistert',
                        style: const TextStyle(color: CalendarStyle.green),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<GameDifficulty>(
                        initialValue: _difficulty,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Schwierigkeit',
                        ),
                        items: [
                          for (final difficulty in GameDifficulty.values)
                            DropdownMenuItem(
                              value: difficulty,
                              child: Text(difficulty.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _difficulty = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Column(
                          children: [
                            for (
                              var row = 0;
                              row < (visibleCount / columns).ceil();
                              row++
                            )
                              Expanded(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (var col = 0; col < columns; col++)
                                      Expanded(
                                        child:
                                            row * columns + col < visibleCount
                                            ? _song(
                                                _page * 8 + row * columns + col,
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            key: const ValueKey('bell-songs-previous'),
                            tooltip: 'Vorherige Lieder',
                            onPressed: _page > 0
                                ? () => setState(() => _page--)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            '${_page + 1}/${(bellMelodies.length / 8).ceil()}',
                          ),
                          IconButton(
                            key: const ValueKey('bell-songs-next'),
                            tooltip: 'Weitere Lieder',
                            onPressed: (_page + 1) * 8 < bellMelodies.length
                                ? () => setState(() => _page++)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _song(int index) {
    final melody = bellMelodies[index];
    final done = widget.store.tokenComplete('bonus:bells:${melody.id}');
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Semantics(
        label: '${melody.title}, ${done ? 'gemeistert' : 'noch offen'}',
        button: true,
        child: OutlinedButton(
          key: ValueKey('bell-song-${melody.id}'),
          onPressed: () => _play(index),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: done
                ? const Color(0xFFE7EFE3)
                : const Color(0xFFF5E6C9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: ExcludeSemantics(
            child: ViewportFit(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    done
                        ? Icons.check_circle_outline_rounded
                        : Icons.notifications_active_outlined,
                    color: done ? CalendarStyle.green : CalendarStyle.gold,
                    size: 25,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    melody.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CalendarStyle.green,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
