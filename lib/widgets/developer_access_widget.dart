import 'package:flutter/material.dart';
import 'package:newgraduate/screens/player_settings_debug_screen.dart';
import 'package:newgraduate/services/platform_operator_service.dart';
import 'package:newgraduate/widgets/smart_youtube_player_manager.dart';

/// أداة للوصول لشاشة إعدادات المشغل للمطورين
/// يمكن إضافتها كزر مخفي في أي شاشة إعدادات أو عن التطبيق
class DeveloperAccessWidget extends StatelessWidget {
  const DeveloperAccessWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _showDeveloperAccessDialog(context);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Icon(
          Icons.developer_mode,
          color: Colors.grey,
          size: 16,
        ),
      ),
    );
  }

  void _showDeveloperAccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'وصول المطور',
          style: TextStyle(fontFamily: 'NotoKufiArabic'),
        ),
        content: const Text(
          'هل تريد الوصول لإعدادات المشغل ومعلومات الكاش؟',
          style: TextStyle(fontFamily: 'NotoKufiArabic'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlayerSettingsDebugScreen(),
                ),
              );
            },
            child: const Text('فتح'),
          ),
        ],
      ),
    );
  }
}

/// طريقة للوصول المباشر لشاشة المطور
/// استخدامها في شاشة الإعدادات أو عن التطبيق:
///
/// ```dart
/// // في أي مكان في التطبيق
/// DeveloperDebugHelper.showPlayerDebugScreen(context);
///
/// // أو كزر مخفي
/// InkWell(
///   onTap: () => DeveloperDebugHelper.showPlayerDebugScreen(context),
///   child: Container(width: 50, height: 50, color: Colors.transparent),
/// )
/// ```
class DeveloperDebugHelper {
  /// فتح شاشة إعدادات المشغل مباشرة
  static void showPlayerDebugScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlayerSettingsDebugScreen(),
      ),
    );
  }

  /// عرض معلومات سريعة عن المشغل في SnackBar
  static Future<void> showQuickPlayerInfo(BuildContext context) async {
    final deviceType = PlatformOperatorService.getDeviceType();
    final deviceName = PlatformOperatorService.getDeviceDisplayName();

    final message = 'الجهاز: $deviceName ($deviceType)';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'NotoKufiArabic'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// تحقق سريع من حالة الكاش
  static Future<void> showCacheStatus(BuildContext context) async {
    try {
      final cacheInfo = await VideoPlayerHelper.getCacheStatus();
      final hasCache = cacheInfo['has_cache'] == true;
      final isValid = cacheInfo['is_valid'] == true;
      final operatorNumber = cacheInfo['operator_number'];

      String message;
      if (!hasCache) {
        message = 'لا يوجد كاش محفوظ';
      } else if (!isValid) {
        message = 'الكاش منتهي الصلاحية - مشغل $operatorNumber';
      } else {
        message = 'الكاش صالح - مشغل $operatorNumber';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'NotoKufiArabic'),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في فحص الكاش: $e',
            style: const TextStyle(fontFamily: 'NotoKufiArabic'),
          ),
        ),
      );
    }
  }
}
