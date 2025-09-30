import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:newgraduate/config/app_constants.dart';
import 'package:newgraduate/services/api_headers_manager.dart';

class EmailVerificationService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// إرسال بريد التحقق
  /// POST /api/email/verify/send
  static Future<Map<String, dynamic>> sendVerificationEmail({
    required String email,
  }) async {
    try {
      final headers = await ApiHeadersManager.instance.getAuthHeaders();

      final response = await http.post(
        Uri.parse('$_baseUrl/api/email/verify/send'),
        headers: headers,
        body: json.encode({
          'email': email,
        }),
      );

      print('📧 إرسال بريد التحقق - Status: ${response.statusCode}');
      print('📧 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'فشل في إرسال بريد التحقق');
      }
    } catch (e) {
      print('❌ خطأ في إرسال بريد التحقق: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  /// فحص حالة التحقق من البريد
  /// POST /api/email/verify/status
  static Future<Map<String, dynamic>> checkVerificationStatus({
    required String email,
  }) async {
    try {
      final headers = await ApiHeadersManager.instance.getAuthHeaders();

      final response = await http.post(
        Uri.parse('$_baseUrl/api/email/verify/status'),
        headers: headers,
        body: json.encode({
          'email': email,
        }),
      );

      print('✅ فحص حالة التحقق - Status: ${response.statusCode}');
      print('✅ Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'فشل في فحص حالة التحقق');
      }
    } catch (e) {
      print('❌ خطأ في فحص حالة التحقق: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  /// تحقق من البريد عبر الرابط
  /// GET /api/verify-email/{token}
  /// هذا عادة ما يتم استخدامه من خلال رابط في البريد الإلكتروني
  static Future<Map<String, dynamic>> verifyEmailWithToken({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/verify-email/$token'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('🔐 تحقق من الرابط - Status: ${response.statusCode}');
      print('🔐 Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'فشل في التحقق من البريد');
      }
    } catch (e) {
      print('❌ خطأ في التحقق من البريد: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  /// التحقق من حالة البريد المحفوظة محلياً
  static Future<bool> isEmailVerified() async {
    // يمكن إضافة منطق لحفظ حالة التحقق محلياً
    // أو استدعاء API للتحقق من الحالة الحالية
    // هنا نفترض أن نحتاج للتحقق من الخادم دائماً
    return false; // placeholder
  }

  /// حفظ حالة التحقق محلياً (اختياري)
  static Future<void> saveVerificationStatus(bool isVerified) async {
    // يمكن استخدام SharedPreferences لحفظ الحالة
    // await SharedPreferences.getInstance().setBool('email_verified', isVerified);
  }
}
