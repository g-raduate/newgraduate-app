import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Blocks long-press gestures while keeping taps/scroll working.
class GlobalLongPressBlocker extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const GlobalLongPressBlocker({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(),
          (LongPressGestureRecognizer instance) {
            // Claim the long-press gesture; do nothing, effectively blocking it.
            instance.onLongPress = () {};
            instance.onLongPressStart = (_) {};
            instance.onLongPressEnd = (_) {};
          },
        ),
      },
      child: child,
    );
  }
}
