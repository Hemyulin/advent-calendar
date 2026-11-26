# Door and practice unlocks

Normal launches use the local device date. Before December all doors are locked;
on December 1 only door 1 is available, then one more each day. Earlier unsolved
doors remain available; completed doors can be replayed. Future dates remain
locked even if old development sessions saved future completions. Locked doors
have a lock and briefly rattle when tapped instead of opening a game or showing
a bottom toast. The tapped carousel tile also rattles. Reduced-motion settings
suppress the translation; locked semantics and haptic feedback remain available.
The existing midnight/resume refresh updates availability without polling.

## Shared policy

`CalendarAccess` owns the rules and the two local preferences, separately from
puzzle logic, achievements and the Pico. `GameAccessScope` forwards the same live
policy through calendar, achievement and practice routes. A first play is recorded
when entering an available calendar game. Existing completed doors also establish
that the corresponding game has been played; progress is not reset.

1. A game cannot be practiced before its first scheduled date or before first
   entering an available calendar door containing that game.
2. Once introduced, unscheduled difficulties are available immediately.
3. A difficulty assigned to any calendar door stays reserved until a matching
   date-available door is completed. A repeated identical level does not relock
   an already released difficulty.
4. A song assigned to a calendar door has its own reservation, independently of
   selected difficulty. It requires completing a matching, date-available door.
5. Both appearances share difficulty/song reservations. Theme switches check the
   actual target song, including the default used when crossing song families.
6. Only the active calendar route can play its own assignment before completing
   that door. Achievement routes never inherit this exception.

For example, Memory starts on day 1, classic Memory is reserved for day 5, and
hard Memory for day 16. Completing day 1 permits easy practice in either skin,
but does not release classic/hard. Chimney has no scheduled easy level, so easy
practice is available after first entering day 9; classic practice requires
completing day 9, and hard practice completing day 17.

Bells first appear on day 10. After finishing that door, its Maoz Tzur melody and
other unreserved easy songs can be practiced. Jingle Bells and classic difficulty
remain reserved until completing day 15. All I Want for Christmas Is You and
hard difficulty remain reserved until completing day 24. Finishing another song
or merely reaching a date cannot release a reserved song.

The optional trash alternative is available once an available calendar game has
been entered. Assistance respects reserved levels; the existing gentler cookie
speed option is still available inside its authorized daily attempt.

## Administration

**Alle Türchen freischalten** is off by default and persisted locally as
`calendar.unlockAll.v1`. It releases all date/practice restrictions for testing.
Turning it off restores them and retains completed doors and first-play history
(`calendar.playedGames.v1`). The obsolete `PREVIEW_ALL_DAYS` build define has no
effect. Widget tests may still explicitly inject `previewAllDays: true`.

Admin **Spiele testen** remains an isolated development preview: every game can
be inspected there without calendar wins, award persistence or physical opening.
The admin switch is a local testing convenience, not authorization for the lock.
