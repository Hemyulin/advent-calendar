/// Observations of a won attempt. Game rules gather these without knowing about
/// persistence, calendar dates, reward text or hardware.
enum RunFeat {
  perfectMemory,
  onlyMenorahs,
  cleanOyVey,
  efficientWorkshop,
  cleanWalk,
  roughWalk,
  safeBattery,
  halfCharged,
  perfectCookie,
  allCandy,
  santaEscaped,
}

class RunFacts {
  const RunFacts({
    this.feats = const {},
    this.completedBellSongs = const {},
    this.hanukkahMode = false,
  });
  final bool hanukkahMode;
  final Set<RunFeat> feats;
  final Set<String> completedBellSongs;
}
