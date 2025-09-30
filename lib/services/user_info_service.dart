import 'package:shared_preferences/shared_preferences.dart';

class UserInfoService {
  static const String _phoneKey = 'user_phone';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _studentIdKey = 'student_id';
  static const String _userImageUrlKey = 'user_image_url';

  // حفظ رقم هاتف المستخدم
  static Future<void> saveUserPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, phone);
  }

  // الحصول على رقم هاتف المستخدم
  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  // حفظ معرف المستخدم
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  // الحصول على معرف المستخدم
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    print('🔍 UserInfoService.getUserId() استرجع: $userId');
    return userId;
  }

  // حفظ اسم المستخدم
  static Future<void> saveUserName(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, userName);
  }

  // الحصول على اسم المستخدم
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // حفظ معرف الطالب
  static Future<void> saveStudentId(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_studentIdKey, studentId);
  }

  // الحصول على معرف الطالب
  static Future<String?> getStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_studentIdKey);
  }

  // حفظ رابط صورة المستخدم
  static Future<void> saveUserImageUrl(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userImageUrlKey, imageUrl);
  }

  // الحصول على رابط صورة المستخدم
  static Future<String?> getUserImageUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userImageUrlKey);
  }

  // حفظ جميع بيانات المستخدم
  static Future<void> saveUserInfo({
    String? phone,
    String? userId,
    String? userName,
    String? studentId,
    String? imageUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (phone != null) await prefs.setString(_phoneKey, phone);
    if (userId != null) await prefs.setString(_userIdKey, userId);
    if (userName != null) await prefs.setString(_userNameKey, userName);
    if (studentId != null) await prefs.setString(_studentIdKey, studentId);
    if (imageUrl != null) await prefs.setString(_userImageUrlKey, imageUrl);
  }

  // حذف جميع بيانات المستخدم
  static Future<void> clearUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_phoneKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_studentIdKey);
    await prefs.remove(_userImageUrlKey);
  }

  // التحقق من وجود بيانات المستخدم
  static Future<bool> hasUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_phoneKey) ||
        prefs.containsKey(_userIdKey) ||
        prefs.containsKey(_userNameKey) ||
        prefs.containsKey(_studentIdKey);
  } // الحصول على معرف فريد للحماية (أولوية للهاتف ثم student_id ثم معرف المستخدم)

  static Future<String> getProtectionId() async {
    final phone = await getUserPhone();
    if (phone != null && phone.isNotEmpty) {
      return phone;
    }

    final studentId = await getStudentId();
    if (studentId != null && studentId.isNotEmpty) {
      return 'طالب-$studentId';
    }

    final userId = await getUserId();
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }

    final userName = await getUserName();
    if (userName != null && userName.isNotEmpty) {
      return userName;
    }

    // إذا لم توجد بيانات، استخدم معرف افتراضي
    return 'مستخدم-${DateTime.now().millisecondsSinceEpoch}';
  }
}
