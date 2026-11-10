import 'dart:math' as math;
import '../games/difficulty.dart';

enum BatteryPhase { ready, playing, won, lost }

enum DeviceKind {
  phone('Smartphone', .72, 'Neue Nachrichten'),
  watch('Smartwatch', .50, 'Training läuft'),
  tablet('Tablet', .84, 'Video läuft'),
  headphones('Kopfhörer', .62, 'Musik aufgedreht'),
  laptop('Laptop', 1.04, 'Update läuft');

  const DeviceKind(this.label, this.drain, this.eventLabel);
  final String label, eventLabel;
  final double drain;
}

class BatteryLevel {
  const BatteryLevel({
    this.duration = 45,
    this.drain = 1,
    this.charge = 7.2,
    this.eventInterval = 4.8,
    this.eventDuration = 2.6,
    this.eventBoost = .8,
    this.initialMinimum = 6,
    this.initialMaximum = 10,
    this.seed,
  });
  final double duration,
      drain,
      charge,
      eventInterval,
      eventDuration,
      eventBoost;
  final int initialMinimum, initialMaximum;
  final int? seed;
  factory BatteryLevel.forDifficulty(GameDifficulty difficulty) =>
      switch (difficulty) {
        GameDifficulty.easy => const BatteryLevel(
          drain: .8,
          charge: 7.4,
          eventInterval: 6.5,
          eventBoost: .6,
        ),
        GameDifficulty.normal => const BatteryLevel(),
        GameDifficulty.hard => const BatteryLevel(
          drain: 1.12,
          charge: 7.5,
          eventInterval: 3.5,
          eventBoost: 1,
          initialMinimum: 4,
          initialMaximum: 8,
        ),
      };
}

class BatteryDevice {
  BatteryDevice(this.kind, this.battery);
  final DeviceKind kind;
  double battery, eventLeft = 0;
}

/// Percentages and seconds only. Input, lifecycle and rendering live elsewhere.
class BatteryGame {
  BatteryGame(this.level) : _random = math.Random(level.seed) {
    if ([
          level.duration,
          level.drain,
          level.charge,
          level.eventInterval,
          level.eventDuration,
        ].any((v) => !v.isFinite || v <= 0) ||
        !level.eventBoost.isFinite ||
        level.eventBoost < 0 ||
        level.initialMinimum < 1 ||
        level.initialMaximum > 10 ||
        level.initialMinimum > level.initialMaximum) {
      throw ArgumentError('Invalid battery level');
    }
    devices = [
      for (final kind in DeviceKind.values)
        BatteryDevice(
          kind,
          (level.initialMinimum +
                  _random.nextInt(
                    level.initialMaximum - level.initialMinimum + 1,
                  ))
              .toDouble(),
        ),
    ];
    _nextEvent = level.eventInterval;
  }
  final BatteryLevel level;
  final math.Random _random;
  late final List<BatteryDevice> devices;
  BatteryPhase phase = BatteryPhase.ready;
  double elapsed = 0, feedbackLeft = 0;
  late double _nextEvent;
  int? connected, failedDevice;
  int eventCount = 0;
  String feedback = '';
  double get progress => (elapsed / level.duration).clamp(0.0, 1.0);
  double get remaining => math.max(0, level.duration - elapsed);
  double get intensity => 1 + .45 * progress;
  double drainFor(int index) =>
      devices[index].kind.drain * level.drain * intensity +
      (devices[index].eventLeft > 0 ? level.eventBoost * intensity : 0);

  void start() {
    if (phase == BatteryPhase.ready) phase = BatteryPhase.playing;
  }

  void connect(int index) {
    if (index < 0 ||
        index >= devices.length ||
        phase == BatteryPhase.won ||
        phase == BatteryPhase.lost) {
      return;
    }
    connected = index;
  }

  void advance(double seconds) {
    if (phase != BatteryPhase.playing || !seconds.isFinite || seconds <= 0) {
      return;
    }
    // UI pauses suspended time. A stalled foreground frame cannot kill a device.
    var left = math.min(seconds, .1);
    while (left > 1e-9 && phase == BatteryPhase.playing) {
      final h = math.min(left, math.min(1 / 120, remaining));
      _step(h);
      left -= h;
    }
  }

  void _step(double h) {
    elapsed = math.min(level.duration, elapsed + h);
    feedbackLeft = math.max(0, feedbackLeft - h);
    for (var i = 0; i < devices.length; i++) {
      final d = devices[i];
      final change = (connected == i ? level.charge : 0) - drainFor(i);
      d.battery = (d.battery + change * h).clamp(0.0, 100.0);
      d.eventLeft = math.max(0, d.eventLeft - h);
      if (d.battery <= 0 && failedDevice == null) failedDevice = i;
    }
    // A dead battery on the final frame is still a loss.
    if (failedDevice != null) {
      phase = BatteryPhase.lost;
    } else if (remaining <= 1e-8) {
      phase = BatteryPhase.won;
    } else if (elapsed >= _nextEvent) {
      final available = [
        for (var i = 0; i < devices.length; i++)
          if (devices[i].eventLeft <= 0) i,
      ];
      if (available.isNotEmpty) {
        final index = available[_random.nextInt(available.length)];
        devices[index].eventLeft = level.eventDuration;
        eventCount++;
        feedback = eventCount.isOdd
            ? 'Ach, das hält noch!'
            : 'Lade ich später.';
        feedbackLeft = 2;
      }
      _nextEvent =
          elapsed +
          level.eventInterval * (.85 + _random.nextDouble() * .3) / intensity;
    }
  }
}
