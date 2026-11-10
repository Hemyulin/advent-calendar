import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../presentation/calendar_style.dart';
import '../completion.dart';
import '../games/game_widgets.dart';
import 'cookie_game.dart';

class CookieScreen extends StatefulWidget {
  const CookieScreen({
    super.key,
    required this.onComplete,
    this.level = const CookieLevel(),
    this.alreadyCompleted = false,
  });
  final CookieLevel level;
  final ChallengeCompletion onComplete;
  final bool alreadyCompleted;
  @override
  State<CookieScreen> createState() => _CookieScreenState();
}

class _CookieScreenState extends State<CookieScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late CookieGame _game;
  late final Ticker _ticker;
  late final AnimationController _feedback;
  late final AnimationController _lift;
  final _focus = FocusNode();
  Duration? _last;
  bool _paused = false;
  bool _foreground = true;
  bool _showResult = false;
  CutDirection? _pressed;
  double _cutFrom = 0;
  Offset _swipeDelta = Offset.zero;
  bool _swipeUsed = false;

  @override
  void initState() {
    super.initState();
    _game = CookieGame(widget.level);
    WidgetsBinding.instance.addObserver(this);
    _feedback = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _lift =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1100),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _showResult = true);
          }
        });
    _ticker = createTicker((elapsed) {
      final previous = _last;
      _last = elapsed;
      if (previous == null ||
          !_foreground ||
          _paused ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      final mistakes = _game.mistakes;
      setState(
        () => _game.advance(
          math.min((elapsed - previous).inMicroseconds / 1e6, .1),
        ),
      );
      if (_game.mistakes != mistakes) {
        _pressed = null;
        _feedback.forward(from: 0);
      }
      _finishIfNeeded();
    });
  }

  void _finishIfNeeded() {
    if (_game.phase == CookiePhase.won) {
      _ticker.stop();
      if (!_lift.isAnimating && !_showResult) {
        if (MediaQuery.disableAnimationsOf(context)) {
          _lift.value = 1;
        } else {
          _lift.forward();
        }
      }
    } else if (_game.phase == CookiePhase.lost) {
      _ticker.stop();
    }
  }

  void _pause() {
    if (_game.phase == CookiePhase.cutting ||
        _game.phase == CookiePhase.recovering) {
      _paused = true;
      _ticker.stop();
      _last = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == false) _pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground && mounted) setState(_pause);
  }

  void _start() {
    if (!_foreground) return;
    setState(() {
      _game.start();
      _paused = false;
      _last = null;
    });
    _focus.requestFocus();
    if (!_ticker.isActive) _ticker.start();
  }

  void _press(CutDirection direction) {
    if (_paused || !_foreground || ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final cutFrom = _game.cutUntil;
    final result = _game.press(direction);
    if (result == CutInput.ignored) return;
    _cutFrom = cutFrom;
    setState(() => _pressed = direction);
    _feedback.forward(from: 0);
    _finishIfNeeded();
  }

  void _swipe(DragUpdateDetails details) {
    if (_swipeUsed) return;
    _swipeDelta += details.delta;
    if (_swipeDelta.distance < 20) return;
    _swipeUsed = true;
    _press(
      _swipeDelta.dx.abs() > _swipeDelta.dy.abs()
          ? (_swipeDelta.dx > 0 ? CutDirection.right : CutDirection.left)
          : (_swipeDelta.dy > 0 ? CutDirection.down : CutDirection.up),
    );
  }

  void _restart() {
    _ticker.stop();
    _feedback.reset();
    _lift.reset();
    setState(() {
      _game = CookieGame(widget.level);
      _last = null;
      _paused = false;
      _showResult = false;
      _pressed = null;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _feedback.dispose();
    _lift.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keys = {
      LogicalKeyboardKey.arrowUp: CutDirection.up,
      LogicalKeyboardKey.arrowDown: CutDirection.down,
      LogicalKeyboardKey.arrowLeft: CutDirection.left,
      LogicalKeyboardKey.arrowRight: CutDirection.right,
    };
    final enabled = _game.phase == CookiePhase.cutting && !_paused;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (_, event) {
        final direction = keys[event.logicalKey];
        if (direction == null) return KeyEventResult.ignored;
        if (event is KeyDownEvent) _press(direction);
        return KeyEventResult.handled;
      },
      child: GameScaffold(
        title: 'Plätzchen ausstechen',
        alreadyCompleted: widget.alreadyCompleted,
        onRestart: _restart,
        instructions:
            'Der Ausstecher folgt der Form. Sobald der Pfeil grün aufleuchtet, wische die passende Richtung über den Teig oder nutze die Pfeile. Ein falscher oder verpasster Pfeil kostet einen Fehler. Die Stelle wird noch einmal angefahren. Bei ${widget.level.mistakeLimit} Fehlern beginnt ein neuer Versuch.',
        children: [
          GameStats(
            text:
                '${_game.next} / ${widget.level.checkpoints} · ${_game.mistakes} / ${widget.level.mistakeLimit} Fehler',
          ),
          Text(
            widget.level.shape.label,
            textAlign: TextAlign.center,
            style: CalendarStyle.heading.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 18),
          Semantics(
            label: _paused
                ? 'Spiel pausiert'
                : _game.phase == CookiePhase.recovering
                ? 'Noch einmal an dieser Stelle'
                : _game.showCue
                ? '${_game.target!.direction.label}${_game.inWindow ? ', jetzt drücken' : ', gleich drücken'}'
                : 'Der Ausstecher folgt der Form',
            liveRegion: true,
            child: GestureDetector(
              key: const ValueKey('cookie-swipe-area'),
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onPanStart: (_) {
                _swipeDelta = Offset.zero;
                _swipeUsed = !enabled;
              },
              onPanUpdate: _swipe,
              onPanEnd: (_) => _swipeDelta = Offset.zero,
              onPanCancel: () {
                _swipeDelta = Offset.zero;
                _swipeUsed = true;
              },
              child: AspectRatio(
                aspectRatio: 1,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_feedback, _lift]),
                  builder: (_, _) => CustomPaint(
                    key: const ValueKey('cookie-board'),
                    painter: _CookiePainter(
                      game: _game,
                      visibleCut:
                          _feedback.isAnimating &&
                              _game.lastInput == CutInput.correct
                          ? _cutFrom +
                                (_game.cutUntil - _cutFrom) *
                                    Curves.easeOut.transform(_feedback.value)
                          : _game.cutUntil,
                      feedback: _feedback.isAnimating ? 1 - _feedback.value : 0,
                      lift: Curves.easeOutCubic.transform(_lift.value),
                      reducedMotion: MediaQuery.disableAnimationsOf(context),
                      paused: _paused,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              for (final direction in CutDirection.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _arrow(direction, enabled),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_game.phase == CookiePhase.ready || _paused)
            FilledButton.icon(
              key: const ValueKey('cookie-start'),
              onPressed: _start,
              icon: Icon(
                _paused ? Icons.play_arrow_rounded : Icons.cookie_outlined,
              ),
              label: Text(_paused ? 'Weiter' : 'Los geht’s'),
            )
          else
            SizedBox(
              height: 48,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Text(
                    _game.phase == CookiePhase.recovering
                        ? 'Noch einmal an dieser Stelle'
                        : _game.inWindow
                        ? 'Jetzt!'
                        : _game.phase == CookiePhase.won
                        ? 'Frisch ausgestochen!'
                        : '',
                    key: ValueKey((_game.phase, _game.inWindow)),
                    style: TextStyle(
                      color: _game.inWindow
                          ? CalendarStyle.green
                          : CalendarStyle.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (_showResult)
            CompletionPanel(
              onComplete: widget.onComplete,
              onReplay: _restart,
              message: 'Dein Plätzchen ist fertig!',
            )
          else if (_game.phase == CookiePhase.lost)
            DefeatPanel(message: 'Neuer Teig, neues Glück.', onRetry: _restart),
        ],
      ),
    );
  }

  Widget _arrow(CutDirection direction, bool enabled) {
    final icon = switch (direction) {
      CutDirection.up => Icons.arrow_upward_rounded,
      CutDirection.down => Icons.arrow_downward_rounded,
      CutDirection.left => Icons.arrow_back_rounded,
      CutDirection.right => Icons.arrow_forward_rounded,
    };
    return Semantics(
      label: direction.label,
      button: true,
      enabled: enabled,
      onTap: enabled ? () => _press(direction) : null,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _feedback,
          builder: (_, _) {
            final pressed = _feedback.isAnimating && _pressed == direction;
            return Material(
              color: !enabled
                  ? CalendarStyle.line.withValues(alpha: .45)
                  : pressed
                  ? (_game.lastInput == CutInput.correct
                        ? CalendarStyle.green
                        : const Color(0xFFBE8C79))
                  : const Color(0xFFE2E9DF),
              borderRadius: BorderRadius.circular(17),
              child: Listener(
                onPointerDown: enabled ? (_) => _press(direction) : null,
                child: InkWell(
                  key: ValueKey('cookie-${direction.name}'),
                  onTap: enabled ? () {} : null,
                  borderRadius: BorderRadius.circular(17),
                  child: SizedBox(
                    height: 62,
                    child: Icon(
                      icon,
                      size: 30,
                      color: pressed
                          ? CalendarStyle.ivory
                          : CalendarStyle.green.withValues(
                              alpha: enabled ? 1 : .4,
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CookiePainter extends CustomPainter {
  _CookiePainter({
    required this.game,
    required this.feedback,
    required this.visibleCut,
    required this.lift,
    required this.reducedMotion,
    required this.paused,
  });
  final CookieGame game;
  final double feedback, lift, visibleCut;
  final bool reducedMotion, paused;

  Path _outline(Size size) {
    final path = Path();
    for (var i = 0; i < game.outline.points.length; i++) {
      final p = game.outline.points[i];
      if (i == 0) {
        path.moveTo(p.x * size.width, p.y * size.height);
      } else {
        path.lineTo(p.x * size.width, p.y * size.height);
      }
    }
    return path..close();
  }

  Offset point(CookiePoint p, Size size) =>
      Offset(p.x * size.width, p.y * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final board = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(28),
    );
    canvas.drawRRect(board, paint..color = const Color(0xFFF0DFBF));
    canvas.save();
    canvas.clipRRect(board);
    final random = math.Random(2412);
    for (var i = 0; i < 75; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        .6 + random.nextDouble() * 1.4,
        paint
          ..color = i.isEven
              ? const Color(0xFFF9EDD8)
              : const Color(0xFFE2CAA2),
      );
    }
    canvas
        .restore(); // Only the flour is clipped; the lifted cookie can rise above the dough.
    canvas.save();
    final path = _outline(size);
    final metric = path.computeMetrics().first;
    if (lift > 0) {
      canvas.drawPath(
        path,
        paint..color = const Color(0xFFAE885D).withValues(alpha: lift * .55),
      );
      canvas.save();
      canvas.translate(0, (reducedMotion ? -8 : -23) * lift);
      canvas.translate(size.width / 2, size.height / 2);
      final scale = 1 + (reducedMotion ? 0 : .045) * lift;
      canvas.scale(scale);
      canvas.rotate(reducedMotion ? 0 : -.035 * lift);
      canvas.translate(-size.width / 2, -size.height / 2);
      canvas.drawShadow(path, const Color(0xFF6F4F29), 9 * lift, false);
      canvas.drawPath(
        path,
        paint
          ..color = Color.lerp(
            const Color(0xFFF0DFBF),
            const Color(0xFFD9AB6E),
            lift,
          )!,
      );
      canvas.drawPath(
        path,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFBD8A4D),
      );
      paint.style = PaintingStyle.fill;
      canvas.save();
      canvas.clipPath(path);
      for (var i = 0; i < 32; i++) {
        canvas.drawCircle(
          Offset(
            random.nextDouble() * size.width,
            random.nextDouble() * size.height,
          ),
          1.5,
          paint..color = CalendarStyle.ivory.withValues(alpha: .8 * lift),
        );
      }
      canvas.restore();
      canvas.restore();
    } else {
      // A dashed flour guide remains visually distinct from the completed cut.
      for (var distance = 0.0; distance < metric.length; distance += 10) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(metric.length, distance + 4)),
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFB89B74),
        );
      }
      paint.style = PaintingStyle.fill;
      if (game.cutUntil > 0) {
        final cut = metric.extractPath(0, metric.length * visibleCut);
        canvas.drawPath(
          cut,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xFFC09460),
        );
        canvas.drawPath(
          cut.shift(const Offset(0, 1)),
          paint
            ..strokeWidth = 1.5
            ..color = const Color(0xFFF9EBD2),
        );
        paint.style = PaintingStyle.fill;
      }
      // Pastry wheel: a steel cutting disc and a warm wooden handle.
      final position = point(game.outline.at(game.progress), size);
      final tangent = game.outline.tangentAt(game.progress);
      final wrong =
          game.lastInput != null && game.lastInput != CutInput.correct;
      final shake = wrong && !reducedMotion
          ? math.sin(feedback * math.pi * 5) * feedback * 3
          : 0.0;
      canvas.save();
      canvas.translate(position.dx + shake, position.dy);
      canvas.rotate(math.atan2(tangent.y, tangent.x));
      canvas.drawLine(
        const Offset(1, -9),
        const Offset(1, -28),
        paint
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFD6BE94),
      );
      canvas.drawLine(
        const Offset(0, -9),
        const Offset(0, -28),
        paint
          ..strokeWidth = 6
          ..color = const Color(0xFF9E7147),
      );
      canvas.drawCircle(
        const Offset(1, 2),
        10,
        paint..color = const Color(0xFFC2A77F),
      );
      canvas.drawCircle(
        Offset.zero,
        10,
        paint..color = const Color(0xFF7E8F88),
      );
      canvas.drawCircle(Offset.zero, 7, paint..color = const Color(0xFFF2F1E5));
      canvas.drawCircle(Offset.zero, 2.5, paint..color = CalendarStyle.gold);
      canvas.restore();
      _paintCheckpointArrows(canvas, size);
    }
    canvas.restore();
  }

  void _paintCheckpointArrows(Canvas canvas, Size size) {
    for (var i = 0; i < game.checkpoints.length; i++) {
      final checkpoint = game.checkpoints[i];
      final center = point(game.outline.at(checkpoint.fraction), size);
      final current = i == game.next && !paused;
      final active = current && game.inWindow;
      final failed =
          current &&
          (game.phase == CookiePhase.recovering ||
              game.phase == CookiePhase.lost);
      final approaching =
          current && game.phase == CookiePhase.cutting && game.showCue;
      final color = i < game.next
          ? CalendarStyle.green.withValues(alpha: .45)
          : failed
          ? const Color(0xFFB87863)
          : active
          ? CalendarStyle.green
          : approaching
          ? CalendarStyle.gold
          : const Color(0xFF977B55);
      if (active || failed) {
        canvas.drawCircle(
          center,
          14,
          Paint()..color = color.withValues(alpha: .12),
        );
      }
      final delta = switch (checkpoint.direction) {
        CutDirection.up => const Offset(0, -1),
        CutDirection.down => const Offset(0, 1),
        CutDirection.left => const Offset(-1, 0),
        CutDirection.right => const Offset(1, 0),
      };
      final perpendicular = Offset(-delta.dy, delta.dx);
      final arrow = Path()
        ..moveTo((center - delta * 7).dx, (center - delta * 7).dy)
        ..lineTo((center + delta * 7).dx, (center + delta * 7).dy)
        ..moveTo(
          (center + delta * 2 - perpendicular * 5).dx,
          (center + delta * 2 - perpendicular * 5).dy,
        )
        ..lineTo((center + delta * 7).dx, (center + delta * 7).dy)
        ..lineTo(
          (center + delta * 2 + perpendicular * 5).dx,
          (center + delta * 2 + perpendicular * 5).dy,
        );
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      // A narrow dough-coloured halo keeps the glyph legible over the guide
      // and cutting wheel without adding a floating badge or moving cue.
      canvas.drawPath(
        arrow,
        stroke
          ..color = const Color(0xFFF0DFBF)
          ..strokeWidth = 5,
      );
      canvas.drawPath(
        arrow,
        stroke
          ..color = color
          ..strokeWidth = active ? 2.6 : 2,
      );
    }
  }

  @override
  bool shouldRepaint(_CookiePainter oldDelegate) => true;
}
