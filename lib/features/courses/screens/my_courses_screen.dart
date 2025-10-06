import 'package:flutter/material.dart';
import 'package:newgraduate/widgets/main_card.dart';
import 'package:newgraduate/widgets/custom_loading_widget.dart';
import 'package:newgraduate/services/courses_service.dart';
import 'package:newgraduate/services/cache_manager.dart';
import 'package:newgraduate/services/token_expired_handler.dart';
import 'package:newgraduate/features/courses/screens/course_detail_screen.dart';
import 'package:newgraduate/services/location_service.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  bool _isLoading = false;
  List<dynamic> _studentCourses = [];

  @override
  void initState() {
    super.initState();
    _initializeCache();
    _loadStudentCourses();
  }

  /// تهيئة نظام الكاش
  Future<void> _initializeCache() async {
    await CacheManager.instance.initialize();
    print('✅ تم تهيئة نظام الكاش لصفحة دوراتي');
  }

  Future<void> _loadStudentCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courses = await CoursesService.getStudentCourses();
      if (courses != null) {
        setState(() {
          _studentCourses = courses;
        });
      } else {
        // التحقق من انتهاء الجلسة عند فشل تحميل البيانات
        if (mounted &&
            await TokenExpiredHandler.handleTokenExpiration(context)) {
          return; // تم التعامل مع انتهاء التوكن
        }

        // إظهار رسالة خطأ عادية إذا لم تنته الجلسة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في تحميل الدورات. يرجى المحاولة مرة أخرى'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ خطأ في تحميل دورات الطالب: $e');

      // التحقق من انتهاء الجلسة في حالة الخطأ
      if (mounted &&
          await TokenExpiredHandler.handleTokenExpiration(
            context,
            errorMessage: e.toString(),
          )) {
        return; // تم التعامل مع انتهاء التوكن
      }

      // إظهار رسالة خطأ عادية
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshCourses() async {
    try {
      // حاول تحديث الموقع وطباعة الاستجابة قبل تحديث الدورات
      try {
        final resp = await LocationService().refreshLocationNow(silent: false);
        print('📨 [MyCourses] استجابة تحديث الموقع من زر التحديث: $resp');
      } catch (e) {
        print('⚠️ [MyCourses] تعذر تحديث الموقع قبل تحديث الدورات: $e');
      }

      final courses =
          await CoursesService.getStudentCourses(forceRefresh: true);
      if (courses != null) {
        setState(() {
          _studentCourses = courses;
        });
      } else {
        // التحقق من انتهاء الجلسة عند فشل التحديث
        if (mounted &&
            await TokenExpiredHandler.handleTokenExpiration(context)) {
          return; // تم التعامل مع انتهاء التوكن
        }

        // إظهار رسالة خطأ عادية
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في تحديث الدورات. يرجى المحاولة مرة أخرى'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ خطأ في تحديث دورات الطالب: $e');

      // التحقق من انتهاء الجلسة في حالة الخطأ
      if (mounted &&
          await TokenExpiredHandler.handleTokenExpiration(
            context,
            errorMessage: e.toString(),
          )) {
        return; // تم التعامل مع انتهاء التوكن
      }

      // إظهار رسالة خطأ عادية
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحديث: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// حساب النسبة المئوية للتقدم بناءً على البيانات المحفوظة في الكاش
  Future<int> _calculateLocalProgress(Map<String, dynamic> course) async {
    try {
      final courseId =
          course['course_id']?.toString() ?? course['id']?.toString();
      if (courseId == null)
        return course['progress']?['percentage']?.round() ?? 0;

      // الحصول على الفيديوهات من الكاش
      final cachedVideos = await CacheManager.instance.getVideos(courseId);
      if (cachedVideos == null || cachedVideos.isEmpty) {
        // إذا لم توجد بيانات في الكاش، استخدم البيانات من الخادم
        return course['progress']?['percentage']?.round() ?? 0;
      }

      // حساب النسبة بناءً على الفيديوهات المكتملة
      final totalVideos = cachedVideos.length;
      final completedVideos =
          cachedVideos.where((video) => video['is_completed'] == true).length;

      if (totalVideos == 0) return 0;

      final localPercentage = ((completedVideos / totalVideos) * 100).round();
      print(
          '📊 حساب النسبة المحلية للدورة $courseId: $completedVideos/$totalVideos = $localPercentage%');

      return localPercentage;
    } catch (e) {
      print('❌ خطأ في حساب النسبة المحلية: $e');
      // في حالة الخطأ، استخدم البيانات من الخادم
      return course['progress']?['percentage']?.round() ?? 0;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دوراتك'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCourses,
            tooltip: 'تحديث الدورات',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCourses,
        child: _buildOwnedCourses(),
      ),
    );
  }

  Widget _buildOwnedCourses() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_studentCourses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.video_library_outlined,
        title: 'لا توجد دورات مسجلة',
        subtitle: 'اشترك في دورة لتظهر هنا',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // تحديد العدد والنسبة وفق العرض (نقلل childAspectRatio لزيادة الارتفاع)
          int crossAxisCount;
          double childAspectRatio;

          if (constraints.maxWidth < 360) {
            crossAxisCount = 2;
            childAspectRatio = 0.66; // ارتفاع أكبر للشاشات الصغيرة جداً
          } else if (constraints.maxWidth < 420) {
            crossAxisCount = 2;
            childAspectRatio = 0.72; // ارتفاع جيد يمنع overflow
          } else if (constraints.maxWidth < 600) {
            crossAxisCount = 2;
            childAspectRatio = 0.8; // شاشات متوسطة
          } else {
            crossAxisCount = 3;
            childAspectRatio = 0.9; // شاشات كبيرة
          }

          // حساب عرض الكرت لاستعماله في قياس الصورة بشكل متجاوب
          final totalSpacing = (crossAxisCount - 1) * 16.0;
          final tileWidth =
              (constraints.maxWidth - totalSpacing) / crossAxisCount;
          final imageSize =
              tileWidth * 0.42; // صورة أصغر قليلاً لتخفيف الضغط عامودياً

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
            ),
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            itemCount: _studentCourses.length,
            itemBuilder: (context, index) {
              final course = _studentCourses[index];

              return FutureBuilder<int>(
                future: _calculateLocalProgress(course),
                builder: (context, snapshot) {
                  final percentage = snapshot.data ??
                      (course['progress']?['percentage']?.round() ?? 0);

                  // تحديد رمز التقدم بناءً على النسبة المئوية
                  String progressIcon;
                  if (percentage == 0) {
                    progressIcon = '🎯';
                  } else if (percentage < 25) {
                    progressIcon = '🟡';
                  } else if (percentage < 50) {
                    progressIcon = '🟠';
                  } else if (percentage < 75) {
                    progressIcon = '🔵';
                  } else if (percentage < 100) {
                    progressIcon = '🟢';
                  } else {
                    progressIcon = '✅';
                  }

                  return MainCard(
                    imageUrl: course['image_url'] ?? '',
                    title: course['title'] ?? 'بدون عنوان',
                    subtitle: '$progressIcon التقدم: ${percentage}%',
                    imageSize: imageSize,
                    onTap: () => _openCourse(course),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const CenterLoadingWidget(
      message: 'جاري التحميل...',
      size: 120,
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoKufiArabic',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'NotoKufiArabic',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openCourse(Map<String, dynamic> course) async {
    // إضافة معلومة أن الطالب يملك هذه الدورة
    final courseWithOwnership = Map<String, dynamic>.from(course);
    courseWithOwnership['isOwned'] = true;
    courseWithOwnership['isStudentCourse'] = true;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailScreen(
          course: courseWithOwnership,
        ),
      ),
    );

    // إذا كانت النتيجة تشير إلى تحديث، أعد تحميل البيانات
    if (result == true) {
      print('🔄 تم تحديث الدورة - إعادة تحميل البيانات');
      await _refreshCourses();
    }
  }
}
