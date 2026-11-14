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
    final m = mouth!,
        x = m.x * size.width,
        y = m.y * size.height,
        w = m.halfWidth * size.width;
    final opening = m.halfHeight * size.height;
    final p = Paint();
    final bag = Path()
      ..moveTo(x - w, y)
      ..cubicTo(
        x - w * .9,
        y + w * .6,
        x - w * 1.2,
        y + w * 1.5,
        x,
        y + w * 1.6,
      )
      ..cubicTo(x + w * 1.2, y + w * 1.5, x + w * .9, y + w * .6, x + w, y)
      ..close();
    canvas.drawShadow(bag, Colors.black.withValues(alpha: .5), 5, false);
    canvas.drawPath(bag, p..color = const Color(0xFFC8A76E));
    canvas.drawPath(
      Path()
        ..moveTo(x - w * .65, y + w * .5)
        ..quadraticBezierTo(x - w * .9, y + w * 1.3, x - w * .15, y + w * 1.4),
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFE8D4A6),
    );
    p.style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y),
        width: w * 2,
        height: math.max(3, opening * 2),
      ),
      p..color = const Color(0xFF584436),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y),
        width: w * 2,
        height: math.max(3, opening * 2),
      ),
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFFEDD7A8),
    );
    canvas.drawPath(
      Path()
        ..moveTo(x + w * .7, y + 5)
        ..quadraticBezierTo(x + w * 1.3, y + w * .3, x + w * .85, y + w * .55),
      p
        ..color = const Color(0xFF67847B)
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(OyVeyPainter old) => true;
}
