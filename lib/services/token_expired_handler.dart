import 'package:flutter/material.dart';
import 'package:newgraduate/services/token_manager.dart';
import 'package:newgraduate/services/user_info_service.dart';
import 'dart:async';

class TokenExpiredHandler {
  static TokenExpiredHandler? _instance;
  TokenExpiredHandler._();

  // Guard to prevent duplicate logout calls
  static bool _logoutInProgress = false;

  static TokenExpiredHandler get instance {
    _instance ??= TokenExpiredHandler._();
    return _instance!;
  }

  /// التحقق من انتهاء صلاحية التوكن وإدارة تسجيل الخروج
  static Future<bool> handleTokenExpiration(
    BuildContext context, {
    int statusCode = 401,
    String? errorMessage,
  }) async {
    // التحقق من حالات انتهاء التوكن
    if (statusCode == 401 ||
        statusCode == 403 ||
        errorMessage?.contains('Unauthorized') == true ||
        errorMessage?.contains('Token expired') == true ||
        errorMessage?.contains('Invalid token') == true) {
      print('🔐 تم اكتشاف انتهاء صلاحية التوكن: Status $statusCode');

      // التحقق من وجود التوكن
      final tokenManager = await TokenManager.getInstance();
      final token = await tokenManager.getToken();

      if (token == null || token.isEmpty) {
        print('❌ لا يوجد توكن محفوظ - المستخدم غير مسجل دخول');
      }

      await _showTokenExpiredDialog(context);
      return true; // يشير إلى أنه تم التعامل مع انتهاء التوكن
    }

    return false; // لم ينته التوكن
  }

  /// عرض رسالة انتهاء التوكن مع العد التنازلي
  static Future<void> _showTokenExpiredDialog(BuildContext context) async {
    int countdown = 5;
    late Timer timer;

    // إنشاء StreamController للعد التنازلي
    final StreamController<int> countdownController = StreamController<int>();

    // سنلتقط سياق الحوار الداخلي ليكون آمناً للاستخدام لاحقاً من داخل التايمر
    BuildContext? dialogContext;

    // بدء العد التنازلي
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      countdown--;
      try {
        if (countdown >= 0) {
          // إرسال القيمة الحالية للمستمعين
          countdownController.add(countdown);
        }

        if (countdown <= 0) {
          timer.cancel();

          // إغلاق الـ Stream بطريقة آمنة
          try {
            if (!countdownController.isClosed) countdownController.close();
          } catch (_) {}

          // اغلاق الحوار باستخدام سياق الحوار الداخلي إذا كان متاحاً
          final popContext = dialogContext ?? context;
          try {
            if (Navigator.canPop(popContext)) {
              Navigator.of(popContext).pop(); // إغلاق الحوار
            }
          } catch (_) {}

          // تنفيذ تسجيل الخروج مرة واحدة فقط
          if (!_logoutInProgress) {
            _logoutInProgress = true;
            try {
              await _performLogout(popContext);
            } catch (e) {
              print('❌ خطأ أثناء محاولة تسجيل الخروج من التايمر: $e');
            }
          }
        }
      } catch (e) {
        print('❌ خطأ في عداد انتهاء الجلسة: $e');
      }
    });

    // عرض الحوار
    return showDialog(
      context: context,
      barrierDismissible: false, // منع إغلاق الحوار بالضغط خارجه
      builder: (BuildContext innerContext) {
        // احفظ سياق الحوار الداخلي لاستخدامه لاحقًا
        dialogContext = innerContext;

        return WillPopScope(
          onWillPop: () async => false, // منع إغلاق الحوار بالضغط على زر الرجوع
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.timer_off_outlined,
                  color: Colors.orange[700],
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'انتهت جلسة العمل',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 64,
                  color: Colors.orange[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'لقد انتهت صلاحية جلسة العمل الخاصة بك لأسباب أمنية',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'سيتم تسجيل خروجك تلقائياً خلال:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<int>(
                        stream: countdownController.stream,
                        initialData: 5,
                        builder: (cntext, snapshot) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${snapshot.data ?? 0}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ثانية',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'يرجى إعادة تسجيل الدخول للمتابعة 😊',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // عند الضغط زر الخروج الآن، قم بإيقاف العداد ومحاولة إغلاق الحوار وتنفيذ الخروج بطريقة آمنة
                  try {
                    timer.cancel();
                  } catch (_) {}

                  try {
                    if (!countdownController.isClosed)
                      countdownController.close();
                  } catch (_) {}

                  final popContext = dialogContext ?? context;
                  try {
                    if (Navigator.canPop(popContext))
                      Navigator.of(popContext).pop();
                  } catch (_) {}

                  if (!_logoutInProgress) {
                    _logoutInProgress = true;
                    try {
                      await _performLogout(popContext);
                    } catch (e) {
                      print('❌ خطأ أثناء تسجيل الخروج عند الضغط: $e');
                    }
                  }
                },
                child: Text(
                  'تسجيل خروج الآن',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// تنفيذ عملية تسجيل الخروج
  static Future<void> _performLogout(BuildContext context) async {
    try {
      print('🔓 بدء عملية تسجيل الخروج التلقائي...');

      // مسح جميع البيانات المحفوظة
      final tokenManager = await TokenManager.getInstance();
      await tokenManager.clearAll();
      await UserInfoService.clearUserInfo();

      print('✅ تم مسح جميع البيانات بنجاح');

      // إظهار رسالة وداع لطيفة
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.waving_hand,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'تم تسجيل خروجك بنجاح. نراك قريباً! 👋',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // الانتقال إلى شاشة تسجيل الدخول
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      print('❌ خطأ في تسجيل الخروج: $e');

      // في حالة الخطأ، الانتقال المباشر لشاشة تسجيل الدخول
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  /// طريقة مساعدة للتحقق من رسائل الخطأ الشائعة
  static bool isTokenError(String? errorMessage, int? statusCode) {
    if (statusCode == 401 || statusCode == 403) return true;

    if (errorMessage == null) return false;

    final lowerMessage = errorMessage.toLowerCase();
    return lowerMessage.contains('unauthorized') ||
        lowerMessage.contains('token expired') ||
        lowerMessage.contains('invalid token') ||
        lowerMessage.contains('authentication failed') ||
        lowerMessage.contains('access denied');
  }
}
