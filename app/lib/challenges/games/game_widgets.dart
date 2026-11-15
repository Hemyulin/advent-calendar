import 'package:flutter/material.dart';

import '../../presentation/calendar_style.dart';
import '../../presentation/viewport_fit.dart';
import '../completion.dart';
import '../../achievements/run_facts.dart';
import '../../achievements/achievement_scope.dart';
import '../../achievements/achievement_store.dart';
import '../../achievements/achievement_celebration.dart';
import '../gift_reward.dart';
import '../seasonal/game_skin_scope.dart';
import 'gift_art.dart';
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
    return GameResultLayer(
      result: result,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            maxLines: 2,
            style: title.length > 24
                ? const TextStyle(fontSize: 18, height: 1.1)
                : null,
          ),
          actions: [
            const SkinSwitch(),
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
        body: SafeArea(
          child: ViewportFit(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...children.where(
                  (child) => child is! CompletionPanel && child is! DefeatPanel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
  late final _giftAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _opening = false, _opened = false;
  GiftOpenResult? _giftResult;

  Future<void> _openGift() async {
    if (!_saved || _opening || _opened) return;
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
    _giftAnimation.dispose();
    super.dispose();
  }

  VoidCallback? _dismissCelebration;
  bool _saving = false;
  bool _saved = false;
  bool _failed = false;

  bool _saveStarted = false;
  bool _hanukkah = false;
  Future<List<Achievement>> Function(RunFacts)? _recordAchievements;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_saveStarted) return;
    _recordAchievements = AchievementScope.maybeOf(context)?.record;
    _hanukkah = GameSkinScope.isHanukkah(context);
    _saveStarted = true;
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
        });
        if (earned.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _dismissCelebration?.call();
            _dismissCelebration = showAchievementCelebration(context, earned);
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
            if (_saved && !_opening) const SkinSwitch(),
            TextButton.icon(
              key: const ValueKey('completion-replay'),
              onPressed: _saved && !_opening ? widget.onReplay : null,
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
                    width: 240,
                    height: 232,
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
                        ? 'Öffnet …'
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
                GiftOpenResult.boxOpened => 'Die Box ist offen!',
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
          if (widget.details != null) widget.details!,
        ],
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
