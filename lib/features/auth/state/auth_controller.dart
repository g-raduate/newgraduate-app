import 'package:flutter/foundation.dart';
import 'package:newgraduate/features/auth/data/auth_repository.dart';
import 'package:newgraduate/services/api_client.dart'
    show EmailNotVerifiedException;
import 'package:newgraduate/services/token_manager.dart';
import 'package:newgraduate/services/student_service.dart';
import 'package:newgraduate/services/cache_manager.dart';
import 'package:newgraduate/services/user_info_service.dart';
import 'package:newgraduate/services/email_verification_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repo);
  final AuthRepository _repo;

  bool _loading = false;
  String? _error;
  String? _token;
  String? _studentId;
  bool _isEmailVerified = false;
  String? _userEmail;
  TokenManager? _tokenManager;

  bool get loading => _loading;
  String? get error => _error;
  String? get token => _token;
  String? get studentId => _studentId;
  bool get isEmailVerified => _isEmailVerified;
  String? get userEmail => _userEmail;

  /// تهيئة TokenManager
  Future<void> _initTokenManager() async {
    _tokenManager ??= await TokenManager.getInstance();
  }

  /// تحميل البيانات المحفوظة عند بدء التطبيق
  Future<void> loadSavedData() async {
    await _initTokenManager();
    _token = await _tokenManager!.getToken();
    _studentId = await _tokenManager!.getStudentId();
    String? instituteId = await _tokenManager!.getInstituteId();

    print('🔄 تحميل البيانات المحفوظة:');
    print('  🔑 Token: ${_token != null ? "موجود" : "لا يوجد"}');
    print('  👤 Student ID: ${_studentId ?? "لا يوجد"}');
    print('  🏢 Institute ID: ${instituteId ?? "لا يوجد"}');

    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? locationSource,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _initTokenManager();

      // الحصول على response كامل للوصول لمعرف المعهد
      print('📡 بدء تسجيل الدخول...');
      final response = await _repo.loginAndGetResponse(
        email: email,
        password: password,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        locationSource: locationSource,
      );

      print('📋 Response كامل من تسجيل الدخول:');
      print('=' * 70);
      print('📄 Raw Response:');
      print(response);
      print('=' * 70);

      // طباعة كل عنصر في الـ response منفصلاً
      print('🔍 تحليل Response بالتفصيل:');
      print('📄 الاستجابة الكاملة لتسجيل الدخول:');
      print(
          '======================================================================');
      print(response.toString());
      print(
          '======================================================================');

      response.forEach((key, value) {
        print('  $key: $value (Type: ${value.runtimeType})');
      });

      final t = (response['token'] as String?) ?? '';
      final s = response['student_id'] as String?;

      // استخراج institute_id و user_id من user object
      final user = response['user'] as Map<String, dynamic>?;

      print('👤 ==================== USER OBJECT DETAILS ====================');
      print('🔍 User Object الكامل: $user');
      print('🔍 User Object Type: ${user.runtimeType}');

      if (user != null) {
        print('📋 محتويات User Object بالتفصيل:');
        user.forEach((key, value) {
          print('  📝 $key: $value (Type: ${value.runtimeType})');
        });
        print('🆔 user.id المستخرج: ${user['id']}');
        print('🏢 user.institute_id المستخرج: ${user['institute_id']}');
        print('📧 user.email: ${user['email'] ?? "غير موجود"}');
        print('👤 user.name: ${user['name'] ?? "غير موجود"}');
      } else {
        print('❌ User Object غير موجود في الاستجابة!');
      }
      print(
          '========================== END USER DETAILS ==========================');

      final instituteId = user?['institute_id'] as String?;
      final userId = user?['id'] as String?;

      // استخراج حالة تحقق البريد - عدة احتمالات حسب API (Laravel: email_verified_at)
      bool emailVerified = true;
      try {
        if (user != null) {
          if (user.containsKey('email_verified_at')) {
            emailVerified = (user['email_verified_at'] != null &&
                user['email_verified_at'].toString().isNotEmpty);
          } else if (user.containsKey('email_verified')) {
            emailVerified = (user['email_verified'] == true ||
                user['email_verified'] == '1' ||
                user['email_verified'] == 1);
          } else if (user.containsKey('verified')) {
            emailVerified = (user['verified'] == true ||
                user['verified'] == '1' ||
                user['verified'] == 1);
          }
        }
      } catch (_) {}

      _isEmailVerified = emailVerified;
      _userEmail = user?['email'] as String?;

      // التحقق من احتمالية وجود user_id في مكان آخر
      final alternativeUserId = response['user_id'] as String?;
      print('🔍 البحث عن user_id في أماكن أخرى:');
      print('  - user.id: $userId');
      print('  - response.user_id: $alternativeUserId');

      print('🔍 استخراج البيانات من Response:');
      print('🔑 Token: ${t.isNotEmpty ? "${t.substring(0, 20)}..." : "فارغ"}');
      print('👤 Student ID: ${s ?? "لا يوجد"}');
      print('👤 User Object: $user');
      print(
          '� Alternative User ID (من response.user_id): ${alternativeUserId ?? "لا يوجد"}');
      print('�🏢 Institute ID (من user): ${instituteId ?? "لا يوجد"}');
      print('📊 Token Length: ${t.length}');

      // اختيار المعرف الصحيح للمستخدم
      String? finalUserId = userId ?? alternativeUserId;
      print('🎯 User ID النهائي المُختار: ${finalUserId ?? "لا يوجد"}');

      if (finalUserId != null && finalUserId == s) {
        print(
            '⚠️ تحذير: user_id مطابق لـ student_id! قد تكون هناك مشكلة في بنية API');
        print('🔍 سنحاول البحث عن معرف آخر في الاستجابة...');

        // البحث عن معرفات أخرى محتملة
        response.forEach((key, value) {
          if (key.toLowerCase().contains('id') && key != 'student_id') {
            print('  🔍 معرف آخر محتمل: $key = $value');
          }
        });
      }
      print(
          '🎯 سيناريو الطالب: ${s == null ? "طالب بدون معهد محدد" : "طالب لديه معهد"}');

      _token = t;
      _studentId = s;

      print('💾 بدء حفظ البيانات في التخزين المحلي...');
      // حفظ البيانات في التخزين المحلي
      await _tokenManager!.saveToken(t);
      print('✅ تم حفظ التوكن');

      if (s != null) {
        await _tokenManager!.saveStudentId(s);
        print('✅ تم حفظ معرف الطالب: $s');
      } else {
        print('ℹ️ لا يوجد معرف طالب - سيتم عرض جميع المعاهد');
      }

      if (instituteId != null) {
        await _tokenManager!.saveInstituteId(instituteId);
        print('✅ تم حفظ معرف المعهد: $instituteId');
      } else {
        print('ℹ️ لا يوجد معرف معهد في الاستجابة');
      }

      // لا نحتاج لحفظ user_id بعد الآن - سيتم الحصول عليه من api/auth/me عند الحذف
      print(
          '💡 تم تخطي حفظ user_id - سيتم الحصول عليه من api/auth/me عند الحاجة');

      // استدعاء معلومات الطالب بعد تسجيل الدخول الناجح
      print('📚 بدء تحميل معلومات الطالب...');
      await StudentService.loadStudentInfoFromLogin(response);

      _loading = false;
      notifyListeners();
      print('🎉 تم إكمال عملية تسجيل الدخول وحفظ البيانات بنجاح');
      print('📱 التطبيق جاهز للاستخدام');
      return true;
    } on EmailNotVerifiedException catch (e) {
      // حالة خاصة: الحساب غير مؤكد
      _loading = false;
      _error = e.message;
      _isEmailVerified = false;
      // حفظ معلومات المساعدة لإعادة الإرسال
      _userEmail = e.email ?? _userEmail;
      notifyListeners();
      return false;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// تسجيل طالب جديد
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String instituteId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      print('📝 بدء عملية تسجيل طالب جديد...');
      print('  📧 البريد الإلكتروني: $email');
      print('  👤 الاسم: $name');
      print('  📱 الهاتف: $phone');
      print('  🏢 معرف المعهد: $instituteId');

      final response = await _repo.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        instituteId: instituteId,
      );

      print('✅ نجح التسجيل: $response');

      // حفظ بيانات المستخدم
      _userEmail = email;

      // في حالة الحصول على token مباشرة (auto-login بعد التسجيل)
      if (response.containsKey('token')) {
        final token = response['token'] as String?;
        final studentId = response['student_id'] as String?;

        if (token != null && token.isNotEmpty) {
          _token = token;
          _studentId = studentId;

          await _initTokenManager();
          await _tokenManager!.saveToken(token);
          if (studentId != null) {
            await _tokenManager!.saveStudentId(studentId);
          }

          // جلب معلومات الطالب من استجابة التسجيل
          await StudentService.loadStudentInfoFromLogin(response);
        }
      }

      // إرسال بريد التحقق تلقائياً
      try {
        await EmailVerificationService.sendVerificationEmail(email: email);
        print('📧 تم إرسال بريد التحقق بنجاح');
      } catch (e) {
        print('⚠️ خطأ في إرسال بريد التحقق: $e');
        // لا نتوقف هنا، التسجيل نجح
      }

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ خطأ في التسجيل: $e');
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// فحص حالة تحقق البريد الإلكتروني
  Future<bool> checkEmailVerificationStatus() async {
    try {
      if (_token == null || _token!.isEmpty) {
        print('⚠️ لا يوجد token للتحقق من حالة البريد');
        return false;
      }

      final isVerified = await _repo.checkEmailVerificationStatus();
      _isEmailVerified = isVerified;
      notifyListeners();

      print('📧 حالة التحقق من البريد: ${isVerified ? "مؤكد" : "غير مؤكد"}');
      return isVerified;
    } catch (e) {
      print('❌ خطأ في فحص حالة التحقق: $e');
      return false;
    }
  }

  /// إرسال بريد التحقق
  Future<bool> sendEmailVerification() async {
    try {
      if (_userEmail == null || _userEmail!.isEmpty) {
        print('⚠️ لا يوجد بريد إلكتروني للمستخدم');
        return false;
      }

      await EmailVerificationService.sendVerificationEmail(email: _userEmail!);
      print('📧 تم إرسال بريد التحقق بنجاح');
      return true;
    } catch (e) {
      print('❌ خطأ في إرسال بريد التحقق: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// تحديث حالة تحقق البريد (للاستدعاء من خارج الكلاس)
  void setEmailVerified(bool isVerified) {
    _isEmailVerified = isVerified;
    notifyListeners();
  }

  /// تسجيل الخروج وحذف بيانات المستخدم
  Future<void> logout() async {
    print('🔄 بدء عملية تسجيل الخروج من AuthController...');

    await _initTokenManager();

    // حذف البيانات من TokenManager
    print('🗑️ حذف tokens والبيانات من TokenManager...');
    await _tokenManager!.clearAll();

    // حذف معلومات الطالب المحفوظة محلياً
    print('🗑️ حذف معلومات الطالب المحفوظة محلياً...');
    await StudentService.clearLocalStudentInfo();

    // حذف جميع بيانات المستخدم من UserInfoService
    print('🗑️ حذف بيانات المستخدم من UserInfoService...');
    await UserInfoService.clearUserInfo();

    // حذف جميع البيانات من الكاش
    print('🗑️ حذف جميع بيانات الكاش...');
    await CacheManager.instance.clearAllCache();

    _token = null;
    _studentId = null;
    _error = null;
    _isEmailVerified = false;
    _userEmail = null;

    notifyListeners();
    print('✅ تم إكمال تسجيل الخروج وحذف جميع البيانات من AuthController');
  }
}
