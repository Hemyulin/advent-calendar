import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../presentation/calendar_style.dart';
import '../presentation/viewport_fit.dart';
import 'achievement_art.dart';
import 'achievement_store.dart';

/// A temporary, pointer-transparent overlay. Its owner may also dismiss it when
/// leaving/replaying the result; dismissal is safe after automatic expiry.
VoidCallback? showAchievementCelebration(
  BuildContext context,
  List<Achievement> earned,
) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null || earned.isEmpty) return null;
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  late OverlayEntry entry;
  var active = true;
  void dismiss() {
    if (!active) return;
    active = false;
    entry.remove();
    entry.dispose();
  }

  entry = OverlayEntry(
    builder: (_) => _AchievementCelebration(
      achievements: List.unmodifiable(earned),
      reducedMotion: reducedMotion,
      onFinished: dismiss,
    ),
  );
  overlay.insert(entry);
  return dismiss;
}

class _AchievementCelebration extends StatefulWidget {
  const _AchievementCelebration({
    required this.achievements,
    required this.reducedMotion,
    required this.onFinished,
  });
  final List<Achievement> achievements;
  final bool reducedMotion;
  final VoidCallback onFinished;
  @override
  State<_AchievementCelebration> createState() =>
      _AchievementCelebrationState();
}

class _AchievementCelebrationState extends State<_AchievementCelebration>
    with SingleTickerProviderStateMixin {
  late final _effect = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  Timer? _timer;
  int _index = 0;
  bool _closing = false;
  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _closing = false;
    if (widget.reducedMotion) {
      _effect.value = 1;
    } else {
      _effect.forward(from: 0);
    }
    _timer = Timer(const Duration(seconds: 3), _advance);
  }

  Future<void> _advance() async {
    if (!mounted) return;
    if (!widget.reducedMotion) {
      setState(() => _closing = true);
      try {
        await _effect
            .animateTo(0, duration: const Duration(milliseconds: 240))
            .orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted) return;
    if (_index == widget.achievements.length - 1) {
      widget.onFinished();
    } else {
      setState(() {
        _index++;
        _start();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _effect.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: AnimatedBuilder(
        animation: _effect,
        builder: (context, _) {
          final progress = _effect.value;
          final opacity = widget.reducedMotion
              ? 1.0
              : _closing
              ? progress
              : (progress * 6).clamp(0.0, 1.0);
          final achievement = widget.achievements[_index];
          return Stack(
            children: [
              if (!widget.reducedMotion &&
                  !_closing &&
                  _index == 0 &&
                  progress < 1)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey('achievement-confetti'),
                      painter: _ConfettiPainter(progress),
                    ),
                  ),
                ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = MediaQuery.sizeOf(context).height < 500;
                      return Align(
                        alignment: compact
                            ? Alignment.topLeft
                            : Alignment.topCenter,
                        child: SizedBox(
                          width: compact
                              ? math
                                    .max(
                                      200.0,
                                      (constraints.maxWidth - 360) / 2 - 8,
                                    )
                                    .clamp(0.0, 300.0)
                              : constraints.maxWidth,
                          height: compact ? 90 : 112,
                          child: ViewportFit(
                            maxWidth: 420,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Opacity(
                              opacity: opacity,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  widget.reducedMotion ? 0 : -6 * (1 - opacity),
                                ),
                                child: Semantics(
                                  container: true,
                                  liveRegion: true,
                                  label:
                                      'Erfolg freigeschaltet! ${achievement.title}${widget.achievements.length > 1 ? '. ${_index + 1} von ${widget.achievements.length} neuen Erfolgen.' : ''}',
                                  child: ExcludeSemantics(
                                    child: Material(
                                      key: const ValueKey(
                                        'achievement-celebration-toast',
                                      ),
                                      color: CalendarStyle.ivory,
                                      elevation: 5,
                                      shadowColor: CalendarStyle.green
                                          .withValues(alpha: .2),
                                      borderRadius: BorderRadius.circular(18),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: CalendarStyle.gold
                                                .withValues(alpha: .4),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            children: [
                                              AchievementIllustration(
                                                achievementId: achievement.id,
                                                earned: true,
                                                width: compact ? 52 : 72,
                                                height: compact ? 38 : 50,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Erfolg freigeschaltet!',
                                                      style: TextStyle(
                                                        color:
                                                            CalendarStyle.gold,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      achievement.title,
                                                      style: TextStyle(
                                                        color:
                                                            CalendarStyle.green,
                                                        fontSize: compact
                                                            ? 14
                                                            : 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (widget.achievements.length >
                                                  1) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${_index + 1}/${widget.achievements.length}',
                                                  style: const TextStyle(
                                                    color: CalendarStyle.muted,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// Small paper ribbons launched from the upper corners, with a deterministic
/// trajectory. Sparse particles and a transparent canvas keep the gift visible.
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(1224);
    final t = progress * 1.5;
    final alpha = (1 - math.max(0, progress - .35) / .65).clamp(0.0, 1.0);
    final p = Paint();
    const colors = [
      Color(0xFFE3B65D),
      Color(0xFFCA6557),
      Color(0xFF94B8A0),
      Color(0xFF5A91A1),
      Color(0xFFFFF0CD),
    ];
    for (var i = 0; i < 36; i++) {
      final fromLeft = i.isEven;
      final origin = size.width * (fromLeft ? .13 : .87);
      final vx =
          (fromLeft ? 1 : -1) * size.width * (.12 + random.nextDouble() * .36);
      final vy = -55 - random.nextDouble() * 145;
      final x = origin + vx * t;
      final y = math.min(size.height * .16, 110) + vy * t + 220 * t * t;
      final rotation =
          random.nextDouble() * math.pi + t * (random.nextDouble() * 6 - 3);
      final width = 3 + random.nextDouble() * 3;
      final height = 5 + random.nextDouble() * 5;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: width, height: height),
          const Radius.circular(1),
        ),
        p..color = colors[i % colors.length].withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
