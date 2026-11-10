import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../presentation/calendar_style.dart';
import '../completion.dart';
import '../games/game_widgets.dart';
import '../games/difficulty.dart';
import 'workshop_game.dart';

class WorkshopScreen extends StatefulWidget {
  const WorkshopScreen({
    super.key,
    required this.onComplete,
    this.level,
    this.alreadyCompleted = false,
  });
  final WorkshopLevel? level;
  final ChallengeCompletion onComplete;
  final bool alreadyCompleted;
  @override
  State<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends State<WorkshopScreen> {
  late WorkshopGame _game;
  final _focus = FocusNode();
  Timer? _completionTimer;
  Offset _drag = Offset.zero;
  bool _swiped = false;
  bool _showResult = false;
  int _restarts = 0;

  @override
  void initState() {
    super.initState();
    _game = WorkshopGame(
      widget.level ?? WorkshopLevel.forDifficulty(GameDifficulty.normal),
    );
  }

  Duration get _movementDuration => MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 170);

  void _move(WorkshopDirection direction) {
    if (_showResult || ModalRoute.of(context)?.isCurrent == false) return;
    final before = _game.placed;
    if (!_game.move(direction)) return;
    setState(() {});
    if (_game.placed > before) HapticFeedback.lightImpact();
    if (_game.won) {
      _completionTimer?.cancel();
      _completionTimer = Timer(
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 350),
        () {
          if (mounted && _game.won) setState(() => _showResult = true);
        },
      );
    }
  }

  void _undo() {
    if (!_game.canUndo || _showResult) return;
    _completionTimer?.cancel();
    setState(_game.undo);
  }

  void _restart() {
    _completionTimer?.cancel();
    setState(() {
      _game = WorkshopGame(_game.level);
      _showResult = false;
      _drag = Offset.zero;
      _swiped = false;
      _restarts++;
    });
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focus,
    autofocus: true,
    onKeyEvent: (_, event) {
      final direction = switch (event.logicalKey) {
        LogicalKeyboardKey.arrowUp => WorkshopDirection.up,
        LogicalKeyboardKey.arrowDown => WorkshopDirection.down,
        LogicalKeyboardKey.arrowLeft => WorkshopDirection.left,
        LogicalKeyboardKey.arrowRight => WorkshopDirection.right,
        _ => null,
      };
      if (direction == null) return KeyEventResult.ignored;
      if (event is KeyDownEvent || event is KeyRepeatEvent) _move(direction);
      return KeyEventResult.handled;
    },
    child: GameScaffold(
      title: 'Wichtelwerkstatt',
      alreadyCompleted: widget.alreadyCompleted,
      onRestart: _restart,
      instructions:
          'Schiebe alle Geschenke auf die goldenen Plätze. Wische über die Werkstatt oder nutze die Pfeile. Du kannst immer nur ein Geschenk schieben, niemals ziehen. Holzkisten versperren den Weg. Mit Rückgängig nimmst du Züge zurück; oben kannst du neu beginnen.',
      children: [
        GameStats(
          text:
              '${_game.placed} / ${_game.presents.length} Geschenke · ${_game.moves} ${_game.moves == 1 ? 'Zug' : 'Züge'}',
        ),
        Semantics(
          label:
              'Werkstatt. Wichtel in Reihe ${_game.elf ~/ _game.level.size + 1}, Spalte ${_game.elf % _game.level.size + 1}. ${_game.placed} Geschenke am Ziel.',
          child: GestureDetector(
            key: const ValueKey('workshop-board'),
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) {
              _drag = Offset.zero;
              _swiped = false;
            },
            onPanUpdate: (details) {
              _drag += details.delta;
              if (_swiped || _drag.distance < 22) return;
              _swiped = true;
              _move(
                _drag.dx.abs() > _drag.dy.abs()
                    ? (_drag.dx > 0
                          ? WorkshopDirection.right
                          : WorkshopDirection.left)
                    : (_drag.dy > 0
                          ? WorkshopDirection.down
                          : WorkshopDirection.up),
              );
            },
            onPanEnd: (_) {
              _drag = Offset.zero;
            },
            onPanCancel: () {
              _drag = Offset.zero;
              _swiped = false;
            },
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tile = constraints.maxWidth / _game.level.size;
                  final boxes = _game.presents;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      key: ValueKey(_restarts),
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _WorkshopFloorPainter(
                              _game.level,
                              boxes.toSet(),
                            ),
                          ),
                        ),
                        for (var i = 0; i < boxes.length; i++)
                          AnimatedPositioned(
                            key: ValueKey('workshop-present-$i'),
                            duration: _movementDuration,
                            curve: Curves.easeOutCubic,
                            left: boxes[i] % _game.level.size * tile,
                            top: boxes[i] ~/ _game.level.size * tile,
                            width: tile,
                            height: tile,
                            child: Semantics(
                              label:
                                  'Geschenk ${i + 1}${_game.level.targets.contains(boxes[i]) ? ', am Ziel' : ''}',
                              child: TweenAnimationBuilder<double>(
                                key: ValueKey(
                                  _game.level.targets.contains(boxes[i]),
                                ),
                                tween: Tween(begin: 0, end: 1),
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 320),
                                builder: (_, t, child) => Transform.scale(
                                  scale: _game.level.targets.contains(boxes[i])
                                      ? 1 + math.sin(t * math.pi) * .1
                                      : 1,
                                  child: child,
                                ),
                                child: CustomPaint(
                                  painter: _PresentPainter(
                                    i,
                                    _game.level.targets.contains(boxes[i]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        AnimatedPositioned(
                          key: const ValueKey('workshop-elf'),
                          duration: _movementDuration,
                          curve: Curves.easeOutCubic,
                          left: _game.elf % _game.level.size * tile,
                          top: _game.elf ~/ _game.level.size * tile,
                          width: tile,
                          height: tile,
                          child: CustomPaint(
                            painter: _ElfPainter(_game.facing),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            for (final direction in WorkshopDirection.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Tooltip(
                    message: direction.label,
                    child: FilledButton.tonal(
                      key: ValueKey('workshop-${direction.name}'),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _game.won ? null : () => _move(direction),
                      child: Icon(switch (direction) {
                        WorkshopDirection.up => Icons.arrow_upward_rounded,
                        WorkshopDirection.down => Icons.arrow_downward_rounded,
                        WorkshopDirection.left => Icons.arrow_back_rounded,
                        WorkshopDirection.right => Icons.arrow_forward_rounded,
                      }, size: 28),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const ValueKey('workshop-undo'),
          onPressed: _game.canUndo ? _undo : null,
          icon: const Icon(Icons.undo_rounded),
          label: const Text('Rückgängig'),
        ),
        if (_showResult)
          CompletionPanel(
            onComplete: widget.onComplete,
            onReplay: _restart,
            message: 'Alle Geschenke sind an ihrem Platz!',
          ),
      ],
    ),
  );
}

class _WorkshopFloorPainter extends CustomPainter {
  _WorkshopFloorPainter(this.level, this.boxes);
  final WorkshopLevel level;
  final Set<int> boxes;
  @override
  void paint(Canvas canvas, Size size) {
    final tile = size.width / level.size;
    final paint = Paint();
    canvas.drawColor(const Color(0xFFF2E9D9), BlendMode.src);
    for (var cell = 0; cell < level.size * level.size; cell++) {
      final x = cell % level.size * tile, y = cell ~/ level.size * tile;
      final rect = Rect.fromLTWH(x + 1, y + 1, tile - 2, tile - 2);
      if (level.walls.contains(cell)) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(tile * .07)),
          paint..color = const Color(0xFFB69A74),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(tile * .06),
            Radius.circular(tile * .04),
          ),
          paint..color = const Color(0xFFCDB18A),
        );
        canvas.drawLine(
          Offset(x + tile * .16, y + tile * .3),
          Offset(x + tile * .84, y + tile * .3),
          paint
            ..color = const Color(0xFFB99A70)
            ..strokeWidth = 1,
        );
        canvas.drawLine(
          Offset(x + tile * .16, y + tile * .67),
          Offset(x + tile * .84, y + tile * .67),
          paint,
        );
        for (final k in [.18, .82]) {
          canvas.drawCircle(
            Offset(x + tile * k, y + tile * .17),
            tile * .02,
            paint..color = const Color(0xFF9D7E57),
          );
          canvas.drawCircle(
            Offset(x + tile * k, y + tile * .83),
            tile * .02,
            paint,
          );
        }
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          paint
            ..color = (cell % level.size + cell ~/ level.size).isEven
                ? const Color(0xFFF9F2E5)
                : const Color(0xFFF4EBD9),
        );
        if (level.targets.contains(cell)) {
          final placed = boxes.contains(cell);
          final mat = RRect.fromRectAndRadius(
            rect.deflate(tile * .1),
            Radius.circular(tile * .13),
          );
          canvas.drawRRect(
            mat,
            paint
              ..color = placed
                  ? const Color(0xFFD6E4CF)
                  : const Color(0xFFF1DDB4),
          );
          canvas.drawRRect(
            mat,
            paint
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = placed
                  ? CalendarStyle.green
                  : CalendarStyle.gold.withValues(alpha: .65),
          );
          final c = Offset(x + tile / 2, y + tile / 2);
          canvas.drawPath(
            Path()
              ..moveTo(c.dx, c.dy)
              ..cubicTo(
                c.dx - tile * .33,
                c.dy - tile * .3,
                c.dx - tile * .23,
                c.dy + tile * .12,
                c.dx,
                c.dy,
              )
              ..cubicTo(
                c.dx + tile * .33,
                c.dy - tile * .3,
                c.dx + tile * .23,
                c.dy + tile * .12,
                c.dx,
                c.dy,
              )
              ..lineTo(c.dx - tile * .12, c.dy + tile * .2)
              ..moveTo(c.dx, c.dy)
              ..lineTo(c.dx + tile * .12, c.dy + tile * .2),
            paint..strokeWidth = tile * .035,
          );
          paint.style = PaintingStyle.fill;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_WorkshopFloorPainter old) => true;
}

class _PresentPainter extends CustomPainter {
  _PresentPainter(this.id, this.placed);
  final int id;
  final bool placed;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final paint = Paint();
    canvas.drawOval(
      const Rect.fromLTWH(16, 78, 68, 13),
      paint..color = const Color(0xFFCDBB9E),
    );
    final color = const [
      Color(0xFFBD6758),
      Color(0xFF4E8171),
      Color(0xFF638E9C),
      Color(0xFFA27B89),
    ][id % 4];
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 22, 68, 59),
        const Radius.circular(9),
      ),
      paint..color = color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(13, 25, 74, 15),
        const Radius.circular(5),
      ),
      paint..color = Color.lerp(color, CalendarStyle.ivory, .1)!,
    );
    canvas.drawRect(
      const Rect.fromLTWH(44, 24, 12, 56),
      paint..color = const Color(0xFFF4DCAB),
    );
    canvas.drawPath(
      Path()
        ..moveTo(50, 26)
        ..cubicTo(15, -1, 20, 41, 50, 26)
        ..cubicTo(83, -1, 80, 41, 50, 26),
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF4DCAB),
    );
    paint.style = PaintingStyle.fill;
    if (placed) {
      canvas.drawCircle(
        const Offset(79, 75),
        12,
        paint..color = CalendarStyle.ivory,
      );
      canvas.drawCircle(
        const Offset(79, 75),
        10,
        paint..color = CalendarStyle.green,
      );
      canvas.drawPath(
        Path()
          ..moveTo(74, 75)
          ..lineTo(78, 79)
          ..lineTo(85, 71),
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = CalendarStyle.ivory,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PresentPainter old) =>
      old.id != id || old.placed != placed;
}

class _ElfPainter extends CustomPainter {
  _ElfPainter(this.facing);
  final WorkshopDirection facing;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final paint = Paint();
    canvas.drawOval(
      const Rect.fromLTWH(20, 82, 60, 12),
      paint..color = const Color(0xFFCDBB9E),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(26, 72, 20, 16),
        const Radius.circular(5),
      ),
      paint..color = const Color(0xFF355D4B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(54, 72, 20, 16),
        const Radius.circular(5),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(23, 44, 54, 36),
        const Radius.circular(16),
      ),
      paint..color = const Color(0xFF568466),
    );
    canvas.drawRect(
      const Rect.fromLTWH(25, 57, 50, 8),
      paint..color = const Color(0xFFB96758),
    );
    canvas.drawCircle(
      const Offset(50, 68),
      2.5,
      paint..color = const Color(0xFFE9C878),
    );
    canvas.drawPath(
      Path()
        ..moveTo(33, 40)
        ..lineTo(21, 34)
        ..lineTo(28, 49)
        ..moveTo(67, 40)
        ..lineTo(79, 34)
        ..lineTo(72, 49),
      paint..color = const Color(0xFFF0C6A0),
    );
    canvas.drawOval(const Rect.fromLTWH(32, 29, 36, 30), paint);
    canvas.drawPath(
      Path()
        ..moveTo(26, 33)
        ..quadraticBezierTo(31, 5, 61, 10)
        ..quadraticBezierTo(69, 10, 74, 20)
        ..quadraticBezierTo(57, 14, 63, 34)
        ..close(),
      paint..color = const Color(0xFF48765A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(27, 29, 39, 7),
        const Radius.circular(4),
      ),
      paint..color = const Color(0xFFE9D3A5),
    );
    canvas.drawCircle(
      const Offset(75, 20),
      5,
      paint..color = const Color(0xFFBE6F5D),
    );
    final gaze = facing.dx * 2.0;
    canvas.drawCircle(
      Offset(42 + gaze, 43),
      1.7,
      paint..color = const Color(0xFF355244),
    );
    canvas.drawCircle(Offset(56 + gaze, 43), 1.7, paint);
    canvas.drawArc(
      const Rect.fromLTWH(45, 47, 10, 5),
      0,
      math.pi,
      false,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ElfPainter old) => old.facing != facing;
}
