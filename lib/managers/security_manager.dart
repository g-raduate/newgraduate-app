import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../config/app_constants.dart';

class SecurityManager {
  static bool _isInitialized = false;
  static BuildContext? _currentContext;

  /// تهيئة مدير الأمان
  static void initialize(BuildContext context) {
    if (_isInitialized) return;

    _currentContext = context;
    _isInitialized = true;

    // تحقق من وضع التطوير
    if (AppConstants.underDevelopmentOverride == true) {
      print(
          '🔧 SecurityManager: وضع التطوير مفعل - تم تعطيل جميع فحوصات الأمان');
      return;
    }

    print('🔒 SecurityManager: تم تهيئة نظام الأمان');

    // بدء الفحص الدوري
    _startSecurityMonitoring(context);
  }

  /// بدء مراقبة الأمان
  static void _startSecurityMonitoring(BuildContext context) {
    print('🔒 SecurityManager: بدء مراقبة الأمان');

    // فحص فوري (لأننا قد انتهينا من السبلاش سكرين)
    SecurityService.performSecurityChecks(context);

    // بدء المراقبة المستمرة بعد ثانيتين
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentContext != null && _currentContext!.mounted) {
        SecurityService.startPeriodicSecurityCheck(_currentContext!);
      }
    });
  }

  /// فحص أمان فوري
  static Future<void> performImmediateCheck() async {
    if (_currentContext == null || !_isInitialized) {
      print('⚠️ SecurityManager: لم يتم تهيئة مدير الأمان');
      return;
    }

    if (AppConstants.underDevelopmentOverride == true) {
      print('🔧 SecurityManager: وضع التطوير مفعل - تم تجاهل الفحص الفوري');
      return;
    }

    await SecurityService.performSecurityChecks(_currentContext!);
  }

  /// إيقاف مراقبة الأمان
  static void stop() {
    SecurityService.stopSecurityChecks();
    _isInitialized = false;
    _currentContext = null;
    print('🔓 SecurityManager: تم إيقاف نظام الأمان');
  }

  /// تحديث السياق (عند تغيير الشاشة)
  static void updateContext(BuildContext context) {
    _currentContext = context;
  }

  /// فحص حالة التهيئة
  static bool get isInitialized => _isInitialized;

  /// فحص وضع التطوير
  static bool get isInDevelopmentMode =>
      AppConstants.underDevelopmentOverride == true;
}
