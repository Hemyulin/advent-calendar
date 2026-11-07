import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../presentation/calendar_style.dart';
import '../completion.dart';
import '../games/game_widgets.dart';
import 'bell_audio.dart';
import 'bell_melodies.dart';
import 'bells_game.dart';

class BellsScreen extends StatefulWidget {
  const BellsScreen({
    super.key,
    required this.onComplete,
    this.level = const BellsLevel(),
    this.audio,
    this.alreadyCompleted = false,
    this.previewControls = false,
  });
  final BellsLevel level;
  final BellAudio? audio;
  final ChallengeCompletion onComplete;
  final bool alreadyCompleted, previewControls;
  @override
  State<BellsScreen> createState() => _BellsScreenState();
}

class _BellsScreenState extends State<BellsScreen> with WidgetsBindingObserver {
  late BellsGame _game;
  late final BellAudio _audio;
  Timer? _timer;
  int _generation = 0;
  bool _ready = false;
  bool _error = false;
  bool _foreground = true;
  BellNote? _active;
  final _strikes = {for (final note in BellNote.values) note: 0};
  Future<void> _input = Future.value();
  int? _previewRound;

  @override
  void initState() {
    super.initState();
    _game = BellsGame(widget.level);
    _audio = widget.audio ?? SampledBellAudio();
    WidgetsBinding.instance.addObserver(this);
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() {
      _error = false;
      _ready = false;
    });
    try {
      await _audio.prepare();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _cancel() {
    _generation++;
    _timer?.cancel();
    _active = null;
    unawaited(_audio.stop().catchError((Object _) {}));
  }

  void _interrupt() {
    _cancel();
    _game.interrupt();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == false) _interrupt();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground && mounted) setState(_interrupt);
  }

  bool _valid(int generation) =>
      mounted && _foreground && generation == _generation;

  void _audioFailed() {
    if (!mounted) return;
    setState(() {
      _interrupt();
      _ready = false;
      _error = true;
    });
  }

  void _listen() {
    if (!_ready || !_foreground) return;
    _cancel();
    if (!_game.listen()) return;
    setState(() {});
    _playNext(0, _generation);
  }

  Future<void> _playNext(int index, int generation) async {
    if (!_valid(generation)) return;
    final notes = _game.current.notes;
    if (index == notes.length) {
      setState(() {
        _active = null;
        _game.finishListening();
      });
      return;
    }
    final note = notes[index];
    try {
      await _audio.play(note.pitch);
      if (!_valid(generation)) return;
      setState(() {
        _active = note.pitch;
        _strikes[note.pitch] = _strikes[note.pitch]! + 1;
      });
      final duration = math.max(
        220,
        (note.beats * _game.level.beatMilliseconds).round(),
      );
      _timer = Timer(
        Duration(milliseconds: duration),
        () => _playNext(index + 1, generation),
      );
    } catch (_) {
      if (_valid(generation)) _audioFailed();
    }
  }

  void _tap(BellNote note) {
    if (_game.phase != BellsPhase.answering || !_ready || !_foreground) return;
    final generation = _generation;
    // Serialize the audio starts and rule updates so fast taps keep their order.
    _input = _input.then((_) => _answer(note, generation));
  }

  Future<void> _answer(BellNote note, int generation) async {
    if (!_valid(generation) || _game.phase != BellsPhase.answering) return;
    try {
      await _audio.play(note);
      if (!_valid(generation)) return;
      setState(() {
        _active = note;
        _strikes[note] = _strikes[note]! + 1;
        _game.tap(note);
      });
      if (_game.phase == BellsPhase.mistake) {
        _generation++; // Discard any taps queued before the mistake.
        _timer?.cancel();
        _timer = Timer(const Duration(milliseconds: 850), () {
          if (mounted) {
            setState(() {
              _active = null;
              _game.retry();
            });
          }
        });
      }
    } catch (_) {
      if (_valid(generation)) _audioFailed();
    }
  }

  void _restart() => setState(() {
    _cancel();
    _game = BellsGame(
      _previewRound == null
          ? widget.level
          : BellsLevel(
              rounds: [bellRounds[_previewRound!]],
              beatMilliseconds: widget.level.beatMilliseconds,
            ),
    );
  });

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _timer?.cancel();
    unawaited(_audio.dispose().catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _game.phase;
    final answering = phase == BellsPhase.answering;
    return GameScaffold(
      title: 'Weihnachtsglocken',
      alreadyCompleted: widget.alreadyCompleted,
      onRestart: _restart,
      instructions:
          'Hör der Melodie zu. Spiele danach dieselben Glocken in derselben Reihenfolge. Dein Tempo ist egal. Du darfst beliebig oft zuhören und es noch einmal versuchen.',
      children: [
        if (widget.previewControls) ...[
          DropdownButtonFormField<int>(
            key: const ValueKey('bell-melody-preview'),
            initialValue: _previewRound,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Melodie ausprobieren',
              border: OutlineInputBorder(),
            ),
            hint: const Text('Alle Stufen'),
            items: [
              for (var i = 0; i < bellRounds.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(
                    bellRounds[i].label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (index) {
              if (index != null) {
                _previewRound = index;
                _restart();
              }
            },
          ),
          const SizedBox(height: 16),
        ],
        GameStats(
          text: _error
              ? 'Der Ton konnte nicht geladen werden.'
              : !_ready
              ? 'Glocken werden gestimmt …'
              : switch (phase) {
                  BellsPhase.ready =>
                    '${_game.current.length} Töne · Hör gut zu',
                  BellsPhase.listening => 'Lausche den Glocken …',
                  BellsPhase.answering => 'Jetzt bist du dran',
                  BellsPhase.mistake => 'Noch einmal – du schaffst das.',
                  BellsPhase.roundWon || BellsPhase.won => 'Wunderbar!',
                },
        ),
        Text(
          _game.current.melody.title,
          textAlign: TextAlign.center,
          style: CalendarStyle.heading.copyWith(fontSize: 25),
        ),
        const SizedBox(height: 12),
        if (_game.level.rounds.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _game.level.rounds.length; i++)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    i < _game.round ? Icons.check_circle_rounded : Icons.circle,
                    size: 9,
                    color: i <= _game.round
                        ? CalendarStyle.green
                        : CalendarStyle.line,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: .7,
            mainAxisSpacing: 12,
            crossAxisSpacing: 4,
          ),
          itemCount: BellNote.values.length,
          itemBuilder: (context, index) {
            final note = BellNote.values[index];
            return _IllustratedBell(
              note: note,
              strike: _strikes[note]!,
              enabled: answering && _ready,
              wrong: phase == BellsPhase.mistake && _active == note,
              onTap: () => _tap(note),
            );
          },
        ),
        const SizedBox(height: 20),
        Semantics(
          label: '${_game.entered} von ${_game.current.length} Tönen richtig',
          liveRegion: true,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 9,
            runSpacing: 6,
            children: [
              for (var i = 0; i < _game.current.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: phase == BellsPhase.mistake
                        ? const Color(0xFFCC8C77)
                        : i < _game.entered
                        ? CalendarStyle.green
                        : CalendarStyle.line,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (phase == BellsPhase.roundWon)
          FilledButton.icon(
            onPressed: () {
              setState(_game.nextRound);
              _listen();
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Nächste Melodie'),
          )
        else if (_error)
          FilledButton.icon(
            onPressed: _prepare,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Ton erneut laden'),
          )
        else
          FilledButton.icon(
            onPressed:
                _ready &&
                    phase != BellsPhase.listening &&
                    phase != BellsPhase.won
                ? _listen
                : null,
            icon: const Icon(Icons.volume_up_outlined),
            label: Text(
              phase == BellsPhase.ready ? 'Melodie anhören' : 'Erneut anhören',
            ),
          ),
        if (phase == BellsPhase.won)
          CompletionPanel(
            onComplete: widget.onComplete,
            onReplay: _restart,
            message: 'Das klingt nach Weihnachten!',
          ),
      ],
    );
  }
}

class _IllustratedBell extends StatefulWidget {
  const _IllustratedBell({
    required this.note,
    required this.strike,
    required this.enabled,
    required this.wrong,
    required this.onTap,
  });
  final BellNote note;
  final int strike;
  final bool enabled, wrong;
  final VoidCallback onTap;
  @override
  State<_IllustratedBell> createState() => _IllustratedBellState();
}

class _IllustratedBellState extends State<_IllustratedBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 780),
  );
  @override
  void didUpdateWidget(_IllustratedBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.strike != widget.strike) _swing.forward(from: 0);
  }

  @override
  void dispose() {
    _swing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Glocke ${widget.note == BellNote.highC ? 'hohes C' : widget.note.label}',
    button: true,
    enabled: widget.enabled,
    child: InkWell(
      key: ValueKey('bell-${widget.note.name}'),
      onTap: widget.enabled ? widget.onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedBuilder(
        animation: _swing,
        builder: (context, _) {
          final pulse = _swing.isAnimating ? 1 - _swing.value : 0.0;
          final angle = MediaQuery.disableAnimationsOf(context)
              ? 0.0
              : math.sin(_swing.value * math.pi * 4) * .14 * pulse;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: RadialGradient(
                colors: [
                  (widget.wrong
                          ? const Color(0xFFE8AF96)
                          : const Color(0xFFF1D38B))
                      .withValues(alpha: pulse * .5),
                  CalendarStyle.ivory.withValues(alpha: 0),
                ],
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Transform.rotate(
                    angle: angle,
                    alignment: Alignment.topCenter,
                    child: CustomPaint(
                      painter: _BellPainter(widget.note.index),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                Text(
                  widget.note.label,
                  style: TextStyle(
                    color: widget.wrong
                        ? const Color(0xFFB76D57)
                        : CalendarStyle.muted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _BellPainter extends CustomPainter {
  _BellPainter(this.index);
  final int index;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 125);
    final paint = Paint();
    canvas.drawLine(
      const Offset(50, 0),
      const Offset(50, 30),
      paint
        ..color = const Color(0xFFCAB692)
        ..strokeWidth = 1.5,
    );
    canvas.drawOval(
      const Rect.fromLTWH(41, 26, 18, 19),
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = CalendarStyle.gold,
    );
    paint.style = PaintingStyle.fill;
    final ribbonColor = index.isEven
        ? CalendarStyle.green
        : const Color(0xFFB65F52);
    canvas.drawPath(
      Path()
        ..moveTo(50, 40)
        ..quadraticBezierTo(24, 17, 23, 37)
        ..quadraticBezierTo(30, 49, 50, 40)
        ..quadraticBezierTo(75, 18, 78, 36)
        ..quadraticBezierTo(72, 50, 50, 40)
        ..close(),
      paint..color = ribbonColor,
    );
    canvas.drawPath(
      Path()
        ..moveTo(46, 40)
        ..lineTo(30, 63)
        ..lineTo(43, 59)
        ..lineTo(49, 66)
        ..lineTo(55, 41)
        ..close(),
      paint..color = ribbonColor,
    );
    canvas.drawCircle(
      const Offset(51, 109),
      8,
      paint..color = const Color(0xFFAE7830),
    );
    final bell = Path()
      ..moveTo(18, 100)
      ..quadraticBezierTo(30, 87, 30, 66)
      ..quadraticBezierTo(31, 43, 50, 43)
      ..quadraticBezierTo(69, 43, 70, 66)
      ..quadraticBezierTo(70, 87, 82, 100)
      ..close();
    canvas.drawPath(
      bell,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFB98536), Color(0xFFF4D693), Color(0xFFD8A34D)],
          stops: [0, .4, 1],
        ).createShader(const Rect.fromLTWH(18, 43, 64, 60)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(39, 56)
        ..quadraticBezierTo(34, 67, 34, 81),
      paint
        ..color = const Color(0xFFFFE9B6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 98, 68, 9),
        const Radius.circular(5),
      ),
      paint..color = const Color(0xFFEAC079),
    );
    canvas.drawOval(
      const Rect.fromLTWH(22, 103, 56, 7),
      paint..color = const Color(0xFFB37C32),
    );
    canvas.drawCircle(
      const Offset(51, 109),
      5,
      paint..color = const Color(0xFFE8BF71),
    );
    paint
      ..color = const Color(0xFFAA7C3F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    if (index % 3 == 0) {
      canvas.drawPath(
        Path()
          ..moveTo(50, 69)
          ..lineTo(41, 83)
          ..lineTo(46, 83)
          ..lineTo(39, 91)
          ..lineTo(61, 91)
          ..lineTo(54, 83)
          ..lineTo(59, 83)
          ..close(),
        paint,
      );
    } else if (index % 3 == 1) {
      canvas.drawPath(
        Path()
          ..moveTo(50, 90)
          ..cubicTo(25, 76, 45, 65, 50, 75)
          ..cubicTo(56, 65, 75, 76, 50, 90),
        paint,
      );
    } else {
      for (var i = 0; i < 3; i++) {
        final angle = i * math.pi / 3;
        final delta = Offset(math.cos(angle), math.sin(angle)) * 10;
        canvas.drawLine(
          const Offset(50, 81) - delta,
          const Offset(50, 81) + delta,
          paint,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BellPainter oldDelegate) => index != oldDelegate.index;
}
