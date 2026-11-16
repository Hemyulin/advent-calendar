import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../oy_vey/oy_vey_art.dart';
import '../oy_vey/oy_vey_game.dart';
import 'game_skin_scope.dart';

const hanukkahBlue = Color(0xFF376C91);
const hanukkahGold = Color(0xFFD9AA50);
const hanukkahMotifNames = [
  'Sufganiyah',
  'Chanukkiah',
  'Sevivon',
  'Schekel',
  'Ölkrug',
  'Davidstern',
  'Tempel',
  'Kerze',
];

class HanukkahMotifPainter extends CustomPainter {
  const HanukkahMotifPainter(this.motif);
  final int motif;
  @override
  void paint(Canvas canvas, Size size) => paintHanukkahMotif(
    canvas,
    Rect.fromLTWH(0, 0, size.width, size.height),
    motif,
  );
  @override
  bool shouldRepaint(HanukkahMotifPainter oldDelegate) =>
      oldDelegate.motif != motif;
}

void paintHanukkahMotif(Canvas c, Rect rect, int motif) {
  final center = rect.center;
  final r = rect.shortestSide / 2;
  if (motif < 3) {
    paintFestiveObject(
      c,
      center,
      r * .9,
      [
        FestiveObject.sufganiyah,
        FestiveObject.hanukkiah,
        FestiveObject.dreidel,
      ][motif],
    );
    return;
  }
  c.save();
  c.translate(center.dx, center.dy);
  c.scale(r / 24);
  final p = Paint()..isAntiAlias = true;
  switch (motif) {
    case 3:
      c.drawCircle(Offset.zero, 21, p..color = hanukkahGold);
      c.drawCircle(
        Offset.zero,
        17,
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFF9E3A8),
      );
      final text = TextPainter(
        text: const TextSpan(
          text: '₪',
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'sans-serif',
            color: Color(0xFF916523),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(c, Offset(-text.width / 2, -text.height / 2));
      text.dispose();
    case 4:
      c.drawOval(
        const Rect.fromLTWH(-18, -11, 36, 35),
        p..color = hanukkahBlue,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-9, -24, 18, 19),
          const Radius.circular(3),
        ),
        p,
      );
      c.drawOval(
        const Rect.fromLTWH(7, -13, 21, 25),
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
      c.drawLine(
        const Offset(-9, 4),
        const Offset(9, 4),
        p
          ..color = hanukkahGold
          ..strokeWidth = 3,
      );
      c.drawOval(
        const Rect.fromLTWH(-7, -24, 14, 4),
        p
          ..style = PaintingStyle.fill
          ..color = hanukkahGold,
      );
    case 5:
      const StarOfDavidPainter().paint(
        c..translate(-23, -23),
        const Size(46, 46),
      );
    case 6:
      // Jerusalem's Temple: tall central sanctuary, lower stone wings and
      // broad approach steps. Large shapes stay readable on a memory card.
      const stone = Color(0xFFEBD3A7);
      const edge = Color(0xFFAD8B54);
      c.drawRect(const Rect.fromLTWH(-20, -7, 40, 23), p..color = stone);
      c.drawRect(
        const Rect.fromLTWH(-20, -7, 40, 23),
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = edge,
      );
      c.drawRect(
        const Rect.fromLTWH(-10, -20, 20, 36),
        p
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFF4E4C5),
      );
      c.drawRect(
        const Rect.fromLTWH(-10, -20, 20, 36),
        p
          ..style = PaintingStyle.stroke
          ..color = edge,
      );
      c.drawRect(
        const Rect.fromLTWH(-12, -22, 24, 4),
        p
          ..style = PaintingStyle.fill
          ..color = hanukkahGold,
      );
      c.drawRect(const Rect.fromLTWH(-22, -9, 12, 3), p);
      c.drawRect(const Rect.fromLTWH(10, -9, 12, 3), p);
      c.drawRect(const Rect.fromLTWH(-6, -3, 12, 19), p);
      c.drawRect(
        const Rect.fromLTWH(-3.5, 0, 7, 16),
        p..color = const Color(0xFF65503A),
      );
      for (final side in [-1.0, 1.0]) {
        for (final y in [0.0, 7.0]) {
          c.drawLine(
            Offset(side * 12, y),
            Offset(side * 18, y),
            p
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.3
              ..color = edge,
          );
        }
      }
      c.drawRect(
        const Rect.fromLTWH(-21, 15, 42, 3),
        p
          ..style = PaintingStyle.fill
          ..color = hanukkahGold,
      );
      c.drawRect(const Rect.fromLTWH(-24, 19, 48, 3), p..color = edge);
    case 7:
      paintOilCandle(
        c,
        const Size(48, 60),
        origin: const Offset(-24, -32),
        percent: 65,
        time: 0,
      );
  }
  c.restore();
}

