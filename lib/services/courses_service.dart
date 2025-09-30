import 'package:http/http.dart' as http;
import 'package:newgraduate/config/app_constants.dart';
import 'package:newgraduate/services/api_headers_manager.dart';
import 'package:newgraduate/services/cache_manager.dart';
import 'package:newgraduate/services/user_info_service.dart';
import 'dart:convert';

/// خدمة الدورات مع دعم الكاش المتقدم
class CoursesService {
  /// جلب دورات الطالب المسجل فيها
  static Future<List<dynamic>?> getStudentCourses({
    String? studentId,
    bool forceRefresh = false,
  }) async {
    try {
      // الحصول على student_id إذا لم يتم تمريره
      studentId ??= await UserInfoService.getStudentId();

      if (studentId == null || studentId.isEmpty) {
        print('❌ لا يوجد student_id متاح');
        return null;
      }

      final cacheKey = 'student_courses_$studentId';

      // إذا لم يكن مطلوباً تحديث إجباري، تحقق من الكاش
      if (!forceRefresh) {
        print('🔍 البحث عن دورات الطالب في الكاش: $cacheKey');
        List<dynamic>? cachedCourses = await CacheManager.instance
            .getCache<List<dynamic>>(cacheKey, type: CacheType.courses);

        if (cachedCourses != null) {
          print('✅ تم تحميل ${cachedCourses.length} دورة من الكاش للطالب');
          return cachedCourses;
        }
      }

      // جلب البيانات من API
      final url =
          '${AppConstants.baseUrl}/api/courses/assigned?student_id=$studentId';

      print('📚 جاري تحميل دورات الطالب من API: $url');
      print('👤 Student ID: $studentId');

      final headers = await ApiHeadersManager.instance.getAuthHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      print('📊 استجابة دورات الطالب: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        List<dynamic> courses;
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          courses = responseData['data'] ?? [];
          print('✅ تم تحميل ${courses.length} دورة للطالب من API');

          // حفظ في الكاش
          await CacheManager.instance
              .setCache(cacheKey, courses, type: CacheType.courses);
          print('💾 تم حفظ دورات الطالب في الكاش');

          return courses;
        } else {
          print('❌ تنسيق الاستجابة غير متوقع لدورات الطالب');
          return null;
        }
      } else {
        print('❌ فشل في تحميل دورات الطالب: ${response.statusCode}');
        print('❌ Response: ${response.body}');

        // فحص انتهاء الجلسة للأكواد الخاصة بالتوكن
        if (response.statusCode == 401 || response.statusCode == 403) {
          print('🔐 تم اكتشاف انتهاء الجلسة في دورات الطالب');
          return null; // الواجهة ستتولى عرض الرسالة وتسجيل الخروج
        }

        return null;
      }
    } catch (e) {
      print('❌ خطأ في تحميل دورات الطالب: $e');
      return null;
    }
  }

  /// جلب قائمة الدورات مع دعم الكاش
  static Future<List<dynamic>?> getCourses({
    String? departmentId,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey =
          departmentId != null ? 'department_$departmentId' : 'all_courses';

      // إذا لم يكن مطلوباً تحديث إجباري، تحقق من الكاش
      if (!forceRefresh) {
        print('🔍 البحث عن دورات في الكاش: $cacheKey');
        List<dynamic>? cachedCourses = await CacheManager.instance
            .getCache<List<dynamic>>(cacheKey, type: CacheType.courses);

        if (cachedCourses != null) {
          print('✅ تم تحميل ${cachedCourses.length} دورة من الكاش');
          return cachedCourses;
        }
      }

      // جلب البيانات من API
      final url = departmentId != null
          ? '${AppConstants.baseUrl}/api/departments/$departmentId/courses'
          : '${AppConstants.baseUrl}/api/courses';

      print('📚 جاري تحميل الدورات من API: $url');

      final headers = await ApiHeadersManager.instance.getAuthHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      print('📊 استجابة الدورات: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        List<dynamic> courses;
        if (responseData is List) {
          courses = responseData;
        } else if (responseData is Map<String, dynamic>) {
          courses = responseData['data'] ?? [];
        } else {
          throw Exception('تنسيق غير متوقع للبيانات');
        }

        // فلترة الدورات لإزالة المجانية (السعر = 0)
        final originalCount = courses.length;
        courses = courses.where((course) {
          final price = course['price'];
          final isFree = course['is_free'];

          // إذا كان is_free موجود، استخدمه
          if (isFree != null) {
            return !isFree; // عرض الدورات غير المجانية فقط
          }

          // إذا لم يكن is_free موجود، تحقق من السعر
          if (price != null) {
            // تحويل السعر إلى رقم للمقارنة
            double coursePrice = 0.0;
            if (price is String) {
              coursePrice = double.tryParse(price) ?? 0.0;
            } else if (price is num) {
              coursePrice = price.toDouble();
            }

            return coursePrice > 0; // عرض الدورات المدفوعة فقط
          }

          // في حالة عدم وجود معلومات السعر أو is_free، عرض الدورة
          return true;
        }).toList();

        print(
            '🔍 تم فلترة ${originalCount - courses.length} دورة مجانية، متبقي ${courses.length} دورة مدفوعة');

        // حفظ البيانات في الكاش
        await CacheManager.instance.setCourses(cacheKey, courses);
        print('💾 تم حفظ ${courses.length} دورة في الكاش');

        return courses;
      } else {
        print('❌ فشل في تحميل الدورات: ${response.statusCode}');
        print('❌ Response: ${response.body}');

        // فحص انتهاء الجلسة
        if (response.statusCode == 401 || response.statusCode == 403) {
          print('🔐 تم اكتشاف انتهاء الجلسة في تحميل الدورات');
        }

        throw Exception('فشل في تحميل الدورات: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في تحميل الدورات: $e');
      return null;
    }
  }

  /// البحث في الدورات مع دعم الكاش
  static Future<List<dynamic>?> searchCourses(String query) async {
    try {
      final cacheKey = 'search_${query.toLowerCase()}';

      // البحث في الكاش أولاً
      List<dynamic>? cachedResults =
          await CacheManager.instance.getCourses(cacheKey);
      if (cachedResults != null) {
        print('✅ تم العثور على نتائج البحث في الكاش: ${cachedResults.length}');
        return cachedResults;
      }

      // البحث عبر API
      final url =
          '${AppConstants.baseUrl}/api/courses/search?q=${Uri.encodeComponent(query)}';
      print('🔍 البحث في الدورات: $url');

      final headers = await ApiHeadersManager.instance.getAuthHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        List<dynamic> results;
        if (responseData is List) {
          results = responseData;
        } else if (responseData is Map<String, dynamic>) {
          results = responseData['data'] ?? [];
        } else {
          throw Exception('تنسيق غير متوقع للبيانات');
        }

        // حفظ نتائج البحث في الكاش لفترة قصيرة
        await CacheManager.instance.setCache(
          cacheKey,
          results,
          type: CacheType.courses,
          expirySeconds: 300, // 5 دقائق فقط للبحث
        );

        print('💾 تم حفظ ${results.length} نتيجة بحث في الكاش');
        return results;
      } else {
        print('❌ فشل في البحث: ${response.statusCode}');
        print('❌ Response: ${response.body}');

        // فحص انتهاء الجلسة
        if (response.statusCode == 401 || response.statusCode == 403) {
          print('🔐 تم اكتشاف انتهاء الجلسة في البحث');
        }

        throw Exception('فشل في البحث: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في البحث: $e');
      return null;
    }
  }

  /// جلب تفاصيل دورة واحدة مع الكاش
  static Future<Map<String, dynamic>?> getCourseDetails(String courseId) async {
    try {
      final cacheKey = 'course_details_$courseId';

      // البحث في الكاش
      Map<String, dynamic>? cachedCourse = await CacheManager.instance
          .getCache<Map<String, dynamic>>(cacheKey, type: CacheType.courses);

      if (cachedCourse != null) {
        print('✅ تم تحميل تفاصيل الدورة من الكاش');
        return cachedCourse;
      }

      // جلب من API
      final url = '${AppConstants.baseUrl}/api/courses/$courseId';
      print('📖 جاري تحميل تفاصيل الدورة: $url');

      final headers = await ApiHeadersManager.instance.getAuthHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> courseData = json.decode(response.body);

        // حفظ في الكاش
        await CacheManager.instance
            .setCache(cacheKey, courseData, type: CacheType.courses);

        print('💾 تم حفظ تفاصيل الدورة في الكاش');
        return courseData;
      } else {
        print('❌ فشل في تحميل تفاصيل الدورة: ${response.statusCode}');
        print('❌ Response: ${response.body}');

        // فحص انتهاء الجلسة
        if (response.statusCode == 401 || response.statusCode == 403) {
          print('🔐 تم اكتشاف انتهاء الجلسة في تفاصيل الدورة');
        }

        throw Exception('فشل في تحميل تفاصيل الدورة: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في تحميل تفاصيل الدورة: $e');
      return null;
    }
  }

  /// تحديث قائمة الدورات (مسح الكاش وإعادة التحميل)
  static Future<List<dynamic>?> refreshCourses({String? departmentId}) async {
    print('🔄 تحديث قائمة الدورات...');

    // مسح الكاش أولاً
    final cacheKey =
        departmentId != null ? 'department_$departmentId' : 'all_courses';
    await CacheManager.instance.removeCache(cacheKey, type: CacheType.courses);

    // إعادة التحميل
    return await getCourses(departmentId: departmentId, forceRefresh: true);
  }

  /// مسح كاش دورة معينة
  static Future<void> clearCourseCache(String courseId) async {
    await CacheManager.instance
        .removeCache('course_details_$courseId', type: CacheType.courses);
    print('🗑️ تم مسح كاش الدورة: $courseId');
  }

  /// إحصائيات الكاش للدورات
  static Future<Map<String, dynamic>> getCacheStats() async {
    final cacheInfo = await CacheManager.instance.getCacheInfo();

    // يمكن إضافة إحصائيات أكثر تفصيلاً هنا
    return {
      'total_courses_cached': 0, // سيتم حسابها لاحقاً
      'cache_hit_rate': 0.0, // معدل النجاح في الكاش
      'total_cache_size': cacheInfo['total_size_mb'] ?? '0',
    };
  }
}
