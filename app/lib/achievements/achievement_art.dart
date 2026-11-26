import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../presentation/festive_art.dart';
import '../challenges/oy_vey/oy_vey_art.dart';
import '../challenges/oy_vey/oy_vey_game.dart';
import '../challenges/seasonal/hanukkah_art.dart';

/// Each achievement is a small storybook scene, not a recolored medal.
enum AchievementScene {
  allDays,
  allGames,
  allExtras,
  shoe,
  menorahs,
  cleanOy,
  goyVey,
  noJewishMisses,
  memory,
  workshop,
  cleanWalk,
  roughWalk,
  safeBattery,
  halfCharged,
  fullyCharged,
  hundredPercent,
  cookies,
  candy,
  allAchievements,
  santaUp,
  bells,
  hanukkah,
  freshBag,
}

class AchievementIllustration extends StatelessWidget {
  const AchievementIllustration({
    super.key,
    required this.achievementId,
    required this.earned,
    this.width = 160,
    this.height = 112,
  });
  final String achievementId;
  final bool earned;
  final double width, height;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedOpacity(
      opacity: earned ? 1 : .62,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 280),
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(
          earned
              ? const [
                  1,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]
              : const [
                  .2126,
                  .7152,
                  .0722,
                  0,
                  0,
                  .2126,
                  .7152,
                  .0722,
                  0,
                  0,
                  .2126,
                  .7152,
                  .0722,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ],
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: AchievementPainter(
              AchievementScene.values.byName(achievementId),
            ),
          ),
        ),
      ),
    ),
  );
}

