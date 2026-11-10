import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../presentation/calendar_style.dart';
import 'walk_game.dart';

class BalancePainter extends CustomPainter {
  BalancePainter(this.lean, this.danger);
  final double lean, danger;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(12, size.height / 2),
      Offset(size.width - 12, size.height / 2),
      p
        ..color = CalendarStyle.line
        ..strokeWidth = 5,
    );
    canvas.drawLine(
      Offset(size.width / 2, 3),
      Offset(size.width / 2, size.height - 3),
      p
        ..color = CalendarStyle.green.withValues(alpha: .3)
        ..strokeWidth = 1.5,
    );
    final x = size.width / 2 + lean.clamp(-1.0, 1.0) * (size.width / 2 - 14);
    canvas.drawCircle(
      Offset(x, size.height / 2),
      7,
      p..color = danger > 0 ? const Color(0xFFBD6B58) : CalendarStyle.green,
    );
  }

  @override
  bool shouldRepaint(BalancePainter old) =>
      old.lean != lean || old.danger != danger;
}

class WinterStreetPainter extends CustomPainter {
  WinterStreetPainter(
    this.game,
    this.ending, {
    required this.reducedMotion,
    this.nightMode = true,
  });
  final WalkGame game;
  final double ending;
  final bool reducedMotion;
  final bool nightMode;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    final w = size.width, h = size.height;
    canvas.drawColor(
      nightMode ? const Color(0xFF283D51) : const Color(0xFFDCEBF0),
      BlendMode.src,
    );
    canvas.save();
    if (!reducedMotion) {
      canvas.translate(w / 2, h / 2);
      canvas.rotate(
        (math.sin(game.elapsed * 1.4) * .012 + game.lean * .012).clamp(
          -.028,
          .028,
        ),
      );
      canvas.translate(-w / 2, -h / 2);
    }
    canvas.drawCircle(
      Offset(w * .79, h * .1),
      17,
      p..color = nightMode ? const Color(0xFFFFF4CB) : const Color(0xFFF2CC77),
    );
    if (nightMode) {
      for (final star in [
        const Offset(.12, .06),
        const Offset(.38, .12),
        const Offset(.59, .04),
      ]) {
        canvas.drawCircle(
          Offset(w * star.dx, h * star.dy),
          1.4,
          p..color = const Color(0xFFE9DEBA),
        );
      }
    }
    // Snow-covered town silhouettes stay restrained while the road scrolls.
    for (var i = 0; i < 6; i++) {
      final x = (i - 1) * w * .23, y = h * (.14 + (i % 2) * .025);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w * .18, h * .16),
          const Radius.circular(3),
        ),
        p
          ..color = nightMode
              ? (i.isEven ? const Color(0xFF526B74) : const Color(0xFF617582))
              : (i.isEven ? const Color(0xFFB5C8C1) : const Color(0xFFB9C9CB)),
      );
      canvas.drawPath(
        Path()
          ..moveTo(x - 4, y)
          ..lineTo(x + w * .09, y - h * .045)
          ..lineTo(x + w * .18 + 4, y)
          ..close(),
        p
          ..color = nightMode
              ? const Color(0xFFB8CBD0)
              : const Color(0xFFF4F1E4),
      );
      canvas.drawRect(
        Rect.fromLTWH(x + w * .05, y + h * .025, w * .04, h * .04),
        p..color = const Color(0xFFEFDCAF),
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(-w * .1, h * .29, w * 1.2, h),
      p..color = nightMode ? const Color(0xFFB0C3CC) : const Color(0xFFF1F1E6),
    );
    final nearHalf = w * .43 * game.level.halfWidth, farHalf = nearHalf * .16;
    // Match the visible verge to the physics boundary at the character's feet.
    final bottomHalf = farHalf + (nearHalf - farHalf) * .81 / .53;
    final road = Path()
      ..moveTo(w / 2 - farHalf, h * .29)
      ..lineTo(w / 2 + farHalf, h * .29)
      ..lineTo(w / 2 + bottomHalf, h * 1.1)
      ..lineTo(w / 2 - bottomHalf, h * 1.1)
      ..close();
    canvas.drawPath(
      road,
      p..color = nightMode ? const Color(0xFF71878B) : const Color(0xFFB8C5BE),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w / 2 - farHalf, h * .29)
        ..lineTo(w / 2 - bottomHalf, h * 1.1)
        ..moveTo(w / 2 + farHalf, h * .29)
        ..lineTo(w / 2 + bottomHalf, h * 1.1),
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFFFFF9E8),
    );
    p.style = PaintingStyle.fill;
    // Pavement seams move towards the viewer, providing forward motion cues.
    final scroll = (game.elapsed * .38) % 1;
    for (var i = 0; i < 10; i++) {
      final t = ((i / 10 + scroll) % 1), depth = math.pow(t, 1.7).toDouble();
      final y = h * (.29 + .82 * depth),
          half = farHalf + (bottomHalf - farHalf) * depth;
      canvas.drawLine(
        Offset(w / 2 - half, y),
        Offset(w / 2 + half, y),
        p
          ..color = nightMode
              ? const Color(0xFF657D82)
              : const Color(0xFFAAB9B0)
          ..strokeWidth = 1,
      );
    }
    final random = math.Random(2412);
    for (var i = 0; i < 28; i++) {
      final x = random.nextDouble() * w,
          y = (random.nextDouble() * h + game.elapsed * 7) % h;
      canvas.drawCircle(
        Offset(x, y),
        1 + random.nextDouble(),
        p..color = const Color(0xFFFFFCF2).withValues(alpha: .7),
      );
    }
    // Street lamps approach and pass along the snowy verges.
    for (var i = 0; i < 5; i++) {
      final depth = ((i / 5 + game.elapsed * .065) % 1);
      final y = h * (.28 + .8 * depth * depth), scale = .18 + .82 * depth;
      for (final side in [-1.0, 1.0]) {
        final x = w / 2 + side * (nearHalf * 1.35 * depth + farHalf);
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y - 65 * scale),
          p
            ..color = const Color(0xFF6B8477)
            ..strokeWidth = 3 * scale,
        );
        canvas.drawCircle(
          Offset(x, y - 67 * scale),
          8 * scale,
          p..color = const Color(0xFFE8C77D),
        );
        canvas.drawCircle(
          Offset(x, y - 67 * scale),
          (nightMode ? 21 : 14) * scale,
          p
            ..color = const Color(
              0xFFF5DA94,
            ).withValues(alpha: nightMode ? .24 : .09),
        );
      }
    }
    if (game.remaining < 7 || game.phase == WalkPhase.home) {
      _house(canvas, size, ((7 - game.remaining) / 7).clamp(0.0, 1.0));
    }
    for (final obstacle in game.obstacles.reversed) {
      final away = obstacle.at - game.elapsed;
      if (away > 5 || away < -.65) continue;
      final depth = (1 - away / 5).clamp(0.0, 1.15);
      final perspective = .15 + .85 * depth;
      final foot = Offset(
        w / 2 + obstacle.x * w * .43 * perspective,
        h * (.29 + .53 * math.pow(depth, 1.6)),
      );
      _obstacle(canvas, foot, perspective * w / 350, obstacle);
    }
    var hero = Offset(w / 2 + game.x * w * .43, h * .82);
    var scale = w / 350;
    var angle = (game.lean * .55).clamp(-1.0, 1.0);
    if (game.phase == WalkPhase.home) {
      hero = Offset(
        hero.dx + (w / 2 - hero.dx) * ending,
        h * (.82 - .12 * ending),
      );
      scale *= 1 - ending * .45;
      angle *= 1 - ending;
    }
    if (game.phase == WalkPhase.fallen) {
      angle += (game.lean >= 0 ? 1 : -1) * ending * 1.2;
      hero += Offset(0, ending * 12);
    }
    _character(
      canvas,
      hero,
      scale,
      angle,
      game.elapsed,
      game.phase == WalkPhase.walking && !reducedMotion,
    );
    if (game.phase == WalkPhase.fallen) {
      for (var i = 0; i < 5; i++) {
        canvas.drawCircle(
          hero + Offset((i - 2) * 11 * ending, -5 - i % 2 * 9),
          5 * ending,
          p..color = const Color(0xFFFFFCF1),
        );
      }
      _label(canvas, 'Ups!', Offset(w / 2, h * .2));
    } else if (game.impactLeft > 0 && game.phase == WalkPhase.walking) {
      _label(canvas, game.feedback, Offset(w / 2, h * .16));
    }
    canvas.restore();
  }

  void _label(Canvas canvas, String text, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: CalendarStyle.green,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: tp.width + 24, height: 32),
        const Radius.circular(16),
      ),
      Paint()..color = CalendarStyle.ivory.withValues(alpha: .94),
    );
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _house(Canvas canvas, Size size, double t) {
    final w = size.width, h = size.height, p = Paint();
    final scale = .22 + t * .78,
        base = h * (.3 + t * .53),
        width = w * .6 * scale,
        height = h * .32 * scale;
    final rect = Rect.fromLTWH(w / 2 - width / 2, base - height, width, height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      p..color = const Color(0xFFBD9680),
    );
    canvas.drawPath(
      Path()
        ..moveTo(rect.left - 10 * scale, rect.top)
        ..lineTo(w / 2, rect.top - height * .5)
        ..lineTo(rect.right + 10 * scale, rect.top)
        ..close(),
      p..color = const Color(0xFF557666),
    );
    canvas.drawLine(
      Offset(rect.left - 8 * scale, rect.top),
      Offset(w / 2, rect.top - height * .5),
      p
        ..color = const Color(0xFFFFF5DF)
        ..strokeWidth = 5 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          w / 2 - width * .12,
          base - height * .58,
          width * .24,
          height * .58,
        ),
        Radius.circular(4 * scale),
      ),
      p..color = const Color(0xFFF4D38A),
    );
    for (final side in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(w / 2 + side * width * .31, base - height * .5),
            width: width * .16,
            height: height * .27,
          ),
          const Radius.circular(3),
        ),
        p..color = const Color(0xFFEBCB8F),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, base + 2),
        width: width * .5,
        height: 15 * scale,
      ),
      p..color = const Color(0xFFF9E5B5).withValues(alpha: .6),
    );
  }

  void _obstacle(Canvas canvas, Offset foot, double scale, StreetObstacle o) {
    canvas.save();
    canvas.translate(foot.dx, foot.dy);
    canvas.scale(scale);
    final p = Paint();
    if (o.kind != StreetObstacleKind.ice) {
      canvas.drawOval(
        const Rect.fromLTWH(-25, -4, 50, 10),
        p..color = const Color(0xFF8D9F96).withValues(alpha: .35),
      );
    }
    switch (o.kind) {
      case StreetObstacleKind.snowman:
        canvas.drawCircle(
          const Offset(0, -18),
          18,
          p..color = const Color(0xFFFFF9E9),
        );
        canvas.drawCircle(const Offset(0, -43), 12, p);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-13, -35, 26, 5),
            const Radius.circular(2),
          ),
          p..color = const Color(0xFFB76C5C),
        );
        canvas.drawRect(const Rect.fromLTWH(4, -35, 5, 14), p);
        canvas.drawPath(
          Path()
            ..moveTo(2, -43)
            ..lineTo(16, -40)
            ..lineTo(2, -39)
            ..close(),
          p..color = const Color(0xFFD39C5F),
        );
        canvas.drawCircle(
          const Offset(-4, -46),
          1.4,
          p..color = CalendarStyle.green,
        );
        canvas.drawCircle(const Offset(2, -17), 2, p);
        canvas.drawCircle(const Offset(2, -25), 2, p);
      case StreetObstacleKind.bicycle:
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFF567466);
        canvas.drawCircle(const Offset(-23, -12), 12, p);
        canvas.drawCircle(const Offset(23, -12), 12, p);
        canvas.drawPath(
          Path()
            ..moveTo(-23, -12)
            ..lineTo(-7, -33)
            ..lineTo(5, -12)
            ..close()
            ..moveTo(-7, -33)
            ..lineTo(15, -33)
            ..lineTo(5, -12)
            ..moveTo(15, -33)
            ..lineTo(23, -12)
            ..moveTo(15, -33)
            ..lineTo(14, -42)
            ..lineTo(23, -42),
          p,
        );
        canvas.drawLine(
          const Offset(-14, -35),
          const Offset(-2, -35),
          p..color = const Color(0xFF9C7152),
        );
      case StreetObstacleKind.bin:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-16, -43, 32, 41),
            const Radius.circular(4),
          ),
          p..color = const Color(0xFF879995),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-20, -47, 40, 7),
            const Radius.circular(3),
          ),
          p..color = const Color(0xFF5B7770),
        );
        canvas.drawLine(
          const Offset(-8, -32),
          const Offset(-8, -10),
          p
            ..color = const Color(0xFFBBC9BC)
            ..strokeWidth = 2,
        );
        canvas.drawLine(const Offset(8, -32), const Offset(8, -10), p);
      case StreetObstacleKind.reveller:
        // Reclining partygoer: bent legs, scarf, closed eyes and a discarded cup.
        p
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 8
          ..color = const Color(0xFF43584F);
        canvas.drawPath(
          Path()
            ..moveTo(8, -9)
            ..lineTo(23, -18)
            ..lineTo(33, -6)
            ..moveTo(8, -5)
            ..lineTo(23, -3)
            ..lineTo(34, 2),
          p,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-17, -18, 32, 18),
            const Radius.circular(8),
          ),
          p
            ..style = PaintingStyle.fill
            ..color = const Color(0xFFAD6E65),
        );
        canvas.drawLine(
          const Offset(-8, -12),
          const Offset(6, -24),
          p..strokeWidth = 7,
        );
        canvas.drawCircle(
          const Offset(-25, -14),
          10,
          p..color = const Color(0xFFE6C5A2),
        );
        canvas.drawArc(
          const Rect.fromLTWH(-35, -24, 20, 17),
          math.pi,
          math.pi,
          false,
          p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..color = const Color(0xFF597A72),
        );
        canvas.drawLine(
          const Offset(-27, -13),
          const Offset(-22, -13),
          p
            ..strokeWidth = 1.5
            ..color = const Color(0xFF4A544F),
        );
        canvas.drawLine(
          const Offset(-16, -18),
          const Offset(-12, -4),
          p
            ..strokeWidth = 4
            ..color = const Color(0xFFE7BE71),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(23, -32, 9, 10),
            const Radius.circular(2),
          ),
          p
            ..style = PaintingStyle.fill
            ..color = const Color(0xFFAD6E65),
        );
        final snooze = TextPainter(
          text: const TextSpan(
            text: 'Z z',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF43584F),
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        snooze.paint(canvas, const Offset(-35, -43));
      case StreetObstacleKind.ice:
        canvas.drawOval(
          const Rect.fromLTWH(-34, -9, 68, 18),
          p..color = const Color(0xFFA3C9CD),
        );
        canvas.drawOval(
          const Rect.fromLTWH(-27, -7, 52, 12),
          p..color = const Color(0xFFCBE3DF),
        );
        canvas.drawLine(
          const Offset(-18, -2),
          const Offset(-3, -5),
          p
            ..color = CalendarStyle.ivory
            ..strokeWidth = 2,
        );
        canvas.drawLine(const Offset(4, 3), const Offset(17, 0), p);
    }
    canvas.restore();
  }

  void _character(
    Canvas canvas,
    Offset foot,
    double scale,
    double lean,
    double time,
    bool moving,
  ) {
    canvas.save();
    canvas.translate(foot.dx, foot.dy);
    canvas.scale(scale);
    canvas.drawOval(
      const Rect.fromLTWH(-18, -4, 36, 9),
      Paint()..color = const Color(0xFF6F8275).withValues(alpha: .3),
    );
    canvas.rotate(lean);
    final gait = moving ? math.sin(time * 9) * 4 : 0.0,
        p = Paint()..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-8, -19),
      Offset(-10, -1 + gait),
      p
        ..color = const Color(0xFF43584F)
        ..strokeWidth = 10,
    );
    canvas.drawLine(Offset(8, -19), Offset(10, -1 - gait), p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-19, -60, 38, 43),
        const Radius.circular(12),
      ),
      p..color = const Color(0xFFB66D61),
    );
    canvas.drawLine(
      const Offset(-16, -51),
      Offset(-28, -32 - gait),
      p
        ..color = const Color(0xFFB66D61)
        ..strokeWidth = 10,
    );
    canvas.drawLine(const Offset(16, -51), Offset(28, -32 + gait), p);
    canvas.drawCircle(
      const Offset(0, -68),
      13,
      p..color = const Color(0xFFE3BF9B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-17, -60, 34, 8),
        const Radius.circular(3),
      ),
      p..color = CalendarStyle.green,
    );
    canvas.drawPath(
      Path()
        ..moveTo(13, -57)
        ..quadraticBezierTo(24, -43, 18, -34),
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    final hairSway = moving && !reducedMotion
        ? math.sin(time * 9 + .7) * 1.5
        : 0.0;
    canvas.drawPath(
      Path()
        ..moveTo(-14, -63)
        ..cubicTo(-21, -89, 19, -91, 16, -65)
        ..quadraticBezierTo(15 + hairSway, -54, 20 + hairSway, -48)
        ..quadraticBezierTo(9, -43, 1, -48)
        ..quadraticBezierTo(-9, -43, -19 + hairSway, -48)
        ..quadraticBezierTo(-14 + hairSway, -56, -14, -63)
        ..close(),
      p
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFE5BC65),
    );
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFF6D88F);
    for (final side in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(side * 7, -78)
          ..quadraticBezierTo(side * 13, -65, side * 11 + hairSway, -51),
        p,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(WinterStreetPainter old) => true;
}
