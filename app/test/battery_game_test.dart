import 'package:advent_calendar/challenges/battery/battery_game.dart';
import 'package:advent_calendar/challenges/games/difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('five initially critical devices and exactly one cable', () {
    final g = BatteryGame(const BatteryLevel(seed: 1));
    expect(g.devices.length, 5);
    expect(g.devices.map((d) => d.kind).toSet().length, 5);
    for (final d in g.devices) {
      expect(d.battery, inInclusiveRange(1, 10));
    }
    g.advance(1);
    expect(g.elapsed, 0);
    g.connect(0);
    g.start();
    final initial = g.devices.map((d) => d.battery).toList();
    g.advance(.1);
    expect(g.devices[0].battery, greaterThan(initial[0]));
    for (var i = 1; i < 5; i++) {
      expect(g.devices[i].battery, lessThan(initial[i]));
    }
    g.connect(3);
    final before = g.devices[0].battery;
    g.advance(.1);
    expect(g.connected, 3);
    expect(g.devices[0].battery, lessThan(before));
    g.connect(-1);
    g.connect(5);
    expect(g.connected, 3);
  });
  test('unplugging stops charging until reconnected', () {
    final g = BatteryGame(const BatteryLevel(seed: 1))
      ..start()
      ..connect(0);
    g.advance(.1);
    final before = g.devices[0].battery;
    g.disconnect();
    g.advance(.1);
    expect(g.connected, isNull);
    expect(g.devices[0].battery, lessThan(before));
    g.connect(1);
    expect(g.connected, 1);
  });
  test(
    'unattended devices die, failure freezes all further input and time',
    () {
      final g = BatteryGame(const BatteryLevel(seed: 2))..start();
      for (var i = 0; i < 150; i++) {
        g.advance(.1);
      }
      expect(g.phase, BatteryPhase.lost);
      expect(g.devices[g.failedDevice!].battery, 0);
      final time = g.elapsed;
      g.connect(0);
      g.start();
      g.advance(.1);
      expect(g.connected, isNull);
      expect(g.elapsed, time);
    },
  );
  test(
    'events increase consumption, expire, and the round grows more frantic',
    () {
      final g = BatteryGame(
        const BatteryLevel(seed: 4, eventInterval: .1, eventDuration: .3),
      )..start();
      g.advance(.1);
      g.advance(.01);
      final index = g.devices.indexWhere((d) => d.eventLeft > 0);
      expect(index, greaterThanOrEqualTo(0));
      final boosted = g.drainFor(index);
      g.devices[index].eventLeft = 0;
      expect(g.drainFor(index), lessThan(boosted));
      final baseline = g.drainFor(index);
      g.devices[index].eventLeft = .005;
      g.advance(.01);
      expect(g.devices[index].eventLeft, 0);
      g.elapsed = 30;
      expect(g.drainFor(index), greaterThan(baseline));
    },
  );
  test('no battery exceeds 100 and zero at the deadline is a loss', () {
    final g = BatteryGame(const BatteryLevel(duration: .1, seed: 8))
      ..start()
      ..connect(0);
    g.devices[0].battery = 99.99;
    g.advance(.1);
    expect(g.phase, BatteryPhase.won);
    expect(g.devices[0].battery, 100);
    final failed = BatteryGame(const BatteryLevel(duration: .1))..start();
    failed.devices[2].battery = .0001;
    failed.advance(.1);
    expect(failed.phase, BatteryPhase.lost);
  });
  test('attentive human-paced switching wins every seeded difficulty', () {
    final failures = <String>[];
    for (final difficulty in GameDifficulty.values) {
      final base = BatteryLevel.forDifficulty(difficulty);
      expect(base.duration, 45);
      for (var seed = 0; seed < 100; seed++) {
        final g = BatteryGame(
          BatteryLevel(
            seed: seed,
            drain: base.drain,
            charge: base.charge,
            eventInterval: base.eventInterval,
            eventBoost: base.eventBoost,
            initialMinimum: base.initialMinimum,
            initialMaximum: base.initialMaximum,
          ),
        )..start();
        var switches = 0;
        // React every half-second, rather than a superhuman frame-by-frame solver.
        while (g.phase == BatteryPhase.playing) {
          final urgent = List.generate(5, (i) => i)
            ..sort(
              (a, b) => (g.devices[a].battery / g.drainFor(a)).compareTo(
                g.devices[b].battery / g.drainFor(b),
              ),
            );
          final target = urgent.first;
          if (g.connected == null ||
              g.devices[g.connected!].battery / g.drainFor(g.connected!) >
                  g.devices[target].battery / g.drainFor(target) + 4) {
            g.disconnect();
            // Include a realistic brief unplugged interval for every move.
            g.advance(.1);
            g.advance(.05);
            g.connect(target);
            switches++;
          }
          for (var i = 0; i < 5; i++) {
            g.advance(.1);
          }
        }
        if (g.phase != BatteryPhase.won) {
          failures.add('$difficulty seed $seed at ${g.elapsed}');
        }
        expect(switches, greaterThan(8));
        expect(switches, lessThan(90));
      }
    }
    expect(failures, isEmpty);
  });
  test('seed repeats events, invalid inputs do not move time', () {
    final a = BatteryGame(const BatteryLevel(seed: 44))..start();
    final b = BatteryGame(const BatteryLevel(seed: 44))..start();
    for (var i = 0; i < 60; i++) {
      a.advance(.1);
      b.advance(.1);
    }
    expect(a.devices.map((d) => d.battery), b.devices.map((d) => d.battery));
    expect(
      a.devices.map((d) => d.eventLeft),
      b.devices.map((d) => d.eventLeft),
    );
    final time = a.elapsed;
    a.advance(double.nan);
    a.advance(-1);
    a.advance(0);
    expect(a.elapsed, time);
    expect(
      () => BatteryGame(const BatteryLevel(charge: 0)),
      throwsArgumentError,
    );
    expect(
      () => BatteryGame(const BatteryLevel(initialMinimum: 0)),
      throwsArgumentError,
    );
  });
}
