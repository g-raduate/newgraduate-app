import 'package:flutter/material.dart';

/// An overlay that blocks touches at the very top and/or bottom of the screen.
/// Useful to prevent accidental taps on top AppBar actions or bottom bars
/// without changing existing screens.
class TouchBlockerOverlay extends StatelessWidget {
  final Widget child;

  /// Height in logical pixels to block from the top edge.
  final double topHeight;

  /// Height in logical pixels to block from the bottom edge.
  final double bottomHeight;

  /// Responsive height as a fraction of the screen height for the top area.
  /// If provided (0.0 - 1.0), it overrides [topHeight].
  final double? topFraction;

  /// Responsive height as a fraction of the screen height for the bottom area.
  /// If provided (0.0 - 1.0), it overrides [bottomHeight].
  final double? bottomFraction;

  /// Whether to enable blocking at the top and bottom.
  final bool blockTop;
  final bool blockBottom;

  /// If true, shows semi-transparent areas for quick visual debugging.
  final bool showDebugBars;

  /// Optional color to paint the blocked areas. If provided, it overrides
  /// [showDebugBars] and will always render using this color.
  final Color? overlayColor;

  const TouchBlockerOverlay({
    super.key,
    required this.child,
    this.topHeight = 120,
    this.bottomHeight = 120,
    this.topFraction,
    this.bottomFraction,
    this.blockTop = true,
    this.blockBottom = true,
    this.showDebugBars = false,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final effectiveTopH = (topFraction != null)
        ? (screenHeight * (topFraction!.clamp(0.0, 1.0)))
        : topHeight;
    final effectiveBottomH = (bottomFraction != null)
        ? (screenHeight * (bottomFraction!.clamp(0.0, 1.0)))
        : bottomHeight;
    // Expand to full size above the Navigator so it covers AppBars/BottomBars.
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (blockTop && effectiveTopH > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: effectiveTopH + media.viewPadding.top,
            child: AbsorbPointer(
              absorbing: true,
              child: IgnorePointer(
                ignoring: false,
                child: Container(
                  color: overlayColor ??
                      (showDebugBars
                          ? Colors.black.withOpacity(0.55)
                          : Colors.transparent),
                ),
              ),
            ),
          ),
        if (blockBottom && effectiveBottomH > 0)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: effectiveBottomH + media.viewPadding.bottom,
            child: AbsorbPointer(
              absorbing: true,
              child: IgnorePointer(
                ignoring: false,
                child: Container(
                  color: overlayColor ??
                      (showDebugBars
                          ? Colors.black.withOpacity(0.55)
                          : Colors.transparent),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
