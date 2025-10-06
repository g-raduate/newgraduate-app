import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:newgraduate/services/location_service.dart';
import 'package:newgraduate/features/courses/screens/my_courses_screen.dart';

class LocationAwareCoursesScreen extends StatefulWidget {
  const LocationAwareCoursesScreen({super.key});

  @override
  State<LocationAwareCoursesScreen> createState() =>
      _LocationAwareCoursesScreenState();
}

class _LocationAwareCoursesScreenState
    extends State<LocationAwareCoursesScreen> {
  @override
  void initState() {
    super.initState();
    // فحص حالة الموقع عند بدء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationService>().checkLocationStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationService>(
      builder: (context, locationService, child) {
        // إذا كان لدى المستخدم صلاحية الموقع، اعرض شاشة الدورات العادية
        if (locationService.canShowCourses) {
          return const MyCoursesScreen();
        }

        // إذا لم يكن لديه صلاحية، اعرض رسالة التفعيل
        return _buildLocationPermissionScreen(context, locationService);
      },
    );
  }

  Widget _buildLocationPermissionScreen(
      BuildContext context, LocationService locationService) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('دوراتك'),
        centerTitle: true,
        automaticallyImplyLeading: false, // إزالة زر الرجوع
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // تحديث الحالة أولاً ثم محاولة إرسال موقع محدث
              await locationService.checkLocationStatus();
              final resp = await locationService.refreshLocationNow();

              if (!mounted) return;

              String message = 'تم تحديث حالة الموقع';
              Color color = Colors.blue;
              if (resp != null) {
                message = '📍 تم إرسال موقعك بنجاح';
                color = Colors.green;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: color,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'تحديث حالة الموقع',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // أيقونة الموقع
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 48,
                  color: cs.onPrimaryContainer,
                ),
              ),

              const SizedBox(height: 24),

              // العنوان الرئيسي
              Text(
                'تفعيل ميزة الموقع',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // النص التوضيحي
              Text(
                'قم بتفعيل ميزة الموقع لعرض دوراتك حسب منطقتك',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // النص التفصيلي
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: cs.primary,
                      size: 20,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'نحتاج لمعرفة موقعك لنتمكن من عرض الدورات المناسبة لمنطقتك وإرسال إشعارات الدورات الجديدة القريبة منك',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // زر تفعيل الموقع
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () async {
                    // إظهار حالة التحميل
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('جاري تفعيل ميزة الموقع...'),
                          ],
                        ),
                        backgroundColor: Colors.blue,
                        duration: Duration(seconds: 30),
                      ),
                    );

                    try {
                      final granted = await locationService
                          .requestLocationPermission(context);

                      // إخفاء رسالة التحميل
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();

                      if (granted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ تم تفعيل الموقع بنجاح'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❌ فشل في تفعيل ميزة الموقع'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      // إخفاء رسالة التحميل
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();

                      print('❌ خطأ في تفعيل الموقع: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ حدث خطأ: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('تفعيل ميزة الموقع'),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // مميزات إضافية
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'مميزات ميزة الموقع:',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• عرض الدورات حسب منطقتك\n• إشعارات للدورات الجديدة القريبة\n• تخصيص المحتوى حسب موقعك',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade700,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
