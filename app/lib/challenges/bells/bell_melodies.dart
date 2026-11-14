/// Concert pitches. H is the German B-natural; B is B-flat.
enum BellNote {
  c('C', 'c5', 72),
  d('D', 'd5', 74),
  dSharp('Dis', 'ds5', 75),
  e('E', 'e5', 76),
  f('F', 'f5', 77),
  fSharp('Fis', 'fs5', 78),
  g('G', 'g5', 79),
  a('A', 'a5', 81),
  bFlat('B', 'bb5', 82),
  h('H', 'b5', 83),
  highC('C↑', 'c6', 84),
  highCSharp('Cis↑', 'cs6', 85),
  highD('D↑', 'd6', 86);

  const BellNote(this.label, this.asset, this.midi);
  final String label, asset;
  final int midi;
}

const standardBells = [
  BellNote.c,
  BellNote.d,
  BellNote.e,
  BellNote.f,
  BellNote.g,
  BellNote.a,
  BellNote.h,
  BellNote.highC,
];
const tannenbaumBells = [
  BellNote.c,
  BellNote.e,
  BellNote.f,
  BellNote.g,
  BellNote.a,
  BellNote.bFlat,
  BellNote.highC,
  BellNote.highD,
];
const klingBells = [
  BellNote.c,
  BellNote.d,
  BellNote.e,
  BellNote.f,
  BellNote.fSharp,
  BellNote.g,
  BellNote.a,
  BellNote.highC,
];
const jingleBells = [
  BellNote.c,
  BellNote.d,
  BellNote.e,
  BellNote.f,
  BellNote.g,
  BellNote.a,
  BellNote.bFlat,
  BellNote.highC,
];

const popBells = [
  BellNote.c,
  BellNote.dSharp,
  BellNote.e,
  BellNote.fSharp,
  BellNote.g,
  BellNote.a,
  BellNote.h,
  BellNote.highC,
];

const lastChristmasBells = [
  BellNote.c,
  BellNote.d,
  BellNote.e,
  BellNote.fSharp,
  BellNote.g,
  BellNote.a,
  BellNote.h,
  BellNote.highCSharp,
];

class MelodyNote {
  const MelodyNote(this.pitch, this.beats, {this.restBeats = 0});
  final BellNote pitch;
  final double beats, restBeats;
}

class BellMelody {
  BellMelody(
    this.id,
    this.title,
    List<MelodyNote> notes, {
    this.bells = standardBells,
  }) : notes = List.unmodifiable(notes);
  final String id, title;
  final List<MelodyNote> notes;
  final List<BellNote> bells;
}

/// Phrases remain separate so repeats, pickups and rests match the score.
List<MelodyNote> _phrase(
  String names,
  List<double> beats, {
  double restAfter = 0,
}) {
  final pitches = names
      .split(' ')
      .map((name) => BellNote.values.byName(name))
      .toList();
  if (pitches.length != beats.length) throw StateError('Invalid melody phrase');
  return List.generate(
    pitches.length,
    (i) => MelodyNote(
      pitches[i],
      beats[i],
      restBeats: i == pitches.length - 1 ? restAfter : 0,
    ),
  );
}

// Curated, complete musical phrases: never a verse or a full-song playback.
// Keep the familiar opening/refrain and its real rhythm, rather than arbitrary
// note-count truncation. Source transpositions: docs/bell-melodies.md.
final bellMelodies = [
  BellMelody('morgen', 'Morgen kommt der Weihnachtsmann', [
    ..._phrase('c c g g a a g', [1, 1, 1, 1, 1, 1, 2]),
  ]),
  BellMelody('alle', 'Alle Jahre wieder', [
    ..._phrase('g a g f e d', [1.5, .5, 1, 1, 2, 2]),
  ]),
  BellMelody('tannenbaum', 'O Tannenbaum', [
    ..._phrase('c f f f g a a a', [1, .75, .25, 1, 1, .75, .25, 1.5]),
  ], bells: tannenbaumBells),
  // Start at the famous chorus, not the less recognizable verse.
  BellMelody('jingle', 'Jingle Bells', [
    ..._phrase('a a a a a a a highC f g a', [
      .5,
      .5,
      1,
      .5,
      .5,
      1,
      .5,
      .5,
      .75,
      .25,
      2,
    ]),
  ], bells: jingleBells),
  BellMelody('kling', 'Kling, Glöckchen', [
    ..._phrase('g e f g a g a g', [2, 1, 1, .5, .5, .5, .5, 2]),
  ], bells: klingBells),
  // Title hook, transposed to G. Short phrase with its chromatic approach.
  BellMelody('all-i-want', 'All I Want for Christmas Is You', [
    ..._phrase('h a g e dSharp a h a g', [
      .5,
      .5,
      .5,
      .5,
      .5,
      1,
      .5,
      .375,
      1.625,
    ]),
  ], bells: popBells),
  // Two statements of the four-note Shchedryk motif, in D minor.
  BellMelody('carol', 'Carol of the Bells', [
    ..._phrase('f e f d f e f d', [1, .5, .5, 1, 1, .5, .5, 1]),
  ]),
  // Vocal refrain hook with C-sharp before the final A; tied notes sustain.
  BellMelody('last-christmas', 'Last Christmas', [
    MelodyNote(BellNote.h, 1.5),
    MelodyNote(BellNote.h, 1),
    MelodyNote(BellNote.a, .5, restBeats: .5),
    ..._phrase('e h h highCSharp a', [.5, .5, .5, .5, 1]),
  ], bells: lastChristmasBells),
];

class BellRound {
  /// Defaults to the curated hook. Explicit lengths support short custom lessons.
  const BellRound(this.melodyIndex, [this._length]);
  final int melodyIndex;
  final int? _length;
  BellMelody get melody => bellMelodies[melodyIndex];
  int get length => _length ?? melody.notes.length;
  List<MelodyNote> get notes =>
      melody.notes.take(length).toList(growable: false);
  String get label => melody.title;
}

const bellRounds = [
  BellRound(1),
  BellRound(0),
  BellRound(2),
  BellRound(4),
  BellRound(3),
  BellRound(6),
  BellRound(7),
  BellRound(5),
];
