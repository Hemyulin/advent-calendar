import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../presentation/calendar_style.dart';
import 'battery_game.dart';

Color devicePaper(DeviceKind kind) => switch (kind) {
  DeviceKind.phone => const Color(0xFFF5E3D9),
  DeviceKind.watch => const Color(0xFFF3E8CD),
  DeviceKind.tablet => const Color(0xFFE5EADF),
  DeviceKind.headphones => const Color(0xFFE1EBEE),
  DeviceKind.laptop => const Color(0xFFEDE2E3),
};

class BatteryPainter extends CustomPainter {
  BatteryPainter({
    required this.percent,
    required this.charging,
    required this.time,
    required this.reducedMotion,
  });
  final double percent, time;
  final bool charging, reducedMotion;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(1, 1, s.width - 8, s.height - 2);
    final color = charging
        ? CalendarStyle.green
        : percent < 5
        ? const Color(0xFFBA5F52)
        : const Color(0xFFB78A3E);
    c.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: .65),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width - 6, s.height * .35, 5, s.height * .3),
        const Radius.circular(2),
      ),
      p..style = PaintingStyle.fill,
    );
    final inner = rect.deflate(4);
    // Keep a visible sliver at critically low charge; the printed value is exact.
    final fill = Rect.fromLTWH(
      inner.left,
      inner.top,
      inner.width * (percent / 100).clamp(.025, 1),
      inner.height,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(4)),
      p..color = color.withValues(alpha: .09),
    );
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(inner, const Radius.circular(4)));
    c.drawRect(fill, p..color = color);
    if (charging && !reducedMotion) {
      for (var x = -inner.height + (time * 35) % 24; x < fill.width; x += 24) {
        c.drawLine(
          Offset(inner.left + x, inner.bottom),
          Offset(inner.left + x + inner.height, inner.top),
          p
            ..color = Colors.white.withValues(alpha: .25)
            ..strokeWidth = 7,
        );
      }
      // A travelling spark stays visible even when the real charge is tiny.
      final spark = (time * .8) % 1;
      c.drawCircle(
        Offset(inner.left + inner.width * spark, inner.center.dy),
        2,
        p..color = color.withValues(alpha: .45),
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(BatteryPainter old) =>
      old.percent != percent ||
      old.charging != charging ||
      old.time != time ||
      old.reducedMotion != reducedMotion;
}

// Shared normalized layout keeps artwork, generous hit areas and ports aligned.
Rect deskDeviceRect(int index, Size size) {
  const positions = [
    Rect.fromLTWH(.04, .04, .40, .27),
    Rect.fromLTWH(.59, .04, .35, .27),
    Rect.fromLTWH(.02, .34, .47, .28),
    Rect.fromLTWH(.55, .33, .43, .28),
    Rect.fromLTWH(.17, .64, .66, .27),
  ];
  final r = positions[index];
  return Rect.fromLTWH(
    r.left * size.width,
    r.top * size.height,
    r.width * size.width,
    r.height * size.height,
  );
}

Offset deskPort(int index, Size size) {
  final r = deskDeviceRect(index, size);
  return Offset(
    r.center.dx + (index == 3 ? r.width * .23 : 0),
    r.top + r.height * .63,
  );
}

Offset cableDock(Size size) => Offset(size.width * .5, size.height * .965);

class CablePainter extends CustomPainter {
  CablePainter({
    required this.end,
    required this.connected,
    required this.dragging,
  });
  final Offset end;
  final bool connected, dragging;
  @override
  void paint(Canvas c, Size s) {
    if (!connected && !dragging) return;
    final edge = end.dx < s.width * .5 ? s.width * .025 : s.width * .975;
    final start = cableDock(s);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        edge + (start.dx - edge) * .3,
        start.dy + 4,
        edge,
        start.dy,
        edge,
        start.dy - 30,
      )
      ..lineTo(edge, end.dy + 18)
      ..cubicTo(edge, end.dy - 10, end.dx, end.dy - 10, end.dx, end.dy);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawPath(
      path.shift(const Offset(1, 2)),
      p
        ..strokeWidth = 5
        ..color = const Color(0xFF354D41).withValues(alpha: .12),
    );
    c.drawPath(
      path,
      p
        ..strokeWidth = 3.5
        ..color = CalendarStyle.green,
    );
    c.drawPath(
      path.shift(const Offset(-.6, -.5)),
      p
        ..strokeWidth = .7
        ..color = const Color(0xFF9FB7A0),
    );
    if (connected || dragging) {
      c.save();
      c.translate(end.dx, end.dy);
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-7, 1, 14, 12),
          const Radius.circular(3),
        ),
        p
          ..style = PaintingStyle.fill
          ..color = CalendarStyle.green,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -5, 8, 7),
          const Radius.circular(1),
        ),
        p..color = const Color(0xFFD3B879),
      );
      c.drawLine(
        const Offset(-2, -3),
        const Offset(2, -3),
        p
          ..color = const Color(0xFFF9EACC)
          ..strokeWidth = 1,
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(CablePainter old) =>
      end != old.end || connected != old.connected || dragging != old.dragging;
}

