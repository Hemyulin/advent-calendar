/// Concert pitches. H is the German B-natural; B is B-flat.
enum BellNote {
  c('C', 'c5', 72),
  d('D', 'd5', 74),
  e('E', 'e5', 76),
  f('F', 'f5', 77),
  fSharp('Fis', 'fs5', 78),
  g('G', 'g5', 79),
  a('A', 'a5', 81),
  bFlat('B', 'bb5', 82),
  h('H', 'b5', 83),
  highC('C↑', 'c6', 84),
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
  BellNote.highD,
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

List<MelodyNote> _morgenOpening() => [
  ..._phrase('c c g g a a g', [1, 1, 1, 1, 1, 1, 2]),
  ..._phrase('f f e e d c', [1, 1, 1, 1, 2, 2]),
];
List<MelodyNote> _klingRefrain() => [
  ..._phrase('g e f g a g a g', [2, 1, 1, .5, .5, .5, .5, 2]),
  ..._phrase('f d g e', [2, 1, 1, 4]),
];
List<MelodyNote> _tannenOpening() => [
  ..._phrase('f f f g', [.75, .25, 1, 1]),
  ..._phrase('a a a a', [.75, .25, 1.5, .5]),
  ..._phrase('g a bFlat e', [.5, .5, 1, 1]),
];
List<MelodyNote> _jingleChorusOpening() => [
  ..._phrase('a a a a a a', [.5, .5, 1, .5, .5, 1]),
  ..._phrase('a highC f g a', [.5, .5, .75, .25, 2]),
  ..._phrase('bFlat bFlat bFlat bFlat', [.5, .5, .75, .25]),
  ..._phrase('bFlat a a a a', [.5, .5, .5, .25, .25]),
];

// Complete verse melodies, checked against the published public-domain scores.
// Jingle Bells includes both the verse and full refrain, in F major.
// Sources and transpositions: docs/bell-melodies.md.
final bellMelodies = [
  BellMelody('morgen', 'Morgen kommt der Weihnachtsmann', [
    ..._morgenOpening(),
    ..._phrase('g g f f e e d', [1, 1, 1, 1, 1, 1, 2]),
    ..._phrase('g g f f e e d', [1, 1, 1, 1, 1, 1, 2]),
    ..._morgenOpening(),
  ]),
  BellMelody('alle', 'Alle Jahre wieder', [
    ..._phrase('g a g f e d', [1.5, .5, 1, 1, 2, 2]),
    ..._phrase('c d e f e d', [1, .5, .5, 1, 1, 3], restAfter: 1),
    ..._phrase('e g a g highC h a', [1, 1, 1, 1, 2, 1, 1]),
    ..._phrase('g f e f g e', [1, .5, .5, 1, 1, 3], restAfter: 1),
  ]),
  BellMelody('tannenbaum', 'O Tannenbaum', [
    ..._phrase('c', [1]),
    ..._tannenOpening(),
    ..._phrase('g f', [1, 1], restAfter: .5),
    ..._phrase('highC', [.5]),
    ..._phrase('highC a highD highC', [.5, .5, 1.5, .5]),
    ..._phrase('highC bFlat bFlat bFlat', [.5, .5, 1.5, .5]),
    ..._phrase('bFlat g highC bFlat', [.5, .5, 1.5, .5]),
    ..._phrase('bFlat a a c', [.5, .5, 1, 1]),
    ..._tannenOpening(),
    ..._phrase('g f', [1, 1]),
  ], bells: tannenbaumBells),
  BellMelody('jingle', 'Jingle Bells', [
    ..._phrase('c a g f', [.5, .5, .5, .5]),
    ..._phrase('c c c', [1.5, .25, .25]),
    ..._phrase('c a g f d', [.5, .5, .5, .5, 2]),
    ..._phrase('d bFlat a g e', [.5, .5, .5, .5, 2]),
    ..._phrase('highC highC bFlat g a', [.5, .5, .5, .5, 2]),
    ..._phrase('c a g f c', [.5, .5, .5, .5, 2]),
    ..._phrase('c a g f d d', [.5, .5, .5, .5, 1.5, .5]),
    ..._phrase('d bFlat a g', [.5, .5, .5, .5]),
    ..._phrase('highC highC highC highC', [.5, .5, .5, .5]),
    ..._phrase('highD highC bFlat g f', [.5, .5, .5, .5, 1], restAfter: 1),
    ..._jingleChorusOpening(),
    ..._phrase('a g g a g highC', [.5, .5, .5, .5, 1, 1]),
    ..._jingleChorusOpening(),
    ..._phrase('highC highC bFlat g f', [.5, .5, .5, .5, 2]),
  ], bells: jingleBells),
  BellMelody('kling', 'Kling, Glöckchen', [
    ..._klingRefrain(),
    ..._phrase('d d e c e d', [1, 1, 1, 1, 2, 2]),
    ..._phrase('f f g d f e', [1, 1, 1, 1, 2, 2]),
    ..._phrase('d d e fSharp g d', [1, 1, 1, 1, 2, 2]),
    ..._phrase('e a g fSharp a g', [1, 1, 1, 1, 2, 2]),
    ..._klingRefrain(),
  ], bells: klingBells),
];

class BellRound {
  /// Omit length for a complete melody. Explicit lengths support custom lessons.
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
];
