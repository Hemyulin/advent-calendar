# Weihnachtsglocken: recognizable hooks and listening guidance

Every melody is a curated musical phrase, lasting about 4–5 seconds at the
standard tempo. Neither normal play nor the preview plays entire verses or
songs. Jingle Bells starts at the familiar chorus, rather than the verse.
The stored data contains only these hooks, so repeat-listening cannot
accidentally fall back to a full-song version.

The five traditional hooks use the published public-domain scores in
[Kinder wollen singen](https://github.com/jollyjinx/kinder-wollen-singen/tree/main/books/weihnachtslieder).
The three additions below use short melody excerpts. No lyrics, vocals or
commercial song recordings are included.

| Tune | Reference and transposition | Hook pitches | Notes |
| --- | --- | --- | --- |
| Morgen kommt der Weihnachtsmann | [Score](https://github.com/jollyjinx/kinder-wollen-singen/blob/main/books/weihnachtslieder/morgen_kommt_der_weihnachtsmann_voices.ly), G → C major | C C G G A A G | 7 |
| Alle Jahre wieder | [Score](https://github.com/jollyjinx/kinder-wollen-singen/blob/main/books/weihnachtslieder/alle_jahre_wieder_voices.ly), D → C major | G A G F E D | 6 |
| O Tannenbaum | [Score](https://github.com/jollyjinx/kinder-wollen-singen/blob/main/books/weihnachtslieder/oh_tannenbaum_voices.ly), F major, raised an octave | C F F F G A A A | 8 |
| Jingle Bells | [Score](https://github.com/jollyjinx/kinder-wollen-singen/blob/main/books/weihnachtslieder/jingle_bells_voices.ly), G → F major, chorus opening | A A A A A A A C↑ F G A | 11 |
| Kling, Glöckchen | [Score](https://github.com/jollyjinx/kinder-wollen-singen/blob/main/books/weihnachtslieder/kling_gloeckchen_voices.ly), D → C major | G E F G A G A G | 8 |
| All I Want for Christmas Is You | [Melody reference](https://www.lucioimbriglio.it/wp-content/uploads/2019/12/All-I-want-for-Christmas-is-you-spartito.pdf), short title hook in G, note durations scaled uniformly for bell playback | H A G E Dis A H A G | 9 |
| Carol of the Bells | [Shchedryk motif reference](https://www.stantons.com/scores/C/M/2/2/7/0/cfn-cm2270.pdf), two statements transposed from G minor to D minor | F E F D F E F D | 8 |
| Last Christmas | [Vocal melody preview](https://playournotes.com/en/sheet-music/last-christmas/1706/notes-and-tablature-for-guitar-melody-line.pdf), short refrain with a C-sharp penultimate note; ties sustained, ornamental grace notes omitted | H H A E H H Cis↑ A | 8 |

The modern song credits are Mariah Carey / Walter Afanasieff and George Michael.
Carol of the Bells uses Mykola Leontovych's Shchedryk motif. References were
inspected for pitch, rests and ties; full scores are not bundled with the app.

Phrases end at recognizable musical boundaries. Repeated pitches, pickups and
dotted durations retain their score timing. Only note order is evaluated;
answers have no timing requirement. Listening again and retrying remain
unlimited, and replay never clears saved completion.

## Difficulty

| Difficulty | Default hook | Challenge and demonstration |
| --- | --- | --- |
| Leicht | Carol of the Bells, 8 notes | Repeated four-note motif with three pitches; every bell swings and glows |
| Klassisch | Last Christmas, 8 notes | Repeated notes, a wider leap and a rest; only the first bell animates |
| Knifflig | All I Want for Christmas Is You, 9 notes | Six distinct pitches, a chromatic note and wide intervals; audio only |

Difficulty comes from the melody's pitch pattern and reduced visual assistance,
not a length ladder. Easy and normal have the same note count. A challenge
still contains one phrase; it never progresses through a whole song.
Player taps always give normal swing/glow feedback. Starting a new demonstration
clears earlier animations so they cannot leak hints into audio-only playback.
Day 5 uses Klassisch.

In **Spiele ausprobieren → Weihnachtsglocken**, select any hook using
**Melodie ausprobieren**. Selected difficulty controls visual guidance for all
eight hooks. Preview completion never modifies calendar progress. `BellsLevel`
configures rounds, tempo and guidance; `BellRound` defaults to the whole curated
hook, with optional shorter prefixes for custom lessons and tests.

## Audio and separation

Each melody uses eight ordered bells; unused bells remain as distractors. The
thirteen-file WAV library supports C5–D6, with D-sharp added for the Mariah
hook and high C-sharp for Last Christmas, alongside F-sharp and B-flat. German labels distinguish H and B.
Recorded VSCO 2 CE glockenspiel chimes provide natural attack and decay, repitched
by at most three semitones. See [asset sources](../app/assets/audio/bells/SOURCES.md)
and [CC0 license](../app/assets/audio/bells/LICENSE-VSCO.txt).
Runtime playback is offline through the existing `audioplayers` dependency.

`BellAudio` separates playback from note-order rules. Scheduling includes note
lengths and rests. Help, backgrounding, replay and preview changes cancel
scheduled notes and partial answers. Audio errors provide a German retry action.
Screens remain fixed, without vertical scrolling.

Tests check exact hook sequences, maximum demonstration duration, musical
complexity across difficulties, bell coverage, complete hook playback and
repeat-listening, guidance, audio failures, completion/replay and layouts.
