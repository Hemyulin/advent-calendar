# Weihnachtsglocken: complete melodies and listening guidance

Each normal challenge now uses one complete song melody instead of a chain of
short fragments. The pitch order and rhythm are transcribed from the published
public-domain LilyPond scores in [Kinder wollen singen](https://github.com/jollyjinx/kinder-wollen-singen/tree/main/books/weihnachtslieder).
A full verse covers the melody for songs with multiple identical lyric verses;
Jingle Bells includes both the verse and the complete refrain. There are no
modern arrangements or lyrics in the game.

| Tune | Reference score and transposition | Notes | Quarter-note beats including rests |
| --- | --- | --- | --- |
| Morgen kommt der Weihnachtsmann | [Score](https://github.com/jollyjinx/kinder-wollen-singen/blob/main/books/weihnachtslieder/morgen_kommt_der_weihnachtsmann_voices.ly), G → C major | 40 | 48 |
| Alle Jahre wieder | [Score](https://github.com/jollyjinx/kinder-wollen-singen/blob/main/books/weihnachtslieder/alle_jahre_wieder_voices.ly), D → C major | 25 | 32 |
| O Tannenbaum | [Score](https://github.com/jollyjinx/kinder-wollen-singen/blob/main/books/weihnachtslieder/oh_tannenbaum_voices.ly), F major, raised an octave | 46 | 36 |
| Jingle Bells | [Score](https://github.com/jollyjinx/kinder-wollen-singen/blob/main/books/weihnachtslieder/jingle_bells_voices.ly), G → F major, verse + refrain | 97 | 64 |
| Kling, Glöckchen | [Score](https://github.com/jollyjinx/kinder-wollen-singen/blob/main/books/weihnachtslieder/kling_gloeckchen_voices.ly), D → C major, retaining the chromatic F-sharp | 48 | 64 |

Repeated phrases, pickups, dotted durations and rests are kept explicitly in
`bell_melodies.dart`. Nothing is clipped to a note-count limit in the production
levels or preview. Only pitch order is evaluated; answers have no time limit or
rhythm score. Listening again and retrying remain unlimited. A wrong note resets
the current answer, and replay never clears saved daily completion.

## Difficulty and visual guidance

| Difficulty | Default complete melody | Demonstration |
| --- | --- | --- |
| Leicht | Alle Jahre wieder, 25 notes | Every played bell swings and glows |
| Klassisch | Morgen kommt der Weihnachtsmann, 40 notes | Only the first note animates; the remaining notes are audio only |
| Knifflig | Jingle Bells, 97 notes | Audio only from the first note onward; all bells remain still |

All player taps retain their normal swing/glow feedback at every difficulty.
Starting another demonstration clears existing animations, so an earlier tap
cannot reveal a bell during an audio-only performance. Repeated listening and
preview selection keep the chosen guidance mode. Day 5 uses Klassisch.

In **Spiele ausprobieren → Weihnachtsglocken**, choose any full song from
**Melodie ausprobieren**. The preview's difficulty determines the visual guidance,
so every song can be tested with all, first-only or no note hints. Preview
victories do not change calendar progress. `BellsLevel` configures rounds, tempo
and `BellGuidance`; `BellRound` defaults to the entire song, with an optional
explicit prefix length retained for custom lessons and isolated tests.

## Bell ranges and recorded audio

Each song has an ordered pitch set. Four songs show eight bells; Jingle Bells
needs nine distinct pitches to preserve its full verse range, so it uses a compact
3×3 layout. The total asset library covers C5–D6 with F-sharp and B-flat included.
German labels distinguish H (B-natural) and B (B-flat). O Tannenbaum's B-flat and
high D, and Kling, Glöckchen's chromatic F-sharp are not replaced by other notes.

Eleven local WAV files use recorded VSCO 2 CE glockenspiel chimes with their
natural attack and decay, repitched by at most three semitones. See
[asset sources and processing](../app/assets/audio/bells/SOURCES.md) and
[CC0 license](../app/assets/audio/bells/LICENSE-VSCO.txt).
The reproducible preparation script is `app/tool/prepare_bells.py`; runtime
playback is fully offline and uses the existing `audioplayers` dependency.

`BellAudio` separates sampled native playback from note-order rules. Playback
scheduling includes each note's duration and following rest. Help, backgrounding,
replay and preview changes cancel scheduled notes and partial answers. Audio
errors show a German retry action. Bell sets retain stable pitch identities when
switching songs. Long answers use a compact progress bar rather than dozens of
individual dots, and all layouts fit without vertical scrolling.

Tests verify complete song lengths, beat totals, representative full phrases,
all chromatic notes, per-song pitch coverage, actual rendered bell movement in
all guidance modes, repeat-listening isolation, complete preview playback,
untimed answering, failure recovery, completion/replay and responsive layouts.
