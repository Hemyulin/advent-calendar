import 'dart:math' as math;

class MouthObservation {
  const MouthObservation({
    required this.x,
    required this.y,
    required this.width,
    required this.gapRatio,
  });

  /// Normalized upright, mirrored preview coordinates, with pixel-space gap/width.
  final double x, y, width, gapRatio;
  bool get valid =>
      [x, y, width, gapRatio].every((v) => v.isFinite) &&
      x > .02 &&
      x < .98 &&
      y > .02 &&
      y < .98 &&
      width >= .035 &&
      width <= .4 &&
      gapRatio >= 0 &&
      gapRatio <= 1;
}

enum CalibrationStep { closed, open, ready }

/// Closed/open calibration and hysteresis are independent of the camera backend.
class MouthCalibration {
  CalibrationStep step = CalibrationStep.closed;
  final List<double> _samples = [];
  double closedRatio = 0, openRatio = 0;
  MouthObservation? mouth;
  bool isOpen = false;
  double amount = 0;
  int get samples => _samples.length;

  void reset() {
    step = CalibrationStep.closed;
    _samples.clear();
    closedRatio = 0;
    openRatio = 0;
    lost();
  }

  void lost() {
    mouth = null;
    isOpen = false;
    amount = 0;
    _samples.clear();
  }

  double _median(List<double> values) {
    final sorted = List<double>.of(values)..sort();
    return sorted[sorted.length ~/ 2];
  }

  void update(MouthObservation? next) {
    if (next == null || !next.valid) {
      lost();
      return;
    }
    final old = mouth;
    // Same response used by Brush Buddies for its tracked mouth bounds.
    const response = .62;
    mouth = old == null
        ? next
        : MouthObservation(
            x: old.x + (next.x - old.x) * response,
            y: old.y + (next.y - old.y) * response,
            width: old.width + (next.width - old.width) * response,
            gapRatio: old.gapRatio + (next.gapRatio - old.gapRatio) * response,
          );
    if (step == CalibrationStep.closed) {
      if (next.gapRatio > .12) {
        _samples.clear();
        return;
      }
      _samples.add(next.gapRatio);
      if (_samples.length > 20) _samples.removeAt(0);
      if (_samples.length == 20 &&
          _samples.reduce(math.max) - _samples.reduce(math.min) < .035) {
        closedRatio = _median(_samples);
        _samples.clear();
        step = CalibrationStep.open;
      }
    } else if (step == CalibrationStep.open) {
      if (next.gapRatio < closedRatio + .08) {
        _samples.clear();
        return;
      }
      _samples.add(next.gapRatio);
      if (_samples.length > 12) _samples.removeAt(0);
      if (_samples.length == 12 &&
          _samples.reduce(math.max) - _samples.reduce(math.min) < .06) {
        openRatio = _median(_samples);
        _samples.clear();
        step = CalibrationStep.ready;
      }
    }
    if (step == CalibrationStep.ready) {
      amount = ((mouth!.gapRatio - closedRatio) / (openRatio - closedRatio))
          .clamp(0.0, 1.0);
      if (!isOpen && amount >= .55) {
        isOpen = true;
      } else if (isOpen && amount <= .3) {
        isOpen = false;
      }
    }
  }
}

class LipPoint {
  const LipPoint(this.x, this.y);
  final double x, y;
}

/// Distances are measured in pixels, not normalized x/y units, so portrait
/// aspect ratio, distance from camera and head roll do not skew openness.
MouthObservation? measureMouth({
  required LipPoint upper,
  required LipPoint lower,
  required LipPoint left,
  required LipPoint right,
  required int imageWidth,
  required int imageHeight,
}) {
  if (imageWidth <= 0 || imageHeight <= 0) return null;
  double distance(LipPoint a, LipPoint b) => math.sqrt(
    math.pow((a.x - b.x) * imageWidth, 2) +
        math.pow((a.y - b.y) * imageHeight, 2),
  );
  final width = distance(left, right);
  if (!width.isFinite || width < 12) return null;
  final result = MouthObservation(
    x: (upper.x + lower.x) / 2,
    y: (upper.y + lower.y) / 2,
    width: width / imageWidth,
    gapRatio: distance(upper, lower) / width,
  );
  return result.valid ? result : null;
}