void paintEliyahu(Canvas c, Size size) {
  c.save();
  c.scale(size.width / 40, size.height / 40);
  final p = Paint()..isAntiAlias = true;
  // Long black coat, white shirt, broad-brimmed hat and sidecurls.
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(9, 22, 22, 18),
      const Radius.circular(3),
    ),
    p..color = const Color(0xFF202B32),
  );
  c.drawPath(
    Path()
      ..moveTo(15, 23)
      ..lineTo(20, 33)
      ..lineTo(25, 23)
      ..close(),
    p..color = const Color(0xFFFFF8E9),
  );
  c.drawLine(
    const Offset(20, 30),
    const Offset(20, 39),
    p
      ..color = const Color(0xFF60717A)
      ..strokeWidth = .8,
  );
  c.drawOval(
    const Rect.fromLTWH(11, 12, 18, 19),
    p..color = const Color(0xFFE5C2A0),
  );
  c.drawPath(
    Path()
      ..moveTo(11, 24)
      ..quadraticBezierTo(20, 29, 29, 24)
      ..quadraticBezierTo(29, 34, 20, 37)
      ..quadraticBezierTo(11, 34, 11, 24),
    p..color = const Color(0xFFE8E7DF),
  );
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(11, 1, 18, 13),
      const Radius.circular(2),
    ),
    p..color = const Color(0xFF17232C),
  );
  c.drawLine(
    const Offset(12, 11),
    const Offset(28, 11),
    p
      ..color = const Color(0xFF3B4A54)
      ..strokeWidth = 2,
  );
  c.drawOval(
    const Rect.fromLTWH(3, 12, 34, 5),
    p
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF17232C),
  );
  c.drawPath(
    Path()
      ..moveTo(12, 17)
      ..cubicTo(8, 20, 14, 22, 10, 25)
      ..quadraticBezierTo(8, 28, 12, 28)
      ..moveTo(28, 17)
      ..cubicTo(32, 20, 26, 22, 30, 25)
      ..quadraticBezierTo(32, 28, 28, 28),
    p
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF677074)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round,
  );
  for (final x in [16.0, 24.0]) {
    c.drawOval(
      Rect.fromCenter(center: Offset(x, 21), width: 6, height: 4),
      p
        ..color = const Color(0xFF35434B)
        ..strokeWidth = .7,
    );
  }
  c.drawLine(const Offset(19, 21), const Offset(21, 21), p);
  c.drawCircle(const Offset(16, 21), .7, p..style = PaintingStyle.fill);
  c.drawCircle(const Offset(24, 21), .7, p);
  c.restore();
}