class AchievementPainter extends CustomPainter {
  const AchievementPainter(this.scene);
  final AchievementScene scene;
  static const green = Color(0xFF276957),
      mint = Color(0xFF94B8A0),
      red = Color(0xFFCA6557),
      pink = Color(0xFFEBA68E),
      gold = Color(0xFFE3B65D),
      blue = Color(0xFF5A91A1),
      plum = Color(0xFFAA8091),
      ink = Color(0xFF49645A),
      cream = Color(0xFFFFF8E8),
      dough = Color(0xFFD7A86A);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 140);
    final p = Paint()..isAntiAlias = true;
    void oval(double x, double y, double w, double h, Color c) =>
        canvas.drawOval(
          Rect.fromLTWH(x, y, w, h),
          p
            ..color = c
            ..style = PaintingStyle.fill,
        );
    void box(double x, double y, double w, double h, Color c, [double r = 5]) =>
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h),
            Radius.circular(r),
          ),
          p
            ..color = c
            ..style = PaintingStyle.fill,
        );
    void line(
      double x,
      double y,
      double x2,
      double y2,
      Color c, [
      double width = 3,
    ]) => canvas.drawLine(
      Offset(x, y),
      Offset(x2, y2),
      p
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
    void polygon(List<Offset> points, Color c) {
      final path = Path()..addPolygon(points, true);
      canvas.drawPath(
        path,
        p
          ..color = c
          ..style = PaintingStyle.fill,
      );
    }

    void label(
      String text,
      double x,
      double y,
      double font,
      Color color, {
      FontWeight weight = FontWeight.w600,
    }) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: font,
            color: color,
            fontWeight: weight,
            fontFamily: 'sans-serif',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
    }

    void ornament(DoorMotif motif, double x, double y, double scale) {
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(scale / 100);
      paintOrnament(canvas, motif);
      canvas.restore();
    }

    void gift(double x, double y, double w, double h, Color c) {
      box(x, y, w, h, c, 3);
      box(x - 2, y, w + 4, 7, c, 2);
      box(x + w * .42, y, w * .16, h, gold, 0);
      final bow = Path()
        ..moveTo(x + w * .5, y)
        ..cubicTo(x + w * .05, y - 17, x + w * .1, y - 23, x + w * .5, y - 4)
        ..cubicTo(x + w * .9, y - 23, x + w * .95, y - 17, x + w * .5, y);
      canvas.drawPath(
        bow,
        p
          ..color = gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    void house(double x, double y, double w, double h, Color color) {
      box(x, y, w, h, color, 3);
      polygon([
        Offset(x - 5, y + 2),
        Offset(x + w / 2, y - 20),
        Offset(x + w + 5, y + 2),
      ], green);
      box(x + w * .38, y + h * .45, w * .24, h * .55, cream, 2);
      box(x + w * .12, y + 10, w * .2, 12, gold, 2);
      box(x + w * .68, y + 10, w * .2, 12, gold, 2);
      line(x - 2, y + 1, x + w / 2, y - 17, cream, 3);
      line(x + w / 2, y - 17, x + w + 2, y + 1, cream, 3);
    }

    void fir(double x, double y, double s) {
      line(x, y + 25 * s, x, y + 42 * s, dough, 4 * s);
      polygon([
        Offset(x, y - 24 * s),
        Offset(x - 18 * s, y + 10 * s),
        Offset(x - 10 * s, y + 10 * s),
        Offset(x - 25 * s, y + 30 * s),
        Offset(x + 25 * s, y + 30 * s),
        Offset(x + 10 * s, y + 10 * s),
        Offset(x + 18 * s, y + 10 * s),
      ], green);
    }

    void sweet(double x, double y, double radius, Color color) {
      polygon([
        Offset(x - radius * .6, y),
        Offset(x - radius * 1.9, y - radius * .7),
        Offset(x - radius * 1.9, y + radius * .7),
      ], color);
      polygon([
        Offset(x + radius * .6, y),
        Offset(x + radius * 1.9, y - radius * .7),
        Offset(x + radius * 1.9, y + radius * .7),
      ], color);
      oval(x - radius, y - radius, radius * 2, radius * 2, cream);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(x, y), radius: radius * .65),
        -.6,
        4.2,
        false,
        p
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * .4,
      );
    }

    final tint = [mint, pink, blue, plum, gold][scene.index % 5];
    oval(10, 12, 180, 112, tint.withValues(alpha: .12));
    oval(28, 121, 144, 9, ink.withValues(alpha: .08));
    switch (scene) {
      case AchievementScene.freshBag:
        oval(43, 119, 114, 10, dough.withValues(alpha: .35));
        box(61, 48, 78, 74, mint, 10);
        for (var i = 0; i < 4; i++) {
          line(75 + i * 16, 66, 77 + i * 14, 111, cream, 3);
        }
        oval(57, 39, 86, 24, green);
        oval(62, 42, 76, 16, cream);
        oval(68, 45, 64, 11, mint);
        box(151, 89, 33, 25, mint, 10);
        oval(172, 89, 14, 25, green);
        line(84, 80, 96, 92, cream, 5);
        line(96, 92, 118, 68, cream, 5);
        paintStar(canvas, const Offset(48, 36), 8, gold);
        paintStar(canvas, const Offset(151, 26), 6, gold);

      case AchievementScene.allDays:
        box(45, 42, 110, 80, red, 4);
        polygon(const [Offset(33, 44), Offset(100, 9), Offset(167, 44)], green);
        line(38, 42, 100, 14, cream, 4);
        line(100, 14, 162, 42, cream, 4);
        for (var i = 0; i < 24; i++) {
          final x = 55 + (i % 6) * 16.0, y = 54 + (i ~/ 6) * 16.0;
          box(x, y, 10, 11, i == 23 ? gold : cream, 1);
          if (i == 23) label('24', x + 5, y + 1, 6, ink);
        }
        line(63, 21, 63, 9, red, 8);
        ornament(DoorMotif.star, 84, -3, 32);
        fir(27, 91, .52);
        fir(175, 90, .6);
      case AchievementScene.allGames:
        box(30, 91, 137, 24, red, 5);
        box(43, 65, 38, 29, blue, 5);
        box(49, 70, 14, 14, cream, 2);
        box(84, 78, 33, 15, green, 3);
        for (final x in [49.0, 85.0, 130.0, 151.0]) {
          oval(x - 7, 109, 14, 14, ink);
          oval(x - 3, 113, 6, 6, gold);
        }
        line(37, 125, 169, 125, dough, 2);
        ornament(DoorMotif.bell, 110, 36, 43);
        ornament(DoorMotif.tree, 139, 50, 35);
        box(83, 30, 25, 35, plum, 3);
        ornament(DoorMotif.star, 80, 27, 30);
        oval(35, 47, 12, 12, gold);
        oval(24, 32, 9, 9, gold.withValues(alpha: .5));
      case AchievementScene.allExtras:
        box(41, 30, 114, 92, dough, 5);
        box(48, 38, 100, 76, cream, 2);
        line(99, 40, 99, 110, dough, 4);
        line(50, 77, 146, 77, dough, 4);
        ornament(DoorMotif.bell, 54, 39, 37);
        sweet(123, 58, 10, red);
        ornament(DoorMotif.mitten, 54, 76, 38);
        ornament(DoorMotif.star, 107, 81, 34);
        oval(136, 82, 31, 31, gold);
        oval(140, 86, 23, 23, cream);
        line(159, 108, 174, 125, green, 8);
        line(145, 98, 150, 103, green, 2);
        line(150, 103, 159, 93, green, 2);
      case AchievementScene.shoe:
        ornament(DoorMotif.boot, 33, 24, 111);
        box(135, 96, 43, 12, dough, 4);
        for (var i = 0; i < 8; i++) {
          line(139 + i * 4, 107, 138 + i * 4, 116, gold, 3);
        }
        line(157, 94, 165, 79, green, 7);
        paintStar(canvas, const Offset(145, 49), 8, gold);
        paintStar(canvas, const Offset(28, 90), 5, gold);
        oval(63, 119, 77, 5, cream.withValues(alpha: .7));
      case AchievementScene.menorahs:
        paintFestiveObject(
          canvas,
          const Offset(100, 77),
          48,
          FestiveObject.hanukkiah,
        );
        for (var i = 0; i < 5; i++) {
          oval(38 + i * 28, 19 + (i.isEven ? 0 : 8), 3, 3, gold);
        }
        line(53, 122, 147, 122, dough, 3);
        ornament(DoorMotif.star, 13, 58, 25);
        ornament(DoorMotif.star, 162, 58, 25);
      case AchievementScene.cleanOy:
        final sack = Path()
          ..moveTo(72, 66)
          ..cubicTo(49, 91, 50, 120, 88, 122)
          ..lineTo(121, 122)
          ..cubicTo(157, 118, 151, 90, 126, 65)
          ..close();
        canvas.drawPath(
          sack,
          p
            ..color = blue
            ..style = PaintingStyle.fill,
        );
        oval(69, 56, 59, 18, cream);
        line(72, 70, 127, 70, gold, 4);
        paintFestiveObject(
          canvas,
          const Offset(91, 43),
          22,
          FestiveObject.dreidel,
        );
        paintFestiveObject(
          canvas,
          const Offset(128, 30),
          17,
          FestiveObject.sufganiyah,
        );
        line(91, 96, 99, 103, cream, 4);
        line(99, 103, 118, 84, cream, 4);
        fir(28, 100, .35);
      case AchievementScene.goyVey:
        paintCollectorSack(
          canvas,
          const Offset(100, 46),
          24,
          3,
          christmasTargets: true,
        );
        paintFestiveObject(
          canvas,
          const Offset(48, 54),
          23,
          FestiveObject.tree,
        );
        paintFestiveObject(
          canvas,
          const Offset(102, 22),
          20,
          FestiveObject.hat,
        );
        paintFestiveObject(
          canvas,
          const Offset(152, 57),
          22,
          FestiveObject.cane,
        );
        oval(94, 28, 3, 3, gold);
        oval(112, 38, 3, 3, gold);
      case AchievementScene.noJewishMisses:
        // A woven catching basket keeps the entire little collection safe.
        paintFestiveObject(
          canvas,
          const Offset(54, 54),
          23,
          FestiveObject.dreidel,
        );
        paintFestiveObject(
          canvas,
          const Offset(101, 43),
          28,
          FestiveObject.hanukkiah,
        );
        paintFestiveObject(
          canvas,
          const Offset(149, 56),
          22,
          FestiveObject.sufganiyah,
        );
        final basket = Path()
          ..moveTo(32, 78)
          ..lineTo(168, 78)
          ..lineTo(157, 115)
          ..quadraticBezierTo(100, 129, 43, 115)
          ..close();
        canvas.drawPath(
          basket,
          p
            ..style = PaintingStyle.fill
            ..color = dough,
        );
        canvas.save();
        canvas.clipPath(basket);
        for (var x = 39.0; x < 170; x += 13) {
          line(x, 78, x + 10, 124, cream.withValues(alpha: .55), 3);
        }
        for (var y = 88.0; y < 124; y += 10) {
          line(32, y, 168, y, gold, 3);
        }
        canvas.restore();
        box(28, 74, 144, 10, green, 5);
        box(74, 88, 55, 22, cream, 6);
        label('15 / 15', 101, 91, 13, green);
        ornament(DoorMotif.star, 22, 29, 18);
        ornament(DoorMotif.star, 172, 28, 18);
      case AchievementScene.memory:
        canvas.save();
        canvas.translate(69, 78);
        canvas.rotate(-.15);
        box(-33, -44, 57, 76, red, 6);
        box(-28, -39, 47, 66, cream, 4);
        ornament(DoorMotif.tree, -32, -34, 56);
        canvas.restore();
        canvas.save();
        canvas.translate(129, 79);
        canvas.rotate(.16);
        box(-25, -44, 57, 76, green, 6);
        box(-20, -39, 47, 66, cream, 4);
        ornament(DoorMotif.tree, -25, -34, 56);
        canvas.restore();
        line(91, 25, 101, 18, gold, 3);
        line(101, 18, 111, 25, gold, 3);
        paintStar(canvas, const Offset(168, 108), 6, gold);
      case AchievementScene.workshop:
        // A comically oversized brain, tiny elf body and round spectacles.
        oval(54, 16, 103, 94, gold.withValues(alpha: .15));
        box(87, 102, 31, 22, green, 8);
        line(94, 124, 89, 128, ink, 5);
        line(111, 124, 117, 128, ink, 5);
        line(88, 108, 75, 114, pink, 6);
        line(118, 108, 131, 101, pink, 6);
        oval(81, 72, 43, 35, pink);
        final brain = Path()
          ..moveTo(102, 76)
          ..cubicTo(84, 87, 60, 80, 62, 65)
          ..cubicTo(45, 62, 47, 42, 61, 37)
          ..cubicTo(57, 22, 77, 13, 88, 22)
          ..cubicTo(96, 11, 110, 13, 116, 22)
          ..cubicTo(134, 12, 151, 24, 147, 39)
          ..cubicTo(164, 49, 158, 68, 144, 68)
          ..cubicTo(143, 84, 116, 86, 102, 76)
          ..close();
        canvas.drawPath(
          brain,
          p
            ..style = PaintingStyle.fill
            ..color = const Color(0xFFF1B3AC),
        );
        final folds = Path()
          ..moveTo(103, 24)
          ..cubicTo(91, 37, 111, 49, 100, 61)
          ..quadraticBezierTo(96, 68, 102, 76)
          ..moveTo(75, 31)
          ..cubicTo(88, 31, 88, 42, 77, 46)
          ..quadraticBezierTo(64, 49, 72, 59)
          ..moveTo(59, 48)
          ..quadraticBezierTo(68, 39, 74, 43)
          ..moveTo(79, 59)
          ..cubicTo(91, 52, 99, 67, 86, 72)
          ..moveTo(119, 30)
          ..cubicTo(134, 24, 143, 40, 130, 44)
          ..quadraticBezierTo(115, 42, 118, 54)
          ..moveTo(142, 50)
          ..cubicTo(132, 48, 126, 56, 132, 64)
          ..moveTo(111, 65)
          ..quadraticBezierTo(122, 59, 124, 73);
        canvas.drawPath(
          folds,
          p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFC8797C),
        );
        polygon(const [Offset(58, 36), Offset(57, 8), Offset(83, 30)], green);
        line(58, 36, 82, 30, mint, 5);
        oval(52, 6, 9, 9, gold);
        oval(84, 82, 16, 13, cream);
        oval(104, 82, 16, 13, cream);
        canvas.drawOval(
          const Rect.fromLTWH(84, 82, 16, 13),
          p
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawOval(const Rect.fromLTWH(104, 82, 16, 13), p);
        line(100, 87, 104, 87, ink, 2);
        oval(92, 86, 3, 4, ink);
        oval(109, 86, 3, 4, ink);
        final smile = Path()
          ..moveTo(98, 98)
          ..quadraticBezierTo(103, 102, 108, 97);
        canvas.drawPath(
          smile,
          p
            ..style = PaintingStyle.stroke
            ..color = ink
            ..strokeWidth = 2,
        );
        gift(143, 99, 23, 25, red);
        gift(37, 101, 22, 23, blue);
        line(142, 85, 150, 78, gold, 2);
        line(153, 91, 164, 90, gold, 2);
      case AchievementScene.cleanWalk:
        final path = Path()
          ..moveTo(87, 132)
          ..cubicTo(58, 105, 142, 90, 109, 62)
          ..lineTo(128, 62)
          ..cubicTo(157, 102, 89, 106, 120, 132)
          ..close();
        canvas.drawPath(
          path,
          p
            ..color = cream
            ..style = PaintingStyle.fill,
        );
        house(91, 40, 58, 42, red);
        fir(39, 78, .65);
        fir(168, 83, .45);
        for (var i = 0; i < 5; i++) {
          oval(
            91 + (i.isEven ? 8 : 0),
            92 + i * 6,
            5,
            3,
            blue.withValues(alpha: .6),
          );
        }
        paintStar(canvas, const Offset(64, 31), 6, gold);
      case AchievementScene.roughWalk:
        house(133, 37, 39, 33, blue);
        line(30, 123, 55, 110, cream, 12);
        line(55, 110, 91, 124, cream, 12);
        line(91, 124, 143, 83, cream, 12);
        oval(33, 79, 26, 25, cream);
        oval(39, 65, 17, 17, cream);
        line(41, 62, 54, 62, ink, 3);
        box(43, 53, 10, 9, ink, 1);
        line(30, 97, 18, 85, dough, 3);
        polygon(const [Offset(49, 72), Offset(62, 76), Offset(49, 77)], gold);
        canvas.save();
        canvas.translate(98, 85);
        canvas.rotate(.23);
        box(-17, -13, 30, 31, red, 5);
        line(14, -4, 21, -4, gold, 4);
        line(21, -4, 21, 9, gold, 4);
        line(21, 9, 14, 9, gold, 4);
        oval(-17, -16, 30, 9, cream);
        canvas.restore();
        line(83, 41, 80, 30, gold, 2);
        line(96, 39, 99, 25, gold, 2);
      case AchievementScene.safeBattery:
        for (var i = 0; i < 5; i++) {
          final x = 24 + i * 31.0, y = 47.0 + (i.isEven ? 8 : 0);
          box(x, y, 26, 51, [red, gold, mint, blue, plum][i], 5);
          box(x + 4, y + 6, 18, 34, cream, 2);
          box(x + 8, y + 17, 10, 17, green, 2);
          box(x + 11, y + 14, 4, 3, green, 1);
          oval(x + 11, y + 44, 4, 4, cream);
        }
        line(37, 111, 162, 111, dough, 2);
        fir(100, 15, .32);
        for (final x in [53.0, 99.0, 145.0]) {
          oval(x, 27, 4, 4, gold);
        }
      case AchievementScene.halfCharged:
        box(46, 31, 111, 70, plum, 7);
        box(53, 38, 97, 55, cream, 3);
        box(66, 50, 65, 28, mint, 4);
        box(70, 54, 29, 20, green, 2);
        box(131, 58, 5, 12, mint, 1);
        label('50 %', 113, 56, 11, green);
        polygon(const [
          Offset(45, 101),
          Offset(157, 101),
          Offset(175, 118),
          Offset(27, 118),
        ], plum);
        box(75, 107, 52, 3, cream, 1);
        line(156, 83, 175, 83, green, 3);
        line(175, 83, 175, 45, green, 3);
        box(167, 28, 16, 19, green, 3);
        line(171, 29, 171, 22, gold, 3);
        line(179, 29, 179, 22, gold, 3);
      case AchievementScene.fullyCharged:
        // A triumphant, overflowing charge: distinct from the half-full laptop.
        box(68, 24, 65, 94, green, 12);
        box(89, 17, 23, 10, gold, 3);
        box(75, 31, 51, 79, cream, 7);
        for (var i = 0; i < 4; i++) {
          box(81, 38 + i * 17.0, 39, 12, mint.withValues(alpha: .4), 3);
          box(81, 38 + i * 17.0, i < 3 ? 39 : 8, 12, mint, 3);
        }
        polygon(const [
          Offset(105, 45),
          Offset(89, 71),
          Offset(100, 71),
          Offset(95, 94),
          Offset(113, 66),
          Offset(102, 66),
        ], gold);
        for (final x in [38.0, 160.0]) {
          line(x, 55, x - 8, 42, gold, 3);
          line(x, 77, x - 13, 77, gold, 3);
          line(x, 99, x - 8, 112, gold, 3);
        }
        label('80 %', 100, 122, 14, green);
      case AchievementScene.hundredPercent:
        // A secret overachiever: a completely full battery wearing a festive hat.
        box(70, 48, 62, 75, green, 11);
        box(77, 55, 48, 61, cream, 6);
        for (var i = 0; i < 4; i++) {
          box(83, 61 + i * 12.0, 36, 8, mint, 2);
        }
        final hat = Path()
          ..moveTo(65, 49)
          ..quadraticBezierTo(75, 2, 108, 19)
          ..quadraticBezierTo(132, 22, 139, 42)
          ..lineTo(126, 38)
          ..lineTo(117, 28)
          ..lineTo(119, 49)
          ..close();
        canvas.drawPath(hat, Paint()..color = red);
        box(65, 43, 70, 12, cream, 6);
        oval(130, 34, 17, 17, cream);
        label('100 %', 101, 81, 13, green);
        for (final x in [40.0, 159.0]) {
          ornament(DoorMotif.star, x, 65, 22);
          oval(x - 3, 96, 5, 5, pink);
          line(x - 4, 28, x + 3, 35, gold, 2);
        }
      case AchievementScene.cookies:
        box(24, 30, 152, 91, dough.withValues(alpha: .3), 15);
        for (var i = 0; i < 3; i++) {
          final cx = 57 + i * 44.0, cy = 76 + (i == 1 ? -11 : 7);
          final shape = Path();
          if (i == 0) {
            for (var k = 0; k < 10; k++) {
              final angle = -math.pi / 2 + k * math.pi / 5,
                  r = k.isEven ? 24.0 : 12.0;
              final point = Offset(
                cx + math.cos(angle) * r,
                cy + math.sin(angle) * r,
              );
              if (k == 0) {
                shape.moveTo(point.dx, point.dy);
              } else {
                shape.lineTo(point.dx, point.dy);
              }
            }
            shape.close();
          } else if (i == 1) {
            shape.addPolygon([
              Offset(cx, cy - 26),
              Offset(cx - 20, cy + 15),
              Offset(cx - 5, cy + 15),
              Offset(cx - 5, cy + 25),
              Offset(cx + 5, cy + 25),
              Offset(cx + 5, cy + 15),
              Offset(cx + 20, cy + 15),
            ], true);
          } else {
            for (var k = 0; k < 24; k++) {
              final angle = k * math.pi / 12,
                  r = k % 4 == 0
                      ? 25.0
                      : k.isEven
                      ? 15.0
                      : 9.0;
              final point = Offset(
                cx + math.cos(angle) * r,
                cy + math.sin(angle) * r,
              );
              if (k == 0) {
                shape.moveTo(point.dx, point.dy);
              } else {
                shape.lineTo(point.dx, point.dy);
              }
            }
            shape.close();
          }
          canvas.drawPath(
            shape,
            p
              ..color = dough
              ..style = PaintingStyle.fill,
          );
          canvas.drawPath(
            shape,
            p
              ..color = cream
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
          oval(cx - 2, cy - 2, 4, 4, red);
        }
        oval(40, 113, 3, 3, cream);
        oval(160, 38, 3, 3, cream);
        oval(153, 113, 4, 4, cream);
      case AchievementScene.candy:
        for (final values in [
          [28.0, 38.0, 28.0, 109.0],
          [28.0, 38.0, 79.0, 38.0],
          [79.0, 38.0, 79.0, 61.0],
          [122.0, 32.0, 171.0, 32.0],
          [171.0, 32.0, 171.0, 111.0],
          [118.0, 84.0, 118.0, 113.0],
          [29.0, 113.0, 118.0, 113.0],
        ]) {
          line(values[0], values[1], values[2], values[3], green, 4);
        }
        sweet(59, 72, 13, red);
        sweet(103, 49, 11, blue);
        sweet(148, 95, 12, plum);
        oval(94, 96, 13, 13, gold);
        oval(96, 98, 4, 4, cream);
      case AchievementScene.santaUp:
        box(65, 80, 70, 44, red, 3);
        box(58, 74, 84, 12, dough, 3);
        for (var row = 0; row < 3; row++) {
          line(
            67,
            91 + row * 13,
            133,
            91 + row * 13,
            cream.withValues(alpha: .6),
            2,
          );
          line(
            row.isEven ? 88 : 112,
            84 + row * 13,
            row.isEven ? 88 : 112,
            91 + row * 13,
            cream.withValues(alpha: .6),
            2,
          );
        }
        box(79, 57, 40, 18, red, 5);
        oval(85, 37, 30, 32, pink);
        polygon(const [
          Offset(83, 54),
          Offset(100, 76),
          Offset(117, 54),
        ], cream);
        polygon(const [Offset(79, 42), Offset(105, 11), Offset(121, 42)], red);
        box(79, 40, 43, 8, cream, 3);
        oval(102, 8, 10, 10, cream);
        oval(92, 50, 3, 3, ink);
        oval(105, 50, 3, 3, ink);
        line(79, 65, 64, 56, red, 8);
        line(119, 65, 134, 56, red, 8);
        line(157, 98, 157, 39, gold, 5);
        line(157, 39, 145, 53, gold, 5);
        line(157, 39, 169, 53, gold, 5);
      case AchievementScene.bells:
        // An open songbook, a pair of golden bells and hand-drawn notes.
        polygon(const [
          Offset(31, 80),
          Offset(91, 72),
          Offset(100, 80),
          Offset(109, 72),
          Offset(169, 80),
          Offset(169, 122),
          Offset(109, 114),
          Offset(100, 122),
          Offset(91, 114),
          Offset(31, 122),
        ], green);
        polygon(const [
          Offset(36, 76),
          Offset(93, 68),
          Offset(100, 76),
          Offset(107, 68),
          Offset(164, 76),
          Offset(164, 115),
          Offset(107, 107),
          Offset(100, 115),
          Offset(93, 107),
          Offset(36, 115),
        ], cream);
        line(100, 77, 100, 113, dough, 1);
        for (var row = 0; row < 3; row++) {
          line(45, 86 + row * 8, 86, 81 + row * 8, mint, 1);
          line(114, 81 + row * 8, 155, 86 + row * 8, mint, 1);
        }
        ornament(DoorMotif.bell, 39, 14, 62);
        ornament(DoorMotif.bell, 97, 8, 62);
        for (final note in [const Offset(61, 97), const Offset(132, 92)]) {
          oval(note.dx - 4, note.dy - 2, 8, 5, green);
          line(note.dx + 3, note.dy, note.dx + 3, note.dy - 14, green, 2);
          line(note.dx + 3, note.dy - 14, note.dx + 10, note.dy - 11, green, 2);
        }
        line(24, 39, 24, 23, gold, 3);
        oval(16, 38, 10, 7, gold);
        line(170, 55, 170, 38, blue, 3);
        oval(162, 54, 10, 7, blue);
      case AchievementScene.hanukkah:
        paintHanukkahMotif(canvas, const Rect.fromLTWH(55, 12, 94, 94), 1);
        paintHanukkahMotif(canvas, const Rect.fromLTWH(21, 76, 42, 42), 2);
        paintHanukkahMotif(canvas, const Rect.fromLTWH(146, 80, 34, 34), 3);
        for (var i = 0; i < 9; i++) {
          oval(56 + i * 11, 122, 6, 6, i.isEven ? blue : gold);
        }
      case AchievementScene.allAchievements:
        // A voucher envelope with an EXTRA tag, deliberately separate from
        // the daily present illustration used in the game completion flow.
        box(39, 51, 123, 68, green, 7);
        box(52, 27, 95, 70, cream, 5);
        label('BONUS', 99, 39, 17, green);
        line(68, 64, 132, 64, gold, 2);
        line(78, 73, 122, 73, mint, 2);
        polygon(const [
          Offset(39, 60),
          Offset(100, 96),
          Offset(162, 60),
          Offset(162, 119),
          Offset(39, 119),
        ], mint);
        line(40, 117, 83, 88, green.withValues(alpha: .3), 1);
        line(161, 117, 118, 88, green.withValues(alpha: .3), 1);
        oval(90, 90, 20, 20, gold);
        label('+', 100, 89, 20, green);
        fir(172, 96, .42);
        paintStar(canvas, const Offset(27, 34), 7, gold);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(AchievementPainter oldDelegate) =>
      oldDelegate.scene != scene;
}
