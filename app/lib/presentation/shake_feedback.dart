import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A brief, decaying rattle; repeated invalid taps restart one finite animation.
class ShakeFeedback extends StatefulWidget {
  const ShakeFeedback({super.key, required this.trigger, required this.child});
  final int trigger;
  final Widget child;
  @override
  State<ShakeFeedback> createState() => _ShakeFeedbackState();
}

class _ShakeFeedbackState extends State<ShakeFeedback>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  @override
  void didUpdateWidget(ShakeFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger &&
        widget.trigger > 0 &&
        !MediaQuery.disableAnimationsOf(context)) {
      _animation.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    child: widget.child,
    builder: (context, child) {
      final reduced = MediaQuery.disableAnimationsOf(context);
      final t = _animation.value;
      final offset = reduced ? 0.0 : math.sin(t * math.pi * 6) * 7 * (1 - t);
      return Transform.translate(offset: Offset(offset, 0), child: child);
    },
  );
}
