import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'game_skin.dart';
import '../../presentation/calendar_style.dart';

class GameSkinScope extends InheritedWidget {
  const GameSkinScope({
    super.key,
    required this.skin,
    required super.child,
    this.toggleReplayTheme,
    this.replay,
    this.isReplay = false,
  });
  final GameSkin skin;
  final bool isReplay;
  final VoidCallback? toggleReplayTheme;
  final void Function(VoidCallback restart)? replay;
  static GameSkinScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameSkinScope>();
  static bool isHanukkah(BuildContext context) =>
      maybeOf(context)?.skin == GameSkin.hanukkah;
  @override
  bool updateShouldNotify(GameSkinScope oldWidget) =>
      oldWidget.skin != skin ||
      oldWidget.isReplay != isReplay ||
      oldWidget.toggleReplayTheme != toggleReplayTheme;
}

/// Themes can be chosen for a fresh replay; a first attempt keeps its assignment.
class SkinnableGame extends StatefulWidget {
  const SkinnableGame({
    super.key,
    required this.initialSkin,
    required this.builder,
    this.isReplay = false,
    this.developmentPreview = false,
  });
  final GameSkin initialSkin;
  final Widget Function(GameSkin) builder;
  final bool isReplay, developmentPreview;
  static const unlockNoticeKey = 'replay.chanukkah-unlock-seen.v2';
  @override
  State<SkinnableGame> createState() => _SkinnableGameState();
}

class _SkinnableGameState extends State<SkinnableGame> {
  late GameSkin _skin = widget.initialSkin;
  late bool _replaying = widget.isReplay;
  bool _completedOnce = false;
  @override
  void initState() {
    super.initState();
    if (_replaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _announce());
    }
  }

  Future<void> _announce() async {
    if (widget.developmentPreview || _skin != GameSkin.christmas || !mounted) {
      return;
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool(SkinnableGame.unlockNoticeKey) == true ||
          !mounted) {
        return;
      }
      if (_skin != GameSkin.christmas ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const ValueKey('hanukkah-unlock-dialog'),
          scrollable: true,
          backgroundColor: CalendarStyle.ivory,
          icon: const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CustomPaint(painter: StarOfDavidPainter()),
            ),
          ),
          title: const Text('Chanukka-Modus freigeschaltet!'),
          content: const Text(
            'Du kannst deine Spiele jetzt auch im jüdischen Modus spielen! '
            'Tippe auf den Davidstern oben in der App-Leiste, um zwischen beiden Varianten zu wechseln.',
          ),
          actions: [
            TextButton(
              key: const ValueKey('hanukkah-unlock-understood'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Verstanden'),
            ),
          ],
        ),
      );
      await preferences.setBool(SkinnableGame.unlockNoticeKey, true);
    } catch (_) {
      // An optional discovery notice must never prevent replay.
    }
  }

  void _replay(VoidCallback restart) {
    setState(() {
      _replaying = true;
      _completedOnce = true;
    });
    restart();
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce());
  }

  void _toggleTheme() {
    if (!mounted) return;
    setState(() {
      _skin = _skin == GameSkin.hanukkah
          ? GameSkin.christmas
          : GameSkin.hanukkah;
      _replaying = true;
    });
  }

  @override
  Widget build(BuildContext context) => GameSkinScope(
    skin: _skin,
    isReplay: widget.isReplay || _completedOnce,
    replay: _replay,
    toggleReplayTheme:
        (widget.developmentPreview ||
            _replaying ||
            widget.initialSkin == GameSkin.hanukkah)
        ? _toggleTheme
        : null,
    child: KeyedSubtree(key: ValueKey(_skin), child: widget.builder(_skin)),
  );
}

class StarOfDavidPainter extends CustomPainter {
  const StarOfDavidPainter({this.color = const Color(0xFF376C91)});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .065
      ..strokeJoin = StrokeJoin.round;
    for (final inverted in [false, true]) {
      final path = Path()
        ..moveTo(size.width * .5, size.height * (inverted ? .93 : .07))
        ..lineTo(size.width * .09, size.height * (inverted ? .29 : .71))
        ..lineTo(size.width * .91, size.height * (inverted ? .29 : .71))
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(StarOfDavidPainter oldDelegate) =>
      oldDelegate.color != color;
}
