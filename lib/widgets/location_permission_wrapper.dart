import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionWrapper extends StatefulWidget {
  final Widget child;

  const LocationPermissionWrapper({
    super.key,
    required this.child,
  });

  @override
  State<LocationPermissionWrapper> createState() =>
      _LocationPermissionWrapperState();
}

class _LocationPermissionWrapperState extends State<LocationPermissionWrapper> {
  bool _hasAskedForPermission = false;

  @override
  void initState() {
    super.initState();
    // طلب الصلاحية بعد بناء الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermissionOnAppStart();
    });
  }

  Future<void> _requestLocationPermissionOnAppStart() async {
    if (_hasAskedForPermission) return;
    _hasAskedForPermission = true;

    try {
      debugPrint(
          '[LocationPermission] Checking location permission on app start...');

      // التحقق من حالة الصلاحية الحالية
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[LocationPermission] Current permission: $permission');

      // إذا كانت الصلاحية لم تُمنح بعد، اطلبها
      if (permission == LocationPermission.denied) {
        debugPrint('[LocationPermission] Requesting permission...');
        permission = await Geolocator.requestPermission();
        debugPrint(
            '[LocationPermission] Permission after request: $permission');

        // عرض رسالة للمستخدم حسب النتيجة
        if (mounted) {
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            _showPermissionResult(true, 'تم منح صلاحية الموقع بنجاح');
          } else if (permission == LocationPermission.denied) {
            _showPermissionResult(false,
                'تم رفض صلاحية الموقع. يمكنك تفعيلها لاحقاً من الإعدادات');
          } else if (permission == LocationPermission.deniedForever) {
            _showPermissionResult(false,
                'تم رفض صلاحية الموقع نهائياً. يرجى تفعيلها من إعدادات التطبيق');
          }
        }
      } else if (permission == LocationPermission.deniedForever) {
        // إذا كانت الصلاحية مرفوضة نهائياً، اعرض رسالة توضيحية
        if (mounted) {
          _showPermissionDeniedForeverDialog();
        }
      } else {
        // الصلاحية ممنوحة مسبقاً
        debugPrint(
            '[LocationPermission] Permission already granted: $permission');
      }

      // التحقق من تفعيل خدمة الموقع
      await _checkLocationService();
    } catch (e, stackTrace) {
      debugPrint('[LocationPermission] Error requesting permission: $e');
      debugPrint('[LocationPermission] Stack trace: $stackTrace');
    }
  }

  Future<void> _checkLocationService() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint(
          '[LocationPermission] Location service enabled: $serviceEnabled');

      if (!serviceEnabled && mounted) {
        // عرض رسالة لتفعيل خدمة الموقع
        _showLocationServiceDialog();
      }
    } catch (e) {
      debugPrint('[LocationPermission] Error checking location service: $e');
    }
  }

  void _showPermissionResult(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 3),
        action: !success
            ? SnackBarAction(
                label: 'الإعدادات',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              )
            : null,
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفعيل خدمة الموقع'),
        content: const Text(
          'خدمة الموقع غير مفعلة. لتحديد موقعك بدقة، يرجى تفعيل خدمة الموقع من إعدادات الجهاز.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لاحقاً'),
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

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('صلاحية الموقع مطلوبة'),
        content: const Text(
          'تم رفض صلاحية الموقع نهائياً. لاستخدام ميزات الموقع في التطبيق، يرجى تفعيل الصلاحية من إعدادات التطبيق.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لاحقاً'),
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

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
