/// Tracks completed challenges independently of content and lock state.
///
/// A persistence implementation will be chosen when progress is implemented.
abstract interface class ProgressRepository {
  Future<Set<String>> completedChallengeIds();

  Future<void> markCompleted(String challengeId);
}
