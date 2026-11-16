/// Observations of an attempt. Game rules gather these without knowing about
/// persistence, calendar dates, reward text or hardware.
enum RunFeat {
  perfectMemory,
  onlyMenorahs,
  cleanOyVey,
  noJewishMisses,
  efficientWorkshop,
  cleanWalk,
  roughWalk,
  safeBattery,
  halfCharged,

  /// Reach 80%; does not require winning.
  fullyCharged,

  /// Optional secret milestone, excluded from the required collection.
  hundredPercent,
  perfectCookie,
  allCandy,
  santaEscaped,
}

class RunFacts {
  const RunFacts({
    this.won = true,
    this.feats = const {},
    this.completedBellSongs = const {},
    this.hanukkahMode = false,
  });

  /// Mid-run milestones must not count as a completed game or calendar door.
  final bool won;
  final bool hanukkahMode;
  final Set<RunFeat> feats;
  final Set<String> completedBellSongs;
}
