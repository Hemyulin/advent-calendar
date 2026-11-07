import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../presentation/calendar_style.dart';
import '../completion.dart';
import '../games/game_widgets.dart';
import 'shoe_game.dart';

class ShoeScreen extends StatefulWidget {
  const ShoeScreen({
    super.key,
    required this.onComplete,
    this.level = const ShoeLevel(),
    this.alreadyCompleted = false,
  });
  final ShoeLevel level;
  final ChallengeCompletion onComplete;
  final bool alreadyCompleted;
  @override
  State<ShoeScreen> createState() => _ShoeScreenState();
}

class _ShoeScreenState extends State<ShoeScreen> {
  late ShoeGame _game;
  ShoePoint? _last;
  ShoePhase? _touchedPhase;
  final _brushAction = CustomSemanticsAction(
    label: 'Die nächste Stelle bürsten',
  );
  @override
  void initState() {
    super.initState();
    _game = ShoeGame(widget.level);
  }

  void _restart() => setState(() {
    _game = ShoeGame(widget.level);
    _last = null;
    _touchedPhase = null;
  });

  @override
  Widget build(BuildContext context) {
    final progress = (_game.progress * 100).floor().clamp(0, 100);
    return GameScaffold(
      title: 'Nikolausstiefel',
      alreadyCompleted: widget.alreadyCompleted,
      onRestart: _restart,
      instructions:
          'Oh je, der Schuh ist ja voller Schlamm! Bürste ihn sauber und poliere ihn danach für den Nikolaus.',
      children: [
        GameStats(
          text: switch (_game.phase) {
            ShoePhase.cleaning => 'Bürsten · $progress %',
            ShoePhase.polishing => 'Polieren · $progress %',
            ShoePhase.finished => 'Blitzblank!',
          },
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: LinearProgressIndicator(
            value: _game.progress,
            minHeight: 7,
            backgroundColor: CalendarStyle.line,
            color: CalendarStyle.green,
            semanticsLabel: _game.phase == ShoePhase.cleaning
                ? 'Schuh säubern'
                : 'Schuh polieren',
            semanticsValue: '$progress Prozent',
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = width * 0.86;
            ShoePoint normalized(Offset local) =>
                ShoePoint(local.dx / width, local.dy / height);
            return Semantics(
              label: _game.won
                  ? 'Ein sauberer Stiefel mit einer Nikolausüberraschung'
                  : 'Ein ${_game.phase == ShoePhase.cleaning ? 'sehr schmutziger' : 'sauberer'} Stiefel. Zum Putzen über den Schuh wischen.',
              customSemanticsActions: _game.won
                  ? null
                  : {_brushAction: () => setState(_game.brushNextPatch)},
              child: ExcludeSemantics(
                child: GestureDetector(
                  key: const ValueKey('shoe-canvas'),
                  behavior: HitTestBehavior.opaque,
                  onPanDown: _game.won
                      ? null
                      : (details) => setState(() {
                          _last = normalized(details.localPosition);
                        }),
                  onPanStart: _game.won
                      ? null
                      : (details) {
                          final point = normalized(details.localPosition);
                          setState(() {
                            final phase = _game.phase;
                            if (_last != null && _game.stroke(_last!, point)) {
                              _touchedPhase = phase;
                            }
                            _last = point;
                          });
                        },
                  onPanUpdate: _game.won
                      ? null
                      : (details) {
                          final point = normalized(details.localPosition);
                          setState(() {
                            final phase = _game.phase;
                            if (_last != null && _game.stroke(_last!, point)) {
                              _touchedPhase = phase;
                            }
                            _last = point;
                          });
                        },
                  onPanEnd: (_) => setState(() => _last = null),
                  onPanCancel: () => setState(() => _last = null),
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(painter: _ShoePainter(_game, _last)),
                        if (!_game.won && _touchedPhase != _game.phase)
                          IgnorePointer(
                            child: Center(
                              child: TweenAnimationBuilder<double>(
                                key: ValueKey(_game.phase),
                                tween: Tween(begin: -0.3, end: 0.3),
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 1600),
                                curve: Curves.easeInOut,
                                builder: (_, value, child) =>
                                    FractionalTranslation(
                                      translation: Offset(value, 0),
                                      child: child,
                                    ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: CalendarStyle.ivory.withValues(
                                      alpha: 0.94,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.swipe_rounded,
                                    size: 38,
                                    color: CalendarStyle.green,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        if (_game.won)
          CompletionPanel(
            onComplete: widget.onComplete,
            onReplay: _restart,
            message: 'Der Nikolaus kann kommen!',
          ),
      ],
    );
  }
}

class _ShoePainter extends CustomPainter {
  const _ShoePainter(this.game, this.cursor);
  final ShoeGame game;
  final ShoePoint? cursor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width, size.height);
    final paint = Paint();
    final body = Path()..moveTo(shoeOutline.first.x, shoeOutline.first.y);
    for (final point in shoeOutline.skip(1)) {
      body.lineTo(point.x, point.y);
    }
    body.close();
    canvas.drawOval(
      const Rect.fromLTWH(0.12, 0.87, 0.80, 0.08),
      paint..color = CalendarStyle.gold.withValues(alpha: 0.1),
    );
    // Treats peek out of the cuff only after both cleaning stages are finished.
    if (game.won) {
      canvas.save();
      canvas.translate(0.46, 0.19);
      canvas.rotate(0.25);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0.02)
          ..lineTo(0, -0.09)
          ..cubicTo(0, -0.18, 0.13, -0.18, 0.13, -0.09),
        paint
          ..color = const Color(0xFFFFEAC6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.026
          ..strokeCap = StrokeCap.round,
      );
      for (var y = -0.07; y < 0.02; y += 0.04) {
        canvas.drawLine(
          Offset(-0.008, y),
          Offset(0.008, y - 0.012),
          paint
            ..color = const Color(0xFFC6584C)
            ..strokeWidth = 0.013,
        );
      }
      canvas.restore();
      paint.style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0.29, 0.035, 0.12, 0.13),
          const Radius.circular(0.012),
        ),
        paint..color = CalendarStyle.green,
      );
      canvas.drawRect(
        const Rect.fromLTWH(0.338, 0.035, 0.022, 0.13),
        paint..color = const Color(0xFFEAC46C),
      );
      canvas.drawCircle(
        const Offset(0.435, 0.10),
        0.045,
        paint..color = const Color(0xFFF0B15C),
      );
    }
    canvas.drawPath(body, paint..color = const Color(0xFFB9564D));
    canvas.save();
    canvas.clipPath(body);
    canvas.drawPath(
      Path()
        ..moveTo(0.15, 0.8)
        ..quadraticBezierTo(0.52, 0.87, 0.94, 0.76)
        ..lineTo(0.94, 0.9)
        ..lineTo(0.15, 0.9)
        ..close(),
      paint..color = CalendarStyle.green,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0.17, 0.79)
        ..quadraticBezierTo(0.52, 0.86, 0.94, 0.75),
      paint
        ..color = const Color(0xFFEFCEA0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.015,
    );
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.26, 0.13, 0.31, 0.065),
        const Radius.circular(0.012),
      ),
      paint..color = const Color(0xFFFFE8C5),
    );
    for (var i = 0; i < 4; i++) {
      final y = 0.28 + i * 0.065;
      canvas.drawCircle(
        Offset(0.32, y),
        0.012,
        paint..color = const Color(0xFFEBC27D),
      );
      canvas.drawCircle(
        Offset(0.51, y),
        0.012,
        paint..color = const Color(0xFFEBC27D),
      );
      canvas.drawLine(
        Offset(0.32, y),
        Offset(0.51, y + 0.018),
        paint
          ..color = const Color(0xFFFFECC9)
          ..strokeWidth = 0.009
          ..strokeCap = StrokeCap.round,
      );
    }
    var index = 0;
    for (final patch in game.patches) {
      final alpha = (patch.dirt / patch.initialDirt).clamp(0.0, 1.0);
      final center = Offset(patch.center.x, patch.center.y);
      final r = 0.72 / math.min(game.level.columns, game.level.rows);
      if (alpha > 0) {
        canvas.save();
        canvas.translate(
          center.dx + math.sin(index * 5.3) * r * 0.18,
          center.dy,
        );
        canvas.rotate(math.sin(index * 7.7) * 2.8);
        paint.color = Color.lerp(
          const Color(0xFF6A4D34),
          const Color(0xFF453C2A),
          (index % 4) / 3,
        )!.withValues(alpha: alpha * 0.96);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: r * (2.1 + math.sin(index) * 0.3),
            height: r * 1.7,
          ),
          paint,
        );
        canvas.drawCircle(Offset(r * 0.6, -r * 0.4), r * 0.65, paint);
        canvas.drawCircle(Offset(-r * 0.6, r * 0.4), r * 0.68, paint);
        canvas.drawLine(
          Offset(-r * 0.4, 0),
          Offset(r * 0.5, r * 0.2),
          paint
            ..color = const Color(0xFFC49861).withValues(alpha: alpha * 0.45)
            ..strokeWidth = r * 0.14,
        );
        canvas.restore();
      }
      if (patch.polish > 0 && !game.won) {
        canvas.drawOval(
          Rect.fromCenter(
            center: center - Offset(r * 0.3, 0),
            width: r * 0.35,
            height: r * 1.2,
          ),
          paint
            ..color = const Color(
              0xFFFFF4D8,
            ).withValues(alpha: patch.polish * 0.13),
        );
      }
      index++;
    }
    if (game.won) {
      canvas.drawPath(
        Path()
          ..moveTo(0.29, 0.23)
          ..quadraticBezierTo(0.30, 0.42, 0.27, 0.63)
          ..quadraticBezierTo(0.24, 0.75, 0.40, 0.75),
        paint
          ..color = const Color(0xFFFFF4D8).withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.025,
      );
      paint.style = PaintingStyle.fill;
    }
    canvas.restore();
    if (game.won) {
      for (final point in [
        const Offset(0.66, 0.59),
        const Offset(0.22, 0.30),
        const Offset(0.90, 0.52),
      ]) {
        final glint = Path()
          ..moveTo(point.dx, point.dy - 0.035)
          ..quadraticBezierTo(
            point.dx + 0.006,
            point.dy - 0.006,
            point.dx + 0.027,
            point.dy,
          )
          ..quadraticBezierTo(
            point.dx + 0.006,
            point.dy + 0.006,
            point.dx,
            point.dy + 0.035,
          )
          ..quadraticBezierTo(
            point.dx - 0.006,
            point.dy + 0.006,
            point.dx - 0.027,
            point.dy,
          )
          ..quadraticBezierTo(
            point.dx - 0.006,
            point.dy - 0.006,
            point.dx,
            point.dy - 0.035,
          );
        canvas.drawPath(glint, paint..color = CalendarStyle.gold);
      }
    }
    if (cursor != null && !game.won) {
      final point = Offset(cursor!.x, cursor!.y);
      canvas.drawCircle(
        point,
        game.level.brushRadius,
        paint..color = const Color(0xFFFFF0D3).withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        point,
        game.level.brushRadius,
        paint
          ..color = CalendarStyle.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.004,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShoePainter oldDelegate) => true;
}
