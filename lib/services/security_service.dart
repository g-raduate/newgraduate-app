import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../config/app_constants.dart';

class SecurityService {
  static bool _isScreenBlocked = false;
  static Timer? _developerModeTimer;
  static OverlayEntry? _blackScreenOverlay;
  static OverlayEntry? _developerModeOverlay;

  /// فحص الأمان العام
  static Future<void> performSecurityChecks(BuildContext context) async {
    // تحقق من وضع التطوير أولاً - إذا كان مفعلاً، تجاهل الحماية
    if (AppConstants.underDevelopmentOverride == true) {
      print('🔧 وضع التطوير مفعل - تجاهل فحوصات الأمان');
      return;
    }

    print('🔍 بدء فحص الأمان...');

    try {
      // فحص وضع المطور
      await _checkDeveloperMode(context);

      // فحص عرض الشاشة (Screen Mirroring)
      await _checkScreenMirroring(context);
    } catch (e) {
      print('⚠️ خطأ في فحص الأمان: $e');
    }
  }

  /// فحص وضع المطور
  static Future<void> _checkDeveloperMode(BuildContext context) async {
    print('🔍 فحص وضع المطور...');

    try {
      if (Platform.isAndroid) {
        print('📱 الجهاز Android - بدء الفحص');

        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        print('📋 معلومات الجهاز: ${androidInfo.model}');
        print('🔧 هل هو جهاز حقيقي: ${androidInfo.isPhysicalDevice}');

        // فحص إذا كان الجهاز في وضع التصحيح
        bool isDeveloperModeEnabled = false;

        try {
          print('🔌 محاولة الاتصال بـ Platform Channel...');
          // استخدام Platform Channel للفحص المتقدم
          const platform = MethodChannel('security_channel');
          isDeveloperModeEnabled =
              await platform.invokeMethod('isDeveloperModeEnabled') ?? false;
          print('✅ نجح الاتصال بـ Platform Channel');
          print('🔧 حالة وضع المطور من Platform: $isDeveloperModeEnabled');
        } catch (e) {
          print('❌ فشل فحص وضع المطور عبر Platform Channel: $e');
          // فحص بديل باستخدام معلومات النظام
          isDeveloperModeEnabled = !androidInfo.isPhysicalDevice;
          print('🔄 استخدام الفحص البديل: $isDeveloperModeEnabled');

          // فحص إضافي للمحاكيات
          if (!androidInfo.isPhysicalDevice ||
              androidInfo.fingerprint.contains('generic') ||
              androidInfo.model.contains('Emulator') ||
              androidInfo.manufacturer.contains('Genymotion')) {
            print('🤖 تم اكتشاف محاكي أو جهاز تطوير');
            isDeveloperModeEnabled = true;
          }
        }

        print('🎯 النتيجة النهائية - وضع المطور: $isDeveloperModeEnabled');

        if (isDeveloperModeEnabled) {
          print('⚠️ تم اكتشاف وضع المطور - عرض التحذير');
          _showDeveloperModeWarning(context);
        } else {
          print('✅ لم يتم اكتشاف وضع المطور');
        }
      } else {
        print('📱 الجهاز ليس Android - تجاهل فحص وضع المطور');
      }
    } catch (e) {
      print('❌ خطأ في فحص وضع المطور: $e');
    }
  }

