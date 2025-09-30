import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';
import '../config/runtime_config.dart';
import 'package:newgraduate/config/app_constants.dart';

class DebugHelper {
  /// تنظيف الـ SharedPreferences وحذف أي URL مخزن قديم
  static Future<void> clearStoredApiUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldUrl = prefs.getString(kApiBaseUrlKey);
      if (oldUrl != null) {
        print('🗑️ تم العثور على URL قديم مخزن: $oldUrl');
        await prefs.remove(kApiBaseUrlKey);
        print('✅ تم حذف URL القديم من SharedPreferences');
      } else {
        print('ℹ️ لا يوجد URL مخزن في SharedPreferences');
      }
    } catch (e) {
      print('❌ خطأ في حذف URL المخزن: $e');
    }
  }

  /// طباعة الـ URLs المستخدمة
  static Future<void> printCurrentUrls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUrl = prefs.getString(kApiBaseUrlKey);
      print('🔍 URL المخزن في SharedPreferences بعد التنظيف: $storedUrl');
      print(
          '🔍 AppConstants.baseUrl (المتغير العالمي): ${AppConstants.baseUrl}');

      if (storedUrl == null) {
        print('✅ لا يوجد URL مخزن - سيتم استخدام المتغير العالمي');
      } else {
        print('⚠️ يوجد URL مخزن - سيتم استخدامه بدلاً من المتغير العالمي!');
      }
    } catch (e) {
      print('❌ خطأ في طباعة URLs: $e');
    }
  }

  /// إجبار استخدام المتغير العالمي
  static Future<void> forceUseGlobalUrl() async {
    try {
      await clearStoredApiUrl();
      print(
          '🎯 تم إجبار التطبيق على استخدام المتغير العالمي: ${AppConstants.baseUrl}');
    } catch (e) {
      print('❌ خطأ في إجبار استخدام المتغير العالمي: $e');
    }
  }

  // Gesture helper to toggle under-development flag quickly
  static Widget withDevToggle(
      {required Widget child, required RuntimeConfig cfg}) {
    int taps = 0;
    DateTime last = DateTime.fromMillisecondsSinceEpoch(0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        final now = DateTime.now();
        if (now.difference(last) < const Duration(seconds: 1)) {
          taps++;
        } else {
          taps = 1;
        }
        last = now;
        if (taps >= 7) {
          taps = 0;
          cfg.setUnderDevelopment(!cfg.underDevelopment);
        }
      },
      child: child,
    );
  }
}
