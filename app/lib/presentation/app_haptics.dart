import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Meaningful input/result cues only, never animation frames or scrolling.
/// Unsupported platforms and disabled per-game feedback never block gameplay.
abstract final class AppHaptics {
  static final _clock = Stopwatch()..start();
  static final _last = <String, int>{};

  static void _emit(
    BuildContext context,
    String kind,
    int interval,
    Future<void> Function() effect,
  ) {
    if (!(HapticsScope.maybeOf(context)?.enabled ?? true)) return;
    final now = _clock.elapsedMilliseconds;
    if (now - (_last[kind] ?? -10000) < interval) return;
    _last[kind] = now;
    unawaited(
      Future<void>.sync(effect).catchError((Object _) {
        // No haptic motor/platform support is a normal fallback.
      }),
    );
  }

  static void selection(BuildContext context) =>
      _emit(context, 'selection', 60, HapticFeedback.selectionClick);
  static void tap(BuildContext context) =>
      _emit(context, 'tap', 80, HapticFeedback.lightImpact);
  static void success(BuildContext context) =>
      _emit(context, 'success', 180, HapticFeedback.mediumImpact);
  static void error(BuildContext context) =>
      _emit(context, 'error', 180, HapticFeedback.mediumImpact);
  static void locked(BuildContext context) =>
      _emit(context, 'locked', 220, HapticFeedback.heavyImpact);

  @visibleForTesting
  static void resetForTesting() => _last.clear();
}

/// Reuses Akku/Öl-Panik's existing opt-in switch for shared result/navigation cues.
class HapticsScope extends InheritedWidget {
  const HapticsScope({super.key, required this.enabled, required super.child});
  final bool enabled;
  static HapticsScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HapticsScope>();
  @override
  bool updateShouldNotify(HapticsScope oldWidget) =>
      enabled != oldWidget.enabled;
}
