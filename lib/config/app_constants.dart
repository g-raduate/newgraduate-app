class AppConstants {
  // Base URL للـ API
  //static const String baseUrl = 'http://192.168.0.167:8000';
  static const String baseUrl = 'https://graduate.invnty.online';
  static const String apiUrl = '$baseUrl/api';

  // وضع التطوير (لإيقاف الحماية مؤقتاً أثناء البرمجة)
  // إذا تركتها null سيتم استخدام القيمة المخزنة من RuntimeConfig (أزرار/إعدادات التطبيق).
  // إذا وضعتها true/false سيتم تجاهل المخزن وتشغيل/إيقاف الحماية يدوياً.
  // مثال:
  //   static const bool? underDevelopmentOverride = true;  // إيقاف الحماية
  //   static const bool? underDevelopmentOverride = false; // تشغيل الحماية
  //   static const bool? underDevelopmentOverride = null;  // اتبع الإعداد المخزن
  static const bool? underDevelopmentOverride = true;

  // مفاتيح التخزين المحلي
  static const String tokenKey = 'auth_token';
  static const String studentIdKey = 'student_id';
  static const String instituteIdKey = 'institute_id';
  static const String userDataKey = 'user_data';

  // إعدادات الشبكة
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);

  // إعدادات التطبيق
  static const String appName = 'تطبيق خريج';
  static const String appVersion = '1.0.0';
}
