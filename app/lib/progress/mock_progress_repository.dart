import 'progress_repository.dart';

/// In-memory sample progress. Nothing is persisted or sent to hardware.
class MockProgressRepository implements ProgressRepository {
  MockProgressRepository({Set<String>? completedIds})
    : _completedIds = {
        ...(completedIds ?? {'day-1', 'day-3', 'day-5'}),
      };

  final Set<String> _completedIds;

  @override
  Future<Set<String>> completedChallengeIds() async => {..._completedIds};

  @override
  Future<void> markCompleted(String challengeId) async {
    _completedIds.add(challengeId);
  }
}
