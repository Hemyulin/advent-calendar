import 'package:shared_preferences/shared_preferences.dart';
import 'progress_repository.dart';

/// Durable calendar checkmarks. Achievement progress and rewards have their own
/// store; neither storage boundary has a dependency on the physical lock.
class LocalProgressRepository implements ProgressRepository {
  static const storageKey = 'progress.completed.v1';
  Future<void> _queue = Future.value();
  @override
  Future<Set<String>> completedChallengeIds() async => {
    ...(await SharedPreferences.getInstance()).getStringList(storageKey) ?? [],
  };
  @override
  Future<void> markCompleted(String challengeId) {
    final result = _queue.then((_) async {
      final preferences = await SharedPreferences.getInstance();
      final ids = <String>{
        ...preferences.getStringList(storageKey) ?? [],
        challengeId,
      };
      if (!await preferences.setStringList(storageKey, ids.toList())) {
        throw StateError('Fortschritt konnte nicht gespeichert werden.');
      }
    });
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
