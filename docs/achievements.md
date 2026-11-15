# Erfolge

The calendar's **Erfolge** button opens a fixed, paged collection. Unearned
achievement illustrations remain visible in muted grayscale, with plain requirements and progress.
Each has a separate native vector scene: calendar house, toy train, treasure
cabinet, polished boot, candlelight, collecting sack, memory cards, elf workbench,
safe winter path, tipsy trip home, batteries, charging laptop, three cookies,
maze sweets, Santa climbing out of a chimney and an extra-bonus envelope. Earned scenes regain their colors.
Tap a badge for its illustrated summary. Longer checklists open via
**Teilziele ansehen**: readable objective cards, adaptive pagination, a filter
for unfinished goals and links to the individual bonus-goal explanations.
The checklist uses two columns in landscape when text size permits; it never
shrinks text to squeeze in every objective. Individual achievements award badges only. A
separate final reward card tracks all 17 achievements; its contents stay hidden
until every achievement has been earned. It is explicitly labelled as an extra
bonus **in addition to the daily presents**, with a voucher envelope rather than
the main gift illustration. The final reward is not another required
achievement and cannot depend on itself.
The screens fit the viewport without vertical scrolling, including large text.

## Rules

| Achievement | Requirement |
| --- | --- |
| 24 kleine Weihnachtswunder | Complete 24 distinct calendar doors. |
| Weihnachts-Alleskönnerin | Win each of the ten game types at least once. |
| Mit Liebe zum Detail | Complete all 29 finite bonus objectives below. |
| Blank für den Nikolaus | Clean and polish the boot in door 6. |
| Lichterfest | Win Oy Vey collecting only Chanukkiot, with no Christmas mistakes. |
| Koscher durch Weihnachten | Win Oy Vey with zero Christmas mistakes. Other correct objects are allowed. |
| Einmal gesehen, nie vergessen | Win Memory without missing an available known twin. |
| Wichtel mit Köpfchen | Solve each difficulty within its bonus move budget. Three objectives. |
| Sicher nach Hause | Win the walk home with zero collisions. |
| Unkaputtbar | Reach home after hitting at least five distinct obstacles. |
| Keine roten Balken | Win Akku-Panik without any battery ever falling below 3%. |
| Halb voll, ganz geschafft | Reach at least 50% on one device at any point and win that run. |
| Wie ausgestochen | One zero-mistake cookie win per difficulty. Three objectives. |
| Naschkatze | Collect all three candies and reach the flag separately on Leicht, Klassisch and Knifflig. Three objectives. |
| Ein ganzes Festtagskonzert | Win each of the eleven curated bell-song excerpts once, at any difficulty. Eleven objectives. |
| Neun Spiele, ein Lichterfest | Win all nine supported games in Chanukka mode; difficulty is freely selectable. |
| Feierabend, Weihnachtsmann! | Return to the starting pipe and leave northward through the rooftop chimney. This is a secret successful ending. |

The individual bonus requirements total 29. Repeated wins never inflate counters.
Replays can earn missed bonuses even when the calendar door is already complete.

### Fairness and measurement

Memory tracks revealed positions. After the first card of a turn is selected,
if its unmatched twin has previously been seen, that twin must be selected next.
Discovering an unknown twin as the second card does not retroactively penalize
the turn. A known-pair mistake stays recorded until the run is restarted.

Workshop limits are 20 / 40 / 68 net moves for the redesigned boards. Independently
searched shortest solutions are 18 / 38 / 65 moves; only 2 / 2 / 3 extra moves
are allowed. The illustration features an oversized brain and a tiny bespectacled
elf. Previously earned achievements remain earned. Undo restores
net moves. Exceeding the budget never loses the puzzle, only the bonus attempt.
Custom levels without a bonus budget do not display a move counter or qualify.
The achievement's detail page offers all three difficulties after the player
has won that game in a calendar door. Cookie and labyrinth practice work the same way.
These real bonus attempts update achievements but never mark a calendar date or
open the physical box. Admin/development previews remain isolated and award nothing.

Cookie perfection means zero wrong directions, early presses and missed timing
windows for the whole outline. Recovery permits winning but does not erase a
mistake. Each difficulty must be perfected in its own run.

Walk collisions already count each obstacle at most once. Both collision bonuses
require reaching home. Battery minima and peaks are measured at every physics
substep, including initial batteries; temporary dips and peaks count even if the
final values change. All built-in battery levels start above 3%.

Generated labyrinths reserve three reachable candy positions off the required
route, favoring deeper branch areas. Candy is optional for ordinary victory,
does not overlap pits or walls, counts once per attempt, and resets after a fall.
The HUD shows the pickup count. Finishing without all candy does not earn a
bonus objective. Naschkatze requires qualifying wins at all three difficulties;
repeated wins at one difficulty cannot substitute for another.

