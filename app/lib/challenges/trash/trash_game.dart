import 'dart:math' as math;

/// A tiny two-step chore. Removing the rubbish alone never completes it.
enum TrashPhase { takeOut, outside, replaceBag, spilled, finished }

enum TrashItem { fullBag, freshBag }

class TrashPoint {
  const TrashPoint(this.x, this.y);
  final double x, y;
}

class TrashGame {
  TrashPhase _phase = TrashPhase.takeOut;
  TrashItem? _held;
  TrashPhase get phase => _phase;
  TrashItem? get held => _held;
  TrashPoint? _origin, _last;
  bool _lifted = false, _spillOutside = false;
  TrashPoint _spillAt = const TrashPoint(.46, .6);
  bool get lifted => _lifted;
  bool get lost => _phase == TrashPhase.spilled;
  bool get spillOutside => _spillOutside;
  TrashPoint get spillAt => _spillAt;
  double rollX = .53;
  double rollAngle = 0;
  double _rollVelocity = 0;
  static const rollY = .25;
  bool get rolling => _rollVelocity.abs() > .001;
  bool get won => _phase == TrashPhase.finished;

  bool begin(TrashPoint point) {
    if (_held != null || won || lost) return false;
    if (_phase == TrashPhase.takeOut && _inside(point, .29, .36, .63, .85)) {
      _held = TrashItem.fullBag;
    } else if (_phase == TrashPhase.outside &&
        _inside(point, .29, .57, .61, .9)) {
      _held = TrashItem.fullBag;
      _lifted = true;
    } else if (_phase == TrashPhase.replaceBag &&
        _inside(point, rollX - .105, rollY - .08, rollX + .105, rollY + .08)) {
      _held = TrashItem.freshBag;
      stopRoll();
    }
    if (_held != null) {
      _origin = point;
      _last = point;
    }
    return _held != null;
  }

  /// First lift vertically, then keep holding while carrying to the door.
  /// Entering the doorway transfers the bag outside before the finger is lifted.
  bool move(TrashPoint point) {
    if (_held == null || !point.x.isFinite || !point.y.isFinite) return false;
    _last = point;
    if (_held == TrashItem.fullBag && _phase == TrashPhase.takeOut) {
      final rise = _origin!.y - point.y;
      if (!_lifted &&
          rise >= .1 &&
          (point.x - _origin!.x).abs() <= rise * 1.8) {
        _lifted = true;
      }
      if (_lifted && _inside(point, .71, .08, 1, .64)) {
        _phase = TrashPhase.outside;
        _held = null;
        _lifted = false;
        return true;
      }
    }
    return false;
  }

  bool drop(TrashPoint point) {
    if (move(point)) return true;
    final item = _held;
    _held = null;
    if (item == TrashItem.fullBag &&
        _phase == TrashPhase.outside &&
        _inside(point, .64, .3, .95, .72)) {
      _phase = TrashPhase.replaceBag;
      _lifted = false;
      return true;
    }
    if (item == TrashItem.fullBag && _lifted) {
      _spillOutside = _phase == TrashPhase.outside;
      _spillAt = point.x.isFinite && point.y.isFinite ? point : _last!;
      _phase = TrashPhase.spilled;
      _lifted = false;
      stopRoll();
      return false;
    }
    if (item == TrashItem.freshBag &&
        _phase == TrashPhase.replaceBag &&
        _inside(point, .25, .41, .67, .88)) {
      _phase = TrashPhase.finished;
      return true;
    }
    return false;
  }

  /// OS interruptions restore the carried item; releasing an active drag spills.
  void cancel({bool interrupted = false}) {
    if (!interrupted && _held == TrashItem.fullBag && _lifted) {
      drop(_last!);
    } else {
      _held = null;
      _lifted = false;
    }
  }

  void stopRoll() => _rollVelocity = 0;

  /// A cylindrical roll rolls along the floor, never into the bin by itself.
  /// Input and time are bounded; grabbing it immediately stops its momentum.
  bool advance(double seconds, double tiltX) {
    if ((_phase != TrashPhase.replaceBag && _phase != TrashPhase.takeOut) ||
        _held != null ||
        !seconds.isFinite ||
        seconds <= 0 ||
        !tiltX.isFinite) {
      return false;
    }
    final dt = seconds.clamp(0.0, .05);
    final input = tiltX.abs() < .025 ? 0.0 : tiltX.clamp(-1.0, 1.0);
    _rollVelocity = ((_rollVelocity + input * 1.7 * dt) * math.exp(-3 * dt))
        .clamp(-.45, .45);
    if (input == 0 && _rollVelocity.abs() < .001) _rollVelocity = 0;
    final before = rollX;
    rollX = (rollX + _rollVelocity * dt).clamp(.11, .57);
    if (rollX == .11 || rollX == .57) _rollVelocity *= -.25;
    rollAngle += (rollX - before) / .055;
    return (rollX - before).abs() > .000001;
  }

  bool _inside(
    TrashPoint p,
    double left,
    double top,
    double right,
    double bottom,
  ) =>
      p.x.isFinite &&
      p.y.isFinite &&
      p.x >= left &&
      p.x <= right &&
      p.y >= top &&
      p.y <= bottom;
}
