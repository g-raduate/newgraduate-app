import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:newgraduate/config/app_constants.dart';
import 'package:newgraduate/services/api_headers_manager.dart';

// نحتاج هذا للوصول لـ PlayerType
enum PlayerType {
  primary, // youtube_player_iframe (المشغل رقم 2)
  backup, // youtube_player_flutter (المشغل رقم 1)
  webview, // webview-based player (المشغل رقم 3)
}

class PlatformOperatorService {
  // endpoints are relative to AppConstants.apiUrl which already includes '/api'
  static const String _androidOperatorEndpoint = '/platform/android/operator';
  static const String _iosOperatorEndpoint = '/platform/ios/operator';

  /// الحصول على رقم المشغل المحدد للمنصة الحالية
  static Future<int> getCurrentPlatformOperator() async {
    try {
      String endpoint;

      // تحديد المنصة الحالية
      if (Platform.isAndroid) {
        endpoint = _androidOperatorEndpoint;
        print('🤖 جاري جلب إعدادات مشغل الأندرويد');
      } else if (Platform.isIOS) {
        endpoint = _iosOperatorEndpoint;
        print('🍎 جاري جلب إعدادات مشغل الآيفون');
      } else {
        print('⚠️ منصة غير مدعومة، استخدام المشغل الافتراضي رقم 1');
        return 1; // المشغل الافتراضي للمنصات غير المدعومة
      }

      final url = Uri.parse('${AppConstants.apiUrl}$endpoint');
      print('🌐 API URL: $url');

      // الحصول على headers أساسية (لا نحتاج token للحصول على إعدادات المشغل)
      final headers = ApiHeadersManager.instance.getBasicHeaders();
      print('📋 Headers: $headers');

      // إرسال الطلب
      final response = await http.get(url, headers: headers).timeout(
            const Duration(seconds: 10),
          );

      print('📡 Response Status: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final operatorNumber = data['data']['current_operator'];
          final operatorName = data['data']['operator_name'];
          final platform = data['data']['platform'];

          print('✅ تم جلب إعدادات المشغل بنجاح:');
          print('   المنصة: $platform');
          print('   رقم المشغل: $operatorNumber');
          print('   اسم المشغل: $operatorName');

          // التأكد من أن رقم المشغل صالح
          if (operatorNumber is int &&
              (operatorNumber >= 1 && operatorNumber <= 3)) {
            return operatorNumber;
          } else {
            print(
                '⚠️ رقم مشغل غير صالح: $operatorNumber، استخدام المشغل الافتراضي');
            return 1;
          }
        } else {
          print(
              '❌ استجابة API غير صالحة: ${data['message'] ?? 'خطأ غير معروف'}');
          return 1; // المشغل الافتراضي
        }
      } else {
        print('❌ خطأ في API: ${response.statusCode} - ${response.body}');
        return 1; // المشغل الافتراضي في حالة الخطأ
      }
    } catch (e) {
      print('💥 خطأ في جلب إعدادات المشغل: $e');
      return 1; // المشغل الافتراضي في حالة الخطأ
    }
  }

  /// الحصول على تفاصيل المشغل للمنصة المحددة
  static Future<Map<String, dynamic>?> getPlatformOperatorDetails(
      {bool forceAndroid = false, bool forceIOS = false}) async {
    try {
      String endpoint;
      String platformName;

      // تحديد المنصة
      if (forceAndroid || (!forceIOS && Platform.isAndroid)) {
        endpoint = _androidOperatorEndpoint;
        platformName = 'Android';
      } else if (forceIOS || Platform.isIOS) {
        endpoint = _iosOperatorEndpoint;
        platformName = 'iOS';
      } else {
        print('⚠️ منصة غير مدعومة');
        return null;
      }

      print('📱 جاري جلب تفاصيل مشغل $platformName');

      final url = Uri.parse('${AppConstants.apiUrl}$endpoint');
      final headers = ApiHeadersManager.instance.getBasicHeaders();

      final response = await http.get(url, headers: headers).timeout(
            const Duration(seconds: 10),
          );

      print('📡 [$platformName] Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          print('✅ [$platformName] تم جلب التفاصيل بنجاح');
          return data['data'];
        } else {
          print('❌ [$platformName] استجابة غير صالحة');
          return null;
        }
      } else {
        print('❌ [$platformName] خطأ في API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('💥 خطأ في جلب تفاصيل المشغل: $e');
      return null;
    }
  }

  /// ترجمة رقم المشغل إلى نوع
  static String getOperatorName(int operatorNumber) {
    switch (operatorNumber) {
      case 1:
        return 'youtube_player_flutter (المشغل رقم 1)';
      case 2:
        return 'youtube_player_iframe (المشغل رقم 2)';
      case 3:
        return 'webview player (المشغل رقم 3)';
      default:
        return 'مشغل غير معروف';
    }
  }

  /// تحديد نوع المشغل بناءً على الرقم
  static PlayerType getPlayerTypeFromNumber(int operatorNumber) {
    switch (operatorNumber) {
      case 1:
        return PlayerType.backup; // youtube_player_flutter
      case 2:
        return PlayerType.primary; // youtube_player_iframe
      case 3:
        return PlayerType.webview; // webview-based player
      default:
        return PlayerType.backup; // الافتراضي
    }
  }

  /// الحصول على نوع الجهاز كنص
  static String getDeviceType() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      return 'unknown';
    }
  }

  /// الحصول على اسم النظام بالعربية
  static String getDeviceDisplayName() {
    final deviceType = getDeviceType();
    switch (deviceType) {
      case 'android':
        return 'أندرويد';
      case 'ios':
        return 'آيفون';
      default:
        return 'غير محدد';
    }
  }

  /// الحصول على اسم المنصة الحالية
  static String getCurrentPlatformName() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else {
      return 'Unknown';
    }
  }
}
