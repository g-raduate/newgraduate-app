import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:newgraduate/features/auth/state/auth_controller.dart';

class AuthService {
  /// معالجة الاستجابة والتحقق من حالة المصادقة
  static void handleAuthResponse(http.Response response, BuildContext context) {
    if (response.statusCode == 401) {
      try {
        print('🔍 معالجة خطأ 401 - فحص المحتوى...');
        final Map<String, dynamic> errorData = json.decode(response.body);
        print('📋 محتوى خطأ 401: $errorData');

        if (errorData['message'] == 'Unauthenticated.') {
          print('🚪 تسجيل خروج المستخدم بسبب انتهاء الصلاحية');

          // تسجيل خروج المستخدم
          final authController =
              Provider.of<AuthController>(context, listen: false);
          authController.logout();

          // إظهار رسالة للمستخدم
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('انتهت صلاحية تسجيل الدخول، يرجى تسجيل الدخول مرة أخرى'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );

          // الانتقال إلى شاشة تسجيل الدخول
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        }
      } catch (e) {
        // في حالة عدم القدرة على قراءة الاستجابة
        print('❌ خطأ في معالجة استجابة المصادقة: $e');
        print('📄 محتوى الاستجابة الخام: ${response.body}');
      }
    }
  }
}