class DeskPainter extends CustomPainter {
  DeskPainter({this.victory = 0});
  final double victory;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..strokeCap = StrokeCap.round;
    final desk = RRect.fromRectAndRadius(
      Offset.zero & s,
      const Radius.circular(26),
    );
    c.drawRRect(desk, p..color = const Color(0xFFF1E8D7));
    c.drawRRect(
      desk.deflate(4),
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFD7C8AC).withValues(alpha: .45),
    );
    // Broad, quiet strokes suggest a pale tabletop rather than a wood texture.
    for (final y in [.32, .63, .92]) {
      c.drawLine(
        Offset(12, s.height * y),
        Offset(s.width - 12, s.height * y + 2),
        p..color = const Color(0xFFCEBEA2).withValues(alpha: .18),
      );
    }
    p.style = PaintingStyle.fill;
    for (var i = 0; i < 7; i++) {
      c.drawCircle(
        Offset(s.width * .09 + (i % 3) * 7, s.height * .91 + (i ~/ 3) * 8),
        i.isEven ? 1.8 : 1.1,
        p..color = const Color(0xFFBB9963).withValues(alpha: .6),
      );
    }
    if (victory > 0) {
      c.drawRRect(
        desk,
        p..color = const Color(0xFFF2CA74).withValues(alpha: victory * .08),
      );
    }
  }

  @override
  bool shouldRepaint(DeskPainter old) => victory != old.victory;
}

