import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../presentation/calendar_style.dart';
import '../completion.dart';
import '../games/game_widgets.dart';
import 'chimney_game.dart';

class ChimneyScreen extends StatefulWidget {
  const ChimneyScreen({
    super.key,
    required this.onComplete,
    this.level = const ChimneyLevel(),
    this.alreadyCompleted = false,
  });
  final ChimneyLevel level;
  final ChallengeCompletion onComplete;
  final bool alreadyCompleted;

  @override
  State<ChimneyScreen> createState() => _ChimneyScreenState();
}

class _ChimneyScreenState extends State<ChimneyScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late ChimneyGame _game;
  late final Ticker _ticker;
  Duration? _last;
  bool _foreground = true;
  int _replays = 0;

  @override
  void initState() {
    super.initState();
    _game = ChimneyGame(widget.level);
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker((elapsed) {
      final previous = _last;
      _last = elapsed;
      if (previous == null ||
          !_foreground ||
          !TickerMode.of(context) ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      if (_game.phase == ChimneyPhase.won || _game.phase == ChimneyPhase.lost) {
        return;
      }
      // A stalled frame must not teleport Santa past a chance to react.
      setState(
        () => _game.advance(
          math.min((elapsed - previous).inMicroseconds / 1e6, 0.1),
        ),
      );
      if (_game.phase == ChimneyPhase.won || _game.phase == ChimneyPhase.lost) {
        _ticker.stop();
      }
    })..start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _last = null;
  }

  void _restart() {
    setState(() {
      _replays++;
      _game = ChimneyGame(
        widget.level,
        random: math.Random(
          widget.level.seed == null ? null : widget.level.seed! + _replays,
        ),
      );
      _last = null;
    });
    if (!_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  Offset _santaPosition() {
    final entry = Offset(_game.incoming.dx / 2, _game.incoming.dy / 2);
    final exit = Offset(
      (_game.outgoing ?? PipeDirection.south).dx / 2,
      (_game.outgoing ?? PipeDirection.south).dy / 2,
    );
    final p = _game.progress;
    final local = p < 0.5 ? entry * (1 - p * 2) : exit * ((p - 0.5) * 2);
    return Offset(
      _game.cell % widget.level.size + 0.5 + local.dx,
      _game.cell ~/ widget.level.size + 0.5 + local.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final preparing = _game.phase == ChimneyPhase.preparing;
    return GameScaffold(
      title: 'Rettet den Weihnachtsmann!',
      alreadyCompleted: widget.alreadyCompleted,
      onRestart: _restart,
      instructions:
          'Tippe auf die Rohre, um sie zu drehen. Verbinde den verschneiten Eingang mit dem Kamin. Nach ${widget.level.preparationSeconds.ceil()} Sekunden krabbelt der Weihnachtsmann los. Du kannst vor ihm weiterbauen. Das Rohr unter ihm bleibt fest.',
      children: [
        GameStats(
          text: preparing
              ? 'Start in ${_game.preparationLeft.ceil()} s'
              : _game.phase == ChimneyPhase.moving
              ? 'Mach den Weg frei!'
              : _game.phase == ChimneyPhase.won
              ? 'Am Kamin angekommen!'
              : 'Hier geht’s nicht weiter',
        ),
        if (preparing)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.level.preparationSeconds == 0
                  ? 0
                  : _game.preparationLeft / widget.level.preparationSeconds,
              backgroundColor: CalendarStyle.line,
              color: CalendarStyle.gold,
              minHeight: 4,
            ),
          ),
        SizedBox(
          height: 56,
          child: CustomPaint(
            painter: _ChimneyEndsPainter(
              top: true,
              size: widget.level.size,
              waiting: preparing,
            ),
          ),
        ),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final unit = constraints.maxWidth / widget.level.size;
              final santa = _santaPosition();
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    GridView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: widget.level.size,
                      ),
                      itemCount: _game.puzzle.tiles.length,
                      itemBuilder: (context, index) {
                        final tile = _game.puzzle.tiles[index];
                        final occupied =
                            _game.phase == ChimneyPhase.moving &&
                            index == _game.cell;
                        final enabled =
                            !occupied &&
                            _game.phase != ChimneyPhase.won &&
                            _game.phase != ChimneyPhase.lost;
                        return Semantics(
                          label:
                              'Rohr, Reihe ${index ~/ widget.level.size + 1}, Spalte ${index % widget.level.size + 1}${occupied ? ', Weihnachtsmann im Rohr' : ''}',
                          button: true,
                          enabled: enabled,
                          child: GestureDetector(
                            key: ValueKey('chimney-tile-$index'),
                            onTap: enabled
                                ? () => setState(() => _game.rotate(index))
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              decoration: BoxDecoration(
                                color: _game.failedCell == index
                                    ? const Color(0xFFF0C4B6)
                                    : occupied
                                    ? const Color(0xFFE4EAD9)
                                    : const Color(0xFFF1E4D2),
                                border: Border.all(
                                  color: CalendarStyle.ivory,
                                  width: 1.5,
                                ),
                              ),
                              child: AnimatedRotation(
                                turns: tile.turns / 4,
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 160),
                                child: CustomPaint(
                                  painter: _PipePainter(tile.shape),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (!preparing)
                      Positioned(
                        left: santa.dx * unit - unit * .23,
                        top: santa.dy * unit - unit * .23,
                        width: unit * .46,
                        height: unit * .46,
                        child: IgnorePointer(
                          child: Semantics(
                            label: 'Weihnachtsmann',
                            child: CustomPaint(painter: _SantaPainter()),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 72,
          child: CustomPaint(
            painter: _ChimneyEndsPainter(top: false, size: widget.level.size),
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_outlined,
              color: CalendarStyle.muted,
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              'Tippen zum Drehen',
              style: TextStyle(color: CalendarStyle.muted),
            ),
          ],
        ),
        if (_game.phase == ChimneyPhase.won)
          CompletionPanel(
            onComplete: widget.onComplete,
            onReplay: _restart,
            message: 'Weihnachtsmann gerettet!',
          )
        else if (_game.phase == ChimneyPhase.lost)
          DefeatPanel(message: 'Der Weg ist versperrt.', onRetry: _restart),
      ],
    );
  }
}

class _PipePainter extends CustomPainter {
  _PipePainter(this.shape);
  final PipeShape shape;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w / 2, h / 2);
    if (shape == PipeShape.straight) {
      path.lineTo(w / 2, h);
    } else {
      path.lineTo(w, h / 2);
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      path,
      paint
        ..color = const Color(0xFFA9664F)
        ..strokeWidth = w * .43,
    );
    canvas.drawPath(
      path,
      paint
        ..color = const Color(0xFFF8D5A1)
        ..strokeWidth = w * .32,
    );
    canvas.drawPath(
      path,
      paint
        ..color = const Color(0xFF694F45)
        ..strokeWidth = w * .22,
    );
    // Copper cuffs distinguish the open ends from the chimney masonry.
    final cuff = Paint()..color = const Color(0xFFC88F69);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .27, 3, w * .46, h * .08),
        const Radius.circular(2),
      ),
      cuff,
    );
    if (shape == PipeShape.straight) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .27, h * .89, w * .46, h * .08),
          const Radius.circular(2),
        ),
        cuff,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .89, h * .27, w * .08, h * .46),
          const Radius.circular(2),
        ),
        cuff,
      );
    }
  }

  @override
  bool shouldRepaint(_PipePainter oldDelegate) => shape != oldDelegate.shape;
}

