import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:newgraduate/services/api_client.dart';

class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  bool _hasLocationPermission = false;
  bool _isLocationServiceEnabled = false;
  Timer? _locationUpdateTimer;
  Timer? _locationStatusCheckTimer;
  Position? _lastKnownPosition;

  bool get hasLocationPermission => _hasLocationPermission;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  bool get canShowCourses =>
      _hasLocationPermission && _isLocationServiceEnabled;
  Position? get lastKnownPosition => _lastKnownPosition;

  /// فحص حالة صلاحية الموقع
  Future<void> checkLocationStatus() async {
    try {
      // فحص تفعيل خدمة الموقع
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

      // فحص صلاحية الوصول للموقع
      LocationPermission permission = await Geolocator.checkPermission();
      _hasLocationPermission = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      notifyListeners();

      debugPrint(
          '[LocationService] Service enabled: $_isLocationServiceEnabled');
      debugPrint(
          '[LocationService] Permission granted: $_hasLocationPermission');
    } catch (e) {
      debugPrint('[LocationService] Error checking location status: $e');
    }
  }

  /// تحديث الموقع الآن بشكل صامت دون طلب صلاحيات (إن كانت مفعلة)
  /// يعيد استجابة السيرفر أو null إذا لم تكن الخدمة/الصلاحية متاحة
  Future<Map<String, dynamic>?> refreshLocationNow({bool silent = true}) async {
    try {
      // تأكد من الحالة أولاً
      await checkLocationStatus();

      if (!_isLocationServiceEnabled) {
        if (!silent) print('⚠️ [LocationService] خدمة الموقع غير مفعلة');
        return null;
      }
      if (!_hasLocationPermission) {
        if (!silent) print('⚠️ [LocationService] صلاحية الموقع غير مفعلة');
        return null;
      }

      final resp = await _updateLocation();
      if (!silent) {
        print('📨 [LocationService] استجابة تحديث الموقع (refreshNow): $resp');
      }
      return resp;
    } catch (e) {
      print('❌ [LocationService] refreshLocationNow error: $e');
      return null;
    }
  }

  /// طلب صلاحية الموقع
  Future<bool> requestLocationPermission(BuildContext context) async {
    try {
      // التحقق من تفعيل خدمة الموقع أولاً
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog(context);
        return false;
      }

      // فحص الصلاحية الحالية
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showOpenSettingsDialog(context);
        return false;
      }

      bool granted = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (granted) {
        _hasLocationPermission = true;
        _isLocationServiceEnabled = true;
        notifyListeners();

        print('🎉 [LocationService] تم تفعيل ميزة الموقع بنجاح!');

        // إرسال الموقع للمرة الأولى
        _updateLocation();

        // بدء التحديثات الدورية
        _startLocationUpdates();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تفعيل الموقع بنجاح'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      return granted;
    } catch (e) {
      debugPrint('[LocationService] Error requesting permission: $e');
      return false;
    }
  }

  /// بدء تحديث الموقع كل 5 دقائق
  void _startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationStatusCheckTimer?.cancel();

    print('🚀 [LocationService] بدء تحديث الموقع كل 5 دقائق');

    // تحديث الموقع كل 5 دقائق
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateLocation();
    });

    // فحص حالة خدمة الموقع كل دقيقة
    _locationStatusCheckTimer =
        Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkLocationServiceStatus();
    });
  }

  /// فحص حالة خدمة الموقع دورياً
  Future<void> _checkLocationServiceStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      bool hasPermission = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      // إذا تم إغلاق الخدمة أو سحب الإذن
      if (!serviceEnabled || !hasPermission) {
        print('⚠️ [LocationService] تم إيقاف خدمة الموقع أو سحب الإذن');

        _hasLocationPermission = false;
        _isLocationServiceEnabled = false;

        // إيقاف التحديثات
        _locationUpdateTimer?.cancel();
        _locationStatusCheckTimer?.cancel();

        notifyListeners();
      }
    } catch (e) {
      print('❌ [LocationService] خطأ في فحص حالة الموقع: $e');
    }
  }

  /// تحديث الموقع وإرساله للسيرفر
  Future<Map<String, dynamic>?> _updateLocation() async {
    try {
      if (!_hasLocationPermission) return null;

      print('🔍 [LocationService] بدء الحصول على الموقع...');

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      print(
          '📍 [LocationService] تم الحصول على الموقع: ${position.latitude}, ${position.longitude}');

      _lastKnownPosition = position;

      // إرسال الموقع للسيرفر
      final response = await _sendLocationToServer(position);
      // طباعة الرسبونس بعد إتمام تحديث الموقع
      print('📨 [LocationService] استجابة تحديث الموقع: $response');

      return response;
    } catch (e) {
      print('❌ [LocationService] خطأ في تحديث الموقع: $e');
      return null;
    }
  }

  /// إرسال الموقع للسيرفر
  Future<Map<String, dynamic>?> _sendLocationToServer(Position position) async {
    try {
      final apiClient = ApiClient();

      // استرجاع التوكن من التخزين المحلي وتعيينه في ApiClient
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print('❌ [LocationService] لا يوجد توكن مصادقة محفوظ');
        return null;
      }

      apiClient.setBearer(token);

      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'location_source': 'gps',
      };

      final response = await apiClient.postJson(
        '/api/student/update-location',
        locationData,
      );

      return response;
    } catch (e) {
      print('❌ [LocationService] خطأ في إرسال الموقع للسيرفر: $e');
      return null;
    }
  }

  /// عرض حوار تفعيل خدمة الموقع
  void _showLocationServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفعيل خدمة الموقع'),
        content: const Text(
          'خدمة الموقع غير مفعلة.\nيرجى تفعيلها لعرض الدورات حسب منطقتك.',
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

  /// عرض حوار فتح إعدادات التطبيق
  void _showOpenSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('صلاحية الموقع مطلوبة'),
        content: const Text(
          'تم رفض صلاحية الموقع نهائياً.\nيرجى تفعيلها من إعدادات التطبيق لعرض الدورات حسب منطقتك.',
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

  /// إيقاف تحديثات الموقع
  void stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationStatusCheckTimer?.cancel();
    _locationUpdateTimer = null;
    _locationStatusCheckTimer = null;
  }

  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }
}
