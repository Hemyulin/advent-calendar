import 'package:flutter/material.dart';
import 'mouth_camera.dart';
import 'mouth_tracking.dart';

/// Other platforms can use the explicitly labelled development driver.
class LocalMouthCamera extends MouthCamera {
  @override
  MouthCameraState state = MouthCameraState.idle;
  @override
  MouthObservation? get observation => null;
  @override
  bool get multipleFaces => false;
  @override
  double get aspectRatio => .75;
  @override
  Widget preview() => const SizedBox.expand();
  @override
  Future<void> start() async {
    state = MouthCameraState.unavailable;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    state = MouthCameraState.idle;
    notifyListeners();
  }
}
