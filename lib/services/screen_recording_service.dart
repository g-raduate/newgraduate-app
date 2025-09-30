import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
// Requires: screen_capture_event
import 'package:screen_capture_event/screen_capture_event.dart';

/// Listens to OS screen recording/screenshot events and exposes a notifier.
/// On iOS, when screen recording starts, [isCaptured] becomes true.
/// Consumers can show a black overlay to protect content.
class ScreenRecordingService {
  final ValueNotifier<bool> isCaptured = ValueNotifier<bool>(false);

  ScreenCaptureEvent? _sce;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Only meaningful on iOS; keep listeners harmless elsewhere.
    if (!Platform.isIOS) return;

    try {
      _sce = ScreenCaptureEvent();

      // Recording listener (true when recording starts, false when it stops)
      _sce!.addScreenRecordListener((bool? isRecording) {
        isCaptured.value = isRecording == true;
      });

      // Optional: react to screenshots (flash-protect for a moment if desired)
      _sce!.addScreenShotListener((String? path) async {
        // Briefly enable shield to protect single-frame copies (200ms)
        isCaptured.value = true;
        await Future<void>.delayed(const Duration(milliseconds: 250));
        isCaptured.value = false;
      });

      // Initialize current state if supported by the plugin
      final bool current = await _sce!.isRecording();
      isCaptured.value = current;
    } catch (e) {
      // If plugin is not installed yet or any error occurs, fail silently.
      debugPrint('ScreenRecordingService init error: $e');
    }
  }

  Future<void> dispose() async {
    try {
      // Plugin provides internal listeners; dispose if available
      // ignore: avoid_dynamic_calls
      _sce?.dispose();
      _sce = null;
    } catch (_) {}
  }
}
