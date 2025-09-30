import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:newgraduate/services/platform_operator_service.dart';

class PlayerCacheService {
  static const String _cacheKey = 'player_settings_cache';
  static const String _lastUpdateKey = 'player_cache_last_update';
  static const int _cacheValidityHours = 6; // مدة صلاحية الكاش بالساعات

  /// معلومات الكاش
  static const Map<String, String> _platformNames = {
    'android': 'Android',
    'ios': 'iOS',
    'web': 'Web',
    'windows': 'Windows',
    'macos': 'macOS',
    'linux': 'Linux',
  };

  /// تحديد نوع المنصة الحالية بدقة
  static String getCurrentPlatformType() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isLinux) {
      return 'linux';
    } else {
      return 'web'; // fallback للمنصات غير المعروفة
    }
  }

  /// الحصول على اسم المنصة الحالية للعرض
  static String getCurrentPlatformDisplayName() {
    final platformType = getCurrentPlatformType();
    return _platformNames[platformType] ?? 'Unknown Platform';
  }

  /// حفظ إعدادات المشغل في الكاش
  static Future<void> savePlayerSettings({
    required String platform,
    required int operatorNumber,
    required String operatorName,
    String? updatedAt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cacheData = {
        'platform': platform,
        'operator_number': operatorNumber,
        'operator_name': operatorName,
        'cached_at': DateTime.now().toIso8601String(),
        'api_updated_at': updatedAt ?? DateTime.now().toIso8601String(),
        'platform_display_name': _platformNames[platform] ?? platform,
      };

      await prefs.setString(_cacheKey, json.encode(cacheData));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());

      print('💾 تم حفظ إعدادات المشغل في الكاش:');
      print('   المنصة: ${cacheData['platform_display_name']}');
      print('   رقم المشغل: $operatorNumber');
      print('   اسم المشغل: $operatorName');
      print('   وقت الحفظ: ${cacheData['cached_at']}');
    } catch (e) {
      print('❌ خطأ في حفظ الكاش: $e');
    }
  }

  /// استرداد إعدادات المشغل من الكاش
  static Future<Map<String, dynamic>?> getPlayerSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_cacheKey);

      if (cacheString == null) {
        print('📭 لا توجد إعدادات محفوظة في الكاش');
        return null;
      }

      final cacheData = json.decode(cacheString) as Map<String, dynamic>;
      final currentPlatform = getCurrentPlatformType();

      // التحقق من تطابق المنصة
      if (cacheData['platform'] != currentPlatform) {
        print(
            '⚠️ تغيرت المنصة من ${cacheData['platform']} إلى $currentPlatform');
        print('🗑️ مسح الكاش القديم');
        await clearCache();
        return null;
      }

      // التحقق من صلاحية الكاش
      if (!_isCacheValid(cacheData['cached_at'])) {
        print('⌛ انتهت صلاحية الكاش، يجب التحديث من API');
        return null;
      }

      print('✅ تم استرداد إعدادات المشغل من الكاش:');
      print('   المنصة: ${cacheData['platform_display_name']}');
      print('   رقم المشغل: ${cacheData['operator_number']}');
      print('   اسم المشغل: ${cacheData['operator_name']}');
      print('   آخر تحديث: ${cacheData['cached_at']}');

      return cacheData;
    } catch (e) {
      print('❌ خطأ في قراءة الكاش: $e');
      return null;
    }
  }

  /// التحقق من صلاحية الكاش
  static bool _isCacheValid(String cachedAtString) {
    try {
      final cachedAt = DateTime.parse(cachedAtString);
      final now = DateTime.now();
      final difference = now.difference(cachedAt);

      final isValid = difference.inHours < _cacheValidityHours;

      if (!isValid) {
        print('⌛ الكاش منتهي الصلاحية:');
        print('   تم الحفظ: $cachedAtString');
        print('   الوقت الحالي: ${now.toIso8601String()}');
        print('   المدة المنقضية: ${difference.inHours} ساعة');
      }

      return isValid;
    } catch (e) {
      print('❌ خطأ في التحقق من صلاحية الكاش: $e');
      return false;
    }
  }

  /// الحصول على رقم المشغل المحفوظ
  Future<int?> getCachedPlayer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedSettings = prefs.getString(_cacheKey);

      if (cachedSettings != null) {
        final data = jsonDecode(cachedSettings);
        return data['operator_number'] as int?;
      }
      return null;
    } catch (e) {
      print('❌ خطأ في جلب المشغل المحفوظ: $e');
      return null;
    }
  }

  /// مسح الكاش
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastUpdateKey);
      print('🗑️ تم مسح كاش إعدادات المشغل');
    } catch (e) {
      print('❌ خطأ في مسح الكاش: $e');
    }
  }

  /// إجبار تحديث الكاش من API
  static Future<PlayerType> forceUpdateFromAPI() async {
    print('🔄 إجبار تحديث إعدادات المشغل من API...');

    try {
      // مسح الكاش القديم
      await clearCache();

      // جلب من API
      final operatorNumber =
          await PlatformOperatorService.getCurrentPlatformOperator();
      final playerType =
          PlatformOperatorService.getPlayerTypeFromNumber(operatorNumber);
      final operatorName =
          PlatformOperatorService.getOperatorName(operatorNumber);
      final currentPlatform = getCurrentPlatformType();

      // حفظ في الكاش
      await savePlayerSettings(
        platform: currentPlatform,
        operatorNumber: operatorNumber,
        operatorName: operatorName,
      );

      print('✅ تم تحديث الكاش بنجاح');
      return playerType;
    } catch (e) {
      print('❌ فشل في تحديث الكاش: $e');
      return PlayerType.backup; // افتراضي
    }
  }

  /// الحصول على إعدادات المشغل مع كاش ذكي
  static Future<PlayerType> getPlayerTypeWithSmartCache() async {
    final currentPlatform = getCurrentPlatformType();
    final platformDisplayName = getCurrentPlatformDisplayName();

    print('🔍 بحث عن إعدادات المشغل للمنصة: $platformDisplayName');
    print('   نوع المنصة: $currentPlatform');

    // محاولة الحصول من الكاش أولاً
    final cachedSettings = await getPlayerSettings();

    if (cachedSettings != null) {
      final operatorNumber = cachedSettings['operator_number'] as int;
      final playerType =
          PlatformOperatorService.getPlayerTypeFromNumber(operatorNumber);

      print('🚀 استخدام الإعدادات المحفوظة من الكاش');
      return playerType;
    }

    // إذا لم يوجد كاش صالح، جلب من API
    print('📡 جلب إعدادات جديدة من API...');

    try {
      final operatorNumber =
          await PlatformOperatorService.getCurrentPlatformOperator();
      final playerType =
          PlatformOperatorService.getPlayerTypeFromNumber(operatorNumber);
      final operatorName =
          PlatformOperatorService.getOperatorName(operatorNumber);

      // حفظ في الكاش للمرات القادمة
      await savePlayerSettings(
        platform: currentPlatform,
        operatorNumber: operatorNumber,
        operatorName: operatorName,
      );

      print('✅ تم جلب وحفظ الإعدادات الجديدة');
      return playerType;
    } catch (e) {
      print('❌ فشل في جلب الإعدادات من API: $e');
      print('🔄 استخدام المشغل الافتراضي (رقم 1)');

      // حفظ الإعداد الافتراضي في الكاش مؤقتاً
      await savePlayerSettings(
        platform: currentPlatform,
        operatorNumber: 1,
        operatorName: 'مشغل افتراضي (فشل API)',
      );

      return PlayerType.backup;
    }
  }

  /// الحصول على معلومات مفصلة عن حالة الكاش
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_cacheKey);
      final lastUpdate = prefs.getString(_lastUpdateKey);

      if (cacheString == null) {
        return {
          'has_cache': false,
          'current_platform': getCurrentPlatformType(),
          'platform_display_name': getCurrentPlatformDisplayName(),
        };
      }

      final cacheData = json.decode(cacheString) as Map<String, dynamic>;
      final isValid = _isCacheValid(cacheData['cached_at']);

      return {
        'has_cache': true,
        'is_valid': isValid,
        'current_platform': getCurrentPlatformType(),
        'platform_display_name': getCurrentPlatformDisplayName(),
        'cached_platform': cacheData['platform'],
        'operator_number': cacheData['operator_number'],
        'operator_name': cacheData['operator_name'],
        'cached_at': cacheData['cached_at'],
        'last_update': lastUpdate,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'current_platform': getCurrentPlatformType(),
        'platform_display_name': getCurrentPlatformDisplayName(),
      };
    }
  }
}
