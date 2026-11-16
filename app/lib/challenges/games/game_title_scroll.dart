import 'package:flutter/material.dart';

import '../../presentation/calendar_style.dart';

/// A small illustrated parchment, sized by its lettering so long titles wrap.
class GameTitleScroll extends StatelessWidget {
  const GameTitleScroll({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: CustomPaint(
      painter: const _ParchmentPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
        child: Text(
          title,
          key: const ValueKey('game-title'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'GrenzeGotisch',
            fontWeight: FontWeight.w500,
            color: CalendarStyle.green,
            fontSize: 26,
            height: 1.1,
          ),
        ),
      ),
    ),
  );
}

class _ParchmentPainter extends CustomPainter {
  const _ParchmentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const edge = Color(0xFFCFAF78);
    final sheet = Path()
      ..moveTo(15, 7)
      ..cubicTo(w * .3, 2, w * .7, 10, w - 15, 6)
      ..lineTo(w - 15, h - 7)
      ..cubicTo(w * .7, h - 2, w * .3, h - 10, 15, h - 6)
      ..close();
    canvas.drawShadow(sheet, const Color(0xFF907349), 2, false);
    canvas.drawPath(
      sheet,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF2DDB5), Color(0xFFFAEED5), Color(0xFFF1DCB2)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      sheet,
      Paint()
        ..color = edge.withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7,
    );

    // Narrow rolled ends, with a curled lip at the foot of each paper roll.
    for (final left in [true, false]) {
      final x = left ? 7.0 : w - 22;
      final roll = Rect.fromLTWH(x, 3, 15, h - 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(roll, const Radius.circular(7)),
        Paint()
          ..shader = LinearGradient(
            colors: left
                ? const [
                    Color(0xFFDDBD87),
                    Color(0xFFFBEDD0),
                    Color(0xFFE8C995),
                  ]
                : const [
                    Color(0xFFE8C995),
                    Color(0xFFFBEDD0),
                    Color(0xFFDDBD87),
                  ],
          ).createShader(roll),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(roll, const Radius.circular(7)),
        Paint()
          ..color = edge.withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7,
      );
      final curl = Path()
        ..moveTo(x + 3, h - 10)
        ..cubicTo(x + 3, h - 4, x + 13, h - 4, x + 12, h - 10)
        ..cubicTo(x + 11, h - 14, x + 6, h - 13, x + 7, h - 9);
      canvas.drawPath(
        curl,
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = .8,
      );
    }
  }

  @override
  bool shouldRepaint(_ParchmentPainter oldDelegate) => false;
}
