import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'maze_game.dart';

abstract interface class TiltSource {
  Stream<Vec2> get events;
}

/// The Android adapter is isolated from both physics and puzzle progress.
/// Unsupported hosts and devices without sensors fall back to touch controls.
class DeviceTiltSource implements TiltSource {
  static const _channel = EventChannel('advent_calendar/tilt');
  @override
  Stream<Vec2> get events {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return Stream.error(UnsupportedError('No native tilt adapter'));
    }
    return _channel.receiveBroadcastStream().map((event) {
      final values = event as List<dynamic>;
      final x = (values[0] as num).toDouble();
      final y = (values[1] as num).toDouble();
      return x.isFinite && y.isFinite ? Vec2(x, y) : Vec2.zero;
    });
  }
}
