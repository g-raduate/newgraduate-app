import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Renders a full-screen black overlay when [listenable] reports true.
class RecordingShield extends StatelessWidget {
  final ValueListenable<bool> listenable;
  final bool showMessage;

  const RecordingShield({
    super.key,
    required this.listenable,
    this.showMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (context, captured, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: captured
              ? Container(
                  key: const ValueKey('shield-on'),
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: showMessage
                      ? Text(
                          'تم إيقاف العرض أثناء تسجيل الشاشة',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.white70),
                          textAlign: TextAlign.center,
                        )
                      : const SizedBox.shrink(),
                )
              : const SizedBox.shrink(key: ValueKey('shield-off')),
        );
      },
    );
  }
}
