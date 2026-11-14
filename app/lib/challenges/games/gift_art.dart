import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../presentation/calendar_style.dart';
import '../../presentation/festive_art.dart';

class GiftPainter extends CustomPainter {
  const GiftPainter({required this.progress});

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
  bool shouldRepaint(GiftPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
