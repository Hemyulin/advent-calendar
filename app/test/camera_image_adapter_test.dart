import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:advent_calendar/challenges/oy_vey/camera_image_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

class _Plane implements Plane {
  _Plane(List<int> data, this.bytesPerRow, {this.bytesPerPixel = 1})
    : bytes = Uint8List.fromList(data);
  @override
  final Uint8List bytes;
  @override
  final int bytesPerRow;
  @override
  final int bytesPerPixel;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Image implements CameraImage {
  _Image(this.width, this.height, this.planes);
  @override
  final int width, height;
  @override
  final List<Plane> planes;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('reused NV21 adapter preserves row padding and VU byte order', () {
    final one = FaceMeshCameraImageAdapter.toNv21(
      _Image(2, 2, [
        _Plane([1, 2, 9, 9, 3, 4, 9, 9, 6, 5, 9, 9], 4),
      ]),
    )!;
    expect(one.yPlane, [1, 2, 9, 9, 3, 4, 9, 9]);
    expect(one.vuPlane, [6, 5, 9, 9]);
    final two = FaceMeshCameraImageAdapter.toNv21(
      _Image(2, 2, [
        _Plane([1, 2, 9, 3, 4, 9], 3),
        _Plane([6, 5, 9, 9], 4, bytesPerPixel: 2),
      ]),
    )!;
    expect(two.yPlane, [1, 2, 3, 4]);
    expect(two.vuPlane, [6, 5]);
    final three = FaceMeshCameraImageAdapter.toNv21(
      _Image(2, 2, [
        _Plane([1, 2, 9, 3, 4, 9], 3),
        _Plane([5, 9], 2, bytesPerPixel: 2),
        _Plane([6, 9], 2, bytesPerPixel: 2),
      ]),
    )!;
    expect(three.yPlane, [1, 2, 3, 4]);
    expect(three.vuPlane, [6, 5]);
  });
  test('bad frame sizes and truncated planes are rejected safely', () {
    expect(FaceMeshCameraImageAdapter.toNv21(_Image(3, 2, [])), isNull);
    expect(
      FaceMeshCameraImageAdapter.toNv21(
        _Image(2, 2, [
          _Plane([1], 2),
        ]),
      ),
      isNull,
    );
    expect(
      FaceMeshCameraImageAdapter.toNv21(
        _Image(2, 2, [
          _Plane([1, 2, 3, 4], 2),
          _Plane([6], 2, bytesPerPixel: 2),
        ]),
      ),
      isNull,
    );
  });
}