/// Paper-cut silhouettes with recognisable hardware details and quiet expressions.
class DeviceIllustration extends CustomPainter {
  DeviceIllustration(
    this.kind,
    this.worried,
    this.charging,
    this.time,
    this.reducedMotion, {
    this.eventActive = false,
    this.dead = false,
    this.victory = 0,
    this.urgent = false,
  });
  final DeviceKind kind;
  final bool worried, charging, reducedMotion, eventActive, dead, urgent;
  final double time, victory;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.translate(s.width / 2, s.height / 2);
    final scale = math.min(s.width / 100, s.height / 80);
    c.scale(scale);
    c.translate(-50, -40);
    final p = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void rounded(Rect rect, double radius, Color color) => c.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      p
        ..style = PaintingStyle.fill
        ..color = color,
    );
    void line(Offset a, Offset b, Color color, double width) => c.drawLine(
      a,
      b,
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
    const ink = Color(0xFF355C51);
    final glass = dead
        ? const Color(0xFFCCCDBF)
        : Color.lerp(
            const Color(0xFFFFF8E8),
            const Color(0xFFF9DF9A),
            victory,
          )!;
    c.drawPath(
      Path()
        ..moveTo(12, 51)
        ..cubicTo(3, 24, 37, 0, 65, 10)
        ..cubicTo(93, 15, 101, 52, 77, 66)
        ..cubicTo(54, 83, 19, 75, 12, 51)
        ..close(),
      p
        ..color = Color.lerp(
          devicePaper(kind),
          const Color(0xFFFFDEA0),
          victory,
        )!.withValues(alpha: .75),
    );
    c.drawOval(
      const Rect.fromLTWH(17, 69, 68, 7),
      p..color = ink.withValues(alpha: .10),
    );
    c.save();
    c.translate(50, 45);
    c.rotate(
      (kind.index - 2) * .045 +
          ((worried || urgent) && !charging && !dead && !reducedMotion
              ? math.sin(time * 8) * .025
              : 0),
    );
    c.translate(-50, -45);
    var face = const Offset(50, 38);
    switch (kind) {
      case DeviceKind.phone:
        rounded(const Rect.fromLTWH(29, 6, 42, 67), 9, const Color(0xFFB96E60));
        rounded(const Rect.fromLTWH(33, 14, 34, 47), 5, glass);
        rounded(
          const Rect.fromLTWH(43, 9, 14, 2),
          1,
          ink.withValues(alpha: .5),
        );
        c.drawCircle(
          const Offset(50, 67),
          2.5,
          p..color = glass.withValues(alpha: .7),
        );
        line(const Offset(36, 20), const Offset(43, 17), Colors.white, 2);
      case DeviceKind.watch:
        rounded(const Rect.fromLTWH(39, 0, 22, 80), 7, const Color(0xFFB9695B));
        for (var y = 5.0; y < 80; y += 7) {
          line(Offset(42, y), Offset(58, y), const Color(0xFFCC8A76), 1);
        }
        rounded(
          const Rect.fromLTWH(26, 17, 48, 48),
          13,
          const Color(0xFFBD9555),
        );
        rounded(const Rect.fromLTWH(31, 22, 38, 38), 9, glass);
        rounded(const Rect.fromLTWH(74, 32, 4, 10), 2, ink);
        face = const Offset(50, 40);
      case DeviceKind.tablet:
        rounded(const Rect.fromLTWH(17, 8, 66, 64), 8, const Color(0xFF719584));
        rounded(const Rect.fromLTWH(22, 14, 56, 49), 4, glass);
        c.drawCircle(const Offset(50, 67), 2, p..color = glass);
        line(const Offset(26, 21), const Offset(41, 17), Colors.white, 3);
      case DeviceKind.headphones:
        final band = Path()
          ..moveTo(20, 50)
          ..lineTo(20, 36)
          ..cubicTo(20, 0, 80, 0, 80, 36)
          ..lineTo(80, 50);
        c.drawPath(
          band,
          p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 11
            ..color = ink,
        );
        c.drawPath(
          band,
          p
            ..strokeWidth = 4
            ..color = const Color(0xFF9DBAB9),
        );
        rounded(
          const Rect.fromLTWH(11, 35, 22, 32),
          9,
          const Color(0xFF6B98A8),
        );
        rounded(
          const Rect.fromLTWH(67, 35, 22, 32),
          9,
          const Color(0xFF6B98A8),
        );
        rounded(const Rect.fromLTWH(27, 40, 6, 23), 3, ink);
        rounded(const Rect.fromLTWH(67, 40, 6, 23), 3, ink);
        c.drawPath(
          Path()
            ..moveTo(79, 67)
            ..cubicTo(81, 79, 52, 74, 62, 69),
          p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = ink,
        );
        face = const Offset(50, 45);
      case DeviceKind.laptop:
        rounded(const Rect.fromLTWH(15, 8, 70, 48), 6, const Color(0xFF9E7C86));
        rounded(const Rect.fromLTWH(20, 13, 60, 37), 3, glass);
        c.drawPath(
          Path()
            ..moveTo(15, 55)
            ..lineTo(85, 55)
            ..lineTo(96, 70)
            ..quadraticBezierTo(97, 74, 92, 74)
            ..lineTo(8, 74)
            ..quadraticBezierTo(3, 74, 4, 70)
            ..close(),
          p..color = const Color(0xFFC5A7AE),
        );
        for (var row = 0; row < 2; row++) {
          for (var col = 0; col < 8; col++) {
            rounded(
              Rect.fromLTWH(22 + col * 7, 58 + row * 4, 5, 2),
              1,
              glass.withValues(alpha: .6),
            );
          }
        }
        rounded(const Rect.fromLTWH(40, 67, 20, 4), 1, const Color(0xFF9E7C86));
        face = const Offset(50, 30);
    }
    // Eyes and mouth express urgency without replacing the device silhouette.
    final eyeColor = ink.withValues(alpha: .85);
    for (final side in [-1.0, 1.0]) {
      final eye = face + Offset(side * 7, -2);
      if (charging || dead || victory > 0) {
        c.drawArc(
          Rect.fromCenter(center: eye, width: 5, height: 4),
          dead ? 0 : math.pi,
          math.pi,
          false,
          p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = eyeColor,
        );
      } else {
        c.drawOval(
          Rect.fromCenter(
            center: eye,
            width: worried || urgent ? 3 : 5,
            height: worried || urgent ? 5 : 1.8,
          ),
          p
            ..style = PaintingStyle.fill
            ..color = eyeColor,
        );
      }
    }
    c.drawArc(
      Rect.fromCenter(
        center:
            face +
            Offset(
              0,
              (worried || urgent) && !charging && victory == 0 && !dead ? 9 : 2,
            ),
        width: 10,
        height: 7,
      ),
      (worried || urgent) && !charging && victory == 0 && !dead ? math.pi : 0,
      math.pi,
      false,
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = eyeColor,
    );
    if ((worried || urgent) && !charging && !dead && victory == 0) {
      c.drawOval(
        Rect.fromCenter(
          center: face + const Offset(14, 1),
          width: 3,
          height: 5,
        ),
        p
          ..style = PaintingStyle.fill
          ..color = const Color(0xFF91B9BD),
      );
    }
    if (eventActive && !dead && victory == 0) {
      _event(c, kind, time, reducedMotion);
    }
    if (charging || victory > 0) {
      c.drawCircle(
        const Offset(72, 15),
        4,
        p
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFDBB96C),
      );
      c.drawCircle(
        const Offset(72, 15),
        7 + (reducedMotion ? 0 : math.sin(time * 4).abs() * 2),
        p..color = const Color(0xFFDBB96C).withValues(alpha: .18),
      );
    }
    c.restore();
    c.restore();
  }

  @override
  bool shouldRepaint(DeviceIllustration old) =>
      kind != old.kind ||
      worried != old.worried ||
      charging != old.charging ||
      reducedMotion != old.reducedMotion ||
      time != old.time ||
      eventActive != old.eventActive ||
      dead != old.dead ||
      victory != old.victory ||
      urgent != old.urgent;

  void _event(Canvas c, DeviceKind kind, double time, bool reduced) {
    final p = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const ink = Color(0xFF527E70), cream = Color(0xFFFFF8E8);
    final offset = reduced ? 0.0 : math.sin(time * 5) * 1.5;
    switch (kind) {
      case DeviceKind.phone:
        for (var i = 0; i < 2; i++) {
          final rect = Rect.fromLTWH(35, 17 + i * 10 + offset, 29, 8);
          c.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            p
              ..color = i == 0
                  ? const Color(0xFFE2C789)
                  : const Color(0xFFA5C2AE),
          );
          c.drawLine(
            rect.centerLeft + const Offset(3, 0),
            rect.centerRight - const Offset(6, 0),
            p
              ..color = cream
              ..strokeWidth = 1.5,
          );
        }
      case DeviceKind.watch:
        c.drawPath(
          Path()
            ..moveTo(32, 34)
            ..lineTo(38, 34)
            ..lineTo(41, 28)
            ..lineTo(45, 38)
            ..lineTo(49, 33)
            ..lineTo(66, 33),
          p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFFBF7867),
        );
      case DeviceKind.tablet:
        const rect = Rect.fromLTWH(27, 18, 46, 17);
        c.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          p..color = const Color(0xFF9EBDB1),
        );
        c.drawPath(
          Path()
            ..moveTo(46, 21)
            ..lineTo(46, 29)
            ..lineTo(54, 25)
            ..close(),
          p..color = cream,
        );
        c.drawLine(
          const Offset(30, 32),
          Offset(32 + (reduced ? 20 : (time * 8) % 35), 32),
          p
            ..color = ink
            ..strokeWidth = 1.5,
        );
      case DeviceKind.headphones:
        for (var i = 0; i < 2; i++) {
          final note = Offset(i == 0 ? 5 : 88, 19 + i * 8 + offset);
          c.drawOval(
            Rect.fromCenter(center: note, width: 7, height: 5),
            p..color = ink,
          );
          c.drawLine(
            note + const Offset(3, 0),
            note + const Offset(3, -13),
            p..strokeWidth = 2,
          );
          c.drawLine(
            note + const Offset(3, -13),
            note + const Offset(8, -10),
            p,
          );
        }
      case DeviceKind.laptop:
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(29, 16, 42, 8),
            const Radius.circular(2),
          ),
          p..color = const Color(0xFFD8C5CD),
        );
        final width = reduced ? 24.0 : 6 + (time * 8) % 32;
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(31, 18, width, 4),
            const Radius.circular(1),
          ),
          p..color = ink,
        );
    }
  }
}

