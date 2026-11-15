import 'package:flutter/material.dart';
import 'game_skin.dart';

class GameSkinScope extends InheritedWidget {
  const GameSkinScope({
    super.key,
    required this.skin,
    required this.onSwitch,
    required super.child,
  });
  final GameSkin skin;
  final VoidCallback onSwitch;
  static GameSkinScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameSkinScope>();
  static bool isHanukkah(BuildContext context) =>
      maybeOf(context)?.skin == GameSkin.hanukkah;
  @override
  bool updateShouldNotify(GameSkinScope oldWidget) => oldWidget.skin != skin;
}

/// Skin changes deliberately recreate the game, including its timers/audio.
/// Completion scopes remain above this widget, so saved progress is retained.
class SkinnableGame extends StatefulWidget {
  const SkinnableGame({
    super.key,
    required this.initialSkin,
    required this.builder,
  });
  final GameSkin initialSkin;
  final Widget Function(GameSkin) builder;
  @override
  State<SkinnableGame> createState() => _SkinnableGameState();
}

class _SkinnableGameState extends State<SkinnableGame> {
  late GameSkin _skin = widget.initialSkin;
  @override
  Widget build(BuildContext context) => GameSkinScope(
    skin: _skin,
    onSwitch: () => setState(
      () => _skin = _skin == GameSkin.christmas
          ? GameSkin.hanukkah
          : GameSkin.christmas,
    ),
    child: KeyedSubtree(key: ValueKey(_skin), child: widget.builder(_skin)),
  );
}

class SkinSwitch extends StatelessWidget {
  const SkinSwitch({super.key});
  @override
  Widget build(BuildContext context) {
    final scope = GameSkinScope.maybeOf(context);
    if (scope == null) return const SizedBox.shrink();
    return IconButton(
      key: const ValueKey('hanukkah-skin-switch'),
      tooltip: scope.skin == GameSkin.hanukkah
          ? 'Weihnachtsmodus · neuer Versuch'
          : 'Chanukka-Modus · neuer Versuch',
      onPressed: scope.onSwitch,
      isSelected: scope.skin == GameSkin.hanukkah,
      icon: const SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(painter: StarOfDavidPainter()),
      ),
      style: IconButton.styleFrom(
        foregroundColor: const Color(0xFF376C91),
        backgroundColor: scope.skin == GameSkin.hanukkah
            ? const Color(0xFFE3ECF2)
            : Colors.transparent,
      ),
    );
  }
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
