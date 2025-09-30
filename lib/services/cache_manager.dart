import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// مدير الكاش المتقدم للتطبيق
/// يدعم تخزين البيانات مؤقتاً لتحسين الأداء وتقليل استهلاك الإنترنت
class CacheManager {
  static CacheManager? _instance;
  static CacheManager get instance => _instance ??= CacheManager._internal();

  CacheManager._internal();

  // مفاتيح أنواع الكاش المختلفة (محجوزة للاستخدام المستقبلي)
  // static const String _coursesCacheKey = 'courses_cache';
  // static const String _videosCacheKey = 'videos_cache';
  // static const String _summariesCacheKey = 'summaries_cache';
  // static const String _studentInfoCacheKey = 'student_info_cache';
  // static const String _instructorsCacheKey = 'instructors_cache';
  // static const String _departmentsCacheKey = 'departments_cache';
  // static const String _imagesCacheKey = 'images_cache';

  // إعدادات انتهاء الصلاحية (بالثواني)
  static const int _defaultCacheExpirySeconds = 3600; // ساعة واحدة
  static const int _shortCacheExpirySeconds =
      900; // 15 دقيقة (تم تقليلها من 30 دقيقة)
  static const int _longCacheExpirySeconds = 86400; // 24 ساعة
  static const int _imageCacheExpirySeconds = 604800; // أسبوع واحد

  late SharedPreferences _prefs;
  late Directory _cacheDir;
  bool _isInitialized = false;

  /// تهيئة مدير الكاش
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _cacheDir = await getTemporaryDirectory();

      // إنشاء مجلد الكاش إذا لم يكن موجوداً
      final cacheSubDir = Directory('${_cacheDir.path}/app_cache');
      if (!await cacheSubDir.exists()) {
        await cacheSubDir.create(recursive: true);
      }
      _cacheDir = cacheSubDir;

      _isInitialized = true;
      print('✅ تم تهيئة مدير الكاش بنجاح');