## Persistence and separation

Pure game models own run observations. Screens supply `RunFacts` to the shared
`CompletionPanel`. A daily `AchievementScope` supplies game, difficulty and door
identity from the route. Saving completion happens first; achievement writes
follow and are retryable without replaying or duplicating Pico acknowledgements.
Standalone preview routes have no achievement writer.

`AchievementStore` persists token sets, earned badges, optional reward text and
claims in one local shared-preferences record. Writes are serialized and applied
in memory only after successful storage. New achievements automatically show an illustrated, pointer-transparent toast
above the shared win card, with one short burst of confetti. Each toast fades
after three seconds; multiple awards queue automatically without extra taps or
repeat confetti bursts. Reduced-motion mode skips moving particles and
transitions, while retaining the announcement. Short landscape screens place
the toast beside the gift. Replaying or leaving cleans up timers and overlays. Awarded badge IDs and received vouchers remain recorded across
restarts. Existing calendar completions can import date progress, but cannot
invent old game-specific statistics; replay earns those bonuses.

`LocalProgressRepository` also persists calendar completion. The old sample
repository is available only for explicit injection in tests or development.
Neither store has a dependency on Pico services or physical unlocking.

## Physical vouchers

**Advent-Verwaltung → Erfolge & Gutscheine** edits the single hidden final
reward text (up to 240 characters). The player must earn all 17 achievements to
reveal and mark that voucher as received once. Collecting all labyrinth candy
awards only **Naschkatze**, with no additional treat or voucher.

Individual reward settings are rejected by the storage API. Legacy per-badge
reward texts and claims are ignored on load, while badges and progress remain.
The admin editor offers only the final reward. Empty text means the surprise has
not been assigned yet; no massage or real-world reward is promised by default.
The final voucher is a local acknowledgement of receipt, not a hardware command,
booking, purchase or authorization. Prepare its physical version separately.

Tests cover every rule, serialized and failed writes, replay and preview
isolation, persistent claims, actual cookie result reporting, known-pair Memory
mistakes, workshop solution budgets, battery extrema, 180 generated candy layouts,
fall resets, German player/admin navigation and responsive layouts.


The Santa goal requires leaving the board northward through the original
entrance at cell 0 after travelling through the chimney. This is an alternate
successful ending, reporting normal daily completion plus the achievement.
Merely travelling upward, returning to the starting pipe without exiting, or
leaving through another board edge does not qualify. Players can rotate vacated
pipes to build the return route; the occupied pipe remains locked.

Rule version 2 re-evaluates the old one-run Naschkatze and the affected aggregate
achievements. An old candy token has no difficulty metadata and cannot prove any
of the three new goals. Other earned badges and difficulty progress remain;
any already-received final voucher stays marked as received to prevent a second
claim after finishing the new requirements.

Rule version 3 replaces the former upward-movement criterion with the actual
rooftop exit. Earlier approximate Santa awards and dependent aggregate awards
are re-evaluated; unrelated badges, candy difficulty progress, daily completion
and previously received voucher acknowledgements remain intact.


## Bell-song collection

**Ein ganzes Festtagskonzert** tracks the eleven stable melody IDs. Winning
the full curated hook counts, regardless of visual assistance or difficulty.
Listening, unfinished answers, shortened custom lessons and repeating a song
do not substitute for the other songs. Correct retries are allowed. Full song
rounds completed within a multi-round challenge are reported with its final win.

After completing a bell-game door, **Lieder spielen** on the achievement detail
page opens the player song collection. Select any song and difficulty; each
completion updates the collection without marking a calendar date or opening
the box. This is distinct from the admin/development preview, which remains
isolated. The collection uses a fixed two-column portrait/four-column landscape
layout with up to eight songs per page, with completed songs visibly checked. The achievement has its own
illustration of golden bells above an open songbook and uses the shared toast
and confetti celebration.

Rule version 4 includes the song collection in the 26 bonus objectives and
16-achievement final reward. Existing individual badges remain earned. Earlier
aggregate bonus awards are re-evaluated until the songs are completed; previously
received final vouchers remain marked as received. Old generic bell-game wins
cannot prove which songs were played, so no historical melody IDs are guessed.

Rule version 5 adds three Hanukkah hooks and the eight-game seasonal achievement.
The current totals are 29 bonus objectives and 17 achievements. Affected aggregate
awards are reevaluated; previous voucher claims remain acknowledged. See
[Chanukka mode](hanukkah.md) for date rules, replay controls and music sources.

Rule version 6 adds the shekel-cleaning variant to the seasonal badge. Existing
individual badges and voucher claims remain earned; the seasonal aggregate and
final bonus now also require the ninth mode. Day 6 defaults to the boot; cleaning
a coin there cannot substitute for the Nikolaus boot achievement.
