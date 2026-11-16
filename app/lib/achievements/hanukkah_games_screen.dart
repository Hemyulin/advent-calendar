import 'package:flutter/material.dart';
import '../challenges/games/difficulty.dart';
import '../challenges/games/game_catalog.dart';
import '../challenges/games/gift_reward_scope.dart';
import '../challenges/gift_reward.dart';
import '../challenges/seasonal/game_skin.dart';
import '../challenges/seasonal/hanukkah_art.dart';
import '../presentation/calendar_style.dart';
import '../presentation/viewport_fit.dart';
import 'achievement_scope.dart';
import 'achievement_store.dart';

/// Real replay attempts, not admin previews; never complete calendar doors.
class HanukkahGamesScreen extends StatefulWidget {
  const HanukkahGamesScreen({
    super.key,
    required this.store,
    this.skin = GameSkin.hanukkah,
  });
  final GameSkin skin;
  final AchievementStore store;
  @override
  State<HanukkahGamesScreen> createState() => _HanukkahGamesScreenState();
}

class _HanukkahGamesScreenState extends State<HanukkahGamesScreen> {
  GameDifficulty _difficulty = GameDifficulty.normal;
  bool get _hanukkah => widget.skin == GameSkin.hanukkah;
  List<Minigame> get _games => _hanukkah ? hanukkahGames : Minigame.values;
  String get _prefix => _hanukkah ? 'skin' : 'game';
  int _page = 0;
  void _play(Minigame game) {
    final difficulty = _difficulty;
    Navigator.of(context).push(
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
              skin: widget.skin,
              alreadyCompleted: widget.store.tokenComplete(
                '$_prefix:${game.name}',
              ),
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
      appBar: AppBar(
        title: Text(_hanukkah ? 'Dein Lichterfest' : 'Spiele auswählen'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      constraints.maxWidth > 500 && constraints.maxHeight < 500
                      ? 4
                      : 2;
                  final visibleCount = (_games.length - _page * 8).clamp(0, 8);
                  return Column(
                    children: [
                      DropdownButtonFormField<GameDifficulty>(
                        initialValue: _difficulty,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Schwierigkeit',
                        ),
                        items: [
                          for (final d in GameDifficulty.values)
                            DropdownMenuItem(value: d, child: Text(d.label)),
                        ],
                        onChanged: (d) {
                          if (d != null) setState(() => _difficulty = d);
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
                                            ? _card(
                                                _games[_page * 8 +
                                                    row * columns +
                                                    col],
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
                            key: const ValueKey('hanukkah-games-previous'),
                            tooltip: 'Vorherige Spiele',
                            onPressed: _page > 0
                                ? () => setState(() => _page--)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text('${_page + 1}/${(_games.length / 8).ceil()}'),
                          IconButton(
                            key: const ValueKey('hanukkah-games-next'),
                            tooltip: 'Weitere Spiele',
                            onPressed: (_page + 1) * 8 < _games.length
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
  Widget _card(Minigame game) {
    final done = widget.store.tokenComplete('$_prefix:${game.name}');
    return Padding(
      padding: const EdgeInsets.all(5),
      child: OutlinedButton(
        key: ValueKey(
          '${_hanukkah ? 'hanukkah' : 'practice'}-game-${game.name}',
        ),
        onPressed: () => _play(game),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: done
              ? const Color(0xFFE5EEE5)
              : const Color(0xFFEAF0F4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: ViewportFit(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: _hanukkah
                    ? CustomPaint(
                        painter: HanukkahMotifPainter(
                          game == Minigame.shoe ? 3 : game.index % 8,
                        ),
                      )
                    : Icon(game.icon, color: CalendarStyle.green),
              ),
              const SizedBox(height: 8),
              Text(
                hanukkahTitle(game),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: hanukkahBlue),
              ),
              if (done) ...[
                const SizedBox(height: 5),
                const Icon(
                  Icons.check_circle_outline,
                  color: CalendarStyle.green,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
