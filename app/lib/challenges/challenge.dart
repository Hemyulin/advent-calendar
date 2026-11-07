/// Shared categories for daily challenge content.
enum ChallengeType { puzzle, quiz, questionnaire, minigame }

/// Shared identity for challenge definitions, independent of UI and hardware.
class Challenge {
  const Challenge({required this.id, required this.type});

  final String id;
  final ChallengeType type;
}
