import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'calendar_style.dart';

/// The collection stays a clear destination, even before the first award.
class CalendarAwardsButton extends StatelessWidget {
  const CalendarAwardsButton({
    super.key,
    required this.earned,
    required this.total,
    required this.onPressed,
  });

  final int earned, total;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Erfolge',
    child: Semantics(
      label: 'Deine Erfolge, $earned von $total erreicht',
      button: true,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: Material(
          color: const Color(0xFFF5E7CC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5CFA5)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: const SizedBox.square(
              dimension: 56,
              child: Padding(
                padding: EdgeInsets.all(7),
                child: CustomPaint(painter: _AwardOrnament()),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _AwardOrnament extends CustomPainter {
  const _AwardOrnament();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 46, size.height / 48);
    final paint = Paint();
    // Two soft red ribbons and a warm, embossed star ornament.
    canvas.drawPath(
      Path()
        ..moveTo(15, 28)
        ..lineTo(11, 46)
        ..lineTo(20, 41)
        ..lineTo(26, 46)
        ..lineTo(28, 28)
        ..close(),
      paint..color = const Color(0xFFB85E50),
    );
    canvas.drawCircle(
      const Offset(23, 19),
      17,
      paint..color = const Color(0xFFE5BC69),
    );
    canvas.drawCircle(
      const Offset(23, 19),
      13.5,
      paint
        ..color = const Color(0xFFFFE8AD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? 10.0 : 4.7;
      final x = 23 + math.cos(angle) * radius;
      final y = 19 + math.sin(angle) * radius;
      if (i == 0) {
        star.moveTo(x, y);
      } else {
        star.lineTo(x, y);
      }
    }
    canvas.drawPath(
      star..close(),
      paint
        ..style = PaintingStyle.fill
        ..color = CalendarStyle.ivory,
    );
    for (final p in [const Offset(3, 8), const Offset(43, 30)]) {
      canvas.drawLine(
        p - const Offset(0, 3),
        p + const Offset(0, 3),
        paint
          ..color = CalendarStyle.gold
          ..strokeWidth = 1,
      );
      canvas.drawLine(p - const Offset(3, 0), p + const Offset(3, 0), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AwardOrnament oldDelegate) => false;
}
