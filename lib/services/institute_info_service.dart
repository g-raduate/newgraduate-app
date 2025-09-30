import 'package:shared_preferences/shared_preferences.dart';

class InstituteInfoService {
  static const String _instituteIdKey = 'institute_id';
  static const String _instituteNameKey = 'institute_name';
  static const String _institutePhoneKey = 'institute_phone';
  static const String _instituteEmailKey = 'institute_email';
  static const String _instituteImageUrlKey = 'institute_image_url';
  static const String _instituteCreatedAtKey = 'institute_created_at';

  // حفظ جميع بيانات المعهد
  static Future<void> saveInstituteInfo({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? imageUrl,
    String? createdAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (id != null) await prefs.setString(_instituteIdKey, id);
    if (name != null) await prefs.setString(_instituteNameKey, name);
    if (phone != null) await prefs.setString(_institutePhoneKey, phone);
    if (email != null) await prefs.setString(_instituteEmailKey, email);
    if (imageUrl != null)
      await prefs.setString(_instituteImageUrlKey, imageUrl);
    if (createdAt != null)
      await prefs.setString(_instituteCreatedAtKey, createdAt);
  }

  // الحصول على معرف المعهد
  static Future<String?> getInstituteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_instituteIdKey);
  }

  // الحصول على اسم المعهد
  static Future<String?> getInstituteName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_instituteNameKey);
  }

  // الحصول على رقم هاتف المعهد
  static Future<String?> getInstitutePhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_institutePhoneKey);
  }

  // الحصول على بريد المعهد الإلكتروني
  static Future<String?> getInstituteEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_instituteEmailKey);
  }

  // الحصول على رابط صورة المعهد
  static Future<String?> getInstituteImageUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_instituteImageUrlKey);
  }

  // الحصول على تاريخ إنشاء المعهد
  static Future<String?> getInstituteCreatedAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_instituteCreatedAtKey);
  }

  // الحصول على جميع بيانات المعهد
  static Future<Map<String, String?>> getAllInstituteInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_instituteIdKey),
      'name': prefs.getString(_instituteNameKey),
      'phone': prefs.getString(_institutePhoneKey),
      'email': prefs.getString(_instituteEmailKey),
      'imageUrl': prefs.getString(_instituteImageUrlKey),
      'createdAt': prefs.getString(_instituteCreatedAtKey),
    };
  }

  // التحقق من وجود بيانات المعهد
  static Future<bool> hasInstituteInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_instituteIdKey) ||
        prefs.containsKey(_instituteNameKey) ||
        prefs.containsKey(_institutePhoneKey);
  }

  // مسح جميع بيانات المعهد
  static Future<void> clearInstituteInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_instituteIdKey);
    await prefs.remove(_instituteNameKey);
    await prefs.remove(_institutePhoneKey);
    await prefs.remove(_instituteEmailKey);
    await prefs.remove(_instituteImageUrlKey);
    await prefs.remove(_instituteCreatedAtKey);
  }
}
