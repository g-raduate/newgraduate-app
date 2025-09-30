import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Applies platform-level privacy protections (e.g., Android FLAG_SECURE).
class PrivacyGuard {
  static final MethodChannel _channel = const MethodChannel('privacy_guard');

  static Future<void> setSecureFlag(bool enabled) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setSecureFlag', {'enabled': enabled});
    } catch (e) {
      debugPrint('PrivacyGuard setSecureFlag error: $e');
    }
  }
}
