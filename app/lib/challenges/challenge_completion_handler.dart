import 'dart:async';
import '../hardware/pico_service.dart';
import '../progress/progress_repository.dart';

/// Central daily-completion boundary. Minigames and previews do not know the
/// Pico protocol. Saved progress is authoritative; feedback is best effort.
class ChallengeCompletionHandler {
  ChallengeCompletionHandler({required this.progress, required this.pico});
  final ProgressRepository progress;
  final PicoService? pico;
  final _completions = <String, Future<void>>{};

  Future<void> complete(String challengeId) => _completions.putIfAbsent(
    challengeId,
    () => _record(challengeId).onError((Object error, StackTrace stack) {
      _completions.remove(challengeId);
      Error.throwWithStackTrace(error, stack);
    }),
  );

  Future<void> _record(String challengeId) async {
    if ((await progress.completedChallengeIds()).contains(challengeId)) return;
    await progress.markCompleted(challengeId);
    // Do not await network availability, health checks or LED acknowledgement.
    unawaited(_acknowledge());
  }

  Future<void> _acknowledge() async {
    try {
      await pico?.acknowledgeGameCompletion();
    } catch (_) {
      // A timeout may follow a successfully processed POST. Never retry it or
      // turn an optional physical acknowledgement into a failed game save.
    }
  }
}
