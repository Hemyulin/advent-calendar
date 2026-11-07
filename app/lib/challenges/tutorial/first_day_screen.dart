import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../presentation/viewport_fit.dart';

import '../../presentation/calendar_style.dart';
import '../completion.dart';
import '../games/game_widgets.dart';
import '../../presentation/festive_art.dart';

/// A one-action introduction. Completion is supplied by the application flow;
/// this screen has no knowledge of storage or the physical lock.
class FirstDayScreen extends StatefulWidget {
  const FirstDayScreen({
    super.key,
    required this.onComplete,
    this.alreadyCompleted = false,
  });

  final ChallengeCompletion onComplete;
  final bool alreadyCompleted;

  @override
  State<FirstDayScreen> createState() => _FirstDayScreenState();
}

class _FirstDayScreenState extends State<FirstDayScreen>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _opening = false;
  bool _completed = false;
  String? _error;

  Future<void> _openPresent() async {
    if (_opening || _completed) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      if (MediaQuery.disableAnimationsOf(context)) {
        _animation.value = 1;
      } else {
        await _animation.forward().orCancel;
      }
      if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
      await widget.onComplete();
      if (!mounted) return;
      setState(() {
        _completed = true;
        _opening = false;
      });
    } on TickerCanceled {
      // Leaving during the animation does not complete the challenge.
    } catch (_) {
      if (!mounted) return;
      _animation.reset();
      setState(() {
        _opening = false;
        _error = 'Das hat gerade nicht geklappt. Versuch es noch einmal.';
      });
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameResultLayer(
      result: _completed
          ? CompletionPanel(
              onComplete: () async {},
              onReplay: () => setState(() {
                _animation.reset();
                _completed = false;
              }),
              message: 'Dein erstes Türchen ist offen.',
            )
          : null,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Türchen 1'),
          actions: [
            if (widget.alreadyCompleted)
              const Tooltip(
                message: 'Bereits geschafft',
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: CalendarStyle.green,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => ViewportFit(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 48),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _completed
                                ? 'Dein erster\nWeihnachtsmoment!'
                                : 'Dein erster\nWeihnachtszauber',
                            textAlign: TextAlign.center,
                            style: CalendarStyle.heading.copyWith(fontSize: 34),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _completed
                              ? 'Dein erstes Türchen ist offen.'
                              : 'Geh zu deinem Adventskalender.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: CalendarStyle.muted,
                            height: 1.7,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ExcludeSemantics(
                          child: SizedBox(
                            width: 240,
                            height: 232,
                            child: AnimatedBuilder(
                              animation: _animation,
                              builder: (context, _) => CustomPaint(
                                painter: _PresentPainter(
                                  progress: _animation.value,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_error != null) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFB94F46)),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: CalendarStyle.green,
                              foregroundColor: CalendarStyle.ivory,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: _opening
                                ? null
                                : _completed
                                ? () => Navigator.pop(context)
                                : _openPresent,
                            child: Text(
                              _completed
                                  ? 'Überraschung geöffnet'
                                  : _opening
                                  ? 'Öffnet …'
                                  : 'Überraschung öffnen',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Tooltip(
                          message: 'Das Öffnen wird nur simuliert.',
                          child: Text(
                            'Vorschau',
                            style: TextStyle(
                              color: CalendarStyle.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PresentPainter extends CustomPainter {
  const _PresentPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 240, size.height / 232);
    final t = Curves.easeOutCubic.transform(progress);
    final paint = Paint();
    const cream = Color(0xFFFFF1CB);
    const red = Color(0xFFCB695B);
    const gold = Color(0xFFEFC46E);

    canvas.drawOval(
      const Rect.fromLTWH(51, 199, 138, 14),
      paint..color = CalendarStyle.gold.withValues(alpha: 0.1),
    );
    canvas.drawCircle(
      const Offset(120, 126),
      96,
      Paint()
        ..shader = RadialGradient(
          colors: [
            gold.withValues(alpha: 0.15 + t * 0.22),
            gold.withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTWH(24, 30, 192, 192)),
    );
    // The lid lifts away from the box; stars rise from the warm interior.
    if (progress > 0) {
      for (var i = 0; i < 7; i++) {
        final angle = math.pi + i * math.pi / 6;
        final center = Offset(
          120 + math.cos(angle) * 83 * t,
          134 + math.sin(angle) * 92 * t,
        );
        paintStar(
          canvas,
          center,
          (i.isEven ? 7 : 4) * t,
          i.isEven ? gold : red,
        );
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(64, 116, 112, 86),
        const Radius.circular(9),
      ),
      paint..color = red,
    );
    canvas.drawOval(
      const Rect.fromLTWH(67, 112, 106, 15),
      paint..color = cream,
    );
    canvas.drawRect(const Rect.fromLTWH(111, 122, 18, 80), paint..color = gold);
    for (final point in [
      const Offset(84, 148),
      const Offset(151, 173),
      const Offset(87, 185),
    ]) {
      canvas.drawCircle(
        point,
        2.5,
        paint..color = cream.withValues(alpha: 0.8),
      );
    }
    canvas.save();
    canvas.translate(120 - 15 * t, 111 - 66 * t);
    canvas.rotate(-0.16 * t);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-62, -9, 124, 22),
        const Radius.circular(6),
      ),
      paint..color = const Color(0xFFE58C79),
    );
    canvas.drawRect(const Rect.fromLTWH(-9, -9, 18, 22), paint..color = gold);
    for (final mirror in [false, true]) {
      canvas.save();
      if (mirror) canvas.scale(-1, 1);
      canvas.drawPath(
        Path()
          ..moveTo(0, -8)
          ..cubicTo(-49, -7, -32, -44, -13, -26)
          ..close(),
        paint
          ..color = gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }
    canvas.restore();
    paintStar(canvas, const Offset(32, 79), 5, CalendarStyle.gold);
    paintStar(canvas, const Offset(210, 146), 6, CalendarStyle.gold);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PresentPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
