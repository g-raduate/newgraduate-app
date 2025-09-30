import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationTestScreen extends StatefulWidget {
  const LocationTestScreen({super.key});

  @override
  State<LocationTestScreen> createState() => _LocationTestScreenState();
}

class _LocationTestScreenState extends State<LocationTestScreen> {
  String _status = 'لم يتم البدء';
  bool _testing = false;

  Future<void> _testLocation() async {
    setState(() {
      _testing = true;
      _status = 'بدء الاختبار...';
    });

    try {
      // اختبار 1: التحقق من تفعيل خدمة الموقع
      setState(() => _status = 'فحص خدمة الموقع...');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[LocationTest] Service enabled: $serviceEnabled');

      if (!serviceEnabled) {
        setState(() => _status = 'خدمة الموقع غير مفعلة');
        return;
      }

      // اختبار 2: فحص الصلاحيات
      setState(() => _status = 'فحص الصلاحيات...');
      var permission = await Geolocator.checkPermission();
      debugPrint('[LocationTest] Permission: $permission');

      if (permission == LocationPermission.denied) {
        setState(() => _status = 'طلب الصلاحية...');
        permission = await Geolocator.requestPermission();
        debugPrint('[LocationTest] Permission after request: $permission');
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _status = 'الصلاحية مرفوضة: $permission');
        return;
      }

      // اختبار 3: الحصول على الموقع
      setState(() => _status = 'الحصول على الموقع...');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() => _status = '''
تم الحصول على الموقع بنجاح!
خط العرض: ${position.latitude}
خط الطول: ${position.longitude}
الدقة: ${position.accuracy} متر
الوقت: ${position.timestamp}
''');
    } catch (e, stackTrace) {
      debugPrint('[LocationTest] Error: $e');
      debugPrint('[LocationTest] Stack: $stackTrace');
      setState(() => _status = 'خطأ: $e');
    } finally {
      setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار الموقع'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'حالة الاختبار:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testing ? null : _testLocation,
              child: _testing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('جاري الاختبار...'),
                      ],
                    )
                  : const Text('بدء اختبار الموقع'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'نصائح لحل مشاكل الموقع:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        '1. تأكد من تفعيل خدمة الموقع في إعدادات الجهاز'),
                    const Text('2. امنح التطبيق صلاحية الوصول للموقع'),
                    const Text('3. تأكد من وجود اتصال بالإنترنت أو GPS'),
                    const Text('4. جرب في مكان مفتوح إذا كنت تستخدم GPS'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
