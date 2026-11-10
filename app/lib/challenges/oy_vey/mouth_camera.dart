import 'package:flutter/material.dart';
import 'mouth_tracking.dart';

export 'local_mouth_camera_stub.dart'
    if (dart.library.io) 'local_mouth_camera_native.dart';

enum MouthCameraState {
  idle,
  loading,
  ready,
  permissionDenied,
  unavailable,
  failed,
}

abstract class MouthCamera extends ChangeNotifier {
  MouthCameraState get state;
  MouthObservation? get observation;
  bool get multipleFaces;
  double get aspectRatio;
  Widget preview();
  Future<void> start();
  Future<void> stop();
}