class _SantaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 40, size.height / 40);
    canvas.drawCircle(
      const Offset(20, 24),
      15,
      Paint()..color = const Color(0xFFBD5349),
    );
    canvas.drawOval(
      const Rect.fromLTWH(8, 15, 24, 24),
      Paint()..color = CalendarStyle.ivory,
    );
    canvas.drawOval(
      const Rect.fromLTWH(12, 15, 16, 15),
      Paint()..color = const Color(0xFFF0C09B),
    );
    canvas.drawPath(
      Path()
        ..moveTo(8, 18)
        ..quadraticBezierTo(13, -3, 29, 5)
        ..lineTo(33, 12)
        ..quadraticBezierTo(23, 6, 28, 18)
        ..close(),
      Paint()..color = const Color(0xFFBD5349),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 15, 23, 5),
        const Radius.circular(3),
      ),
      Paint()..color = CalendarStyle.ivory,
    );
    canvas.drawCircle(
      const Offset(33, 12),
      4,
      Paint()..color = CalendarStyle.ivory,
    );
    final eyes = Paint()..color = CalendarStyle.green;
    canvas.drawCircle(const Offset(16, 23), 1.2, eyes);
    canvas.drawCircle(const Offset(24, 23), 1.2, eyes);
    canvas.drawCircle(
      const Offset(20, 27),
      2.5,
      Paint()..color = const Color(0xFFE5A085),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SantaPainter oldDelegate) => false;
}

