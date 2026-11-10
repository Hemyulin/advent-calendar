import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';
import 'camera_image_adapter.dart';
import 'mouth_camera.dart';
import 'mouth_tracking.dart';

/// Camera/conversion/rotation pattern adapted from Brush Buddies. Unlike its
/// photo flow this adapter exposes no recording, capture, disk or network API.
class LocalMouthCamera extends MouthCamera {
  MouthCameraState _state = MouthCameraState.idle;
  @override
  MouthCameraState get state => _state;
  MouthObservation? _observation;
  @override
  MouthObservation? get observation => _observation;
  @override
  bool multipleFaces = false;
  CameraController? _camera;
  FaceDetectorProcessor? _detector;
  FaceMeshProcessor? _mesh;
  Future<void> _operations = Future.value();
  int _epoch = 0;
  int _frameFailures = 0;
  int? _lastRotation;
  bool _disposed = false, _busy = false;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);
  @override
  double get aspectRatio {
    final c = _camera;
    final size = c?.value.previewSize;
    if (c == null || size == null) return .75;
    final portrait =
        c.value.deviceOrientation == DeviceOrientation.portraitUp ||
        c.value.deviceOrientation == DeviceOrientation.portraitDown;
    return portrait ? size.height / size.width : size.width / size.height;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _valid(int epoch) => !_disposed && epoch == _epoch;
  @override
  Widget preview() => _camera?.value.isInitialized == true
      ? CameraPreview(_camera!)
      : const SizedBox.expand();

  @override
  Future<void> start() {
    final epoch = ++_epoch;
    _operations = _operations.then((_) => _start(epoch));
    return _operations;
  }

  Future<void> _start(int epoch) async {
    await _release();
    if (!_valid(epoch)) return;
    _frameFailures = 0;
    _state = MouthCameraState.loading;
    _notify();
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        _state = MouthCameraState.unavailable;
        _notify();
        return;
      }
      final cameras = await availableCameras();
      if (!_valid(epoch)) return;
      final front = cameras
          .where((c) => c.lensDirection == CameraLensDirection.front)
          .firstOrNull;
      if (front == null) {
        _state = MouthCameraState.unavailable;
        _notify();
        return;
      }
      final camera = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      _camera = camera;
      await camera.initialize();
      if (!_valid(epoch)) {
        await _release();
        return;
      }
      _detector = await FaceDetectorProcessor.create(
        delegate: FaceMeshDelegate.xnnpack,
        maxResults: 2,
        minDetectionConfidence: .55,
        roiScaleY: 1.7,
        roiShiftY: -.2,
      );
      _mesh = await FaceMeshProcessor.create(
        delegate: FaceMeshDelegate.xnnpack,
        minDetectionConfidence: .55,
        minTrackingConfidence: .55,
      );
      if (!_valid(epoch)) {
        await _release();
        return;
      }
      await camera.startImageStream((frame) => _process(frame, epoch));
      if (!_valid(epoch)) {
        await _release();
        return;
      }
      _state = MouthCameraState.ready;
      _notify();
    } on CameraException catch (e) {
      if (_valid(epoch)) {
        _state =
            e.code.toLowerCase().contains('denied') ||
                e.code.toLowerCase().contains('restricted')
            ? MouthCameraState.permissionDenied
            : MouthCameraState.failed;
        _notify();
      }
      await _release();
    } catch (_) {
      if (_valid(epoch)) {
        _state = MouthCameraState.failed;
        _notify();
      }
      await _release();
    }
  }

  void _process(CameraImage image, int epoch) {
    if (!_valid(epoch) ||
        _busy ||
        DateTime.now().difference(_lastFrame).inMilliseconds < 80) {
      return;
    }
    final camera = _camera, detector = _detector, mesh = _mesh;
    if (camera == null || detector == null || mesh == null) return;
    _busy = true;
    _lastFrame = DateTime.now();
    try {
      const rotations = {
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      };
      final device = rotations[camera.value.deviceOrientation]!;
      final rotation = Platform.isAndroid
          ? (camera.description.sensorOrientation + device) % 360
          : device;
      if (_lastRotation != null && _lastRotation != rotation) {
        _observation = null;
        _notify();
      }
      _lastRotation = rotation;
      FaceDetectionResult detection;
      FaceMeshResult? result;
      if (Platform.isAndroid) {
        final input = FaceMeshCameraImageAdapter.toNv21(image);
        if (input == null) {
          _frameFailed(epoch);
          return;
        }
        detection = detector.processNv21(
          input,
          rotationDegrees: rotation,
          mirrorHorizontal: true,
        );
        if (detection.detections.length == 1) {
          result = mesh.processNv21(
            input,
            roi: detection.primaryDetection!.expandedFaceRect,
            rotationDegrees: rotation,
            mirrorHorizontal: true,
          );
        }
      } else {
        final input = FaceMeshCameraImageAdapter.toBgra(image);
        if (input == null) {
          _frameFailed(epoch);
          return;
        }
        detection = detector.process(
          input,
          rotationDegrees: rotation,
          mirrorHorizontal: true,
        );
        if (detection.detections.length == 1) {
          result = mesh.process(
            input,
            roi: detection.primaryDetection!.expandedFaceRect,
            rotationDegrees: rotation,
            mirrorHorizontal: true,
          );
        }
      }
      _frameFailures = 0;
      multipleFaces = detection.detections.length > 1;
      _observation = null;
      if (result != null &&
          result.score >= .55 &&
          result.landmarks.length > 291) {
        final points = result.landmarks;
        _observation = measureMouth(
          upper: LipPoint(points[13].x, points[13].y),
          lower: LipPoint(points[14].x, points[14].y),
          left: LipPoint(points[61].x, points[61].y),
          right: LipPoint(points[291].x, points[291].y),
          imageWidth: result.imageWidth,
          imageHeight: result.imageHeight,
        );
      }
      _notify();
    } catch (_) {
      _frameFailed(epoch);
    } finally {
      _busy = false;
    }
  }

  void _frameFailed(int epoch) {
    if (!_valid(epoch)) return;
    _observation = null;
    if (++_frameFailures >= 10) {
      _epoch++;
      _state = MouthCameraState.failed;
      _operations = _operations.then((_) => _release());
    }
    _notify();
  }

  @override
  Future<void> stop() {
    _epoch++;
    _state = MouthCameraState.idle;
    _observation = null;
    _notify();
    _operations = _operations.then((_) => _release());
    return _operations;
  }

  Future<void> _release() async {
    final camera = _camera;
    _camera = null;
    if (camera != null) {
      try {
        if (camera.value.isStreamingImages) await camera.stopImageStream();
      } catch (_) {}
      try {
        await camera.dispose();
      } catch (_) {}
    }
    _mesh?.close();
    _mesh = null;
    _detector?.close();
    _detector = null;
    _observation = null;
    _lastRotation = null;
    multipleFaces = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    unawaited(_operations.then((_) => _release()));
    super.dispose();
  }
}
