/// A tiny two-step chore. Removing the rubbish alone never completes it.
enum TrashPhase { takeOut, replaceBag, finished }

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
  bool get won => _phase == TrashPhase.finished;

  bool begin(TrashPoint point) {
    if (_held != null || won) return false;
    if (_phase == TrashPhase.takeOut && _inside(point, .29, .36, .63, .85)) {
      _held = TrashItem.fullBag;
    } else if (_phase == TrashPhase.replaceBag &&
        _inside(point, .72, .68, .97, .91)) {
      _held = TrashItem.freshBag;
    }
    return _held != null;
  }

  bool drop(TrashPoint point) {
    final item = _held;
    _held = null;
    if (item == TrashItem.fullBag &&
        _phase == TrashPhase.takeOut &&
        _inside(point, .71, .08, 1, .39)) {
      _phase = TrashPhase.replaceBag;
      return true;
    }
    if (item == TrashItem.freshBag &&
        _phase == TrashPhase.replaceBag &&
        _inside(point, .25, .41, .67, .88)) {
      _phase = TrashPhase.finished;
      return true;
    }
    return false;
  }

  void cancel() => _held = null;

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
