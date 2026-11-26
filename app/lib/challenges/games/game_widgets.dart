import 'package:flutter/material.dart';

import '../../presentation/calendar_style.dart';
import '../../presentation/viewport_fit.dart';
import '../completion.dart';
import '../../achievements/run_facts.dart';
import '../../achievements/achievement_scope.dart';
import '../../achievements/achievement_store.dart';
import '../../achievements/achievement_celebration.dart';
import '../../achievements/achievement_win_summary.dart';
import '../gift_reward.dart';
import '../seasonal/game_skin_scope.dart';
import 'gift_art.dart';
import 'game_title_scroll.dart';
import 'challenge_assistance.dart';
import 'gift_reward_scope.dart';

class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.title,
    required this.instructions,
    required this.children,
    this.alreadyCompleted = false,
    this.onRestart,
  });
  final String title, instructions;
  final List<Widget> children;
  final bool alreadyCompleted;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    final results = children
        .where((child) => child is CompletionPanel || child is DefeatPanel)
        .toList();
    final result = results.isEmpty ? null : results.last;
    return _CompletionHistory(
      alreadyCompleted:
          alreadyCompleted ||
          (GameSkinScope.maybeOf(context)?.isReplay ?? false),
      child: GameResultLayer(
        result: result,
        child: Scaffold(
          appBar: AppBar(
            actions: [
              if (result == null)
                if (ChallengeAssistance.maybeOf(context) case final assistance?)
                  IconButton(
                    key: const ValueKey('challenge-assistance'),
                    tooltip: 'Zu schwer?',
                    onPressed: assistance.open,
                    icon: const Icon(Icons.tune_rounded),
                  ),
              if (GameSkinScope.maybeOf(context)?.toggleReplayTheme
                  case final start?)
                IconButton(
                  key: const ValueKey('hanukkah-replay'),
                  tooltip: GameSkinScope.isHanukkah(context)
                      ? 'Weihnachtsmodus spielen'
                      : 'Chanukka spielen',
                  isSelected: GameSkinScope.isHanukkah(context),
                  style: IconButton.styleFrom(
                    backgroundColor: GameSkinScope.isHanukkah(context)
                        ? const Color(0xFFE3ECF2)
                        : Colors.transparent,
                  ),
                  onPressed: start,
                  icon: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CustomPaint(painter: StarOfDavidPainter()),
                  ),
                ),
              if (alreadyCompleted)
                const Tooltip(
                  message: 'Bereits geschafft',
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: CalendarStyle.green,
                      size: 20,
                    ),
                  ),
                ),
              if (onRestart != null)
                IconButton(
                  tooltip: 'Neu starten',
                  onPressed: onRestart,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              IconButton(
                tooltip: 'Anleitung',
                onPressed: () => showGameHelp(context, title, instructions),
                icon: const Icon(Icons.help_outline_rounded),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: GameTitleScroll(title: title),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: ViewportFit(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...children.where(
                    (child) =>
                        child is! CompletionPanel && child is! DefeatPanel,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Remembers replay within a mounted game, including games without skin support.
class _CompletionHistory extends StatefulWidget {
  const _CompletionHistory({
    required this.alreadyCompleted,
    required this.child,
  });
  final bool alreadyCompleted;
  final Widget child;
  @override
  State<_CompletionHistory> createState() => _CompletionHistoryState();
}

class _CompletionHistoryState extends State<_CompletionHistory> {
  bool _replayed = false;
  @override
  Widget build(BuildContext context) => _CompletionContext(
    isReplay: widget.alreadyCompleted || _replayed,
    markReplay: () => setState(() => _replayed = true),
    child: widget.child,
  );
}

class _CompletionContext extends InheritedWidget {
  const _CompletionContext({
    required this.isReplay,
    required this.markReplay,
    required super.child,
  });
  final bool isReplay;
  final VoidCallback markReplay;
  static _CompletionContext? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CompletionContext>();
  @override
  bool updateShouldNotify(_CompletionContext oldWidget) =>
      oldWidget.isReplay != isReplay;
}

/// Results live above the complete screen, including the app bar. They block
/// background input and expose their own return/replay actions to accessibility.
class GameResultLayer extends StatelessWidget {
  const GameResultLayer({super.key, required this.child, this.result});
  final Widget child;
  final Widget? result;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      AbsorbPointer(absorbing: result != null, child: child),
      if (result != null)
        Positioned.fill(
          key: const ValueKey('game-result-overlay'),
          child: BlockSemantics(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ModalBarrier(
                  dismissible: false,
                  color: Color(0x990F211B),
                  semanticsLabel: 'Spielergebnis',
                ),
                SafeArea(
                  child: ViewportFit(
                    maxWidth: 360,
                    padding: const EdgeInsets.all(24),
                    child: FocusScope(
                      autofocus: true,
                      child: Semantics(
                        scopesRoute: true,
                        explicitChildNodes: true,
                        namesRoute: true,
                        label: 'Spielergebnis',
                        child: Material(
                          color: result is CompletionPanel
                              ? CalendarStyle.ivory
                              : const Color(0xFFF5E6C9),
                          elevation: 18,
                          borderRadius: BorderRadius.circular(24),
                          clipBehavior: Clip.antiAlias,
                          child: result,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class GameStats extends StatelessWidget {
  const GameStats({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: CalendarStyle.green.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: CalendarStyle.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

/// Victory is reported once. A failed save can be retried without replaying.
class CompletionPanel extends StatefulWidget {
  const CompletionPanel({
    super.key,
    required this.onComplete,
    required this.onReplay,
    required this.message,
    this.details,
    this.facts = const RunFacts(),
  });
  final RunFacts facts;
  final Widget? details;
  final ChallengeCompletion onComplete;
  final VoidCallback onReplay;
  final String message;
  @override
  State<CompletionPanel> createState() => _CompletionPanelState();
}

class _CompletionPanelState extends State<CompletionPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _giftAnimation;

  @override
  void initState() {
    super.initState();
    _giftAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  bool _opening = false, _opened = false;
  GiftOpenResult? _giftResult;

  Future<void> _openGift() async {
    if (_isReplay || !_saved || _opening || _opened) return;
    final open = GiftRewardScope.maybeOf(context)?.openGift;
    setState(() => _opening = true);
    // Hardware feedback and the visual reveal run independently. The shared
    // handler bounds the request and never repeats an uncertain physical action.
    final result = _requestGift(open);
    try {
      if (MediaQuery.disableAnimationsOf(context)) {
        _giftAnimation.value = 1;
      } else {
        await _giftAnimation.forward().orCancel;
      }
      final feedback = await result;
      if (!mounted) return;
      setState(() {
        _opening = false;
        _opened = true;
        _giftResult = feedback;
      });
    } on TickerCanceled {
      // An intentional gift tap is not repeated when leaving during the reveal.
    }
  }

  Future<void> _reopenBox() async {
    if (_isReplay || !_saved || !_opened || _opening) return;
    final reopen = GiftRewardScope.maybeOf(context)?.reopenBox;
    if (reopen == null) return;
    setState(() => _opening = true);
    final result = await _requestGift(reopen);
    if (!mounted) return;
    setState(() {
      _opening = false;
      _giftResult = result;
    });
  }

  Future<GiftOpenResult> _requestGift(
    Future<GiftOpenResult> Function()? open,
  ) async {
    try {
      return open == null ? GiftOpenResult.preview : await open();
    } catch (_) {
      return GiftOpenResult.unconfirmed;
    }
  }

  @override
  void dispose() {
    _dismissCelebration?.call();
    _dismissConfetti?.call();
    _giftAnimation.dispose();
    super.dispose();
  }

  VoidCallback? _dismissCelebration, _dismissConfetti;
  List<Achievement> _earnedAchievements = const [];
  bool _saving = false;
  bool _saved = false;
  bool _failed = false;

  bool _saveStarted = false;
  bool _hanukkah = false;
  bool _isReplay = false;
  Future<List<Achievement>> Function(RunFacts)? _recordAchievements;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_saveStarted) return;
    _recordAchievements = AchievementScope.maybeOf(context)?.record;
    _hanukkah = GameSkinScope.isHanukkah(context);
    _isReplay = _CompletionContext.of(context)?.isReplay ?? false;
    _saveStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _dismissConfetti = showVictoryConfetti(context);
    });
    _save();
  }

  Future<void> _save() async {
    if (_saving || _saved) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      // Keep the won attempt's facts and writer even if the player immediately
      // returns to the calendar while completion storage is still finishing.
      final complete = widget.onComplete;
      final facts = RunFacts(
        feats: widget.facts.feats,
        completedBellSongs: widget.facts.completedBellSongs,
        hanukkahMode: _hanukkah,
      );
      final record = _recordAchievements;
      await complete();
      final earned = await record?.call(facts) ?? <Achievement>[];
      if (mounted) {
        setState(() {
          _saved = true;
          _earnedAchievements = List.unmodifiable(earned);
        });
        if (earned.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _dismissCelebration?.call();
            _dismissCelebration = showAchievementCelebration(
              context,
              earned,
              confetti: false,
            );
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              key: const ValueKey('completion-replay'),
              onPressed: _saved && !_opening
                  ? () {
                      _CompletionContext.of(context)?.markReplay();
                      final replay = GameSkinScope.maybeOf(context)?.replay;
                      if (replay == null) {
                        widget.onReplay();
                      } else {
                        replay(widget.onReplay);
                      }
                    }
                  : null,
              icon: const Icon(Icons.replay_rounded, size: 17),
              label: const Text(
                'Noch einmal spielen',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(foregroundColor: CalendarStyle.muted),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_isReplay) ...[
          const SizedBox(height: 18),
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 88,
            color: CalendarStyle.gold,
          ),
          const SizedBox(height: 18),
          Text(
            'Großartig!',
            key: const ValueKey('completion-congratulations'),
            textAlign: TextAlign.center,
            style: CalendarStyle.heading.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 12),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: CalendarStyle.green, fontSize: 16),
          ),
          if (widget.details != null) widget.details!,
        ] else
          Semantics(
            button: true,
            enabled: _saved && !_opening && !_opened,
            label: _opened ? 'Geschenk geöffnet' : 'Geschenk öffnen',
            child: InkResponse(
              key: const ValueKey('completion-gift'),
              onTap: _saved && !_opening && !_opened ? _openGift : null,
              radius: 125,
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: _earnedAchievements.isEmpty ? 240 : 188,
                      height: _earnedAchievements.isEmpty ? 232 : 178,
                      child: AnimatedBuilder(
                        animation: _giftAnimation,
                        builder: (_, _) => CustomPaint(
                          painter: GiftPainter(progress: _giftAnimation.value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _opening
                          ? 'Jetzt die Box öffnen'
                          : _opened
                          ? 'Geschenk geöffnet'
                          : _saving
                          ? 'Einen Moment …'
                          : _failed
                          ? 'Noch nicht gespeichert'
                          : 'Zum Öffnen tippen',
                      textAlign: TextAlign.center,
                      style: CalendarStyle.heading.copyWith(fontSize: 25),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_opened) ...[
          const SizedBox(height: 14),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: CalendarStyle.green, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(
              switch (_giftResult) {
                GiftOpenResult.boxOpened => 'Die Box wurde entriegelt.',
                GiftOpenResult.notConfigured =>
                  'Die Box ist noch nicht eingerichtet.',
                GiftOpenResult.unconfirmed =>
                  'Die Box hat das Öffnen nicht bestätigt.',
                GiftOpenResult.preview => 'Vorschau · ohne Box',
                _ =>
                  _hanukkah
                      ? 'Dein Festtagsmoment gehört dir.'
                      : 'Dein Weihnachtsmoment gehört dir.',
              },
              textAlign: TextAlign.center,
              style: const TextStyle(color: CalendarStyle.muted, fontSize: 13),
            ),
          ),
          if (GiftRewardScope.maybeOf(context)?.reopenBox != null &&
              (_giftResult == GiftOpenResult.boxOpened ||
                  _giftResult == GiftOpenResult.unconfirmed)) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              key: const ValueKey('completion-reopen-box'),
              onPressed: _opening ? null : _reopenBox,
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: Text(_opening ? 'Öffnet …' : 'Box erneut öffnen'),
            ),
          ],
          if (widget.details != null) widget.details!,
        ],
        if (_earnedAchievements.isNotEmpty)
          AchievementWinSummary(achievements: _earnedAchievements),
        if (_saving) ...[
          const SizedBox(height: 12),
          Semantics(
            label: 'Fortschritt wird gespeichert',
            liveRegion: true,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
        if (_failed) ...[
          const SizedBox(height: 12),
          const Text('Speichern fehlgeschlagen.', textAlign: TextAlign.center),
          TextButton(onPressed: _save, child: const Text('Erneut speichern')),
        ],
        const SizedBox(height: 24),
        TextButton.icon(
          key: const ValueKey('completion-calendar'),
          onPressed: _opening ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 15),
          label: const Text(
            'Zurück zum Kalender',
            style: TextStyle(fontSize: 12),
          ),
          style: TextButton.styleFrom(foregroundColor: CalendarStyle.muted),
        ),
      ],
    ),
  );
}

class DefeatPanel extends StatelessWidget {
  const DefeatPanel({
    super.key,
    required this.message,
    required this.onRetry,
    this.details,
  });
  final Widget? details;
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Text(
          'Fast geschafft',
          style: CalendarStyle.heading.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        ?details,
        const SizedBox(height: 14),
        FilledButton(
          onPressed: onRetry,
          child: const Text('Noch einmal versuchen'),
        ),
        if (ChallengeAssistance.maybeOf(context) case final assistance?)
          TextButton(
            onPressed: assistance.open,
            child: const Text('Zu schwer?'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zurück zum Kalender'),
        ),
      ],
    ),
  );
}

Future<void> showGameHelp(BuildContext context, String title, String text) =>
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Schließen',
      barrierColor: const Color(0x990F211B),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, _) => SafeArea(
        child: ViewportFit(
          padding: const EdgeInsets.all(24),
          maxWidth: 360,
          child: Material(
            color: CalendarStyle.ivory,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    color: CalendarStyle.gold,
                    size: 30,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: CalendarStyle.heading.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Verstanden'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
