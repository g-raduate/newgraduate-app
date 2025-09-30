import 'package:http/http.dart' as http;
import 'package:newgraduate/config/app_constants.dart';
import 'package:newgraduate/services/api_headers_manager.dart';
import 'package:newgraduate/services/user_info_service.dart';
import 'dart:convert';

class StudentService {
  // جلب معلومات الطالب باستخدام student_id
  static Future<Map<String, dynamic>?> getStudentInfo(String studentId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/students/$studentId';
      print('📚 جاري جلب معلومات الطالب من: $url');

      final headers = await ApiHeadersManager.instance.getAuthHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      print('📊 استجابة معلومات الطالب: ${response.statusCode}');
      print('📊 محتوى استجابة الطالب:');
      print('=' * 50);
      print(response.body);
      print('=' * 50);

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        print('✅ نوع بيانات الطالب: ${responseData.runtimeType}');

        Map<String, dynamic> studentData;

        if (responseData is Map<String, dynamic>) {
          studentData = responseData;
        } else {
          throw Exception('تنسيق غير متوقع لبيانات الطالب');
        }

        // طباعة تفصيلية لمعلومات الطالب
        print('👤 معلومات الطالب:');
        print('  - المعرف: ${studentData['id']}');
        print('  - الاسم: ${studentData['name']}');
        print('  - الإيميل: ${studentData['email']}');
        print('  - الهاتف: ${studentData['phone']}');
        print('  - رابط الصورة: ${studentData['image_url']}');
        print('  - المعهد: ${studentData['institute_id']}');
        print('  - الحالة: ${studentData['status']}');
        print('  - تاريخ الإنشاء: ${studentData['created_at']}');

        // حفظ معلومات الطالب في UserInfoService للاستخدام في الحماية
        await _saveStudentInfoLocally(studentData);

        return studentData;
      } else {
        print('❌ فشل في جلب معلومات الطالب: ${response.statusCode}');
        print('❌ Response: ${response.body}');

        // فحص انتهاء الجلسة
        if (response.statusCode == 401 || response.statusCode == 403) {
          print('🔐 تم اكتشاف انتهاء الجلسة في معلومات الطالب');
        }

        throw Exception('فشل في جلب معلومات الطالب: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في جلب معلومات الطالب: $e');
      return null;
    }
  }

  // حفظ معلومات الطالب محلياً للاستخدام في نظام الحماية
  static Future<void> _saveStudentInfoLocally(
      Map<String, dynamic> studentData) async {
    try {
      await UserInfoService.saveUserInfo(
        phone: studentData['phone']?.toString(),
        // لا نحفظ userId هنا لتجنب استبدال user_id الحقيقي من تسجيل الدخول
        userName: studentData['name']?.toString(),
        studentId: studentData['id']?.toString(), // حفظ student_id فقط
        imageUrl: studentData['image_url']?.toString(),
      );

      print('✅ تم حفظ معلومات الطالب محلياً للحماية');
    } catch (e) {
      print('⚠️ خطأ في حفظ معلومات الطالب محلياً: $e');
    }
  }

  // تحديث معلومات الطالب
  static Future<bool> updateStudentInfo(
      String studentId, Map<String, dynamic> updates) async {
    try {
      final url = '${AppConstants.baseUrl}/api/students/$studentId';
      print('📝 جاري تحديث معلومات الطالب: $url');

      final headers = await ApiHeadersManager.instance.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(updates),
      );

      print('📊 استجابة تحديث الطالب: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ تم تحديث معلومات الطالب بنجاح');

        // إعادة جلب المعلومات المحدثة
        await getStudentInfo(studentId);

        return true;
      } else {
        print('❌ فشل في تحديث معلومات الطالب: ${response.statusCode}');
        print('❌ Response: ${response.body}');

        // فحص انتهاء الجلسة
        if (response.statusCode == 401 || response.statusCode == 403) {
          print('🔐 تم اكتشاف انتهاء الجلسة في تحديث الطالب');
        }

        throw Exception('فشل في تحديث معلومات الطالب: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في تحديث معلومات الطالب: $e');
      return false;
    }
  }

  // جلب معلومات الطالب المحفوظة محلياً
  static Future<Map<String, String?>> getLocalStudentInfo() async {
    return {
      'phone': await UserInfoService.getUserPhone(),
      'userId': await UserInfoService.getUserId(),
      'userName': await UserInfoService.getUserName(),
      'studentId': await UserInfoService.getStudentId(),
      'imageUrl': await UserInfoService.getUserImageUrl(),
    };
  }

  // التحقق من وجود معلومات الطالب محلياً
  static Future<bool> hasLocalStudentInfo() async {
    return await UserInfoService.hasUserInfo();
  }

  // حذف معلومات الطالب المحفوظة محلياً
  static Future<void> clearLocalStudentInfo() async {
    await UserInfoService.clearUserInfo();
    print('🗑️ تم حذف معلومات الطالب المحفوظة محلياً');
  }

  // استدعاء معلومات الطالب تلقائياً بعد تسجيل الدخول الناجح
  static Future<void> loadStudentInfoFromLogin(
      Map<String, dynamic> loginResponse) async {
    try {
      // البحث عن student_id في استجابة تسجيل الدخول
      String? studentId;
      // لا نحتاج userId هنا لأنه يتم حفظه في AuthController

      if (loginResponse.containsKey('student_id')) {
        studentId = loginResponse['student_id']?.toString();
      } else if (loginResponse.containsKey('user') &&
          loginResponse['user'] is Map &&
          loginResponse['user']['student_id'] != null) {
        studentId = loginResponse['user']['student_id']?.toString();
      }

      // البحث عن user_id في استجابة تسجيل الدخول
      // ملاحظة: user_id يتم حفظه بالفعل في AuthController، لذا لا نحتاج لإعادة حفظه هنا
      // if (loginResponse.containsKey('user_id')) {
      //   userId = loginResponse['user_id']?.toString();
      // } else if (loginResponse.containsKey('user') &&
      //     loginResponse['user'] is Map &&
      //     loginResponse['user']['id'] != null) {
      //   userId = loginResponse['user']['id']?.toString();
      // }

      print('🆔 معرفات مستخرجة من تسجيل الدخول:');
      print('  👤 Student ID: ${studentId ?? "لا يوجد"}');
      print('  ℹ️ User ID: تم حفظه بالفعل في AuthController');

      // حفظ المعرفات المتاحة
      if (studentId != null && studentId.isNotEmpty) {
        await UserInfoService.saveStudentId(studentId);
        print('✅ تم حفظ student_id: $studentId');
      }

      // لا نحفظ user_id هنا لتجنب الكتابة فوق القيمة الصحيحة من AuthController
      // if (userId != null && userId.isNotEmpty) {
      //   await UserInfoService.saveUserId(userId);
      //   print('✅ تم حفظ user_id: $userId');
      // }

      if (studentId != null && studentId.isNotEmpty) {
        print('🎓 جاري تحميل معلومات الطالب...');

        // جلب معلومات الطالب الكاملة
        final studentInfo = await getStudentInfo(studentId);

        if (studentInfo != null) {
          print('✅ تم تحميل معلومات الطالب بنجاح بعد تسجيل الدخول');
        } else {
          print('⚠️ فشل في تحميل معلومات الطالب');
        }
      } else {
        print('⚠️ لم يتم العثور على student_id في استجابة تسجيل الدخول');
        print('📄 محتوى استجابة تسجيل الدخول: $loginResponse');
      }
    } catch (e) {
      print('❌ خطأ في تحميل معلومات الطالب من تسجيل الدخول: $e');
    }
  }
}