      // تنظيف الكاش المنتهي الصلاحية عند البدء
      await _cleanExpiredCache();
    } catch (e) {
      print('❌ خطأ في تهيئة مدير الكاش: $e');
    }
  }

  /// حفظ بيانات في الكاش
  Future<bool> setCache(
    String key,
    dynamic data, {
    int? expirySeconds,
    CacheType type = CacheType.general,
  }) async {
    await _ensureInitialized();

    try {
      final expiryTime = DateTime.now().millisecondsSinceEpoch +
          ((expirySeconds ?? _getCacheExpiryForType(type)) * 1000);

      final cacheData = {
        'data': data,
        'expiry': expiryTime,
        'type': type.toString(),
        'cached_at': DateTime.now().toIso8601String(),
      };

      final cacheKey = _generateCacheKey(key, type);

      if (type == CacheType.image) {
        // للصور، نحفظها كملفات منفصلة
        return await _saveToDisk(cacheKey, cacheData);
      } else {
        // للبيانات العادية، نحفظها في SharedPreferences
        return await _prefs.setString(cacheKey, json.encode(cacheData));
      }
    } catch (e) {
      print('❌ خطأ في حفظ الكاش للمفتاح $key: $e');
      return false;
    }
  }

  /// استرجاع بيانات من الكاش
  Future<T?> getCache<T>(String key,
      {CacheType type = CacheType.general}) async {
    await _ensureInitialized();

    try {
      final cacheKey = _generateCacheKey(key, type);
      String? cacheString;

      if (type == CacheType.image) {
        cacheString = await _loadFromDisk(cacheKey);
      } else {
        cacheString = _prefs.getString(cacheKey);
      }

      if (cacheString == null) {
        print('🔍 لا توجد بيانات مخزنة للمفتاح: $key');
        return null;
      }

      final cacheData = json.decode(cacheString) as Map<String, dynamic>;
      final expiryTime = cacheData['expiry'] as int;

      // فحص انتهاء الصلاحية
      if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
        print('⏰ انتهت صلاحية الكاش للمفتاح: $key');
        await removeCache(key, type: type);
        return null;
      }

      print('✅ تم استرجاع البيانات من الكاش للمفتاح: $key');
      return cacheData['data'] as T?;
    } catch (e) {
      print('❌ خطأ في استرجاع الكاش للمفتاح $key: $e');
      return null;
    }
  }

  /// حذف بيانات محددة من الكاش
  Future<bool> removeCache(String key,
      {CacheType type = CacheType.general}) async {
    await _ensureInitialized();

    try {
      final cacheKey = _generateCacheKey(key, type);

      if (type == CacheType.image) {
        return await _removeFromDisk(cacheKey);
      } else {
        return await _prefs.remove(cacheKey);
      }
    } catch (e) {
      print('❌ خطأ في حذف الكاش للمفتاح $key: $e');
      return false;
    }
  }

  /// مسح كاش نوع معين
  Future<bool> clearCacheByType(CacheType type) async {
    await _ensureInitialized();

    try {
      final allKeys = _prefs.getKeys();
      final typePrefix = '${type.toString()}_';

      for (final key in allKeys) {
        if (key.startsWith(typePrefix)) {
          await _prefs.remove(key);
        }
      }

      // مسح ملفات الكاش أيضاً
      if (type == CacheType.image) {
        final files = await _cacheDir.list().toList();
        for (final file in files) {
          if (file.path.contains(typePrefix)) {
            await file.delete();
          }
        }
      }

      print('✅ تم مسح كاش النوع: $type');
      return true;
    } catch (e) {
      print('❌ خطأ في مسح كاش النوع $type: $e');
      return false;
    }
  }

  /// مسح جميع البيانات المخزنة
  Future<bool> clearAllCache() async {
    await _ensureInitialized();

    try {
      // مسح SharedPreferences
      final allKeys = _prefs.getKeys();
      for (final key in allKeys) {
        if (key.contains('_cache_')) {
          await _prefs.remove(key);
        }
      }

      // مسح ملفات الكاش
      if (await _cacheDir.exists()) {
        await _cacheDir.delete(recursive: true);
        await _cacheDir.create(recursive: true);
      }

      print('✅ تم مسح جميع بيانات الكاش');
      return true;
    } catch (e) {
      print('❌ خطأ في مسح جميع الكاش: $e');
      return false;
    }
  }

  /// الحصول على حجم الكاش بالبايت
  Future<int> getCacheSize() async {
    await _ensureInitialized();

    try {
      int totalSize = 0;

      // حساب حجم SharedPreferences
      final allKeys = _prefs.getKeys();
      for (final key in allKeys) {
        if (key.contains('_cache_')) {
          final value = _prefs.getString(key) ?? '';
          totalSize += value.length;
        }
      }

      // حساب حجم الملفات
      if (await _cacheDir.exists()) {
        await for (final file in _cacheDir.list(recursive: true)) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      return totalSize;
    } catch (e) {
      print('❌ خطأ في حساب حجم الكاش: $e');
      return 0;
    }
  }

  /// الحصول على تفاصيل الكاش
  Future<Map<String, dynamic>> getCacheInfo() async {
    await _ensureInitialized();

    try {
      final size = await getCacheSize();
      final sizeInMB = (size / (1024 * 1024)).toStringAsFixed(2);

      final allKeys = _prefs.getKeys();
      final cacheKeys =
          allKeys.where((key) => key.contains('_cache_')).toList();

      return {
        'total_size_bytes': size,
        'total_size_mb': sizeInMB,
        'total_items': cacheKeys.length,
        'cache_directory': _cacheDir.path,
        'last_cleanup':
            _prefs.getString('last_cache_cleanup') ?? 'لم يتم التنظيف بعد',
      };
    } catch (e) {
      print('❌ خطأ في الحصول على معلومات الكاش: $e');
      return {};
    }
  }

  /// دوال مخصصة لأنواع البيانات المختلفة

  // كاش الدورات
  Future<bool> setCourses(String key, List<dynamic> courses) async {
    return await setCache(key, courses, type: CacheType.courses);
  }

  Future<List<dynamic>?> getCourses(String key) async {
    return await getCache<List<dynamic>>(key, type: CacheType.courses);
  }

  // كاش الفيديوهات
  Future<bool> setVideos(String courseId, List<dynamic> videos) async {
    return await setCache('course_$courseId', videos, type: CacheType.videos);
  }

  Future<List<dynamic>?> getVideos(String courseId) async {
    return await getCache<List<dynamic>>('course_$courseId',
        type: CacheType.videos);
  }

  Future<bool> clearVideosCache(String courseId) async {
    return await removeCache('course_$courseId', type: CacheType.videos);
  }

  // كاش الملخصات
  Future<bool> setSummaries(String courseId, List<dynamic> summaries) async {
    return await setCache('course_$courseId', summaries,
        type: CacheType.summaries);
  }

  Future<List<dynamic>?> getSummaries(String courseId) async {
    return await getCache<List<dynamic>>('course_$courseId',
        type: CacheType.summaries);
  }

  Future<bool> clearSummariesCache(String courseId) async {
    return await removeCache('course_$courseId', type: CacheType.summaries);
  }

  // كاش معلومات الطالب
  Future<bool> setStudentInfo(
      String studentId, Map<String, dynamic> info) async {
    return await setCache(studentId, info, type: CacheType.studentInfo);
  }

  Future<Map<String, dynamic>?> getStudentInfo(String studentId) async {
    return await getCache<Map<String, dynamic>>(studentId,
        type: CacheType.studentInfo);
  }

  /// دوال مساعدة خاصة

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  String _generateCacheKey(String key, CacheType type) {
    final hash = md5.convert(utf8.encode(key)).toString();
    return '${type.toString()}_cache_$hash';
  }

  int _getCacheExpiryForType(CacheType type) {
    switch (type) {
      case CacheType.videos:
      case CacheType.summaries:
        return _shortCacheExpirySeconds;
      case CacheType.image:
        return _imageCacheExpirySeconds;
      case CacheType.studentInfo:
      case CacheType.courses:
        return _longCacheExpirySeconds;
      case CacheType.instructors:
      case CacheType.departments:
        return _defaultCacheExpirySeconds;
      case CacheType.general:
        return _defaultCacheExpirySeconds;
    }
  }

  Future<bool> _saveToDisk(String key, Map<String, dynamic> data) async {
    try {
      final file = File('${_cacheDir.path}/$key.json');
      await file.writeAsString(json.encode(data));
      return true;
    } catch (e) {
      print('❌ خطأ في حفظ الملف: $e');
      return false;
    }
  }

  Future<String?> _loadFromDisk(String key) async {
    try {
      final file = File('${_cacheDir.path}/$key.json');
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      print('❌ خطأ في قراءة الملف: $e');
      return null;
    }
  }

  Future<bool> _removeFromDisk(String key) async {
    try {
      final file = File('${_cacheDir.path}/$key.json');
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      print('❌ خطأ في حذف الملف: $e');
      return false;
    }
  }

  Future<void> _cleanExpiredCache() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final allKeys =
          _prefs.getKeys().where((key) => key.contains('_cache_')).toList();

      for (final key in allKeys) {
        try {
          final cacheString = _prefs.getString(key);
          if (cacheString != null) {
            final cacheData = json.decode(cacheString) as Map<String, dynamic>;
            final expiryTime = cacheData['expiry'] as int;

            if (now > expiryTime) {
              await _prefs.remove(key);
              print('🗑️ تم حذف كاش منتهي الصلاحية: $key');
            }
          }
        } catch (e) {
          // في حالة وجود خطأ في قراءة البيانات، احذف المفتاح
          await _prefs.remove(key);
        }
      }

      // حفظ وقت آخر تنظيف
      await _prefs.setString(
          'last_cache_cleanup', DateTime.now().toIso8601String());
      print('✅ تم تنظيف الكاش المنتهي الصلاحية');
    } catch (e) {
      print('❌ خطأ في تنظيف الكاش: $e');
    }
  }
}

/// أنواع الكاش المختلفة
enum CacheType {
  general,
  courses,
  videos,
  summaries,
  studentInfo,
  instructors,
  departments,
  image,
}
