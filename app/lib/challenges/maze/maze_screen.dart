import 'package:flutter/gestures.dart';
import '../seasonal/game_skin_scope.dart';
import '../seasonal/hanukkah_art.dart';
import '../../achievements/run_facts.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../presentation/calendar_style.dart';
import '../completion.dart';
import '../games/difficulty.dart';
import '../games/game_widgets.dart';
import 'maze_game.dart';
import 'tilt_source.dart';

class MazeScreen extends StatefulWidget {
  const MazeScreen({
    super.key,
    required this.onComplete,
    this.course,
    this.tiltSource,
    this.alreadyCompleted = false,
  });
  final MazeCourse? course;
  final TiltSource? tiltSource;
  final ChallengeCompletion onComplete;
  final bool alreadyCompleted;
  @override
  State<MazeScreen> createState() => _MazeScreenState();
}

class _MazeScreenState extends State<MazeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late MazeGame _game;
  late final Ticker _ticker;
  final _focus = FocusNode();
  final _keys = <LogicalKeyboardKey>{};
  StreamSubscription<Vec2>? _subscription;
  Timer? _sensorTimeout;
  Duration? _previous;
  Vec2 _tilt = Vec2.zero;
  Vec2 _calibration = Vec2.zero;
  Vec2 _touch = Vec2.zero;
  Offset? _touchStart;
  bool _useSensors = true;
  bool _sensorReady = false;
  bool _active = true;
  String? _sensorMessage;

  @override
  void initState() {
    super.initState();
    _game = MazeGame(
      widget.course ?? MazeCourse.forDifficulty(GameDifficulty.normal),
    );
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
    _listen();
  }

  void _listen() {
    _subscription?.cancel();
    _sensorTimeout?.cancel();
    _sensorReady = false;
    _subscription = (widget.tiltSource ?? DeviceTiltSource()).events.listen(
      (event) {
        if (!mounted || !_active || !_useSensors) return;
        if (!_sensorReady) _calibration = event;
        _tilt = event;
        _wake();
        _sensorTimeout?.cancel();
        _sensorTimeout = Timer(const Duration(seconds: 3), _fallback);
        if (!_sensorReady) setState(() => _sensorReady = true);
      },
      onError: (_) => _fallback(),
      onDone: _fallback,
    );
    _sensorTimeout = Timer(const Duration(seconds: 3), () {
      if (!_sensorReady) _fallback();
    });
  }

  void _fallback() {
    if (!mounted || !_useSensors) return;
    _subscription?.cancel();
    _sensorTimeout?.cancel();
    setState(() {
      _useSensors = false;
      _sensorMessage =
          'Keine Sensordaten verfügbar. Ziehe auf dem Spielfeld oder nutze die Pfeiltasten.';
    });
  }

  void _wake() {
    if (mounted && _active && !_game.won && !_game.lost && !_ticker.isActive) {
      _previous = null;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final previous = _previous;
    _previous = elapsed;
    if (previous == null ||
        !_active ||
        ModalRoute.of(context)?.isCurrent != true ||
        _game.won ||
        _game.lost) {
      return;
    }
    var control = _touch;
    if (_keys.isNotEmpty) {
      control = Vec2(
        (_keys.contains(LogicalKeyboardKey.arrowRight) ? 1.0 : 0) -
            (_keys.contains(LogicalKeyboardKey.arrowLeft) ? 1 : 0),
        (_keys.contains(LogicalKeyboardKey.arrowDown) ? 1.0 : 0) -
            (_keys.contains(LogicalKeyboardKey.arrowUp) ? 1 : 0),
      );
    } else if (_useSensors) {
      control = (_tilt - _calibration) * 2.2;
    }
    if (control.length < 0.008 && _game.velocity.length < 0.003) {
      _game.stop();
      _ticker.stop();
      return;
    }
    setState(
      () =>
          _game.advance((elapsed - previous).inMicroseconds / 1000000, control),
    );
    if (_game.won || _game.lost) _ticker.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _previous = null;
    _touch = Vec2.zero;
    _keys.clear();
    _game.stop();
    if (!_active) {
      _ticker.stop();
    }
    if (!_active) {
      _subscription?.cancel();
      _sensorTimeout?.cancel();
    } else if (_useSensors) {
      _listen();
    }
  }

  void _restart() => setState(() {
    _game = MazeGame(
      widget.course ?? MazeCourse.forDifficulty(GameDifficulty.normal),
    );
    _touch = Vec2.zero;
    _keys.clear();
  });

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _sensorTimeout?.cancel();
    _ticker.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyboardListener(
    focusNode: _focus,
    autofocus: true,
    onKeyEvent: (event) {
      if (event is KeyUpEvent) {
        _keys.remove(event.logicalKey);
      } else if (event is KeyDownEvent) {
        _keys.add(event.logicalKey);
        _wake();
      }
    },
    child: GameScaffold(
      title: 'Kugellabyrinth',
      alreadyCompleted: widget.alreadyCompleted,
      onRestart: _restart,
      instructions:
          'Bringe die Kugel zur Zielflagge. Neige das Handy oder ziehe im Touch-Modus auf dem Spielfeld; am Computer gehen auch die Pfeiltasten. Meide die schwarzen Abgründe: Jeder Sturz kostet ein Leben. Erreiche die Flagge, um das Türchen zu lösen. ${GameSkinScope.isHanukkah(context) ? 'Schekel' : 'Süßigkeiten'} in den Seitenwegen sind ein freiwilliges Bonusziel; nach einem Sturz sammelst du sie erneut.',
      children: [
        GameStats(
          text:
              '${_game.livesLeft} Leben${_game.layout.candies.isEmpty ? '' : ' · ${_game.collectedCandy.length} / ${_game.layout.candies.length} ${GameSkinScope.isHanukkah(context) ? 'Schekel' : 'Süßigkeiten'}'}',
        ),
        Semantics(
          label: 'Erreiche die Zielflagge und meide die Abgründe.',
          child: GestureDetector(
            key: const ValueKey('maze-touch-area'),
            dragStartBehavior: DragStartBehavior.down,
            behavior: HitTestBehavior.opaque,
            onPanStart: !_useSensors
                ? (details) {
                    _touchStart = details.localPosition;
                    _focus.requestFocus();
                  }
                : null,
            onPanUpdate: !_useSensors
                ? (details) {
                    final delta =
                        details.localPosition -
                        (_touchStart ?? details.localPosition);
                    setState(
                      () => _touch = Vec2(
                        (delta.dx / 60).clamp(-1.0, 1.0),
                        (delta.dy / 60).clamp(-1.0, 1.0),
                      ),
                    );
                    _wake();
                  }
                : null,
            onPanEnd: !_useSensors
                ? (_) => setState(() => _touch = Vec2.zero)
                : null,
            onPanCancel: !_useSensors
                ? () => setState(() => _touch = Vec2.zero)
                : null,
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CustomPaint(
                  painter: _MazePainter(
                    _game.layout,
                    _game.position,
                    _game.collectedCandy,
                    hanukkah: GameSkinScope.isHanukkah(context),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!_game.won && !_game.lost) ...[
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Neigen')),
              ButtonSegment(value: false, label: Text('Touch')),
            ],
            selected: {_useSensors},
            onSelectionChanged: (value) {
              setState(() {
                _useSensors = value.first;
                _touch = Vec2.zero;
                _game.stop();
                _sensorMessage = null;
              });
              if (_useSensors) {
                _listen();
              } else {
                _subscription?.cancel();
                _sensorTimeout?.cancel();
              }
            },
          ),
          const SizedBox(height: 12),
          if (_useSensors)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_sensorReady)
                  Semantics(
                    label: 'Bewegungssensor wird verbunden',
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  const Tooltip(
                    message: 'Zum Steuern sanft neigen',
                    child: Icon(
                      Icons.screen_rotation_alt_rounded,
                      color: CalendarStyle.green,
                      size: 26,
                    ),
                  ),
                IconButton(
                  tooltip: 'Diese Haltung als Mitte setzen',
                  onPressed: _sensorReady
                      ? () => setState(() {
                          _calibration = _tilt;
                          _game.stop();
                        })
                      : null,
                  icon: const Icon(Icons.center_focus_strong_rounded),
                ),
              ],
            )
          else if (_sensorMessage != null)
            Tooltip(
              message: _sensorMessage!,
              child: const Icon(
                Icons.sensors_off_rounded,
                size: 18,
                color: CalendarStyle.muted,
              ),
            ),
        ],
        if (_game.won)
          CompletionPanel(
            facts: RunFacts(feats: {if (_game.allCandy) RunFeat.allCandy}),
            onComplete: widget.onComplete,
            onReplay: _restart,
            message: 'Die Kugel ist im Ziel!',
          )
        else if (_game.lost)
          DefeatPanel(message: 'Keine Leben mehr.', onRetry: _restart),
      ],
    ),
  );
}

