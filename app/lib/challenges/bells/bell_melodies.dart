/// Concert pitches for the eight sampled bells. German notation uses H for B.
enum BellNote {
  c('C', 'c5', 72),
  d('D', 'd5', 74),
  e('E', 'e5', 76),
  f('F', 'f5', 77),
  g('G', 'g5', 79),
  a('A', 'a5', 81),
  h('H', 'b5', 83),
  highC('C↑', 'c6', 84);

  const BellNote(this.label, this.asset, this.midi);
  final String label, asset;
  final int midi;
}

class MelodyNote {
  const MelodyNote(this.pitch, this.beats);
  final BellNote pitch;
  final double beats;
}

class BellMelody {
  const BellMelody(this.id, this.title, this.notes);
  final String id, title;
  final List<MelodyNote> notes;
}

// Public-domain tunes, manually transcribed from the published LilyPond scores.
// Source references and transpositions: docs/bell-melodies.md.
const bellMelodies = [
  BellMelody('morgen', 'Morgen kommt der Weihnachtsmann', [
    MelodyNote(BellNote.c, 1),
    MelodyNote(BellNote.c, 1),
    MelodyNote(BellNote.g, 1),
    MelodyNote(BellNote.g, 1),
    MelodyNote(BellNote.a, 1),
    MelodyNote(BellNote.a, 1),
    MelodyNote(BellNote.g, 2),
    MelodyNote(BellNote.f, 1),
    MelodyNote(BellNote.f, 1),
    MelodyNote(BellNote.e, 1),
  ]),
  BellMelody('alle', 'Alle Jahre wieder', [
    MelodyNote(BellNote.g, 1.5),
    MelodyNote(BellNote.a, .5),
    MelodyNote(BellNote.g, 1),
    MelodyNote(BellNote.f, 1),
    MelodyNote(BellNote.e, 2),
    MelodyNote(BellNote.d, 2),
    MelodyNote(BellNote.c, 1),
    MelodyNote(BellNote.d, .5),
    MelodyNote(BellNote.e, .5),
    MelodyNote(BellNote.f, 1),
  ]),
  BellMelody('tannenbaum', 'O Tannenbaum', [
    MelodyNote(BellNote.c, 1),
    MelodyNote(BellNote.f, .75),
    MelodyNote(BellNote.f, .25),
    MelodyNote(BellNote.f, 1),
    MelodyNote(BellNote.g, 1),
    MelodyNote(BellNote.a, .75),
    MelodyNote(BellNote.a, .25),
    MelodyNote(BellNote.a, 1.5),
    MelodyNote(BellNote.a, .5),
    MelodyNote(BellNote.g, .5),
  ]),
  // Refrain, beginning with the third "Jingle" phrase (bar 19 in the source).
  BellMelody('jingle', 'Jingle Bells', [
    MelodyNote(BellNote.e, .5),
    MelodyNote(BellNote.g, .5),
    MelodyNote(BellNote.c, .75),
    MelodyNote(BellNote.d, .25),
    MelodyNote(BellNote.e, 2),
    MelodyNote(BellNote.f, .5),
    MelodyNote(BellNote.f, .5),
    MelodyNote(BellNote.f, .75),
    MelodyNote(BellNote.f, .25),
    MelodyNote(BellNote.f, .5),
  ]),
  BellMelody('kling', 'Kling, Glöckchen', [
    MelodyNote(BellNote.g, 2),
    MelodyNote(BellNote.e, 1),
    MelodyNote(BellNote.f, 1),
    MelodyNote(BellNote.g, .5),
    MelodyNote(BellNote.a, .5),
    MelodyNote(BellNote.g, .5),
    MelodyNote(BellNote.a, .5),
    MelodyNote(BellNote.g, 2),
    MelodyNote(BellNote.f, 2),
    MelodyNote(BellNote.d, 1),
  ]),
];

class BellRound {
  const BellRound(this.melodyIndex, this.length);
  final int melodyIndex, length;
  BellMelody get melody => bellMelodies[melodyIndex];
  List<MelodyNote> get notes =>
      melody.notes.take(length).toList(growable: false);
  String get label => '${melody.title} · $length Töne';
}

const bellRounds = [
  BellRound(0, 4),
  BellRound(1, 5),
  BellRound(2, 6),
  BellRound(3, 7),
  BellRound(4, 8),
  BellRound(1, 9),
  BellRound(0, 10),
];