class _ChimneyEndsPainter extends CustomPainter {
  _ChimneyEndsPainter({
    required this.top,
    required this.size,
    this.waiting = false,
  });
  final bool top, waiting;
  final int size;
  @override
  void paint(Canvas canvas, Size bounds) {
    final unit = bounds.width / size;
    final x = top ? unit / 2 : bounds.width - unit / 2;
    final paint = Paint();
    if (top) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - unit * .3, 23, unit * .6, 33),
          const Radius.circular(4),
        ),
        paint..color = const Color(0xFFA9664F),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - unit * .39, 21, unit * .78, 9),
          const Radius.circular(5),
        ),
        paint..color = const Color(0xFFE1EAE5),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - unit * .22, 32, unit * .44, 24),
          const Radius.circular(3),
        ),
        paint..color = const Color(0xFF694F45),
      );
      if (waiting) {
        canvas.save();
        canvas.translate(x - 20, 0);
        _SantaPainter().paint(canvas, const Size(40, 40));
        canvas.restore();
      }
      for (final offset in [
        Offset(bounds.width * .43, 20),
        Offset(bounds.width * .76, 32),
        Offset(bounds.width * .9, 12),
      ]) {
        canvas.drawCircle(offset, 2.5, paint..color = CalendarStyle.line);
      }
    } else {
      final width = unit * .9;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - width / 2, 0, width, 51),
          const Radius.circular(5),
        ),
        paint..color = CalendarStyle.green,
      );
      canvas.drawRect(
        Rect.fromLTWH(x - width * .32, 10, width * .64, 37),
        paint..color = const Color(0xFF354239),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - width * .6, 45, width * 1.2, 8),
          const Radius.circular(3),
        ),
        paint..color = const Color(0xFFAB762C),
      );
      canvas.drawPath(
        Path()
          ..moveTo(x - 13, 42)
          ..quadraticBezierTo(x - 18, 30, x - 7, 26)
          ..quadraticBezierTo(x - 8, 34, x - 2, 34)
          ..quadraticBezierTo(x + 8, 16, x + 7, 14)
          ..quadraticBezierTo(x + 23, 38, x + 11, 42)
          ..close(),
        paint..color = const Color(0xFFE7A34D),
      );
      canvas.drawOval(
        Rect.fromLTWH(x - 6, 31, 12, 14),
        paint..color = const Color(0xFFFFD993),
      );
      canvas.drawLine(
        Offset(12, 57),
        Offset(bounds.width - 12, 57),
        paint
          ..color = CalendarStyle.line
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_ChimneyEndsPainter oldDelegate) =>
      top != oldDelegate.top ||
      waiting != oldDelegate.waiting ||
      size != oldDelegate.size;
}
