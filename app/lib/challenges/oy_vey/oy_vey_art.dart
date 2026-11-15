import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../presentation/calendar_style.dart';
import 'oy_vey_game.dart';

class FestiveObjectIcon extends StatelessWidget {
  const FestiveObjectIcon(this.kind, {super.key, this.size = 34});
  final FestiveObject kind;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: kind.label,
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ObjectIconPainter(kind)),
    ),
  );
}

class _ObjectIconPainter extends CustomPainter {
  _ObjectIconPainter(this.kind);
  final FestiveObject kind;
  @override
  void paint(Canvas canvas, Size size) {
    paintFestiveObject(
      canvas,
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      kind,
    );
  }

  @override
  bool shouldRepaint(_ObjectIconPainter old) => old.kind != kind;
}

void paintFestiveObject(
  Canvas canvas,
  Offset center,
  double radius,
  FestiveObject kind,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(radius / 22);
  final p = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  switch (kind) {
    case FestiveObject.sufganiyah:
      canvas.drawOval(
        const Rect.fromLTWH(-19, -13, 38, 29),
        p..color = const Color(0xFFC68D47),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-18, -15, 36, 24),
        p..color = const Color(0xFFEAC084),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-16, -12, 32, 15),
        p..color = const Color(0xFFFFF3DB),
      );
      canvas.drawCircle(
        const Offset(2, -4),
        5,
        p..color = const Color(0xFFB55050),
      );
      for (final o in [
        const Offset(-10, -7),
        const Offset(10, -8),
        const Offset(-5, 0),
      ]) {
        canvas.drawCircle(o, 1.5, p..color = Colors.white);
      }
    case FestiveObject.dreidel:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -22, 6, 12),
          const Radius.circular(2),
        ),
        p..color = const Color(0xFFC19B5E),
      );
      canvas.drawPath(
        Path()
          ..moveTo(-14, -11)
          ..lineTo(11, -13)
          ..lineTo(17, 10)
          ..lineTo(0, 23)
          ..lineTo(-15, 10)
          ..close(),
        p..color = const Color(0xFF537E9B),
      );
      canvas.drawPath(
        Path()
          ..moveTo(1, -11)
          ..lineTo(17, -8)
          ..lineTo(17, 10)
          ..lineTo(0, 23)
          ..close(),
        p..color = const Color(0xFF365F7B),
      );
      canvas.drawPath(
        Path()
          ..moveTo(-9, -3)
          ..lineTo(-2, -3)
          ..lineTo(-2, 8)
          ..lineTo(-9, 8),
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFFF5DB99),
      );
    case FestiveObject.hanukkiah:
      p
        ..color = const Color(0xFFD0A24F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawLine(const Offset(0, -17), const Offset(0, 18), p);
      for (var i = 1; i <= 4; i++) {
        final x = i * 4.5;
        canvas.drawPath(
          Path()
            ..moveTo(-x, -8)
            ..lineTo(-x, 4 + i * 2.0)
            ..quadraticBezierTo(0, 17, x, 4 + i * 2.0)
            ..lineTo(x, -8),
          p,
        );
      }
      canvas.drawLine(const Offset(-9, 20), const Offset(9, 20), p);
      p.style = PaintingStyle.fill;
      for (var i = -4; i <= 4; i++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(i * 4.5, i == 0 ? -20 : -11),
            width: 3,
            height: 5,
          ),
          p..color = const Color(0xFFF4C36A),
        );
      }
    case FestiveObject.tree:
      canvas.drawRect(
        const Rect.fromLTWH(-3, 11, 6, 10),
        p..color = const Color(0xFFB18A60),
      );
      canvas.drawPath(
        Path()
          ..moveTo(0, -22)
          ..lineTo(12, -5)
          ..lineTo(7, -5)
          ..lineTo(17, 8)
          ..lineTo(10, 8)
          ..lineTo(21, 17)
          ..lineTo(-21, 17)
          ..lineTo(-10, 8)
          ..lineTo(-17, 8)
          ..lineTo(-7, -5)
          ..lineTo(-12, -5)
          ..close(),
        p..color = CalendarStyle.green,
      );
      canvas.drawCircle(
        const Offset(-6, 6),
        2,
        p..color = const Color(0xFFD7B168),
      );
      canvas.drawCircle(const Offset(7, 12), 2, p);
    case FestiveObject.hat:
      canvas.drawPath(
        Path()
          ..moveTo(-18, 12)
          ..quadraticBezierTo(-13, -27, 8, -17)
          ..quadraticBezierTo(18, -12, 19, -2)
          ..quadraticBezierTo(7, -12, 6, -3)
          ..lineTo(15, 12)
          ..close(),
        p..color = const Color(0xFFBE6257),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-20, 9, 38, 10),
          const Radius.circular(5),
        ),
        p..color = CalendarStyle.ivory,
      );
      canvas.drawCircle(const Offset(19, -2), 6, p);
    case FestiveObject.cane:
      final path = Path()
        ..moveTo(-6, 21)
        ..lineTo(-6, -9)
        ..cubicTo(-6, -25, 15, -25, 15, -9);
      canvas.drawPath(
        path,
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..color = CalendarStyle.ivory,
      );
      for (final y in [-9.0, 1.0, 11.0]) {
        canvas.drawLine(
          Offset(-8, y),
          Offset(-4, y + 3),
          p
            ..strokeWidth = 4
            ..color = const Color(0xFFB95753),
        );
      }
      canvas.drawLine(const Offset(4, -19), const Offset(8, -17), p);
  }
  canvas.restore();
}

