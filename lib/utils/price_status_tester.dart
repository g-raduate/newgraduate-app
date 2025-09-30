// ملف اختبار مؤقت لتجربة الخدمة - يمكن حذفه لاحقاً
import '../services/price_status_service.dart';

class PriceStatusTester {
  /// اختبار سريع لخدمة حالة الأسعار
  static Future<void> testService() async {
    try {
      print('=== اختبار خدمة حالة الأسعار ===');

      // فحص عادي مع كاش
      final shouldShow1 = await PriceStatusService.shouldShowPrices();
      print('النتيجة الأولى (مع كاش): $shouldShow1');

      // فحص ثاني (يجب أن يستخدم الكاش)
      final shouldShow2 = await PriceStatusService.shouldShowPrices();
      print('النتيجة الثانية (من الكاش): $shouldShow2');

      // فحص فوري (بدون كاش)
      final shouldShow3 = await PriceStatusService.forceCheck();
      print('النتيجة الثالثة (فحص فوري): $shouldShow3');

      print('=== انتهى الاختبار ===');
    } catch (e) {
      print('خطأ في الاختبار: $e');
    }
  }

  /// مسح الكاش
  static Future<void> clearCacheTest() async {
    await PriceStatusService.clearCache();
    print('تم مسح الكاش');
  }
}
