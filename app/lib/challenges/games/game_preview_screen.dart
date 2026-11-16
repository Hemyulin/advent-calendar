import 'package:flutter/material.dart';

import '../../presentation/calendar_style.dart';
import '../../presentation/viewport_fit.dart';
import 'difficulty.dart';
import 'game_catalog.dart';
import '../seasonal/game_skin.dart';
import '../seasonal/game_skin_scope.dart';

class GamePreviewScreen extends StatefulWidget {
  const GamePreviewScreen({super.key, this.skin = GameSkin.christmas});
  final GameSkin skin;
  @override
  State<GamePreviewScreen> createState() => _GamePreviewScreenState();
}

class _GamePreviewScreenState extends State<GamePreviewScreen> {
  GameDifficulty _difficulty = GameDifficulty.normal;
  List<Minigame> get _games =>
      widget.skin == GameSkin.hanukkah ? hanukkahGames : Minigame.values;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.skin == GameSkin.hanukkah
            ? 'Chanukka-Spiele ausprobieren'
            : 'Spiele ausprobieren',
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Vorschau',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: CalendarStyle.muted),
                  ),
                  if (widget.skin == GameSkin.christmas)
                    TextButton.icon(
                      key: const ValueKey('preview-hanukkah-games'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const GamePreviewScreen(skin: GameSkin.hanukkah),
                        ),
                      ),
                      icon: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomPaint(painter: StarOfDavidPainter()),
                      ),
                      label: const Text('Chanukka-Spiele'),
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<GameDifficulty>(
                    initialValue: _difficulty,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Schwierigkeit',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final level in GameDifficulty.values)
                        DropdownMenuItem(
                          value: level,
                          child: Text(level.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _difficulty = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Column(
                      children: [
                        for (
                          var row = 0;
                          row < (_games.length / 2).ceil();
                          row++
                        )
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var col = 0; col < 2; col++)
                                  Expanded(
                                    child: row * 2 + col >= _games.length
                                        ? const SizedBox.shrink()
                                        : Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: _gameCard(
                                              _games[row * 2 + col],
                                            ),
                                          ),
                                  ),
                              ],
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
      ),
    ),
  );

  Widget _gameCard(Minigame game) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => buildMinigame(
          game,
          _difficulty,
          () async {},
          developmentPreview: true,
          skin: widget.skin,
        ),
      ),
    ),
    child: ViewportFit(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(game.icon, size: 32),
          const SizedBox(height: 10),
          Text(
            widget.skin == GameSkin.hanukkah ? hanukkahTitle(game) : game.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19),
          ),
        ],
      ),
    ),
  );
}