/// The initial loose plug is draggable, with no idle cable attached.
class ChargingPlugPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    final x = s.width / 2;
    c.drawOval(
      Rect.fromCenter(center: Offset(x, s.height * .8), width: 32, height: 7),
      p..color = CalendarStyle.green.withValues(alpha: .12),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 8, 5, 16, 17),
        const Radius.circular(2),
      ),
      p..color = const Color(0xFFD3B879),
    );
    c.drawLine(
      Offset(x - 4, 10),
      Offset(x + 4, 10),
      p
        ..strokeWidth = 2
        ..color = const Color(0xFFFFF3D1),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 14, 19, 28, 25),
        const Radius.circular(7),
      ),
      p..color = CalendarStyle.green,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 7, 26, 14, 3),
        const Radius.circular(1),
      ),
      p..color = const Color(0xFF8EAE99),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 5, 42, 10, 7),
        const Radius.circular(2),
      ),
      p..color = CalendarStyle.green,
    );
  }

  @override
  bool shouldRepaint(ChargingPlugPainter old) => false;
}

class BatteryCountdown extends StatelessWidget {
  const BatteryCountdown({
    super.key,
    required this.remaining,
    required this.elapsed,
    required this.running,
    required this.reducedMotion,
  });
  final double remaining, elapsed;
  final bool running, reducedMotion;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Verbleibende Zeit: ${remaining.ceil()} Sekunden',
    child: ExcludeSemantics(
      child: Container(
        key: const ValueKey('battery-countdown'),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0E9DA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD6C6A6).withValues(alpha: .6),
          ),
        ),
        child: Column(
          children: [
            const Text(
              'RESTZEIT',
              style: TextStyle(
                color: CalendarStyle.muted,
                fontSize: 9,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 5),
            AspectRatio(
              aspectRatio: 4.7,
              child: CustomPaint(
                painter: _CountdownPainter(
                  remaining,
                  elapsed,
                  running,
                  reducedMotion,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Inset seven-segment numerals, with smaller hundredths, like a quiet prop timer.
class _CountdownPainter extends CustomPainter {
  _CountdownPainter(
    this.remaining,
    this.elapsed,
    this.running,
    this.reducedMotion,
  );
  final double remaining, elapsed;
  final bool running, reducedMotion;
  static const _digits = [
    0x3f,
    0x06,
    0x5b,
    0x4f,
    0x66,
    0x6d,
    0x7d,
    0x07,
    0x7f,
    0x6f,
  ];
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 300, s.height / 64);
    final ticks = (math.max(0, remaining) * 100).ceil();
    final minutes = (ticks ~/ 6000).toString().padLeft(2, '0');
    final seconds = ((ticks ~/ 100) % 60).toString().padLeft(2, '0');
    final hundredths = (ticks % 100).toString().padLeft(2, '0');
    final urgent = remaining <= 10 && remaining > 0;
    final color = urgent ? const Color(0xFFB65E50) : CalendarStyle.green;
    final pulse = urgent && running && !reducedMotion
        ? .9 + math.sin(elapsed * math.pi * 2).abs() * .1
        : 1.0;
    final p = Paint()..strokeCap = StrokeCap.round;
    void digit(String char, Offset origin, double width, double height) {
      final mask = _digits[int.parse(char)];
      final segments = [
        (Offset(3, 0), Offset(width - 3, 0)),
        (Offset(width, 3), Offset(width, height / 2 - 3)),
        (Offset(width, height / 2 + 3), Offset(width, height - 3)),
        (Offset(3, height), Offset(width - 3, height)),
        (const Offset(0, 3), Offset(0, height / 2 - 3)),
        (Offset(0, height / 2 + 3), Offset(0, height - 3)),
        (Offset(3, height / 2), Offset(width - 3, height / 2)),
      ];
      // Bits 4 and 5 are lower-left and upper-left in the standard digit masks.
      final bits = [0, 1, 2, 3, 5, 4, 6];
      for (var i = 0; i < 7; i++) {
        final lit = mask & (1 << bits[i]) != 0;
        c.drawLine(
          origin + segments[i].$1,
          origin + segments[i].$2,
          p
            ..strokeWidth = width * .12
            ..color = color.withValues(alpha: lit ? pulse : .055),
        );
      }
    }

    digit(minutes[0], const Offset(10, 7), 30, 48);
    digit(minutes[1], const Offset(53, 7), 30, 48);
    for (final y in [22.0, 40.0]) {
      c.drawCircle(Offset(100, y), 2.1, p..color = color.withValues(alpha: .8));
    }
    digit(seconds[0], const Offset(118, 7), 30, 48);
    digit(seconds[1], const Offset(161, 7), 30, 48);
    c.drawCircle(
      const Offset(207, 54),
      2,
      p..color = color.withValues(alpha: .65),
    );
    digit(hundredths[0], const Offset(221, 25), 20, 30);
    digit(hundredths[1], const Offset(253, 25), 20, 30);
    // Tiny brass fasteners make it feel like a physical object on the desk.
    for (final x in [1.0, 296.0]) {
      c.drawCircle(
        Offset(x, 31),
        2,
        p..color = const Color(0xFFBCA677).withValues(alpha: .55),
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_CountdownPainter old) =>
      remaining != old.remaining ||
      elapsed != old.elapsed ||
      running != old.running ||
      reducedMotion != old.reducedMotion;
}
