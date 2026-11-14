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

/// Position smoothing only. No opening threshold or calibration is required.
class MouthTracker {
  MouthObservation? mouth;
  void reset() => mouth = null;
  void lost() => mouth = null;
  void update(MouthObservation? next) {
    if (next == null || !next.valid) {
      lost();
      return;
    }
    final old = mouth;
    const response = .62;
    mouth = old == null
        ? next
        : MouthObservation(
            x: old.x + (next.x - old.x) * response,
            y: old.y + (next.y - old.y) * response,
            width: old.width + (next.width - old.width) * response,
            gapRatio: next.gapRatio,
          );
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
