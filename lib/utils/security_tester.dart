// ملف اختبار لنظام الأمان - يمكن حذفه لاحقاً
import '../managers/security_manager.dart';
import '../services/security_service.dart';
import 'package:flutter/material.dart';

class SecurityTester {
  /// اختبار سريع لنظام الأمان
  static Future<void> testSecuritySystem() async {
    try {
      print('=== اختبار نظام الأمان ===');

      print('حالة التهيئة: ${SecurityManager.isInitialized}');
      print('وضع التطوير: ${SecurityManager.isInDevelopmentMode}');

      // اختبار فحص فوري (يحتاج context)
      // await SecurityManager.performImmediateCheck();

      print('=== انتهى اختبار النظام ===');
    } catch (e) {
      print('خطأ في اختبار النظام: $e');
    }
  }

  /// اختبار إيقاف النظام
  static void testStopSecurity() {
    SecurityManager.stop();
    print('تم إيقاف نظام الأمان للاختبار');
  }

  /// اختبار بدء النظام
  static void testStartSecurity(BuildContext context) {
    SecurityManager.initialize(context);
    print('تم بدء نظام الأمان للاختبار');
  }

  /// فرض عرض تحذير وضع المطور (للاختبار)
  static void forceShowDeveloperWarning(BuildContext context) {
    print('🧪 اختبار عرض تحذير وضع المطور');
    SecurityService.forceShowDeveloperWarning(context);
  }

  /// فرض عرض الشاشة السوداء (للاختبار)
  static void forceShowBlackScreen(BuildContext context) {
    print('🧪 اختبار عرض الشاشة السوداء');
    SecurityService.forceShowBlackScreen(context);
  }

  /// اختبار فحص وضع المطور مباشرة
  static Future<void> testDeveloperModeCheck(BuildContext context) async {
    print('🧪 اختبار فحص وضع المطور مباشرة');
    await SecurityService.performSecurityChecks(context);
  }
}
