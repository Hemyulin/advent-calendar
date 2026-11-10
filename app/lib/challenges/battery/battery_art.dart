import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../presentation/calendar_style.dart';
import 'battery_game.dart';

IconData deviceIcon(DeviceKind kind) => switch (kind) {
  DeviceKind.phone => Icons.smartphone_rounded,
  DeviceKind.watch => Icons.watch_rounded,
  DeviceKind.tablet => Icons.tablet_mac_rounded,
  DeviceKind.headphones => Icons.headphones_rounded,
  DeviceKind.laptop => Icons.laptop_mac_rounded,
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

class CablePainter extends CustomPainter {
  CablePainter(this.index, this.color);
  final int? index;
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final end = index == null
        ? Offset(s.width / 2, 378)
        : Offset(
            s.width *
                (index == 4
                    ? .5
                    : index!.isEven
                    ? .24
                    : .76),
            index == 4
                ? 348
                : index! < 2
                ? 106
                : 230,
          );
    final start = Offset(s.width / 2, 414);
    c.drawPath(
      Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx - 42,
          start.dy - 30,
          end.dx + 28,
          end.dy + 40,
          end.dx,
          end.dy,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    if (index != null) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: end, width: 17, height: 10),
          const Radius.circular(3),
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(CablePainter old) =>
      index != old.index || color != old.color;
}

/// Tiny face changes from sleepy to worried to relieved; no bitmap assets.
class DeviceFace extends CustomPainter {
  DeviceFace(this.worried, this.charging, this.time, this.reducedMotion);
  final bool worried, charging, reducedMotion;
  final double time;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = CalendarStyle.green
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final offset = !reducedMotion && worried ? math.sin(time * 9) : 0.0;
    for (final x in [s.width * .32, s.width * .68]) {
      c.drawLine(Offset(x + offset, 4), Offset(x + offset, 6), p);
    }
    c.drawArc(
      Rect.fromCenter(
        center: Offset(s.width / 2, worried && !charging ? 15 : 8),
        width: 9,
        height: 7,
      ),
      worried && !charging ? math.pi : 0,
      math.pi,
      false,
      p,
    );
  }

  @override
  bool shouldRepaint(DeviceFace old) =>
      worried != old.worried || charging != old.charging || time != old.time;
}