class OyVeyPainter extends CustomPainter {
  OyVeyPainter(this.game, this.mouth, {required this.visible});
  final OyVeyGame game;
  final CatchMouth? mouth;
  final bool visible;
  @override
  void paint(Canvas canvas, Size size) {
    for (final item in game.objects) {
      final center = Offset(item.x * size.width, item.y * size.height);
      final radius = item.radius * size.width;
      canvas.drawCircle(
        center,
        radius * 1.12,
        Paint()..color = CalendarStyle.ivory.withValues(alpha: .88),
      );
      paintFestiveObject(canvas, center, radius, item.kind);
    }
    if (!visible || mouth == null) return;
    final m = mouth!;
    paintCollectorSack(
      canvas,
      Offset(m.x * size.width, m.y * size.height),
      m.halfWidth * size.width,
      m.halfHeight * size.height,
    );
  }

  @override
  bool shouldRepaint(OyVeyPainter old) => true;
}

/// The rim is the actual collision opening. The soft, wider sack hangs below
/// it; decoration never makes the catch area larger than the visible opening.
void paintCollectorSack(
  Canvas canvas,
  Offset center,
  double halfWidth,
  double halfHeight,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  // Keep the writing legible while the narrow neck matches the catch area.
  final scale = math.max(1.0, halfWidth / 24);
  canvas.scale(scale);
  final rimWidth = halfWidth / scale;
  final rimHeight = halfHeight / scale;
  final p = Paint()..isAntiAlias = true;
  final bag = Path()
    ..moveTo(-rimWidth, 0)
    ..cubicTo(-19, 16, -35, 31, -32, 59)
    ..cubicTo(-30, 82, 28, 86, 34, 62)
    ..cubicTo(39, 35, 18, 15, rimWidth, 0)
    ..close();
  canvas.drawShadow(bag, Colors.black.withValues(alpha: .24), 3, false);
  canvas.drawPath(bag, p..color = const Color(0xFFD8BA83));
  final light = Path()
    ..moveTo(-20, 14)
    ..cubicTo(-18, 33, -31, 61, -18, 68)
    ..cubicTo(-25, 54, -12, 28, -13, 17)
    ..close();
  canvas.drawPath(light, p..color = const Color(0xFFE9D3A8));
  final seam = Path()
    ..moveTo(24, 21)
    ..cubicTo(39, 53, 31, 76, 5, 76);
  canvas.drawPath(
    seam,
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFB28F59),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset.zero,
      width: rimWidth * 2,
      height: rimHeight * 2,
    ),
    p
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF584436),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset.zero,
      width: rimWidth * 2,
      height: rimHeight * 2,
    ),
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFF0DBB1),
  );
  final cord = Path()
    ..moveTo(-25, 12)
    ..quadraticBezierTo(0, 20, 24, 12)
    ..moveTo(23, 12)
    ..cubicTo(36, 2, 39, 21, 23, 16)
    ..cubicTo(39, 20, 37, 32, 28, 25)
    ..moveTo(25, 17)
    ..lineTo(36, 37);
  canvas.drawPath(
    cord,
    p
      ..color = const Color(0xFF5C7866)
      ..strokeWidth = 2,
  );

  void handwriting(
    String text,
    double y,
    double fontSize,
    TextDirection direction,
  ) {
    final label = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF365D67),
          fontSize: fontSize,
          fontFamily: 'sans-serif',
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: direction,
    )..layout();
    label.paint(canvas, Offset(-label.width / 2, y));
    label.dispose();
  }

  canvas.save();
  canvas.rotate(-.07);
  handwriting('Weihnachten', 29, 8.5, TextDirection.ltr);
  // Two wonky pen strokes cross out the original label.
  canvas.drawPath(
    Path()
      ..moveTo(-28, 37)
      ..lineTo(28, 32)
      ..moveTo(-25, 33)
      ..lineTo(26, 38),
    p
      ..color = const Color(0xFFA35248)
      ..strokeWidth = 1.6,
  );
  handwriting('חנוכה', 45, 18, TextDirection.rtl);
  canvas.drawPath(
    Path()
      ..moveTo(-20, 66)
      ..quadraticBezierTo(0, 68, 22, 64),
    p
      ..color = const Color(0xFF365D67)
      ..strokeWidth = 1,
  );
  canvas.restore();
  canvas.restore();
}
