import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../presentation/calendar_style.dart';
import '../completion.dart';
import '../games/game_widgets.dart';
import 'memory_game.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({
    super.key,
    required this.onComplete,
    this.level = const MemoryLevel(),
    this.alreadyCompleted = false,
  });
  final MemoryLevel level;
  final ChallengeCompletion onComplete;
  final bool alreadyCompleted;
  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  late MemoryGame _game;
  Timer? _mismatchTimer;
  static const _icons = [
    Icons.park_rounded,
    Icons.card_giftcard_rounded,
    Icons.favorite_rounded,
    Icons.star_rounded,
    Icons.snowing,
    Icons.notifications_rounded,
    Icons.cookie_rounded,
    Icons.local_cafe_rounded,
  ];
  static const _names = [
    'Tannenbaum',
    'Geschenk',
    'Herz',
    'Stern',
    'Schneeflocke',
    'Glocke',
    'Plätzchen',
    'Tasse',
  ];
  static const _colors = [
    CalendarStyle.green,
    Color(0xFFB94F46),
    Color(0xFFA84E6B),
    CalendarStyle.gold,
    Color(0xFF477F96),
    Color(0xFF99623C),
    Color(0xFFB57B45),
    Color(0xFF796895),
  ];

  @override
  void initState() {
    super.initState();
    _game = MemoryGame(widget.level);
  }

  void _reveal(int index) {
    if (!_game.reveal(index)) return;
    setState(() {});
    if (_game.second != null) {
      // Even with reduced motion, keep the mismatch visible long enough to read.
      _mismatchTimer = Timer(const Duration(milliseconds: 1000), () {
        if (mounted) setState(_game.hideMismatch);
      });
    }
  }

  void _restart() {
    _mismatchTimer?.cancel();
    setState(() => _game = MemoryGame(widget.level));
  }

  @override
  void dispose() {
    _mismatchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    title: 'Paare finden',
    alreadyCompleted: widget.alreadyCompleted,
    onRestart: _restart,
    instructions:
        'Decke zwei Karten auf und finde alle acht Weihnachtspaare. Jedes aufgedeckte Paar zählt als Versuch.',
    children: [
      GameStats(
        text: '${_game.pairsFound} / 8 Paare · ${_game.attemptsLeft} Versuche',
      ),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 16,
        itemBuilder: (context, index) {
          final visible = _game.isFaceUp(index);
          final matched = _game.matched.contains(index);
          return Semantics(
            button: true,
            onTap: !visible && !_game.won && !_game.lost && _game.second == null
                ? () => _reveal(index)
                : null,
            enabled:
                !visible && !_game.won && !_game.lost && _game.second == null,
            label:
                'Karte ${index + 1}, ${matched
                    ? '${_names[_game.cards[index]]}, gefunden'
                    : visible
                    ? _names[_game.cards[index]]
                    : 'verdeckt'}',
            child: ExcludeSemantics(
              child: InkWell(
                key: ValueKey('memory-card-$index'),
                onTap: () => _reveal(index),
                borderRadius: BorderRadius.circular(14),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: visible ? 1 : 0),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  builder: (context, value, _) {
                    final showFace = value >= 0.5;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(math.pi * (showFace ? value - 1 : value)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: showFace
                              ? (matched
                                    ? const Color(0xFFE2EDDD)
                                    : const Color(0xFFFFEBD3))
                              : CalendarStyle.green,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: matched
                                ? CalendarStyle.green.withValues(alpha: 0.4)
                                : CalendarStyle.gold.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            showFace
                                ? _icons[_game.cards[index]]
                                : Icons.ac_unit_rounded,
                            color: showFace
                                ? _colors[_game.cards[index]]
                                : const Color(0xFFF1D49C),
                            size: 30,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 20),
      if (_game.won)
        CompletionPanel(
          onComplete: widget.onComplete,
          onReplay: _restart,
          message: 'Alle Paare gefunden.',
        )
      else if (_game.lost)
        DefeatPanel(message: 'Versuche aufgebraucht.', onRetry: _restart),
    ],
  );
}
