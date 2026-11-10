import 'package:advent_calendar/challenges/oy_vey/mouth_tracking.dart';
import 'package:advent_calendar/challenges/oy_vey/oy_vey_game.dart';
import 'package:flutter_test/flutter_test.dart';

const open = CatchMouth(.5, .5, .11, true);
OyVeyGame game() => OyVeyGame(const OyVeyLevel(spawnSeconds: 999, seed: 1));
FallingObject item(
  int id,
  FestiveObject kind, {
  double x = .5,
  double y = .5,
}) => FallingObject(id: id, kind: kind, x: x, y: y);
MouthObservation pose(double ratio, {double x = .5}) =>
    MouthObservation(x: x, y: .55, width: .12, gapRatio: ratio);

void main() {
  test('15 correct objects win; each is counted once', () {
    final g = game();
    for (var i = 0; i < 15; i++) {
      g.objects.add(item(i, FestiveObject.values[i % 3]));
    }
    g.advance(.01, open);
    expect(g.won, isTrue);
    expect(g.collected, 15);
    expect(g.feedback, 'Mazel tov!');
    g.advance(.1, open);
    expect(g.collected, 15);
    expect(g.mistakes, 0);
  });
  test('three Christmas objects lose, with no extra counts afterwards', () {
    final g = game();
    for (var i = 0; i < 4; i++) {
      g.objects.add(item(i, FestiveObject.values[3 + i % 3]));
    }
    g.advance(.01, open);
    expect(g.lost, isTrue);
    expect(g.mistakes, 3);
    expect(g.collected, 0);
    expect(g.feedback, 'Oy vey!');
    g.advance(.1, open);
    expect(g.mistakes, 3);
  });
  test(
    'closed mouths swallow nothing and missed good objects are harmless',
    () {
      final g = game()..objects.add(item(1, FestiveObject.tree));
      for (var i = 0; i < 100; i++) {
        g.advance(.1, const CatchMouth(.5, .5, .11, false));
      }
      expect(g.mistakes, 0);
      expect(g.collected, 0);
      expect(g.objects, isEmpty);
      g.objects.add(item(2, FestiveObject.sufganiyah, x: .9, y: 1.1));
      g.advance(.1, open);
      expect(g.mistakes, 0);
      expect(g.objects, isEmpty);
    },
  );
  test('swept collision catches fast falling objects without tunnelling', () {
    final g = OyVeyGame(const OyVeyLevel(startSpeed: 20, spawnSeconds: 999));
    g.objects.add(item(1, FestiveObject.dreidel, y: 0));
    g.advance(.1, open);
    expect(g.collected, 1);
  });
  test('ellipse collision rejects corners of its enclosing rectangle', () {
    final g = game()..objects.add(item(1, FestiveObject.tree, x: .64, y: .535));
    g.advance(.001, open);
    expect(g.mistakes, 0);
  });
  test(
    'head movement is swept, while loss/reacquisition never teleports catches',
    () {
      final g = game();
      g.advance(.01, const CatchMouth(.2, .5, .07, true));
      g.objects.add(item(1, FestiveObject.sufganiyah));
      g.advance(.01, const CatchMouth(.8, .5, .07, true));
      expect(g.collected, 1);
      final paused = game();
      paused.advance(.01, const CatchMouth(.2, .5, .07, true));
      paused.objects.add(item(1, FestiveObject.tree));
      final elapsed = paused.elapsed;
      paused.advance(100, null);
      expect(paused.elapsed, elapsed);
      expect(paused.objects.single.y, .5);
      paused.advance(.01, const CatchMouth(.8, .5, .07, true));
      expect(paused.mistakes, 0);
    },
  );
  test('spawn and speed increase gradually and seeded runs are repeatable', () {
    final a = OyVeyGame(const OyVeyLevel(seed: 7)),
        b = OyVeyGame(const OyVeyLevel(seed: 7));
    final speed = a.speed, interval = a.spawnInterval;
    for (var i = 0; i < 100; i++) {
      a.advance(.1, const CatchMouth(.5, .8, .1, false));
      b.advance(.1, const CatchMouth(.5, .8, .1, false));
    }
    expect(a.objects.map((o) => o.kind), b.objects.map((o) => o.kind));
    expect(a.objects.map((o) => o.x), b.objects.map((o) => o.x));
    expect(a.speed, greaterThan(speed));
    a.collected = 10;
    expect(a.spawnInterval, lessThan(interval));
  });
  test(
    'invalid timing and mouth coordinates do not progress the simulation',
    () {
      final g = game();
      g.advance(double.nan, open);
      g.advance(-1, open);
      g.advance(1, const CatchMouth(double.nan, .5, .1, true));
      expect(g.elapsed, 0);
      expect(g.objects, isEmpty);
      expect(() => OyVeyGame(const OyVeyLevel(target: 0)), throwsArgumentError);
    },
  );
  test('lip gap is aspect-correct, scale-independent and roll-invariant', () {
    final m = measureMouth(
      upper: const LipPoint(.5, .49),
      lower: const LipPoint(.5, .51),
      left: const LipPoint(.4, .5),
      right: const LipPoint(.6, .5),
      imageWidth: 400,
      imageHeight: 800,
    )!;
    expect(m.gapRatio, closeTo(.2, 1e-9));
    expect(m.width, closeTo(.2, 1e-9));
    final rolled = measureMouth(
      upper: const LipPoint(.48, .5),
      lower: const LipPoint(.52, .5),
      left: const LipPoint(.5, .45),
      right: const LipPoint(.5, .55),
      imageWidth: 400,
      imageHeight: 800,
    )!;
    expect(rolled.gapRatio, closeTo(m.gapRatio, 1e-9));
    expect(
      measureMouth(
        upper: const LipPoint(.5, .5),
        lower: const LipPoint(.5, .5),
        left: const LipPoint(.5, .5),
        right: const LipPoint(.5, .5),
        imageWidth: 400,
        imageHeight: 800,
      ),
      isNull,
    );
  });
  test('calibration requires stable closed and distinctly open samples', () {
    final c = MouthCalibration();
    for (var i = 0; i < 25; i++) {
      c.update(pose(.3));
    }
    expect(c.step, CalibrationStep.closed);
    for (var i = 0; i < 20; i++) {
      c.update(pose(.02));
    }
    expect(c.step, CalibrationStep.open);
    for (var i = 0; i < 20; i++) {
      c.update(pose(.06));
    }
    expect(c.step, CalibrationStep.open);
    for (var i = 0; i < 12; i++) {
      c.update(pose(.3));
    }
    expect(c.step, CalibrationStep.ready);
    expect(c.isOpen, isTrue);
    for (var i = 0; i < 12; i++) {
      c.update(pose(.15));
    }
    expect(c.isOpen, isTrue);
    for (var i = 0; i < 12; i++) {
      c.update(pose(.02));
    }
    expect(c.isOpen, isFalse);
    for (var i = 0; i < 12; i++) {
      c.update(pose(.15));
    }
    expect(c.isOpen, isFalse);
    c.update(null);
    expect(c.mouth, isNull);
    expect(c.isOpen, isFalse);
    expect(c.step, CalibrationStep.ready);
    c.update(pose(.3, x: .8));
    expect(c.mouth!.x, .8);
    c.reset();
    expect(c.step, CalibrationStep.closed);
  });
}
