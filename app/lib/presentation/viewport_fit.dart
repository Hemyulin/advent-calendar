import 'package:flutter/material.dart';

/// Fixed game pages fit their available viewport; they never become documents
/// that need scrolling. The canvas and its hit targets share the same transform.
class ViewportFit extends StatelessWidget {
  const ViewportFit({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.maxWidth = 500,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: LayoutBuilder(
      builder: (context, constraints) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: constraints.maxWidth.clamp(0.0, maxWidth),
            child: child,
          ),
        ),
      ),
    ),
  );
}