/// A small sculpted clay guardian inspired by the Prague golem.
void paintPragueGolem(Canvas c, Size size, {Offset gaze = Offset.zero}) {
  c.save();
  c.scale(size.width / 100, size.height / 100);
  final p = Paint()..isAntiAlias = true;
  const clay = Color(0xFFB68A69),
      shade = Color(0xFF8D654E),
      light = Color(0xFFD3AE8D),
      groove = Color(0xFF765540);
  void block(Rect rect, Color color, double radius) => c.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(radius)),
    p..color = color,
  );
  c.drawOval(
    const Rect.fromLTWH(15, 85, 70, 10),
    p..color = const Color(0xFFD1C1A6),
  );
  block(const Rect.fromLTWH(29, 77, 19, 16), shade, 4);
  block(const Rect.fromLTWH(53, 77, 19, 16), shade, 4);
  block(const Rect.fromLTWH(13, 54, 18, 31), shade, 6);
  block(const Rect.fromLTWH(69, 54, 18, 31), shade, 6);
  block(const Rect.fromLTWH(22, 50, 56, 35), clay, 8);
  block(const Rect.fromLTWH(25, 54, 5, 22), light, 2);
  final head = Path()
    ..moveTo(27, 15)
    ..lineTo(72, 15)
    ..lineTo(81, 24)
    ..lineTo(78, 49)
    ..lineTo(68, 59)
    ..lineTo(32, 59)
    ..lineTo(21, 49)
    ..lineTo(19, 25)
    ..close();
  c.drawPath(head, p..color = clay);
  c.drawPath(
    Path()
      ..moveTo(27, 15)
      ..lineTo(72, 15)
      ..lineTo(77, 21)
      ..lineTo(24, 21)
      ..close(),
    p..color = light,
  );
  c.drawPath(
    Path()
      ..moveTo(72, 21)
      ..lineTo(81, 24)
      ..lineTo(78, 49)
      ..lineTo(68, 59)
      ..lineTo(65, 54)
      ..lineTo(72, 45)
      ..close(),
    p..color = shade,
  );
  // Engraved אמת, rendered as text so the Hebrew spelling remains intact.
  final inscription = TextPainter(
    text: const TextSpan(
      text: 'אמת',
      style: TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: groove,
      ),
    ),
    textDirection: TextDirection.rtl,
  )..layout();
  inscription.paint(c, Offset(49 - inscription.width / 2, 21));
  inscription.dispose();
  for (final x in [37.0, 62.0]) {
    block(Rect.fromLTWH(x - 7, 37, 14, 8), groove, 3);
    c.drawCircle(
      Offset(x + gaze.dx * 1.5, 41 + gaze.dy),
      2.5,
      p..color = const Color(0xFFF2D990),
    );
  }
  c.drawLine(
    const Offset(42, 51),
    const Offset(57, 51),
    p
      ..color = groove
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round,
  );
  c.drawPath(
    Path()
      ..moveTo(31, 26)
      ..lineTo(27, 30)
      ..lineTo(30, 34)
      ..moveTo(64, 65)
      ..lineTo(60, 70)
      ..lineTo(64, 75),
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = shade,
  );
  c.drawPath(
    Path()
      ..moveTo(41, 65)
      ..lineTo(50, 61)
      ..lineTo(59, 65)
      ..lineTo(59, 76)
      ..lineTo(41, 76)
      ..close(),
    p
      ..color = groove
      ..strokeWidth = 1.2,
  );
  c.restore();
}

