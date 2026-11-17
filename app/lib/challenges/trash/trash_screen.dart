import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/scheduler.dart';
import '../maze/maze_game.dart';
import '../maze/tilt_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../achievements/run_facts.dart';
import '../../presentation/calendar_style.dart';
import '../completion.dart';
import '../games/game_widgets.dart';
import 'trash_game.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({
    super.key,
    required this.onComplete,
    this.alreadyCompleted = false,
    this.tiltSource,
  });
  final ChallengeCompletion onComplete;
  final bool alreadyCompleted;
  final TiltSource? tiltSource;
  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  TrashGame _game = TrashGame();
  Offset? _drag, _panOrigin;
  Offset _doorFrom = const Offset(.86, .22);
  Offset _throwFrom = const Offset(.8, .5);
  bool _showResult = false, _disposing = false, _foreground = true;
  late final AnimationController _finish;
  late final AnimationController _disposal;
  late final AnimationController _door;
  late final AnimationController _spill;
  bool _doorOpening = false, _showFailure = false;
  late final Ticker _rollTicker;
  StreamSubscription<Vec2>? _subscription;
  double? _baseline;
  double _tilt = 0;
  Duration? _previous;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _finish = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _disposal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _door = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _spill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _rollTicker = createTicker(_tick);
  }

  bool get _motionAllowed =>
      mounted &&
      _foreground &&
      !_disposing &&
      !_doorOpening &&
      (_game.phase == TrashPhase.replaceBag ||
          _game.phase == TrashPhase.takeOut) &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  void _listen() {
    if (!_motionAllowed || _subscription != null) return;
    _baseline = null;
    _subscription = (widget.tiltSource ?? DeviceTiltSource()).events.listen(
      (event) {
        if (!_motionAllowed) return;
        _baseline ??= event.x;
        _tilt = (event.x - _baseline!).clamp(-1.0, 1.0);
        if (_game.held == null &&
            (_tilt.abs() > .025 || _game.rolling) &&
            !_rollTicker.isActive) {
          _previous = null;
          _rollTicker.start();
        }
      },
      onError: (_) => _stopMotion(),
      onDone: _stopMotion,
    );
  }

  void _stopMotion() {
    _subscription?.cancel();
    _subscription = null;
    _rollTicker.stop();
    _previous = null;
    _baseline = null;
    _tilt = 0;
    _game.stopRoll();
  }

  void _tick(Duration elapsed) {
    final previous = _previous;
    _previous = elapsed;
    if (!_motionAllowed) {
      _stopMotion();
      return;
    }
    if (_game.held != null) {
      _rollTicker.stop();
      _previous = null;
      return;
    }
    if (previous != null &&
        _game.advance((elapsed - previous).inMicroseconds / 1000000, _tilt)) {
      setState(() {});
    }
    if (_tilt.abs() <= .025 && !_game.rolling) {
      _rollTicker.stop();
      _previous = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionAllowed) {
      _listen();
    } else {
      _stopMotion();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _listen();
    } else {
      _stopMotion();
      if (_game.held != null) {
        setState(() {
          _game.cancel(interrupted: true);
          _drag = null;
        });
      }
    }
  }

  void _restart() {
    _stopMotion();
    setState(() {
      _finish.reset();
      _disposal.reset();
      _door.reset();
      _spill.reset();
      _doorOpening = false;
      _showFailure = false;
      _game = TrashGame();
      _drag = null;
      _showResult = false;
      _disposing = false;
    });
    _listen();
  }

  void _move(Offset point) {
    if (_disposing || _doorOpening || _game.lost) return;
    final entered = _game.move(TrashPoint(point.dx, point.dy));
    setState(() {
      _drag = entered ? null : point;
      if (entered) {
        _doorOpening = true;
        _doorFrom = point;
      }
    });
    if (entered) {
      _stopMotion();
      _goOutside();
    }
  }

  Future<void> _goOutside() async {
    try {
      if (!MediaQuery.disableAnimationsOf(context)) {
        await _door.forward(from: 0).orCancel;
      }
      if (mounted && _game.phase == TrashPhase.outside) {
        setState(() => _doorOpening = false);
      }
    } on TickerCanceled {
      /* Restart or navigation cancels the transition. */
    }
  }

  Future<void> _spillTrash() async {
    _stopMotion();
    try {
      if (!MediaQuery.disableAnimationsOf(context)) {
        await _spill.forward(from: 0).orCancel;
      }
      if (mounted && _game.lost) setState(() => _showFailure = true);
    } on TickerCanceled {
      /* The next attempt starts clean. */
    }
  }

  void _drop(Offset point) {
    final wasOutside = _game.phase == TrashPhase.outside;
    var accepted = false;
    setState(() {
      accepted = _game.drop(TrashPoint(point.dx, point.dy));
      _drag = null;
      if (wasOutside && accepted) {
        _disposing = true;
        _throwFrom = point;
      }
    });
    if (_game.lost) _spillTrash();
    if (wasOutside && accepted) _returnToKitchen();
    if (_game.won) {
      _stopMotion();
      _celebrate();
    }
  }

  Future<void> _returnToKitchen() async {
    try {
      if (!MediaQuery.disableAnimationsOf(context)) {
        await _disposal.forward(from: 0).orCancel;
      }
      if (!mounted || _game.phase != TrashPhase.replaceBag) return;
      setState(() => _disposing = false);
      _listen();
    } on TickerCanceled {
      /* Restarting cancels the throw. */
    }
  }

  Future<void> _celebrate() async {
    try {
      if (!MediaQuery.disableAnimationsOf(context)) {
        await _finish.forward().orCancel;
      }
      if (mounted && _game.won) setState(() => _showResult = true);
    } on TickerCanceled {
      /* Restarting cancels the previous reveal. */
    }
  }

  void _accessibleMove() {
    if (_game.won || _game.lost || _disposing || _doorOpening) return;
    final outside = _game.phase == TrashPhase.outside;
    final full = _game.phase == TrashPhase.takeOut;
    _game.begin(
      full
          ? const TrashPoint(.46, .6)
          : outside
          ? const TrashPoint(.44, .75)
          : TrashPoint(_game.rollX, TrashGame.rollY),
    );
    if (full) {
      _move(const Offset(.46, .42));
      _move(const Offset(.86, .22));
    } else {
      _drop(outside ? const Offset(.8, .5) : const Offset(.46, .6));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopMotion();
    _rollTicker.dispose();
    _finish.dispose();
    _disposal.dispose();
    _door.dispose();
    _spill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final full = _game.phase == TrashPhase.takeOut;
    final outside = _game.phase == TrashPhase.outside || _disposing;
    return GameScaffold(
      title: 'Müll rausbringen',
      alreadyCompleted: widget.alreadyCompleted,
      onRestart: _restart,
      instructions:
          'Zieh den Müll nach oben und halte ihn fest. Bring ihn zur Tür und wirf ihn draußen in die Tonne.',
      children: [
        if (_game.lost)
          const GameStats(text: 'Hoppla!')
        else if (full || outside)
          const GameStats(text: 'Müll rausbringen')
        else
          const SizedBox(height: 64),
        AspectRatio(
          aspectRatio: .9,
          child: LayoutBuilder(
            builder: (context, constraints) {
              Offset normalized(Offset p) => Offset(
                p.dx / constraints.maxWidth,
                p.dy / constraints.maxHeight,
              );
              return Semantics(
                label: full
                    ? 'Küche mit vollem Müllbeutel'
                    : outside
                    ? 'Draußen vor der Mülltonne'
                    : 'Küche mit leerem Mülleimer. Eine Beutelrolle liegt auf der Arbeitsplatte.',
                customSemanticsActions:
                    _game.won || _game.lost || _disposing || _doorOpening
                    ? null
                    : {
                        CustomSemanticsAction(
                          label: full
                              ? 'Müllbeutel nach draußen tragen'
                              : outside
                              ? 'Müllbeutel wegwerfen'
                              : 'Beutelrolle verwenden',
                        ): _accessibleMove,
                      },
                child: GestureDetector(
                  key: const ValueKey('trash-kitchen'),
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (details) =>
                      _panOrigin = normalized(details.localPosition),
                  onPanStart: (details) {
                    if (_disposing || _doorOpening || _game.lost) return;
                    final p = _panOrigin ?? normalized(details.localPosition);
                    if (_game.begin(TrashPoint(p.dx, p.dy))) {
                      _rollTicker.stop();
                      _previous = null;
                      _move(normalized(details.localPosition));
                    }
                  },
                  onPanUpdate: (details) {
                    if (_game.held != null) {
                      _move(normalized(details.localPosition));
                    }
                  },
                  onPanEnd: (_) {
                    if (!_doorOpening) {
                      if (_drag case final p?) _drop(p);
                    }
                    _panOrigin = null;
                  },
                  onPanCancel: () {
                    setState(() {
                      _game.cancel();
                      _drag = null;
                      _panOrigin = null;
                    });
                    if (_game.lost) _spillTrash();
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _finish,
                      _disposal,
                      _door,
                      _spill,
                    ]),
                    builder: (_, _) => CustomPaint(
                      painter: TrashKitchenPainter(
                        phase: _doorOpening ? TrashPhase.takeOut : _game.phase,
                        lifted: _game.lifted,
                        openingDoor: _doorOpening,
                        doorProgress: _door.value,
                        doorFrom: _doorFrom,
                        spillProgress: _spill.value,
                        spillAt: Offset(_game.spillAt.x, _game.spillAt.y),
                        spillOutside: _game.spillOutside,
                        held: _game.held,
                        drag: _drag,
                        finish: _finish.value,
                        disposing: _disposing,
                        throwProgress: _disposal.value,
                        throwFrom: _throwFrom,
                        rollX: _game.rollX,
                        rollAngle: _game.rollAngle,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 38,
          child: !_game.lost && (full || outside)
              ? Text(
                  full
                      ? (_game.lifted
                            ? 'Nicht loslassen!'
                            : 'Nach oben ziehen.')
                      : 'Ab in die Tonne.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CalendarStyle.green,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        if (_showFailure)
          DefeatPanel(message: 'Alles eingesaut!', onRetry: _restart),
        if (_showResult)
          CompletionPanel(
            onComplete: widget.onComplete,
            onReplay: _restart,
            message:
                'Müll draußen. Neuer Beutel drin. Ein kleines Weihnachtswunder!',
            facts: const RunFacts(feats: {RunFeat.freshBag}),
          ),
      ],
    );
  }
}

/// A warm kitchen drawn entirely in Flutter, with a dark bag and a pale liner
/// that stay distinct from the bin and the disposal doorway.
class TrashKitchenPainter extends CustomPainter {
  const TrashKitchenPainter({
    required this.phase,
    this.held,
    this.drag,
    this.finish = 0,
    this.disposing = false,
    this.throwProgress = 0,
    this.throwFrom = const Offset(.8, .5),
    this.rollX = .53,
    this.lifted = false,
    this.openingDoor = false,
    this.doorProgress = 0,
    this.doorFrom = const Offset(.86, .22),
    this.spillProgress = 0,
    this.spillAt = const Offset(.46, .6),
    this.spillOutside = false,
    this.rollAngle = 0,
  });
  final TrashPhase phase;
  final TrashItem? held;
  final Offset? drag;
  final double finish, throwProgress, rollX, rollAngle;
  final bool disposing;
  final Offset throwFrom, doorFrom, spillAt;
  final bool lifted, openingDoor, spillOutside;
  final double doorProgress, spillProgress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 440);
    if (phase == TrashPhase.outside ||
        disposing ||
        (phase == TrashPhase.spilled && spillOutside)) {
      _outside(canvas);
      if (phase == TrashPhase.spilled) _paintSpill(canvas);
      canvas.restore();
      return;
    }
    final p = Paint()..isAntiAlias = true;
    void box(Rect rect, Color color, [double radius = 8]) => canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      p
        ..color = color
        ..style = PaintingStyle.fill,
    );
    void line(Offset a, Offset b, Color c, [double width = 2]) =>
        canvas.drawLine(
          a,
          b,
          p
            ..color = c
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round,
        );
    void oval(Rect rect, Color c) => canvas.drawOval(
      rect,
      p
        ..color = c
        ..style = PaintingStyle.fill,
    );
    const green = CalendarStyle.green,
        gold = Color(0xFFC79D55),
        dark = Color(0xFF344A43),
        mint = Color(0xFFD4E4D7);
    box(const Rect.fromLTWH(0, 0, 400, 440), const Color(0xFFF3E9D9), 24);
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 400, 440),
        const Radius.circular(24),
      ),
    );
    box(const Rect.fromLTWH(0, 287, 400, 153), const Color(0xFFE8D5B8), 0);
    for (var i = 0; i < 5; i++) {
      line(
        Offset(0, 304 + i * 31),
        Offset(400, 304 + i * 31),
        const Color(0xFFDBC5A3),
        1,
      );
    }
    // Tiled backsplash and cupboards.
    for (var x = 0; x < 275; x += 46) {
      line(
        Offset(x.toDouble(), 0),
        Offset(x.toDouble(), 124),
        CalendarStyle.ivory,
      );
    }
    for (var y = 32; y < 124; y += 42) {
      line(
        Offset(0, y.toDouble()),
        Offset(274, y.toDouble()),
        CalendarStyle.ivory,
      );
    }
    box(const Rect.fromLTWH(-8, 139, 276, 148), const Color(0xFF8FA693), 2);
    box(const Rect.fromLTWH(-8, 128, 282, 13), const Color(0xFFBE9264), 3);
    for (var i = 0; i < 3; i++) {
      box(Rect.fromLTWH(10 + i * 87, 153, 74, 116), const Color(0xFFA3B7A4), 5);
      line(Offset(60 + i * 87, 169), Offset(73 + i * 87, 169), green, 3);
    }
    // A small festive tea towel; no decorative clutter around the controls.
    box(const Rect.fromLTWH(18, 153, 32, 73), const Color(0xFFBB6555), 3);
    for (var i = 0; i < 3; i++) {
      line(
        Offset(19, 204 + i * 6),
        Offset(48, 204 + i * 6),
        const Color(0xFFF2D8AF),
        2,
      );
    }
    if (held != TrashItem.freshBag && phase != TrashPhase.finished) {
      _roll(canvas);
    }
    // The exit is a real door with a snowy outdoor view and a doormat.
    box(const Rect.fromLTWH(287, 20, 105, 266), const Color(0xFFCEAD80), 5);
    if (openingDoor) {
      box(const Rect.fromLTWH(295, 28, 89, 250), const Color(0xFFDCE7DF), 3);
    }
    canvas.save();
    if (openingDoor) {
      canvas.translate(295, 28);
      canvas.skew(0, -.14 * doorProgress);
      canvas.scale(1 - .93 * Curves.easeInOut.transform(doorProgress), 1);
      canvas.translate(-295, -28);
    }
    box(const Rect.fromLTWH(295, 28, 89, 250), const Color(0xFF819D9C), 3);
    box(const Rect.fromLTWH(302, 37, 75, 112), const Color(0xFFD9E4DE), 2);
    line(const Offset(339, 39), const Offset(339, 147), CalendarStyle.ivory, 4);
    line(const Offset(303, 95), const Offset(376, 95), CalendarStyle.ivory, 4);
    for (final star in [
      const Offset(316, 62),
      const Offset(358, 111),
      const Offset(369, 53),
    ]) {
      oval(Rect.fromCircle(center: star, radius: 2.5), CalendarStyle.ivory);
    }
    oval(const Rect.fromLTWH(365, 178, 7, 7), gold);
    canvas.restore();
    oval(const Rect.fromLTWH(285, 287, 105, 25), const Color(0xFFBDA17A));
    // Bin body and dark opening remain visible when the bag is removed.
    oval(const Rect.fromLTWH(91, 355, 177, 24), const Color(0xFFD5BB95));
    final body = Path()
      ..moveTo(112, 230)
      ..lineTo(258, 230)
      ..lineTo(242, 358)
      ..quadraticBezierTo(185, 376, 128, 358)
      ..close();
    canvas.drawPath(body, p..color = const Color(0xFF8C9D98));
    for (var i = 0; i < 5; i++) {
      line(
        Offset(137 + i * 21, 254),
        Offset(145 + i * 17, 348),
        const Color(0xFFABB8AF),
        3,
      );
    }
    oval(const Rect.fromLTWH(108, 207, 154, 47), const Color(0xFFB2C0B8));
    oval(const Rect.fromLTWH(117, 213, 136, 33), const Color(0xFF46534D));
    box(const Rect.fromLTWH(164, 359, 40, 9), dark, 3);
    if (phase == TrashPhase.takeOut && !lifted && !openingDoor) {
      _rubbish(canvas);
    }
    if (openingDoor) {
      final t = Curves.easeInOut.transform(doorProgress);
      final at = Offset.lerp(
        Offset(doorFrom.dx * 400, doorFrom.dy * 440),
        const Offset(340, 200),
        t,
      )!;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(1 - .6 * t);
      _bag(canvas, Offset.zero, full: true);
      canvas.restore();
    }
    if (phase == TrashPhase.spilled) _paintSpill(canvas);
    if (phase == TrashPhase.finished) {
      final t = Curves.easeOutCubic.transform(finish);
      _bag(canvas, Offset(185, 205 + 47 * t), full: false);
      oval(const Rect.fromLTWH(111, 209, 148, 40), mint);
      oval(const Rect.fromLTWH(122, 214, 126, 25), const Color(0xFF71957F));
      for (var i = 0; i < 7; i++) {
        final a = -math.pi + i * math.pi / 6;
        final r = 35 + finish * 75;
        final c = Offset(185 + math.cos(a) * r, 222 + math.sin(a) * r);
        oval(Rect.fromCircle(center: c, radius: 3 * (1 - finish) + 1), gold);
      }
    }
    if (drag case final at? when held == TrashItem.freshBag || lifted) {
      _bag(
        canvas,
        Offset(at.dx * 400, at.dy * 440),
        full: held == TrashItem.fullBag,
      );
    }
    canvas.restore();
    canvas.restore();
  }

  void _rubbish(Canvas canvas) {
    final p = Paint()..isAntiAlias = true;
    // An open liner with crumpled paper, a wrapper and a banana peel.
    canvas.drawPath(
      Path()
        ..moveTo(120, 223)
        ..lineTo(124, 200)
        ..lineTo(140, 210)
        ..lineTo(232, 205)
        ..lineTo(247, 222)
        ..quadraticBezierTo(185, 247, 120, 223),
      p..color = const Color(0xFF647B69),
    );
    canvas.drawPath(
      Path()
        ..moveTo(139, 211)
        ..lineTo(129, 180)
        ..lineTo(149, 174)
        ..lineTo(158, 186)
        ..lineTo(175, 180)
        ..lineTo(185, 212)
        ..close(),
      p..color = const Color(0xFFF0E5CE),
    );
    p
      ..color = const Color(0xFFC5B79A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(
      Path()
        ..moveTo(137, 185)
        ..lineTo(154, 194)
        ..lineTo(148, 208)
        ..moveTo(154, 194)
        ..lineTo(172, 186),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(194, 187, 32, 29),
        const Radius.circular(3),
      ),
      p
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFBA6D56),
    );
    canvas.drawLine(
      const Offset(198, 191),
      const Offset(221, 191),
      p
        ..color = const Color(0xFFE7CBA4)
        ..strokeWidth = 3,
    );
    p
      ..color = const Color(0xFFC3A04E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(174, 187)
        ..quadraticBezierTo(176, 220, 203, 213)
        ..moveTo(176, 195)
        ..quadraticBezierTo(165, 211, 161, 204),
      p,
    );
    canvas.drawOval(
      const Rect.fromLTWH(218, 208, 18, 9),
      p
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF78824E),
    );
  }

  void _paintSpill(Canvas canvas) {
    final t = Curves.easeIn.transform(spillProgress);
    final scatter = ((spillProgress - .25) / .75).clamp(0.0, 1.0);
    final from = Offset(
      spillAt.dx.clamp(.13, .85) * 400,
      spillAt.dy.clamp(.12, .85) * 440,
    );
    final landing = Offset(from.dx, 383);
    final bagAt = Offset.lerp(from, landing, t)!;
    final p = Paint()..isAntiAlias = true;
    for (var i = 0; i < 8; i++) {
      final at = Offset(
        38 + ((i * 73) % 320).toDouble(),
        i < 6 ? 324 + ((i * 29) % 86).toDouble() : 150 + (i - 6) * 65,
      );
      p.color = const Color(0xFF7C644B).withValues(alpha: scatter * .6);
      canvas.drawOval(
        Rect.fromCenter(
          center: at,
          width: 27 + (i % 3) * 14,
          height: 11 + (i % 2) * 6,
        ),
        p,
      );
      for (var j = 0; j < 3; j++) {
        canvas.drawCircle(
          at + Offset(19 + j * 7, j.isEven ? 10 : -10),
          2 + j.toDouble(),
          p,
        );
      }
    }
    canvas.save();
    canvas.translate(bagAt.dx, bagAt.dy);
    canvas.rotate(t * 1.35);
    canvas.scale(1 - .18 * t);
    _bag(canvas, Offset.zero, full: true);
    canvas.restore();
    for (var i = 0; i < 22; i++) {
      final target = Offset(
        26 + ((i * 83) % 348).toDouble(),
        280 + ((i * 37) % 143).toDouble(),
      );
      final at =
          Offset.lerp(from, target, Curves.easeOut.transform(scatter))! -
          Offset(0, math.sin(scatter * math.pi) * (30 + i % 4 * 12));
      if (scatter == 0) continue;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(i * .79 + scatter * (i.isEven ? 2 : -2));
      p.color = [
        const Color(0xFFEDE0C8),
        const Color(0xFFB86B53),
        const Color(0xFF75805C),
      ][i % 3];
      canvas.drawPath(
        Path()
          ..moveTo(-7, -5)
          ..lineTo(3, -7)
          ..lineTo(8, 2)
          ..lineTo(2, 7)
          ..lineTo(-6, 4)
          ..close(),
        p,
      );
      canvas.restore();
    }
  }

  void _roll(Canvas canvas) {
    canvas.save();
    canvas.translate(rollX * 400, TrashGame.rollY * 440);
    final p = Paint()..isAntiAlias = true;
    canvas.drawOval(
      const Rect.fromLTWH(-40, 17, 82, 10),
      p..color = const Color(0xFFD5BB95),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-34, -18, 68, 36),
        const Radius.circular(12),
      ),
      p..color = const Color(0xFFD4E4D7),
    );
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-32, -18, 60, 36),
        const Radius.circular(12),
      ),
    );
    for (var i = -1; i < 4; i++) {
      final y = -18 + ((rollAngle * 12 + i * 18) % 54);
      canvas.drawLine(
        Offset(-30, y),
        Offset(24, y),
        p
          ..color = const Color(0xFFE8EFE5)
          ..strokeWidth = 2,
      );
    }
    canvas.restore();
    canvas.drawOval(
      const Rect.fromLTWH(20, -18, 23, 36),
      p..color = const Color(0xFF94B5A0),
    );
    canvas.save();
    canvas.translate(31, 0);
    canvas.rotate(rollAngle);
    p
      ..color = const Color(0xFFD4E4D7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      const Rect.fromLTWH(-6, -12, 12, 24),
      .4,
      math.pi * 1.65,
      false,
      p,
    );
    canvas.drawOval(
      const Rect.fromLTWH(-3, -5, 6, 10),
      p
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF52735F),
    );
    canvas.restore();
    canvas.restore();
  }

  void _outside(Canvas canvas) {
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 400, 440),
        const Radius.circular(24),
      ),
    );
    final p = Paint()..isAntiAlias = true;
    void rect(Rect r, Color c, [double radius = 6]) => canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      p
        ..color = c
        ..style = PaintingStyle.fill,
    );
    rect(const Rect.fromLTWH(0, 0, 400, 440), const Color(0xFFD9E4DE), 0);
    rect(const Rect.fromLTWH(0, 263, 400, 177), const Color(0xFFF5F0E5), 0);
    final path = Path()
      ..moveTo(80, 440)
      ..lineTo(150, 263)
      ..lineTo(220, 263)
      ..lineTo(320, 440)
      ..close();
    canvas.drawPath(path, p..color = const Color(0xFFD4C5AE));
    // A snowy fence and a warmly lit kitchen door behind you.
    for (var i = 0; i < 9; i++) {
      rect(
        Rect.fromLTWH(94 + i * 39, 156, 17, 114),
        const Color(0xFF9EAC9C),
        3,
      );
    }
    rect(const Rect.fromLTWH(93, 180, 307, 11), const Color(0xFF8A9C8D), 2);
    rect(const Rect.fromLTWH(93, 232, 307, 11), const Color(0xFF8A9C8D), 2);
    rect(const Rect.fromLTWH(-7, 45, 92, 267), const Color(0xFFCEAD80), 3);
    rect(const Rect.fromLTWH(4, 56, 68, 246), const Color(0xFF819D9C), 2);
    rect(const Rect.fromLTWH(13, 70, 50, 106), const Color(0xFFF4DFAC), 2);
    for (final snow in [
      const Offset(123, 61),
      const Offset(188, 108),
      const Offset(317, 51),
      const Offset(358, 120),
    ]) {
      canvas.drawCircle(snow, 3, p..color = CalendarStyle.ivory);
    }
    // An open outdoor wheelie bin: the bag must actually be thrown into it.
    canvas.drawOval(
      const Rect.fromLTWH(243, 301, 139, 25),
      p..color = const Color(0xFFD7D5C6),
    );
    final bin = Path()
      ..moveTo(257, 190)
      ..lineTo(365, 190)
      ..lineTo(353, 304)
      ..lineTo(271, 304)
      ..close();
    canvas.drawPath(bin, p..color = const Color(0xFF496D58));
    for (var i = 0; i < 3; i++) {
      rect(Rect.fromLTWH(280 + i * 24, 222, 4, 69), const Color(0xFF6C8A70), 2);
    }
    canvas.drawOval(
      const Rect.fromLTWH(253, 179, 116, 29),
      p..color = const Color(0xFF2D4438),
    );
    canvas.save();
    canvas.translate(358, 180);
    canvas.rotate(.8);
    rect(const Rect.fromLTWH(-112, -15, 119, 15), const Color(0xFF648269), 4);
    canvas.restore();
    for (final x in [279.0, 345.0]) {
      canvas.drawCircle(Offset(x, 311), 11, p..color = const Color(0xFF39463D));
    }
    if (disposing) {
      final t = Curves.easeInOut.transform(throwProgress);
      final from = Offset(throwFrom.dx * 400, throwFrom.dy * 440);
      final to = const Offset(311, 192);
      final at =
          Offset.lerp(from, to, t)! - Offset(0, math.sin(t * math.pi) * 75);
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(1 - .85 * t);
      _bag(canvas, Offset.zero, full: true);
      canvas.restore();
    } else if (drag case final point?) {
      _bag(canvas, Offset(point.dx * 400, point.dy * 440), full: true);
    } else if (phase != TrashPhase.spilled) {
      _bag(canvas, const Offset(176, 330), full: true);
    }
    canvas.restore();
  }

  void _bag(Canvas canvas, Offset center, {required bool full}) {
    canvas.save();
    canvas.translate(center.dx - 55, center.dy - 70);
    final p = Paint()..isAntiAlias = true;
    final bag = Path()
      ..moveTo(32, 16)
      ..quadraticBezierTo(5, 42, 6, 98)
      ..quadraticBezierTo(7, 124, 55, 125)
      ..quadraticBezierTo(104, 124, 104, 98)
      ..quadraticBezierTo(104, 44, 77, 16)
      ..close();
    canvas.drawPath(
      bag,
      p..color = full ? const Color(0xFF344A43) : const Color(0xFFB3D2BE),
    );
    p
      ..color = full ? const Color(0xFF587365) : const Color(0xFFE5F0E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(32, 28)
        ..quadraticBezierTo(20, 72, 29, 108),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(77, 34)
        ..quadraticBezierTo(91, 77, 83, 109),
      p,
    );
    if (full) {
      p
        ..color = const Color(0xFF344A43)
        ..strokeWidth = 7;
      canvas.drawPath(
        Path()
          ..moveTo(29, 18)
          ..quadraticBezierTo(11, -13, 27, -14)
          ..quadraticBezierTo(43, -11, 38, 16)
          ..moveTo(74, 17)
          ..quadraticBezierTo(68, -13, 83, -12)
          ..quadraticBezierTo(101, -9, 84, 22),
        p,
      );
      canvas.drawOval(
        const Rect.fromLTWH(27, 9, 58, 18),
        p
          ..style = PaintingStyle.fill
          ..color = const Color(0xFF263B31),
      );
      canvas.drawPath(
        Path()
          ..moveTo(37, 14)
          ..lineTo(33, 1)
          ..lineTo(45, -3)
          ..lineTo(55, 13)
          ..close(),
        p..color = const Color(0xFFF0E5CE),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(63, 4, 14, 14),
          const Radius.circular(2),
        ),
        p..color = const Color(0xFFBA6D56),
      );
    } else {
      canvas.drawOval(
        const Rect.fromLTWH(25, 9, 57, 16),
        p
          ..color = const Color(0xFF71957F)
          ..style = PaintingStyle.fill,
      );
      canvas.drawOval(
        const Rect.fromLTWH(25, 9, 57, 16),
        p
          ..color = const Color(0xFFE5F0E5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(TrashKitchenPainter old) =>
      old.phase != phase ||
      old.held != held ||
      old.drag != drag ||
      old.finish != finish ||
      old.disposing != disposing ||
      old.throwProgress != throwProgress ||
      old.rollX != rollX ||
      old.rollAngle != rollAngle ||
      old.lifted != lifted ||
      old.openingDoor != openingDoor ||
      old.doorProgress != doorProgress ||
      old.spillProgress != spillProgress ||
      old.spillAt != spillAt;
}
