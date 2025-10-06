import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:newgraduate/services/api_client.dart';
import 'dart:convert';
import 'package:newgraduate/utils/prefs_keys.dart';

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  static const _kAuthToken = kAuthToken;
  static const _kStudentId = kStudentId;

  Future<(String token, String? studentId)> login({
    required String email,
    required String password,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? locationSource, // gps|network|manual
  }) async {
    final deviceInfo = await _getDeviceInfo();

    print('🔐 AuthRepository.login() - البيانات المرسلة:');
    print('📧 Email: $email');
    print('🎭 Role: student');
    print('📱 Device Info: ${deviceInfo ?? 'N/A'}');
    print('📍 Location: ${latitude ?? 0.0}, ${longitude ?? 0.0}');

    final requestBody = {
      'email': email,
      'password': password,
      // device_info مطلوب دائماً حسب الباك إند كـ string ≤ 255 حرف
      'device_info': _deviceInfoToString(deviceInfo),
      // البيانات الجغرافية مطلوبة دائماً حسب الباك إند
      'latitude': latitude ?? 0.0,
      'longitude': longitude ?? 0.0,
      'accuracy': accuracy ?? 0.0,
      'location_source': locationSource ?? 'manual',
    };

    print('📡 إرسال طلب تسجيل الدخول إلى: /api/auth/login');
    print('📊 Request Body: ${requestBody.keys.toList()}');

    try {
      final res = await _api.postJson('/api/auth/login', requestBody);

      print('✅ استجابة تسجيل الدخول مستلمة!');
      print('📄 Response type: ${res.runtimeType}');
      print('🔑 Keys in response: ${res.keys.toList()}');

      final token = (res['token'] as String?) ?? '';
      final studentId = res['student_id'] as String?;

      if (token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        if (studentId != null) {
          await prefs.setString('student_id', studentId);
        }
        _api.setBearer(token);
        print('✅ تم حفظ التوكن بنجاح');
      } else {
        print('⚠️ لم يتم استلام توكن من الخادم');
      }

      return (token, studentId);
    } catch (e, stackTrace) {
      print('❌ خطأ في تسجيل الدخول: $e');
      print('📍 Stack trace: $stackTrace');

      if (e.toString().contains('302')) {
        print(
            '🔄 HTTP 302 Redirect detected - الخادم يعيد التوجيه بدلاً من معالجة طلب API');
      }

      rethrow;
    }
  }

  Future<Map<String, dynamic>> loginAndGetResponse({
    required String email,
    required String password,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? locationSource,
  }) async {
    final deviceInfo = await _getDeviceInfo();

    final res = await _api.postJson('/api/auth/login', {
      'email': email,
      'password': password,
      'device_info': _deviceInfoToString(deviceInfo),
      'latitude': latitude ?? 0.0,
      'longitude': longitude ?? 0.0,
      'accuracy': accuracy ?? 0.0,
      'location_source': locationSource ?? 'manual',
    });

    final token = (res['token'] as String?) ?? '';
    final studentId = res['student_id'] as String?;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAuthToken, token);
    if (studentId != null) await prefs.setString(_kStudentId, studentId);
    _api.setBearer(token);
    return res;
  }

  /// تسجيل طالب جديد
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required String instituteId,
    String role = 'student',
  }) async {
    final deviceInfo = await _getDeviceInfo();

    final requestBody = {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'phone': phone,
      'institute_id': instituteId,
      'role': role,
      // device_info كـ string ≤ 255 حرف
      'device_info': _deviceInfoToString(deviceInfo),
    };

    print('🔐 AuthRepository.register() - البيانات المرسلة:');
    print('📧 Email: $email');
    print('👤 Name: $name');
    print('📱 Phone: $phone');
    print('🏢 Institute ID: $instituteId');
    print('🎭 Role: $role');
    if (deviceInfo != null) print('📱 Device Info: $deviceInfo');

    try {
      final res = await _api.postJson('/api/auth/register', requestBody);

      // في حالة الحصول على token مباشرة بعد التسجيل
      if (res.containsKey('token')) {
        final token = (res['token'] as String?) ?? '';
        final studentId = res['student_id'] as String?;

        if (token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kAuthToken, token);
          if (studentId != null) await prefs.setString(_kStudentId, studentId);
          _api.setBearer(token);
        }
      }

      return res;
    } catch (e) {
      print('❌ AuthRepository.register() - خطأ: $e');

      // معالجة مهيكلة لأخطاء التحقق 422 القادمة من الخادم
      if (e is HttpException) {
        if (e.statusCode == 422) {
          try {
            final body = e.body;
            final decoded = jsonDecode(body);
            if (decoded is Map<String, dynamic> &&
                decoded['errors'] is Map<String, dynamic>) {
              final raw = decoded['errors'] as Map<String, dynamic>;
              // بناء رسالة مجمعة مفهومة
              final parts = <String>[];
              void addFirst(String key, String label) {
                final val = raw[key];
                if (val is List && val.isNotEmpty) {
                  parts.add(val.first.toString());
                } else if (val != null) {
                  parts.add(val.toString());
                }
              }

              addFirst('email', 'البريد');
              addFirst('phone', 'الهاتف');
              addFirst('password', 'كلمة السر');
              addFirst('password_confirmation', 'تأكيد كلمة السر');
              final joined = parts.isNotEmpty
                  ? parts.join('، ')
                  : (decoded['message']?.toString() ??
                      'البيانات المدخلة غير صحيحة');
              throw Exception('HttpException(422): $joined');
            }
          } catch (parseErr) {
            // سقط parsing؛ نكمل بالأسلوب النصي التقليدي
          }
        } else if (e.statusCode == 500) {
          print('⚠️ خطأ 500: قد يكون مشكلة في إعدادات البريد الإلكتروني');
          throw Exception(
              'HttpException(500): خطأ مؤقت في الخادم - قد تكون مشكلة في إرسال البريد');
        }
      }

      // تحسين رسائل الخطأ النصية كبديل
      final errorString = e.toString();
      if (errorString.contains('HttpException(422)')) {
        if (errorString.contains('email') && errorString.contains('phone')) {
          throw Exception(
              'HttpException(422): البريد الإلكتروني ورقم الهاتف مستخدمان من قبل');
        } else if (errorString.contains('email has already been taken')) {
          throw Exception(
              'HttpException(422): البريد الإلكتروني مستخدم من قبل');
        } else if (errorString.contains('phone has already been taken')) {
          throw Exception('HttpException(422): رقم الهاتف مستخدم من قبل');
        }
      } else if (errorString.contains('HttpException(500)')) {
        print('⚠️ خطأ 500: قد يكون مشكلة في إعدادات البريد الإلكتروني');
        throw Exception(
            'HttpException(500): خطأ مؤقت في الخادم - قد تكون مشكلة في إرسال البريد');
      }

      rethrow;
    }
  }

  /// فحص حالة تحقق البريد الإلكتروني
  Future<bool> checkEmailVerificationStatus() async {
    try {
      final res = await _api.postJson('/api/email/verify/status', {});
      return res['verified'] == true || res['is_verified'] == true;
    } catch (e) {
      print('خطأ في فحص حالة التحقق: $e');
      return false;
    }
  }

  /// إرسال بريد التحقق
  Future<void> sendEmailVerification(String email) async {
    await _api.postJson('/api/email/verify/send', {
      'email': email,
    });
  }

  /// إعادة إرسال بريد التحقق باستخدام الـ API الجديد
  Future<Map<String, dynamic>> resendEmailVerification(String email) async {
    final res = await _api.postJson('/api/email/resend', {
      'email': email,
    });
    return res;
  }

  Future<Map<String, dynamic>> getMe() async {
    return await _api.getJson('/api/auth/me');
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAuthToken);
  }

  Future<String?> getSavedStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kStudentId);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAuthToken);
    await prefs.remove(_kStudentId);
    _api.setBearer(null);
  }

  /// تحميل البيانات المحفوظة وتعيين Bearer token
  Future<void> hydrateBearerFromPrefs() async {
    final token = await getSavedToken();
    if (token?.isNotEmpty == true) {
      _api.setBearer(token);
    }
  }

  Future<void> loadSavedToken() async {
    final token = await getSavedToken();
    if (token?.isNotEmpty == true) {
      _api.setBearer(token);
    }
  }

  Future<Map<String, dynamic>?> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'model': info.model,
          'brand': info.brand,
          'version': info.version.release,
          'sdk': info.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': info.model,
          'name': info.name,
          'version': info.systemVersion,
        };
      }
    } catch (e) {
      print('Error getting device info: $e');
    }
    return null;
  }

  /// تحويل معلومات الجهاز إلى نص بحد أقصى 255 حرف
  String _deviceInfoToString(Map<String, dynamic>? deviceInfo) {
    if (deviceInfo == null) return 'Unknown Device';

    final buffer = StringBuffer();
    deviceInfo.forEach((key, value) {
      if (buffer.length > 0) buffer.write(', ');
      buffer.write('$key: $value');
    });

    String result = buffer.toString();
    // التأكد من أن النص لا يتجاوز 255 حرف
    if (result.length > 255) {
      result = result.substring(0, 252) + '...';
    }

    return result;
  }
}
