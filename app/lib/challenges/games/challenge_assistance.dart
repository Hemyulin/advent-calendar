import 'package:flutter/material.dart';
import '../../achievements/achievement_scope.dart';
import '../../achievements/achievement_store.dart';
import '../../achievements/run_facts.dart';
import '../../content/calendar_schedule.dart';
import '../../content/game_access_scope.dart';
import '../../presentation/calendar_style.dart';
import '../../presentation/viewport_fit.dart';
import '../completion.dart';
import '../seasonal/game_skin.dart';
import 'difficulty.dart';
import 'game_catalog.dart';

class ChallengeAssistance extends InheritedWidget {
  const ChallengeAssistance({
    super.key,
    required this.open,
    required super.child,
  });
  final VoidCallback open;
  static ChallengeAssistance? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChallengeAssistance>();
  @override
  bool updateShouldNotify(ChallengeAssistance oldWidget) =>
      oldWidget.open != open;
}

/// Changes only this attempt. The calendar assignment and prior wins survive.
/// Completion still goes through the daily handler; facts use the game actually played.
class FlexibleChallenge extends StatefulWidget {
  const FlexibleChallenge({
    super.key,
    required this.assignment,
    required this.onComplete,
    required this.record,
    this.alreadyCompleted = false,
  });
  final DayAssignment assignment;
  final ChallengeCompletion onComplete;
  final bool alreadyCompleted;
  final Future<List<Achievement>> Function(Minigame, GameDifficulty, RunFacts)
  record;
  @override
  State<FlexibleChallenge> createState() => _FlexibleChallengeState();
}

class _FlexibleChallengeState extends State<FlexibleChallenge> {
  late Minigame _game = widget.assignment.game;
  late GameDifficulty _difficulty = widget.assignment.difficulty;
  bool _relaxed = false, _dialogOpen = false;
  int _attempt = 0;
  late bool _completedOnce = widget.alreadyCompleted;

  Future<void> _complete() async {
    await widget.onComplete();
    if (mounted) setState(() => _completedOnce = true);
  }

  Future<void> _offer() async {
    if (_dialogOpen) return;
    setState(() => _dialogOpen = true);
    final lower =
        GameDifficulty.values[(_difficulty.index - 1).clamp(
          0,
          GameDifficulty.values.length - 1,
        )];
    final canRelax =
        GameAccessScope.reason(
              context,
              _game,
              _game == Minigame.cookies ? _difficulty : lower,
              skin: widget.assignment.skin,
            ) ==
            null &&
        _game != Minigame.trash &&
        (_game == Minigame.cookies
            ? !_relaxed
            : _difficulty != GameDifficulty.easy);
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ViewportFit(
          maxWidth: 360,
          padding: const EdgeInsets.all(24),
          child: Material(
            color: CalendarStyle.ivory,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Zu knifflig?',
                    textAlign: TextAlign.center,
                    style: CalendarStyle.heading.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Dein Türchen zählt trotzdem.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (canRelax) ...[
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context, 'easier'),
                      icon: const Icon(Icons.speed_rounded),
                      label: const Text(
                        'Etwas leichter',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_game != Minigame.trash)
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, 'trash'),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text(
                        'Lieber Müll rausbringen',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Weiterspielen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() => _dialogOpen = false);
    if (!mounted || choice == null) return;
    if (!GameAccessScope.allow(
      context,
      choice == 'trash' ? Minigame.trash : _game,
      choice == 'trash'
          ? GameDifficulty.easy
          : _game == Minigame.cookies
          ? _difficulty
          : lower,
      skin: choice == 'trash' ? GameSkin.christmas : widget.assignment.skin,
    )) {
      return;
    }
    setState(() {
      if (choice == 'trash') {
        _game = Minigame.trash;
        _difficulty = GameDifficulty.easy;
        _relaxed = false;
      } else {
        _relaxed = true;
        if (_game != Minigame.cookies) {
          _difficulty = GameDifficulty.values[_difficulty.index - 1];
        }
      }
      _attempt++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = _game, difficulty = _difficulty;
    final relaxed = _relaxed;
    final child = AchievementScope(
      record: (facts) => widget.record(
        game,
        difficulty,
        relaxed
            ? RunFacts(
                won: facts.won,
                hanukkahMode: facts.hanukkahMode,
                // A gentler attempt opens its door but does not claim strict bonus goals.
              )
            : facts,
      ),
      child: buildMinigame(
        game,
        difficulty,
        _complete,
        alreadyCompleted: _completedOnce,
        skin: game == Minigame.trash
            ? GameSkin.christmas
            : widget.assignment.skin,
        melodyId: widget.assignment.melodyId,
        relaxedCookies: relaxed && game == Minigame.cookies,
      ),
    );
    return KeyedSubtree(
      key: ValueKey(_attempt),
      child: TickerMode(
        enabled: !_dialogOpen,
        child: game == Minigame.trash
            ? child
            : ChallengeAssistance(open: _offer, child: child),
      ),
    );
  }
}
