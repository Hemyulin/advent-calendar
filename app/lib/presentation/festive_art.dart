import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'calendar_style.dart';

enum DoorMotif {
  reindeer,
  hat,
  present,
  candyCane,
  mitten,
  tree,
  bell,
  star,
  boot,
}

/// Storybook illustrations and rotating colours give the days their own
/// character, with a special Nikolaus boot for day six.
class DoorDesign {
  DoorDesign.forDay(int day)
    : motif = day == 6 ? DoorMotif.boot : DoorMotif.values[(day - 1) % 8],
      color = _colors[((day - 1) % 8 + (day - 1) ~/ 8) % _colors.length];

  static const _colors = [
    Color(0xFFB94F46),
    Color(0xFF477F96),
    Color(0xFFA84E6B),
    Color(0xFF387A67),
    Color(0xFF99623C),
  ];

  final DoorMotif motif;
  final Color color;
}

/// Small, flat storybook ornaments, drawn in a 100 × 100 coordinate space.
void paintOrnament(Canvas canvas, DoorMotif motif) {
  const cream = Color(0xFFFFF4DA);
  const red = Color(0xFFEF8774);
  const gold = Color(0xFFF1C665);
  const dark = Color(0xFF4D4236);
  final paint = Paint()..isAntiAlias = true;

  void line(Offset a, Offset b, Color color, double width) {
    canvas.drawLine(
      a,
      b,
      paint
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void oval(Rect bounds, Color color) {
    canvas.drawOval(
      bounds,
      paint
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void path(Path path, Color color) {
    canvas.drawPath(
      path,
      paint
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void box(Rect rect, Color color, double radius) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      paint
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  switch (motif) {
    case DoorMotif.reindeer:
      for (final mirror in [false, true]) {
        canvas.save();
        if (mirror) {
          canvas.translate(100, 0);
          canvas.scale(-1, 1);
        }
        line(const Offset(33, 42), const Offset(25, 12), gold, 4);
        line(const Offset(28, 24), const Offset(15, 18), gold, 4);
        line(const Offset(27, 21), const Offset(34, 12), gold, 4);
        oval(const Rect.fromLTWH(15, 39, 23, 12), const Color(0xFFDCA568));
        canvas.restore();
      }
      oval(const Rect.fromLTWH(28, 31, 44, 56), const Color(0xFFE6B778));
      oval(const Rect.fromLTWH(35, 58, 30, 27), cream);
      oval(const Rect.fromLTWH(35, 49, 4, 5), dark);
      oval(const Rect.fromLTWH(61, 49, 4, 5), dark);
      oval(const Rect.fromLTWH(43, 62, 14, 11), red);
      box(const Rect.fromLTWH(33, 83, 34, 7), red, 3);
    case DoorMotif.hat:
      path(
        Path()
          ..moveTo(22, 70)
          ..quadraticBezierTo(28, 15, 62, 18)
          ..quadraticBezierTo(88, 20, 82, 49)
          ..quadraticBezierTo(67, 34, 58, 38)
          ..lineTo(70, 70)
          ..close(),
        red,
      );
      path(
        Path()
          ..moveTo(35, 64)
          ..quadraticBezierTo(37, 34, 57, 25)
          ..quadraticBezierTo(43, 42, 45, 65)
          ..close(),
        const Color(0xFFF7A38B),
      );
      box(const Rect.fromLTWH(17, 64, 59, 17), cream, 8);
      oval(const Rect.fromLTWH(73, 42, 19, 19), cream);
    case DoorMotif.present:
      box(const Rect.fromLTWH(20, 37, 60, 49), red, 5);
      box(const Rect.fromLTWH(16, 32, 68, 15), const Color(0xFFF4A28C), 4);
      box(const Rect.fromLTWH(44, 32, 12, 54), gold, 1);
      for (final mirror in [false, true]) {
        canvas.save();
        if (mirror) {
          canvas.translate(100, 0);
          canvas.scale(-1, 1);
        }
        canvas.drawPath(
          Path()
            ..moveTo(50, 32)
            ..cubicTo(13, 35, 25, 5, 41, 20)
            ..close(),
          paint
            ..color = gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5,
        );
        canvas.restore();
      }
      paint.style = PaintingStyle.fill;
      oval(const Rect.fromLTWH(59, 55, 4, 4), cream);
      oval(const Rect.fromLTWH(29, 68, 4, 4), cream);
    case DoorMotif.candyCane:
      canvas.save();
      canvas.translate(12, -7);
      canvas.rotate(0.2);
      final cane = Path()
        ..moveTo(44, 91)
        ..lineTo(44, 33)
        ..cubicTo(44, 8, 79, 8, 79, 34);
      canvas.drawPath(
        cane,
        paint
          ..color = cream
          ..style = PaintingStyle.stroke
          ..strokeWidth = 15
          ..strokeCap = StrokeCap.round,
      );
      for (var y = 43.0; y < 88; y += 17) {
        line(Offset(39, y), Offset(49, y - 6), red, 6);
      }
      line(const Offset(49, 20), const Offset(57, 27), red, 6);
      line(const Offset(70, 19), const Offset(69, 29), red, 6);
      canvas.restore();
      paint.style = PaintingStyle.fill;
      path(
        Path()
          ..moveTo(43, 60)
          ..lineTo(25, 48)
          ..lineTo(24, 70)
          ..close(),
        gold,
      );
      path(
        Path()
          ..moveTo(43, 60)
          ..lineTo(60, 49)
          ..lineTo(62, 70)
          ..close(),
        gold,
      );
      oval(const Rect.fromLTWH(37, 55, 10, 10), cream);
    case DoorMotif.mitten:
      path(
        Path()
          ..moveTo(33, 79)
          ..lineTo(24, 49)
          ..cubicTo(14, 28, 30, 27, 35, 43)
          ..lineTo(35, 27)
          ..cubicTo(35, 4, 71, 4, 73, 30)
          ..lineTo(74, 61)
          ..quadraticBezierTo(73, 79, 59, 82)
          ..close(),
        red,
      );
      box(const Rect.fromLTWH(30, 76, 38, 14), cream, 4);
      line(const Offset(55, 38), const Offset(55, 62), cream, 2);
      line(const Offset(44, 44), const Offset(66, 56), cream, 2);
      line(const Offset(44, 56), const Offset(66, 44), cream, 2);
    case DoorMotif.tree:
      box(const Rect.fromLTWH(45, 72, 10, 17), gold, 2);
      path(
        Path()
          ..moveTo(50, 15)
          ..lineTo(22, 51)
          ..lineTo(34, 51)
          ..lineTo(15, 77)
          ..lineTo(85, 77)
          ..lineTo(66, 51)
          ..lineTo(78, 51)
          ..close(),
        const Color(0xFFAED1A5),
      );
      line(const Offset(33, 49), const Offset(64, 61), cream, 2);
      oval(const Rect.fromLTWH(45, 34, 7, 7), red);
      oval(const Rect.fromLTWH(32, 63, 7, 7), gold);
      oval(const Rect.fromLTWH(63, 66, 7, 7), red);
      paintStar(canvas, const Offset(50, 13), 8, gold);
    case DoorMotif.bell:
      oval(const Rect.fromLTWH(43, 76, 14, 14), gold);
      path(
        Path()
          ..moveTo(19, 74)
          ..quadraticBezierTo(30, 66, 30, 43)
          ..cubicTo(30, 15, 70, 15, 70, 43)
          ..quadraticBezierTo(70, 66, 81, 74)
          ..close(),
        gold,
      );
      box(const Rect.fromLTWH(19, 70, 62, 9), cream, 4);
      path(
        Path()
          ..moveTo(50, 23)
          ..quadraticBezierTo(20, 3, 24, 23)
          ..quadraticBezierTo(33, 35, 50, 23)
          ..quadraticBezierTo(80, 3, 76, 23)
          ..quadraticBezierTo(67, 35, 50, 23),
        red,
      );
      line(const Offset(36, 46), const Offset(35, 58), cream, 3);
    case DoorMotif.boot:
      path(
        Path()
          ..moveTo(27, 22)
          ..lineTo(56, 22)
          ..lineTo(57, 57)
          ..cubicTo(91, 54, 93, 83, 77, 86)
          ..lineTo(24, 86)
          ..quadraticBezierTo(17, 82, 23, 67)
          ..close(),
        red,
      );
      box(const Rect.fromLTWH(23, 17, 37, 14), cream, 4);
      box(const Rect.fromLTWH(23, 80, 58, 8), gold, 3);
      line(const Offset(34, 43), const Offset(49, 47), cream, 2);
      line(const Offset(34, 54), const Offset(49, 58), cream, 2);
      paintStar(canvas, const Offset(76, 28), 9, gold);
    case DoorMotif.star:
      paintStar(canvas, const Offset(50, 49), 37, gold);
      paintStar(canvas, const Offset(50, 49), 25, const Color(0xFFFFDB85));
      oval(const Rect.fromLTWH(38, 44, 4, 5), dark);
      oval(const Rect.fromLTWH(58, 44, 4, 5), dark);
      canvas.drawArc(
        const Rect.fromLTWH(44, 49, 12, 10),
        0,
        math.pi,
        false,
        paint
          ..color = dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      paint.style = PaintingStyle.fill;
  }
}

void paintStar(Canvas canvas, Offset center, double radius, Color color) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final angle = -math.pi / 2 + i * math.pi / 5;
    final r = i.isEven ? radius : radius * 0.46;
    final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  canvas.drawPath(path..close(), Paint()..color = color);
}

/// A little drooping string of warm fairy lights.
void paintFairyLights(Canvas canvas, double width) {
  final wire = Path()
    ..moveTo(8, 16)
    ..quadraticBezierTo(width / 2, 61, width - 8, 16);
  canvas.drawPath(
    wire,
    Paint()
      ..color = CalendarStyle.gold.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
  for (var i = 0; i < 9; i++) {
    final t = (i + 0.5) / 9;
    final x = 8 + (width - 16) * t;
    final y = 16 + 90 * t * (1 - t);
    canvas.drawLine(
      Offset(x, y),
      Offset(x, y + 6),
      Paint()
        ..color = CalendarStyle.gold
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      Offset(x, y + 8),
      9,
      Paint()..color = const Color(0xFFF7CB6B).withValues(alpha: 0.13),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 8), width: 4, height: 6),
      Paint()
        ..color = i.isEven ? const Color(0xFFFFD477) : const Color(0xFFECAD83),
    );
  }
}