/// Faceted painted wooden dreidels, with a handle, Hebrew face and pointed tip.
void paintWorkshopDreidel(Canvas c, Size size, {int variant = 0}) {
  c.save();
  c.scale(size.width / 100, size.height / 100);
  final p = Paint()..isAntiAlias = true;
  final color = const [
    hanukkahBlue,
    Color(0xFF528377),
    Color(0xFFB78C4A),
    Color(0xFF9B7187),
  ][variant % 4];
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(45, 10, 11, 23),
      const Radius.circular(3),
    ),
    p..color = const Color(0xFFC89F64),
  );
  c.drawPath(
    Path()
      ..moveTo(22, 35)
      ..lineTo(50, 24)
      ..lineTo(78, 35)
      ..lineTo(50, 46)
      ..close(),
    p..color = Color.lerp(color, Colors.white, .28)!,
  );
  c.drawPath(
    Path()
      ..moveTo(22, 35)
      ..lineTo(50, 46)
      ..lineTo(50, 74)
      ..lineTo(22, 63)
      ..close(),
    p..color = color,
  );
  c.drawPath(
    Path()
      ..moveTo(50, 46)
      ..lineTo(78, 35)
      ..lineTo(78, 63)
      ..lineTo(50, 74)
      ..close(),
    p..color = Color.lerp(color, Colors.black, .2)!,
  );
  c.drawPath(
    Path()
      ..moveTo(22, 63)
      ..lineTo(50, 74)
      ..lineTo(78, 63)
      ..lineTo(50, 91)
      ..close(),
    p..color = Color.lerp(color, Colors.black, .1)!,
  );
  // A carved נ on the light-facing side, drawn natively at small tile sizes.
  c.drawPath(
    Path()
      ..moveTo(35, 47)
      ..lineTo(40, 49)
      ..lineTo(40, 61)
      ..lineTo(30, 57),
    p
      ..color = const Color(0xFFF8E6B5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  c.restore();
}

void paintOilCandle(
  Canvas c,
  Size size, {
  Offset origin = Offset.zero,
  required double percent,
  required double time,
  bool filling = false,
  bool dead = false,
  int index = 0,
}) {
  c.save();
  final scale = math.min(size.width / 100, size.height / 110);
  c.translate(
    origin.dx + (size.width - 100 * scale) / 2,
    origin.dy + (size.height - 110 * scale) / 2,
  );
  c.scale(scale);
  final p = Paint()..isAntiAlias = true;
  final color = [
    hanukkahBlue,
    const Color(0xFFAA8091),
    const Color(0xFF699590),
    const Color(0xFFC08A4A),
    const Color(0xFF7081A1),
  ][index % 5];
  c.drawOval(
    const Rect.fromLTWH(17, 96, 66, 8),
    p..color = const Color(0xFFDAD1B9),
  );
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(28, 42, 44, 52),
      const Radius.circular(8),
    ),
    p..color = color.withValues(alpha: .2),
  );
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(
        31,
        91 - (percent / 100).clamp(.04, 1) * 44,
        38,
        (percent / 100).clamp(.04, 1) * 44,
      ),
      const Radius.circular(5),
    ),
    p..color = hanukkahGold.withValues(alpha: .85),
  );
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(27, 42, 46, 52),
      const Radius.circular(8),
    ),
    p
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = 3,
  );
  c.drawOval(
    const Rect.fromLTWH(25, 38, 50, 12),
    p
      ..style = PaintingStyle.fill
      ..color = color,
  );
  c.drawLine(
    const Offset(50, 39),
    const Offset(50, 29),
    p
      ..color = const Color(0xFF60513E)
      ..strokeWidth = 3,
  );
  if (!dead) {
    final sway = math.sin(time * 7 + index) * 3;
    c.drawPath(
      Path()
        ..moveTo(50, 33)
        ..cubicTo(25, 24, 49 + sway, 5, 51 + sway, 0)
        ..cubicTo(51 + sway, 13, 72, 26, 50, 33),
      p..color = hanukkahGold,
    );
    c.drawOval(
      const Rect.fromLTWH(44, 18, 12, 15),
      p..color = const Color(0xFFFFE8A3),
    );
  }
  if (filling) {
    c.drawLine(
      const Offset(77, 22),
      const Offset(67, 43),
      p
        ..color = hanukkahGold
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }
  c.restore();
}

class OilCandlePainter extends CustomPainter {
  const OilCandlePainter({
    required this.percent,
    required this.time,
    required this.index,
    this.filling = false,
    this.dead = false,
  });
  final double percent, time;
  final int index;
  final bool filling, dead;
  @override
  void paint(Canvas canvas, Size size) => paintOilCandle(
    canvas,
    size,
    percent: percent,
    time: time,
    index: index,
    filling: filling,
    dead: dead,
  );
  @override
  bool shouldRepaint(OilCandlePainter oldDelegate) => true;
}

class OilJugPainter extends CustomPainter {
  const OilJugPainter();
  @override
  void paint(Canvas canvas, Size size) => paintHanukkahMotif(
    canvas,
    Rect.fromLTWH(0, 0, size.width, size.height),
    4,
  );
  @override
  bool shouldRepaint(OilJugPainter oldDelegate) => false;
}

class OilSupplyPainter extends CustomPainter {
  const OilSupplyPainter({required this.end, required this.visible});
  final Offset end;
  final bool visible;
  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) return;
    canvas.save();
    canvas.translate(end.dx, end.dy - 14);
    canvas.rotate(-.35);
    paintHanukkahMotif(canvas, const Rect.fromLTWH(-17, -20, 34, 34), 4);
    canvas.restore();
  }

  @override
  bool shouldRepaint(OilSupplyPainter oldDelegate) =>
      end != oldDelegate.end || visible != oldDelegate.visible;
}

class OilLevelPainter extends CustomPainter {
  const OilLevelPainter({required this.percent});
  final double percent;
  @override
  void paint(Canvas canvas, Size size) {
    final outline = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(6),
    );
    final p = Paint()..color = hanukkahGold.withValues(alpha: .2);
    canvas.drawRRect(outline, p);
    canvas.save();
    canvas.clipRRect(outline);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        size.width * (percent / 100).clamp(.02, 1),
        size.height,
      ),
      p..color = hanukkahGold,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(OilLevelPainter oldDelegate) =>
      percent != oldDelegate.percent;
}
