import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';
import 'api_headers_manager.dart';

class PriceStatusService {
  static const String _cacheKey = 'price_status_cache';
  static const String _cacheTimeKey = 'price_status_cache_time';
  static const Duration _cacheDuration = Duration(hours: 3); // كاش لمدة 3 ساعات

  /// فحص حالة إظهار الأسعار
  static Future<bool> shouldShowPrices() async {
    try {
      // التحقق من الكاش أولاً
      final cachedResult = await _getCachedResult();
      if (cachedResult != null) {
        return cachedResult;
      }

      // استدعاء API إذا لم يكن هناك كاش أو انتهت صلاحيته
      final result = await _fetchFromAPI();

      // حفظ النتيجة في الكاش
      await _cacheResult(result);

      return result;
    } catch (e) {
      print('Error checking price status: $e');
      // في حالة الخطأ، إرجاع القيمة الافتراضية (إظهار الأسعار)
      return true;
    }
  }

  /// جلب البيانات من API
  static Future<bool> _fetchFromAPI() async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/prices/show-status');
    final headers = await ApiHeadersManager.instance.getAuthHeaders();

    final response = await http
        .get(
          url,
          headers: headers,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == true && data['data'] != null) {
        return data['data']['show_prices'] ?? true;
      }
    }

    // في حالة عدم نجاح الاستجابة، إرجاع القيمة الافتراضية
    return true;
  }

  /// جلب النتيجة من الكاش إذا كانت صالحة
  static Future<bool?> _getCachedResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // التحقق من وقت الكاش
      final cacheTimeString = prefs.getString(_cacheTimeKey);
      if (cacheTimeString == null) return null;

      final cacheTime = DateTime.parse(cacheTimeString);
      final now = DateTime.now();

      // التحقق من صلاحية الكاش (3 ساعات)
      if (now.difference(cacheTime) > _cacheDuration) {
        return null; // الكاش منتهي الصلاحية
      }

      // جلب النتيجة من الكاش
      return prefs.getBool(_cacheKey);
    } catch (e) {
      print('Error reading cache: $e');
      return null;
    }
  }

  /// حفظ النتيجة في الكاش
  static Future<void> _cacheResult(bool result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cacheKey, result);
      await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching result: $e');
    }
  }

  /// مسح الكاش (للاستخدام عند الحاجة لإعادة تحميل فوري)
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimeKey);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// فحص فوري بدون كاش (للاستخدام عند الحاجة لتحديث فوري)
  static Future<bool> forceCheck() async {
    try {
      await clearCache();
      return await shouldShowPrices();
    } catch (e) {
      print('Error in force check: $e');
      return true;
    }
  }
}
