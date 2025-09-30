import 'package:shared_preferences/shared_preferences.dart';
import 'package:newgraduate/config/app_constants.dart';

class TokenManager {
  static TokenManager? _instance;
  static SharedPreferences? _prefs;

  TokenManager._();

  static Future<TokenManager> getInstance() async {
    _instance ??= TokenManager._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  /// حفظ التوكن
  Future<bool> saveToken(String token) async {
    try {
      return await _prefs!.setString(AppConstants.tokenKey, token);
    } catch (e) {
      print('خطأ في حفظ التوكن: $e');
      return false;
    }
  }

  /// الحصول على التوكن
  Future<String?> getToken() async {
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      return _prefs?.getString(AppConstants.tokenKey);
    } catch (e) {
      print('خطأ في جلب التوكن: $e');
      return null;
    }
  }

  /// حفظ معرف الطالب
  Future<bool> saveStudentId(String studentId) async {
    try {
      return await _prefs!.setString(AppConstants.studentIdKey, studentId);
    } catch (e) {
      print('خطأ في حفظ معرف الطالب: $e');
      return false;
    }
  }

  /// حفظ معرف المعهد
  Future<bool> saveInstituteId(String instituteId) async {
    try {
      return await _prefs!.setString(AppConstants.instituteIdKey, instituteId);
    } catch (e) {
      print('خطأ في حفظ معرف المعهد: $e');
      return false;
    }
  }

  /// الحصول على معرف الطالب
  Future<String?> getStudentId() async {
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      return _prefs?.getString(AppConstants.studentIdKey);
    } catch (e) {
      print('خطأ في جلب معرف الطالب: $e');
      return null;
    }
  }

  /// الحصول على معرف المعهد
  Future<String?> getInstituteId() async {
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      return _prefs?.getString(AppConstants.instituteIdKey);
    } catch (e) {
      print('خطأ في جلب معرف المعهد: $e');
      return null;
    }
  }

  /// التحقق من وجود التوكن
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// حذف جميع البيانات المحفوظة (تسجيل الخروج)
  Future<bool> clearAll() async {
    try {
      await _prefs!.remove(AppConstants.tokenKey);
      await _prefs!.remove(AppConstants.studentIdKey);
      await _prefs!.remove(AppConstants.instituteIdKey);
      await _prefs!.remove(AppConstants.userDataKey);
      return true;
    } catch (e) {
      print('خطأ في حذف البيانات: $e');
      return false;
    }
  }

  /// الحصول على header المصادقة
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    print('🔑 التوكن المستخدم في Headers: ${token ?? "لا يوجد توكن"}');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
