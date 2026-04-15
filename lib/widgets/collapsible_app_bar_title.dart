import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Wraps a title widget and smoothly animates its left padding from
/// [expandedLeft] (when the [FlexibleSpaceBar] is fully expanded) to
/// [collapsedLeft] (when fully collapsed). Use this instead of a fixed
/// [FlexibleSpaceBar.titlePadding] left value so the title clears the
/// leading back-button only when the bar is actually collapsed.
///
/// Set [FlexibleSpaceBar.titlePadding] left to 0 and let this widget
/// own the horizontal start offset.
class CollapsibleAppBarTitle extends StatelessWidget {
  final Widget child;
  final double expandedLeft;
  final double collapsedLeft;

  const CollapsibleAppBarTitle({
    super.key,
    required this.child,
    this.expandedLeft = 20,
    this.collapsedLeft = 72,
  });

  @override
  Widget build(BuildContext context) {
    final settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    double leftPad = expandedLeft;
    if (settings != null && settings.maxExtent > settings.minExtent) {
      final t = ((settings.maxExtent - settings.currentExtent) /
              (settings.maxExtent - settings.minExtent))
          .clamp(0.0, 1.0);
      leftPad = ui.lerpDouble(expandedLeft, collapsedLeft, t)!;
    }
    return Padding(
      padding: EdgeInsets.only(left: leftPad),
      child: child,
    );
  }
}
