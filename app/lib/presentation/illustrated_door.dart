import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../content/calendar_day.dart';
import 'calendar_style.dart';
import 'festive_art.dart';

/// A hinged paper door. Only the leaf moves; its frame and lights stay put.
class IllustratedDoor extends StatefulWidget {
  const IllustratedDoor({super.key, required this.day, this.onTap});

  final CalendarDay day;
  final Future<void> Function()? onTap;

  @override
  State<IllustratedDoor> createState() => _IllustratedDoorState();
}

class _IllustratedDoorState extends State<IllustratedDoor>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 780),
  );
  bool _opening = false;

  Future<void> _open() async {
    final onTap = widget.onTap;
    if (_opening || !widget.day.isAvailable || onTap == null) return;
    setState(() => _opening = true);
    try {
      if (!MediaQuery.disableAnimationsOf(context)) {
        await _controller.forward().orCancel;
      }
      if (!mounted) return;
      await onTap();
    } on TickerCanceled {
      // Changing the selected day or leaving the screen cancels the opening.
    } finally {
      if (mounted) {
        _controller.reset();
        setState(() => _opening = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final locked = !day.isAvailable;
    return Semantics(
      button: true,
      enabled: !locked && !_opening,
      onTap: locked || _opening ? null : _open,
      label:
          'Türchen ${day.number}, ${locked
              ? 'gesperrt'
              : day.state == DayState.completed
              ? 'bereits geöffnet'
              : 'öffnen'}',
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: locked || _opening ? null : _open,
          child: AspectRatio(
            aspectRatio: 0.84,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DoorPainter(day: day, leaf: false),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final progress = Curves.easeInOutCubic.transform(
                          _controller.value,
                        );
                        return Transform(
                          alignment: const Alignment(-0.65, 0),
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0018)
                            ..rotateY(-math.pi * 0.46 * progress),
                          child: child,
                        );
                      },
                      child: CustomPaint(
                        painter: _DoorPainter(day: day, leaf: true),
                        child: Stack(
                          children: [
                            Positioned(
                              top: constraints.maxHeight * 0.27,
                              left: 0,
                              right: 0,
                              child: Text(
                                '${day.number}'.padLeft(2, '0'),
                                textAlign: TextAlign.center,
                                textScaler: TextScaler.noScaling,
                                style: CalendarStyle.heading.copyWith(
                                  fontSize: constraints.maxWidth * 0.29,
                                  height: 1,
                                  color: const Color(0xFFFFF4DA),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: constraints.maxHeight * 0.025,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CalendarStyle.ivory,
                          shape: BoxShape.circle,
                          border: Border.all(color: CalendarStyle.line),
                        ),
                        child: Icon(
                          locked
                              ? Icons.lock_outline_rounded
                              : day.state == DayState.completed
                              ? Icons.check_circle_outline_rounded
                              : Icons.lock_open_rounded,
                          color: DoorDesign.forDay(day.number).color,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DoorPainter extends CustomPainter {
  const _DoorPainter({required this.day, required this.leaf});

  final CalendarDay day;
  final bool leaf;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 280, size.height / 333);
    final design = DoorDesign.forDay(day.number);
    final paint = Paint();
    const rect = Rect.fromLTWH(43, 61, 194, 243);
    if (!leaf) {
      canvas.drawCircle(
        const Offset(140, 165),
        130,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFF5D99A).withValues(alpha: 0.3),
              CalendarStyle.ivory.withValues(alpha: 0),
            ],
          ).createShader(const Rect.fromLTWH(10, 35, 260, 260)),
      );
      final frame = RRect.fromRectAndRadius(rect, const Radius.circular(17));
      canvas.drawShadow(
        Path()..addRRect(frame),
        const Color(0xFFAF784A).withValues(alpha: 0.22),
        8,
        true,
      );
      canvas.drawRRect(frame, paint..color = const Color(0xFFF1DEC0));
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(6), const Radius.circular(12)),
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFFFF9D9), Color(0xFFF3C86B)],
          ).createShader(rect),
      );
      paintStar(canvas, const Offset(140, 178), 27, const Color(0xFFFFFCED));
      paintStar(canvas, const Offset(99, 215), 8, const Color(0xFFFFFCED));
      paintStar(canvas, const Offset(181, 138), 10, const Color(0xFFFFFCED));
      paintFairyLights(canvas, 280);
      paintStar(canvas, const Offset(26, 112), 7, CalendarStyle.gold);
      paintStar(canvas, const Offset(257, 252), 6, const Color(0xFFDE9980));
      paintStar(canvas, const Offset(250, 91), 4, CalendarStyle.gold);
      canvas.drawCircle(
        const Offset(24, 237),
        2,
        paint..color = const Color(0xFFDE9980),
      );
    } else {
      final door = RRect.fromRectAndRadius(
        rect.deflate(6),
        const Radius.circular(12),
      );
      final color = day.isAvailable
          ? design.color
          : Color.lerp(design.color, CalendarStyle.ivory, 0.13)!;
      canvas.drawRRect(door, paint..color = color);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(14), const Radius.circular(6)),
        paint
          ..color = const Color(0xFFFFE9BE).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      paint.style = PaintingStyle.fill;
      for (var y = 88.0; y < 282; y += 10) {
        canvas.drawLine(
          Offset(54, y),
          Offset(54, y + 3),
          paint
            ..color = const Color(0xFFFFE9BE).withValues(alpha: 0.4)
            ..strokeWidth = 1,
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(217, 174, 10, 24),
          const Radius.circular(5),
        ),
        paint..color = const Color(0xFFF4C978),
      );
      canvas.drawCircle(
        const Offset(222, 181),
        1.5,
        paint..color = design.color,
      );
      canvas.save();
      canvas.translate(96, 173);
      canvas.scale(0.88);
      paintOrnament(canvas, design.motif);
      canvas.restore();
      for (final point in [
        const Offset(80, 180),
        const Offset(198, 211),
        const Offset(86, 257),
        const Offset(187, 275),
      ]) {
        canvas.drawCircle(
          point,
          1.6,
          paint..color = const Color(0xFFFFE9BE).withValues(alpha: 0.65),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DoorPainter oldDelegate) =>
      oldDelegate.day.number != day.number ||
      oldDelegate.day.state != day.state ||
      oldDelegate.leaf != leaf;
}
