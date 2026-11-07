import 'package:flutter/material.dart';

import '../../presentation/calendar_style.dart';
import '../../presentation/viewport_fit.dart';
import '../completion.dart';

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
                          color: const Color(0xFFF5E6C9),
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
  });
  final Widget? details;
  final ChallengeCompletion onComplete;
  final VoidCallback onReplay;
  final String message;
  @override
  State<CompletionPanel> createState() => _CompletionPanelState();
}

class _CompletionPanelState extends State<CompletionPanel> {
  bool _saving = false;
  bool _saved = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _save();
  }

  Future<void> _save() async {
    if (_saving || _saved) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onComplete();
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFFF5E6C9),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 450),
          tween: Tween(begin: 0.7, end: 1),
          builder: (_, value, child) =>
              Transform.scale(scale: value, child: child),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: CalendarStyle.green,
            size: 42,
          ),
        ),
        const SizedBox(height: 12),
        Text('Geschafft!', style: CalendarStyle.heading.copyWith(fontSize: 28)),
        const SizedBox(height: 8),
        Text(widget.message, textAlign: TextAlign.center),
        if (widget.details != null) widget.details!,
        const SizedBox(height: 12),
        if (_saving)
          Semantics(
            label: 'Fortschritt wird gespeichert',
            liveRegion: true,
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        if (_failed)
          const Text('Speichern fehlgeschlagen.', textAlign: TextAlign.center),
        if (_failed)
          TextButton(onPressed: _save, child: const Text('Erneut speichern')),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _saved ? widget.onReplay : null,
          child: const Text('Noch einmal spielen'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zurück zum Kalender'),
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
