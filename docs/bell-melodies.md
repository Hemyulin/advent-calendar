# Weihnachtsglocken: melodies and audio

The game uses short, monophonic fragments of five public-domain tunes, with no
lyrics or modern arrangements. Pitch and duration were checked against the
published LilyPond scores in [Kinder wollen singen](https://github.com/jollyjinx/kinder-wollen-singen/tree/main/books/weihnachtslieder).
Only pitch order is evaluated. Demonstrations retain the notated rhythm to make
the songs recognizable; player input has no time limit or rhythm scoring.

| Tune | Reference score | Fragment in concert pitch (scientific octave 5) |
| --- | --- | --- |
| Morgen kommt der Weihnachtsmann | [Score](https://github.com/jollyjinx/kinder-wollen-singen/blob/main/books/weihnachtslieder/morgen_kommt_der_weihnachtsmann_voices.ly), G major → C major | C C G G A A G F F E |
| Alle Jahre wieder | [Score](https://github.com/jollyjinx/kinder-wollen-singen/blob/main/books/weihnachtslieder/alle_jahre_wieder_voices.ly), D major → C major | G A G F E D C D E F |
| O Tannenbaum | [Score](https://github.com/jollyjinx/kinder-wollen-singen/blob/main/books/weihnachtslieder/oh_tannenbaum_voices.ly), F major, raised one octave | C F F F G A A A A G |
| Jingle Bells | [Score](https://github.com/jollyjinx/kinder-wollen-singen/blob/main/books/weihnachtslieder/jingle_bells_voices.ly), refrain from bar 19, G major → C major | E G C D E F F F F F |
| Kling, Glöckchen | [Score](https://github.com/jollyjinx/kinder-wollen-singen/blob/main/books/weihnachtslieder/kling_gloeckchen_voices.ly), D major → C major | G E F G A G A G F D |

All eight bells form C5–C6 (German labels C, D, E, F, G, A, H, C↑).
Fragments stay within this range, including the F-major Tannenbaum opening;
its later B-flat is outside the selected fragment and is not substituted.
Durations are stored in quarter-note beats separately from the pitch-order rules.
The player can listen again indefinitely. A wrong note resets only the current
attempt, while completed rounds remain complete. Replay never clears daily progress.

## Levels and preview

Day 5 uses the standard progression of 4, 5, 6, 7, 8 and 10 notes. Leicht stops
at 8; Knifflig also includes a 9-note round. All difficulties start at four notes
and cover all five tunes. `BellsLevel` accepts custom rounds and demonstration
tempo. `BellRound` selects a prefix from reusable `bellMelodies` data.

In **Spiele ausprobieren → Weihnachtsglocken**, choose any fragment from the
**Melodie ausprobieren** selector. Each selection becomes a standalone preview
round. Preview callbacks remain isolated from calendar progress.

## Recorded sound and playback

Eight local WAV files use recorded VSCO 2 CE glockenspiel chimes with their
natural struck-metal attack and decay, transposed by at most three semitones.
See [asset sources and processing](../app/assets/audio/bells/SOURCES.md) and
[CC0 license](../app/assets/audio/bells/LICENSE-VSCO.txt).
The reproducible Python preparation script is `app/tool/prepare_bells.py`.
The eight files together add about 1.2 MB. Runtime playback is fully offline.

`BellAudio` separates playback from game rules. `SampledBellAudio` uses the
cross-platform `audioplayers` package and preloads two voices per note, allowing
repeated strikes to overlap without truncating the preceding strike's tail.
Stopped generations cannot start delayed notes. Resources are released on exit.
Loading and playback errors show a German retry action rather than allowing
silent play. Help, backgrounding, replay and preview changes cancel scheduled
notes and partial answers; resume offers a fresh listen to the current melody.

- `bell_melodies.dart`: pitch set, public-domain melody data and round definitions.
- `bells_game.dart`: pure Dart note-order validation and progression.
- `bell_audio.dart`: injectable audio boundary and sampled native playback.
- `bells_screen.dart`: fixed-size scene, illustrated golden bells, swing/glow,
  melody playback scheduling, input and shared completion overlay.

Tests cover pitch sequences and durations, difficulty progression, eight distinct
PCM assets, unlimited retries, no timing requirement, playback order, cancelled
playback, audio failures, completion, replay, all preview fragments and responsive
layouts without vertical scrolling. Native audio still needs a listening check
on the target phone for device volume and perceived latency.
