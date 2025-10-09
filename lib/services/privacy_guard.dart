import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Applies platform-level privacy protections
/// Android: FLAG_SECURE to prevent screenshots and screen recording
/// iOS: Advanced protection including App Switcher, Screen Recording, and Screenshot detection
class PrivacyGuard {
  // قنوات الاتصال مع الكود الأصلي
  static final MethodChannel _androidChannel =
      const MethodChannel('privacy_guard');
  static final MethodChannel _iosChannel =
      const MethodChannel('ios_privacy_guard');

  // حالة الحماية
  static bool _isProtectionEnabled = false;

  /// تفعيل/تعطيل FLAG_SECURE على Android
  static Future<void> setSecureFlag(bool enabled) async {
    if (!Platform.isAndroid) return;
    try {
      await _androidChannel.invokeMethod('setSecureFlag', {'enabled': enabled});
      debugPrint('✅ Android FLAG_SECURE: ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('⚠️ PrivacyGuard setSecureFlag error: $e');
    }
  }

  /// تفعيل جميع حمايات iOS (App Switcher + Screen Recording + Screenshot)
  static Future<void> enableIOSProtection() async {
    if (!Platform.isIOS) return;
    try {
      await _iosChannel.invokeMethod('enableProtection');
      _isProtectionEnabled = true;
      debugPrint('✅ iOS Privacy Protection: enabled');
    } catch (e) {
      debugPrint('⚠️ PrivacyGuard enableIOSProtection error: $e');
    }
  }

  /// تعطيل جميع حمايات iOS
  static Future<void> disableIOSProtection() async {
    if (!Platform.isIOS) return;
    try {
      await _iosChannel.invokeMethod('disableProtection');
      _isProtectionEnabled = false;
      debugPrint('⚠️ iOS Privacy Protection: disabled');
    } catch (e) {
      debugPrint('⚠️ PrivacyGuard disableIOSProtection error: $e');
    }
  }

  /// تفعيل/تعطيل حماية iOS حسب الحالة
  static Future<void> setIOSProtection(bool enabled) async {
    if (!Platform.isIOS) return;
    try {
      await _iosChannel
          .invokeMethod('setProtectionEnabled', {'enabled': enabled});
      _isProtectionEnabled = enabled;
      debugPrint(
          '✅ iOS Privacy Protection: ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('⚠️ PrivacyGuard setIOSProtection error: $e');
    }
  }

  /// فحص إذا كانت الشاشة قيد التسجيل حالياً (iOS فقط)
  static Future<bool> isScreenBeingCaptured() async {
    if (!Platform.isIOS) return false;
    try {
      final result = await _iosChannel.invokeMethod('isScreenBeingCaptured');
      return result == true;
    } catch (e) {
      debugPrint('⚠️ PrivacyGuard isScreenBeingCaptured error: $e');
      return false;
    }
  }

  /// تفعيل الحماية على كلا المنصتين
  static Future<void> enableAllProtections() async {
    if (Platform.isAndroid) {
      await setSecureFlag(true);
    } else if (Platform.isIOS) {
      await enableIOSProtection();
    }
    debugPrint('✅ Privacy Protection enabled for ${Platform.operatingSystem}');
  }

  /// تعطيل الحماية على كلا المنصتين
  static Future<void> disableAllProtections() async {
    if (Platform.isAndroid) {
      await setSecureFlag(false);
    } else if (Platform.isIOS) {
      await disableIOSProtection();
    }
    debugPrint(
        '⚠️ Privacy Protection disabled for ${Platform.operatingSystem}');
  }

  /// الحصول على حالة الحماية الحالية
  static bool get isProtectionEnabled => _isProtectionEnabled;
}
