import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Platform storage is unavailable in widget tests. Each test starts clean;
  // persistence tests can seed their own values afterwards.
  setUp(() => SharedPreferences.setMockInitialValues({}));
  await testMain();
}