class _MazePainter extends CustomPainter {
  const _MazePainter(
    this.layout,
    this.ball,
    this.collectedCandy, {
    this.hanukkah = false,
  });
  final bool hanukkah;
  final Set<int> collectedCandy;
  final MazeLayout layout;
  final Vec2 ball;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFF3E5CC), BlendMode.src);
    final paint = Paint();
    Offset point(Vec2 v) => Offset(v.x * size.width, v.y * size.height);
    for (final wall in layout.walls) {
      final rect = Rect.fromLTWH(
        wall.x * size.width,
        wall.y * size.height,
        wall.width * size.width,
        wall.height * size.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(const Offset(1, 2)),
          const Radius.circular(3),
        ),
        paint..color = const Color(0xFFD1B990),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        paint..color = CalendarStyle.green,
      );
    }
    final cell = size.width / layout.cells;
    for (var i = 0; i < layout.candies.length; i++) {
      if (collectedCandy.contains(i)) continue;
      final center = point(layout.candies[i]);
      if (hanukkah) {
        paintHanukkahMotif(
          canvas,
          Rect.fromCenter(
            center: center,
            width: cell * .48,
            height: cell * .48,
          ),
          3,
        );
        continue;
      }
      final radius = cell * .14;
      final wrapper = Paint()..color = const Color(0xFFCB695B);
      for (final sign in [-1.0, 1.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(center.dx + sign * radius * .7, center.dy)
            ..lineTo(center.dx + sign * radius * 1.9, center.dy - radius * .8)
            ..lineTo(center.dx + sign * radius * 1.9, center.dy + radius * .8)
            ..close(),
          wrapper,
        );
      }
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = const Color(0xFFFFF5DA),
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * .65),
        -.8,
        3.8,
        false,
        Paint()
          ..color = const Color(0xFFCB695B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * .45,
      );
    }
    // Hazards are broken, matte voids: no halo, token border or reward shape.
    for (final pit in layout.pits) {
      final center = point(pit);
      final radius = layout.pitRadius * size.width;
      final rim = Path();
      for (var i = 0; i < 14; i++) {
        final angle = i * math.pi * 2 / 14;
        final r = radius * (i.isEven ? 1.08 : 0.9);
        final p = center + Offset(math.cos(angle), math.sin(angle)) * r;
        if (i == 0) {
          rim.moveTo(p.dx, p.dy);
        } else {
          rim.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(rim..close(), paint..color = const Color(0xFF726B5F));
      canvas.drawCircle(
        center,
        radius * 0.84,
        paint..color = const Color(0xFF22241F),
      );
      for (final direction in [-1.0, 1.0]) {
        canvas.drawLine(
          center + Offset(-radius * 0.25, direction * radius * 0.25),
          center + Offset(radius * 0.25, -direction * radius * 0.25),
          paint
            ..color = const Color(0xFF946A58)
            ..strokeWidth = math.max(1.3, cell * 0.022)
            ..strokeCap = StrokeCap.round,
        );
      }
      // Small cracks make the edge read as damaged ground rather than a cup.
      final crack = Path()
        ..moveTo(center.dx - radius, center.dy)
        ..lineTo(center.dx - radius - cell * 0.08, center.dy - cell * 0.045)
        ..lineTo(center.dx - radius - cell * 0.11, center.dy + cell * 0.015);
      canvas.drawPath(
        crack,
        paint
          ..color = const Color(0xFF807665)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      paint.style = PaintingStyle.fill;
    }

    // A rectangular finish pad and a chequered flag cannot be mistaken for pits.
    final finish = point(layout.goal);
    final pad = RRect.fromRectAndRadius(
      Rect.fromCenter(center: finish, width: cell * 0.78, height: cell * 0.78),
      Radius.circular(cell * 0.08),
    );
    canvas.drawRRect(pad, paint..color = const Color(0xFFD2E5C4));
    canvas.drawRRect(
      pad,
      paint
        ..color = CalendarStyle.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, cell * 0.025),
    );
    paint.style = PaintingStyle.fill;
    final pole = Offset(finish.dx - cell * 0.17, finish.dy + cell * 0.27);
    canvas.drawOval(
      Rect.fromCenter(center: pole, width: cell * 0.25, height: cell * 0.055),
      paint..color = CalendarStyle.green.withValues(alpha: 0.22),
    );
    canvas.drawLine(
      pole,
      pole - Offset(0, cell * 0.6),
      paint
        ..color = CalendarStyle.green
        ..strokeWidth = math.max(1.8, cell * 0.035)
        ..strokeCap = StrokeCap.round,
    );
    final flag = Rect.fromLTWH(
      pole.dx + cell * 0.02,
      pole.dy - cell * 0.58,
      cell * 0.43,
      cell * 0.3,
    );
    canvas.drawRect(flag, paint..color = const Color(0xFFFFFCED));
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 4; col++) {
        if ((row + col).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(
              flag.left + col * flag.width / 4,
              flag.top + row * flag.height / 3,
              flag.width / 4,
              flag.height / 3,
            ),
            paint..color = CalendarStyle.green,
          );
        }
      }
    }
    canvas.drawRect(
      flag,
      paint
        ..color = CalendarStyle.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    paint.style = PaintingStyle.fill;

    final r = layout.ballRadius * size.width;
    canvas.drawCircle(
      point(ball) + Offset(r * 0.2, r * 0.35),
      r,
      paint..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      point(ball),
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          colors: [Color(0xFFFFF1B2), Color(0xFFD29A35), Color(0xFF996223)],
        ).createShader(Rect.fromCircle(center: point(ball), radius: r)),
    );
  }

  @override
  bool shouldRepaint(_MazePainter oldDelegate) =>
      hanukkah != oldDelegate.hanukkah ||
      oldDelegate.ball != ball ||
      oldDelegate.layout != layout;
}