  /// فحص عرض الشاشة
  static Future<void> _checkScreenMirroring(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('security_channel');
        final bool isScreenMirroring =
            await platform.invokeMethod('isScreenMirroring') ?? false;

        if (isScreenMirroring) {
          _showBlackScreen(context);
        } else {
          _removeBlackScreen();
        }
      }
    } catch (e) {
      print('خطأ في فحص عرض الشاشة: $e');
    }
  }

  /// عرض الشاشة السوداء
  static void _showBlackScreen(BuildContext context) {
    if (_isScreenBlocked) return;

    _isScreenBlocked = true;

    try {
      _blackScreenOverlay = OverlayEntry(
        builder: (context) => Material(
          color: Colors.black,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: const Center(
              child: Icon(
                Icons.security,
                color: Colors.red,
                size: 100,
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(_blackScreenOverlay!);
      print('🔒 تم تفعيل الشاشة السوداء بسبب اكتشاف عرض الشاشة');
    } catch (e) {
      print('❌ خطأ في عرض الشاشة السوداء: $e');
      _isScreenBlocked = false; // إعادة تعيين الحالة في حالة الفشل
    }
  }

  /// إزالة الشاشة السوداء
  static void _removeBlackScreen() {
    if (!_isScreenBlocked) return;

    _blackScreenOverlay?.remove();
    _blackScreenOverlay = null;
    _isScreenBlocked = false;
    print('✅ تم إزالة الشاشة السوداء');
  }

  /// عرض تحذير وضع المطور
  static void _showDeveloperModeWarning(BuildContext context) {
    print('🚨 بدء عرض تحذير وضع المطور');

    try {
      // تأخير قصير للتأكد من توفر Overlay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          _showDeveloperModeOverlay(context);
        }
      });
    } catch (e) {
      print('❌ خطأ في عرض تحذير وضع المطور: $e');
    }
  }

  /// عرض Overlay تحذير وضع المطور
  static void _showDeveloperModeOverlay(BuildContext context) {
    try {
      print('📋 محاولة إنشاء Overlay للتحذير...');

      _developerModeOverlay = OverlayEntry(
        builder: (context) => Material(
          color: Colors.black.withOpacity(0.8),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(40),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'تحذير أمني',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontFamily: 'NotoKufiArabic',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'تم اكتشاف تفعيل وضع المطور في جهازك.\nيرجى إيقاف وضع المطور للمتابعة.\n\nسيتم إغلاق التطبيق خلال 15 ثانية...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontFamily: 'NotoKufiArabic',
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'الإعدادات > خيارات المطور > إيقاف',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontFamily: 'NotoKufiArabic',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(_developerModeOverlay!);
      print('✅ تم إدراج Overlay للتحذير');

      // إغلاق التطبيق بعد 15 ثانية
      _developerModeTimer = Timer(const Duration(seconds: 15), () {
        _exitApp();
      });

      print('⚠️ تم عرض تحذير وضع المطور - سيتم إغلاق التطبيق خلال 15 ثانية');
    } catch (e) {
      print('❌ خطأ في عرض Overlay التحذير: $e');
      // في حالة فشل الـ Overlay، أظهر dialog بديل
      _showDeveloperModeDialog(context);
    }
  }

  /// عرض Dialog بديل لتحذير وضع المطور
  static void _showDeveloperModeDialog(BuildContext context) {
    print('🔄 استخدام Dialog بديل للتحذير');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 30,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'تحذير أمني',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontFamily: 'NotoKufiArabic',
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تم اكتشاف تفعيل وضع المطور في جهازك.\nيرجى إيقاف وضع المطور للمتابعة.\n\nسيتم إغلاق التطبيق خلال 15 ثانية...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontFamily: 'NotoKufiArabic',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'الإعدادات > خيارات المطور > إيقاف',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontFamily: 'NotoKufiArabic',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    // إغلاق التطبيق بعد 15 ثانية
    _developerModeTimer = Timer(const Duration(seconds: 15), () {
      _exitApp();
    });

    print('✅ تم عرض Dialog التحذير - سيتم إغلاق التطبيق خلال 15 ثانية');
  }

  /// إغلاق التطبيق
  static void _exitApp() {
    print('🚪 إغلاق التطبيق بسبب وضع المطور');
    SystemNavigator.pop(); // إغلاق التطبيق على Android
    exit(0); // إغلاق التطبيق بشكل كامل
  }

  /// تنظيف الموارد
  static void dispose() {
    _developerModeTimer?.cancel();
    _blackScreenOverlay?.remove();
    _developerModeOverlay?.remove();
    _developerModeTimer = null;
    _blackScreenOverlay = null;
    _developerModeOverlay = null;
    _isScreenBlocked = false;
  }

  /// فحص دوري للأمان (يمكن استدعاؤه كل فترة)
  static void startPeriodicSecurityCheck(BuildContext context) {
    // تحقق من وضع التطوير أولاً
    if (AppConstants.underDevelopmentOverride == true) {
      return;
    }

    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (context.mounted) {
        performSecurityChecks(context);
      } else {
        timer.cancel();
      }
    });
  }

  /// اختبار يدوي لعرض تحذير وضع المطور (للاختبار فقط)
  static void forceShowDeveloperWarning(BuildContext context) {
    print('🧪 فرض عرض تحذير وضع المطور للاختبار');
    _showDeveloperModeWarning(context);
  }

  /// اختبار يدوي لعرض الشاشة السوداء (للاختبار فقط)
  static void forceShowBlackScreen(BuildContext context) {
    print('🧪 فرض عرض الشاشة السوداء للاختبار');
    _showBlackScreen(context);
  }

  /// إيقاف جميع فحوصات الأمان
  static void stopSecurityChecks() {
    dispose();
  }
}
