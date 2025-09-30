import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// خدمة بسيطة لطلب صلاحية الموقع
class LocationPermissionService {
  static bool _hasRequestedPermission = false;

  /// طلب صلاحية الموقع مع إظهار حوار توضيحي
  static Future<bool> requestLocationPermission(BuildContext context) async {
    try {
      debugPrint('[LocationService] Starting permission request...');

      // التحقق من حالة الصلاحية الحالية
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[LocationService] Current permission: $permission');

      // إذا كانت الصلاحية ممنوحة مسبقاً
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        debugPrint('[LocationService] Permission already granted');
        return true;
      }

      // إذا كانت الصلاحية مرفوضة نهائياً
      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Permission denied forever');
        if (context.mounted) {
          _showOpenSettingsDialog(context);
        }
        return false;
      }

      // طلب الصلاحية
      debugPrint('[LocationService] Requesting permission...');
      permission = await Geolocator.requestPermission();
      debugPrint('[LocationService] Permission after request: $permission');

      // التحقق من النتيجة
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم منح صلاحية الموقع بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          _showOpenSettingsDialog(context);
        }
        return false;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم رفض صلاحية الموقع'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('[LocationService] Error: $e');
      debugPrint('[LocationService] Stack trace: $stackTrace');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في طلب صلاحية الموقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// طلب صلاحية الموقع عند بدء التطبيق (مرة واحدة فقط)
  static Future<void> requestPermissionOnAppStart(BuildContext context) async {
    if (_hasRequestedPermission) return;
    _hasRequestedPermission = true;

    // انتظار قصير للتأكد من بناء الواجهة
    await Future.delayed(const Duration(milliseconds: 1000));

    if (context.mounted) {
      await requestLocationPermission(context);
    }
  }

  /// التحقق من تفعيل خدمة الموقع
  static Future<bool> checkLocationService(BuildContext context) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && context.mounted) {
        _showLocationServiceDialog(context);
        return false;
      }
      return serviceEnabled;
    } catch (e) {
      debugPrint('[LocationService] Error checking service: $e');
      return false;
    }
  }

  /// حوار لفتح إعدادات التطبيق
  static void _showOpenSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('صلاحية الموقع مطلوبة'),
        content: const Text(
          'تم رفض صلاحية الموقع نهائياً. لاستخدام ميزات الموقع، يرجى تفعيل الصلاحية من إعدادات التطبيق.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openAppSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  /// حوار لفتح إعدادات الموقع
  static void _showLocationServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفعيل خدمة الموقع'),
        content: const Text(
          'خدمة الموقع غير مفعلة. يرجى تفعيلها من إعدادات الجهاز لتحديد موقعك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openLocationSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }
}
