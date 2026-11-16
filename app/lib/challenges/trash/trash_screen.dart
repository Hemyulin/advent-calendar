import 'dart:math' as math;
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
  });
  final ChallengeCompletion onComplete;
  final bool alreadyCompleted;
  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen>
    with SingleTickerProviderStateMixin {
  TrashGame _game = TrashGame();
  Offset? _drag;
  bool _showResult = false;
  late final _finish = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  void _restart() => setState(() {
    _finish.reset();
    _game = TrashGame();
    _drag = null;
    _showResult = false;
  });

  void _drop(Offset point) {
    setState(() {
      _game.drop(TrashPoint(point.dx, point.dy));
      _drag = null;
    });
    if (_game.won) _celebrate();
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
    if (_game.won) return;
    final full = _game.phase == TrashPhase.takeOut;
    _game.begin(full ? const TrashPoint(.46, .6) : const TrashPoint(.84, .8));
    _drop(full ? const Offset(.86, .22) : const Offset(.46, .6));
  }

  @override
  void dispose() {
    _finish.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final full = _game.phase == TrashPhase.takeOut;
    return GameScaffold(
      title: 'Müll rausbringen',
      alreadyCompleted: widget.alreadyCompleted,
      onRestart: _restart,
      instructions:
          'Zieh den vollen Müllbeutel zur Tür. Setze danach einen frischen Beutel in den leeren Mülleimer ein.',
      children: [
        GameStats(
          text: _game.won
              ? 'So gehört sich das!'
              : full
              ? 'Müll raus …'
              : '… und einen neuen Beutel rein.',
        ),
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
                    ? 'Voller Müllbeutel im Küchenmülleimer'
                    : 'Leerer Mülleimer und frische Müllbeutel',
                customSemanticsActions: _game.won
                    ? null
                    : {
                        CustomSemanticsAction(
                          label: full
                              ? 'Müllbeutel zur Tür bringen'
                              : 'Frischen Beutel einsetzen',
                        ): _accessibleMove,
                      },
                child: GestureDetector(
                  key: const ValueKey('trash-kitchen'),
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (details) {
                    final p = normalized(details.localPosition);
                    if (_game.begin(TrashPoint(p.dx, p.dy))) {
                      setState(() => _drag = p);
                    }
                  },
                  onPanUpdate: (details) {
                    if (_game.held != null) {
                      setState(() => _drag = normalized(details.localPosition));
                    }
                  },
                  onPanEnd: (_) {
                    if (_drag case final p?) _drop(p);
                  },
                  onPanCancel: () => setState(() {
                    _game.cancel();
                    _drag = null;
                  }),
                  child: AnimatedBuilder(
                    animation: _finish,
                    builder: (_, _) => CustomPaint(
                      painter: TrashKitchenPainter(
                        phase: _game.phase,
                        held: _game.held,
                        drag: _drag,
                        finish: _finish.value,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _game.won
              ? 'Neuer Beutel. Neues Glück.'
              : full
              ? 'Vollen Beutel zur Tür ziehen.'
              : 'Frischen Beutel einsetzen.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: CalendarStyle.green, fontSize: 16),
        ),
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
  });
  final TrashPhase phase;
  final TrashItem? held;
  final Offset? drag;
  final double finish;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 440);
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
    // The exit is a real door with a snowy outdoor view and a doormat.
    box(const Rect.fromLTWH(287, 20, 105, 266), const Color(0xFFCEAD80), 5);
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
    oval(const Rect.fromLTWH(285, 287, 105, 25), const Color(0xFFBDA17A));
    if (phase == TrashPhase.takeOut) {
      oval(
        const Rect.fromLTWH(316, 168, 50, 50),
        CalendarStyle.ivory.withValues(alpha: .75),
      );
      line(const Offset(328, 193), const Offset(353, 193), green, 3);
      line(const Offset(345, 185), const Offset(353, 193), green, 3);
      line(const Offset(345, 201), const Offset(353, 193), green, 3);
    }
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
    if (phase == TrashPhase.takeOut && held != TrashItem.fullBag) {
      _bag(canvas, const Offset(185, 252), full: true);
    }
    if (phase == TrashPhase.replaceBag) {
      // Fresh liners on a low shelf, visually distinct from the dark refuse bag.
      box(const Rect.fromLTWH(289, 376, 100, 12), const Color(0xFFBE9264), 3);
      if (held != TrashItem.freshBag) {
        box(const Rect.fromLTWH(303, 326, 73, 45), mint, 14);
        oval(const Rect.fromLTWH(351, 326, 25, 45), const Color(0xFF9EBDA9));
        oval(const Rect.fromLTWH(358, 338, 11, 20), green);
        line(
          const Offset(312, 341),
          const Offset(343, 341),
          CalendarStyle.ivory,
          3,
        );
      }
      // A restrained dashed target around the empty rim.
      for (var i = 0; i < 16; i++) {
        final a = i * math.pi / 8;
        final b = a + .14;
        line(
          Offset(185 + math.cos(a) * 79, 229 + math.sin(a) * 28),
          Offset(185 + math.cos(b) * 79, 229 + math.sin(b) * 28),
          gold,
          2,
        );
      }
    }
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
    if (drag case final at?) {
      _bag(
        canvas,
        Offset(at.dx * 400, at.dy * 440),
        full: held == TrashItem.fullBag,
      );
    }
    canvas.restore();
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
      canvas.drawPath(
        Path()
          ..moveTo(52, 17)
          ..quadraticBezierTo(24, -5, 35, -12)
          ..quadraticBezierTo(48, -18, 58, 14)
          ..quadraticBezierTo(70, -16, 83, -8)
          ..quadraticBezierTo(93, 3, 60, 20),
        p
          ..color = const Color(0xFF344A43)
          ..strokeWidth = 9,
      );
      canvas.drawLine(
        const Offset(43, 19),
        const Offset(68, 18),
        p
          ..color = const Color(0xFFC79D55)
          ..strokeWidth = 5,
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
      old.finish != finish;
}
