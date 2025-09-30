import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:newgraduate/providers/simple_theme_provider.dart';
import 'package:newgraduate/config/app_constants.dart';
import 'package:newgraduate/services/api_headers_manager.dart';
import 'package:newgraduate/services/cache_manager.dart';
import 'package:newgraduate/services/token_expired_handler.dart';
import 'package:newgraduate/services/courses_service.dart';
import 'package:newgraduate/services/price_status_service.dart';
import 'package:newgraduate/widgets/smart_youtube_player_manager.dart';
import 'package:newgraduate/widgets/user_info_dialog.dart';
import 'package:newgraduate/widgets/custom_loading_widget.dart';
import 'package:newgraduate/services/player_cache_service.dart';
import 'package:newgraduate/features/courses/screens/summary_viewer_screen.dart';
import 'package:newgraduate/features/courses/screens/course_purchase_screen.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseDetailScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  static const int _expectedTabs = 3;
  late TabController _tabController;
  List<dynamic> videos = [];
  List<dynamic> summaries = [];
  bool isLoadingVideos = true;
  bool isLoadingSummaries = true;
  String? videosError;
  String? summariesError;
  Set<String> loadingVideoIds = {}; // متتبع حالة التحميل للفيديوهات
  bool _hasChanges = false; // متتبع التحديثات لإبلاغ الصفحة السابقة
  bool _isEnrollingInFreeCourse =
      false; // متتبع حالة التسجيل في الدورة المجانية

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _expectedTabs, vsync: this);
    _initializeCache();
    _loadCourseData();
  }

  /// تهيئة نظام الكاش
  Future<void> _initializeCache() async {
    await CacheManager.instance.initialize();
    print('✅ تم تهيئة نظام الكاش لصفحة تفاصيل الدورة');
  }

  @override
  void didUpdateWidget(covariant CourseDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إذا تغيّر عدد التبويبات بفعل Hot Reload/تعديلات، نعيد إنشاء المتحكم
    if (_tabController.length != _expectedTabs) {
      _tabController.dispose();
      _tabController = TabController(length: _expectedTabs, vsync: this);
    }
  }

  @override
  void reassemble() {
    // يُستدعى في Hot Reload (debug فقط)
    super.reassemble();
    if (_tabController.length != _expectedTabs) {
      _tabController.dispose();
      _tabController = TabController(length: _expectedTabs, vsync: this);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseData() async {
    await Future.wait([
      _loadVideos(forceRefresh: true),
      _loadSummaries(forceRefresh: true),
    ]);
  }

  Future<void> _loadVideos({bool forceRefresh = false}) async {
    try {
      setState(() {
        isLoadingVideos = true;
        videosError = null;
      });

      final courseId = widget.course['course_id'] ?? widget.course['id'];
      final isStudentCourse = widget.course['isStudentCourse'] == true;

      // إذا كانت دورة الطالب وتحتوي على فيديوهات مرفقة، تحقق من الكاش أولاً
      if (isStudentCourse && widget.course['videos'] != null && !forceRefresh) {
        // تحقق من الكاش أولاً حتى لو كانت دورة طالب
        print('🔍 دورة طالب - التحقق من الكاش أولاً للدورة: $courseId');
        List<dynamic>? cachedVideos =
            await CacheManager.instance.getVideos(courseId.toString());

        if (cachedVideos != null) {
          print(
              '✅ تم العثور على ${cachedVideos.length} فيديو محدث في الكاش (دورة طالب)');
          setState(() {
            videos = cachedVideos;
            isLoadingVideos = false;
          });
          return;
        } else {
          print(
              'ℹ️ لا توجد فيديوهات في الكاش - استخدام البيانات المرفقة (دورة طالب)');
        }
      }

      // إذا لم يوجد كاش أو كان التحديث إجباري، استخدم البيانات المرفقة لدورة الطالب
      if (isStudentCourse && widget.course['videos'] != null) {
        final courseVideos = widget.course['videos'] as List<dynamic>;
        print(
            '🎥 استخدام فيديوهات الدورة المرسلة مع البيانات: ${courseVideos.length}');

        setState(() {
          videos = courseVideos;
          isLoadingVideos = false;
        });

        // حفظ في الكاش
        await CacheManager.instance
            .setVideos(courseId.toString(), courseVideos);
        return;
      }

      // محاولة تحميل البيانات من الكاش أولاً (إلا إذا كان التحديث إجباري)
      if (!forceRefresh) {
        print('🔍 البحث عن فيديوهات في الكاش للدورة: $courseId');
        List<dynamic>? cachedVideos =
            await CacheManager.instance.getVideos(courseId.toString());

        if (cachedVideos != null) {
          print('✅ تم العثور على ${cachedVideos.length} فيديو في الكاش');
          // طباعة حالة أول فيديو للتحقق
          if (cachedVideos.isNotEmpty) {
            final firstVideo = cachedVideos.first;
            print(
                '🎥 أول فيديو في الكاش: ${firstVideo['title']} - مكتمل: ${firstVideo['is_completed']}');
          }

          setState(() {
            videos = cachedVideos;
            isLoadingVideos = false;
          });
          print('✅ تم تحميل ${cachedVideos.length} فيديو من الكاش');
          return;
        } else {
          print('ℹ️ لا توجد فيديوهات في الكاش للدورة: $courseId');
        }
      } else {
        print('🔄 تحديث إجباري - تجاهل الكاش وتحميل من السيرفر');
      }

      // إذا لم توجد في الكاش، قم بجلبها من API
      final url =
          '${AppConstants.baseUrl}/api/courses/$courseId/videos/previews';
      print('🎥 جاري تحميل فيديوهات المعاينة من API: $url');

      final headers = await ApiHeadersManager.instance.getAuthHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      print('📊 استجابة الفيديوهات: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        print('✅ نوع البيانات المستلمة: ${responseData.runtimeType}');

        // طباعة تفصيلية لكل فيديو (معطلة لتقليل الطباعة)
        if (responseData is List) {
          // print('📝 عدد الفيديوهات في الاستجابة: ${responseData.length}');
          // for (int i = 0; i < responseData.length; i++) {
          //   final video = responseData[i];
          //   print('🎬 فيديو ${i + 1}:');
          //   print('  - العنوان: ${video['title']}');
          //   print('  - مجاني: ${video['is_free']}');
          //   print('  - الرابط: ${video['link']}');
          //   print('  - جميع المفاتيح: ${video.keys.toList()}');
          //   print('  - البيانات الكاملة: $video');
          //   print('  ---');
          // }
        } else if (responseData is Map<String, dynamic>) {
          print('📝 بيانات على شكل Map: ${responseData.keys.toList()}');
          if (responseData.containsKey('data')) {
            final videosList = responseData['data'];
            print('📝 عدد الفيديوهات في data: ${videosList?.length ?? 0}');
          }
        }

        List<dynamic> finalVideos;

        if (responseData is List) {
          finalVideos = responseData;
        } else if (responseData is Map<String, dynamic>) {
          finalVideos = responseData['data'] ?? [];
        } else {
          throw Exception('تنسيق غير متوقع للبيانات');
        }

        // حفظ البيانات في الكاش
        await CacheManager.instance.setVideos(courseId.toString(), finalVideos);
        print('💾 تم حفظ ${finalVideos.length} فيديو في الكاش');

        setState(() {
          videos = finalVideos;
          isLoadingVideos = false;
        });

        print('🎥 إجمالي الفيديوهات المحملة: ${videos.length}');
      } else {
        print('❌ فشل في تحميل الفيديوهات: ${response.statusCode}');
        print('❌ Response: ${response.body}');

        // التحقق من انتهاء الجلسة
        if (mounted &&
            await TokenExpiredHandler.handleTokenExpiration(
              context,
              statusCode: response.statusCode,
              errorMessage: response.body,
            )) {
          return; // تم التعامل مع انتهاء التوكن
        }

        throw Exception('فشل في تحميل الفيديوهات: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في تحميل الفيديوهات: $e');

      // التحقق من انتهاء الجلسة في حالة الخطأ
      if (mounted &&
          await TokenExpiredHandler.handleTokenExpiration(
            context,
            errorMessage: e.toString(),
          )) {
        return; // تم التعامل مع انتهاء التوكن
      }

      if (mounted) {
        setState(() {
          videosError = e.toString();
          isLoadingVideos = false;
          videos = [];
        });
      }
    }
  }

  Future<void> _loadSummaries({bool forceRefresh = false}) async {
    try {
      setState(() {
        isLoadingSummaries = true;
        summariesError = null;
      });

      final courseId = widget.course['course_id'] ?? widget.course['id'];

      // محاولة تحميل البيانات من الكاش أولاً (إلا إذا كان التحديث إجباري)
      if (!forceRefresh) {
        print('🔍 البحث عن ملخصات في الكاش للدورة: $courseId');
        List<dynamic>? cachedSummaries =
            await CacheManager.instance.getSummaries(courseId.toString());

        if (cachedSummaries != null) {
          setState(() {
            summaries = cachedSummaries;
            isLoadingSummaries = false;
          });
          print('✅ تم تحميل ${cachedSummaries.length} ملخص من الكاش');
          return;
        }
      } else {
        print('🔄 تحديث إجباري للملخصات - تجاهل الكاش');
      }

      // إذا لم توجد في الكاش، قم بجلبها من API
      final url = '${AppConstants.baseUrl}/api/courses/$courseId/summaries';
      print('📄 جاري تحميل الملخصات من API: $url');

      final headers = await ApiHeadersManager.instance.getAuthHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      print('📊 استجابة الملخصات: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        print('✅ نوع بيانات الملخصات: ${responseData.runtimeType}');

        List<dynamic> finalSummaries;

        if (responseData is List) {
          finalSummaries = responseData;
        } else if (responseData is Map<String, dynamic>) {
          finalSummaries = responseData['data'] ?? [];
        } else {
          throw Exception('تنسيق غير متوقع للبيانات');
        }

        // حفظ البيانات في الكاش
        await CacheManager.instance
            .setSummaries(courseId.toString(), finalSummaries);
        print('💾 تم حفظ ${finalSummaries.length} ملخص في الكاش');

        setState(() {
          summaries = finalSummaries;
          isLoadingSummaries = false;
        });

        print('📄 تم تحميل ${summaries.length} ملخص');
      } else {
        print('❌ فشل في تحميل الملخصات: ${response.statusCode}');
        print('❌ Response: ${response.body}');

        // التحقق من انتهاء الجلسة
        if (mounted &&
            await TokenExpiredHandler.handleTokenExpiration(
              context,
              statusCode: response.statusCode,
              errorMessage: response.body,
            )) {
          return; // تم التعامل مع انتهاء التوكن
        }

        throw Exception('فشل في تحميل الملخصات: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في تحميل الملخصات: $e');

      // التحقق من انتهاء الجلسة في حالة الخطأ
      if (mounted &&
          await TokenExpiredHandler.handleTokenExpiration(
            context,
            errorMessage: e.toString(),
          )) {
        return; // تم التعامل مع انتهاء التوكن
      }

      if (mounted) {
        setState(() {
          summariesError = e.toString();
          isLoadingSummaries = false;
          summaries = [];
        });
      }
    }
  }

  Future<void> _openVideoLink(String videoLink, String videoTitle) async {
    try {
      // التحقق من أن الرابط يحتوي على YouTube
      if (videoLink.contains('youtube.com') || videoLink.contains('youtu.be')) {
        // التحقق من معلومات المستخدم أولاً
        final hasUserInfo = await showUserInfoDialog(context);
        if (!hasUserInfo) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    const Text('يجب إدخال معلومات المستخدم لمشاهدة الفيديو'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }

        // فتح المشغل الذكي الجديد - يحدد المشغل المناسب من قاعدة البيانات
        if (mounted) {
          final smartPlayer = VideoPlayerHelper.createSmartPlayer(
            videoUrl: videoLink,
            videoTitle: videoTitle,
            allowRotation:
                true, // السماح بالدوران للوضع الأفقي لمحاضرات الدورات
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => smartPlayer,
              fullscreenDialog: true, // للحصول على تجربة أفضل
            ),
          );
        }
      } else {
        // للروابط الأخرى، استخدم المتصفح الخارجي
        final uri = Uri.parse(videoLink);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'لا يمكن فتح الرابط: $videoLink';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onError,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('خطأ في فتح الرابط: $e'),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// تبديل حالة إكمال الفيديو للطالب
  Future<void> _toggleVideoCompletion(
      String videoId, bool currentStatus) async {
    // إضافة الفيديو لقائمة التحميل
    setState(() {
      loadingVideoIds.add(videoId);
    });

    try {
      print('=' * 50);
      print('🔄 بدء تبديل حالة إكمال الفيديو');
      print('🔄 تبديل حالة إكمال الفيديو: $videoId من $currentStatus');
      print('🕐 الوقت: ${DateTime.now()}');
      print('=' * 30);

      final String apiUrl =
          '${AppConstants.baseUrl}/api/videos/$videoId/toggle';
      final headers = await ApiHeadersManager.instance.getAuthHeaders();

      print('📡 إرسال طلب إلى: $apiUrl');
      print('📋 Headers المُرسلة: $headers');
      print('🎯 معرف الفيديو: $videoId');
      print('📊 الحالة الحالية: $currentStatus');

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('📊 كود الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ تم تحديث حالة الفيديو بنجاح');
        print('📄 محتوى الاستجابة الكامل: ${response.body}');
        print('📋 headers الاستجابة: ${response.headers}');

        // فك تشفير الاستجابة للحصول على الكويزات
        final responseData = json.decode(response.body);
        print('🔍 تحليل response data:');
        print('   - نوع البيانات: ${responseData.runtimeType}');
        print('   - المفاتيح المتاحة: ${responseData.keys}');
        print('   - البيانات الكاملة: $responseData');

        // طباعة تفصيلية للكويزات إن وجدت
        if (responseData['available_quizzes'] != null) {
          print('🎯 الكويزات المتاحة:');
          final quizzes = responseData['available_quizzes'] as List;
          for (int i = 0; i < quizzes.length; i++) {
            print('   كويز ${i + 1}: ${quizzes[i]}');
          }
        } else {
          print('ℹ️ لا توجد كويزات متاحة في الاستجابة');
        }

        // تحديث حالة الفيديو محلياً
        setState(() {
          final videoIndex = videos.indexWhere((v) => v['id'] == videoId);
          if (videoIndex != -1) {
            final oldStatus = videos[videoIndex]['is_completed'];
            videos[videoIndex]['is_completed'] = !currentStatus;
            print(
                '🔄 تحديث حالة الفيديو $videoId: $oldStatus → ${!currentStatus}');
            print('📝 بيانات الفيديو المحدث: ${videos[videoIndex]}');
          } else {
            print('❌ لم يتم العثور على الفيديو $videoId في القائمة المحلية');
          }
        });

        // تسجيل أن هناك تحديثات
        _hasChanges = true;

        // تحديث الكاش بالبيانات المحدثة
        try {
          final courseId = widget.course['course_id']?.toString() ??
              widget.course['id']?.toString();
          print('🔍 معرف الدورة للكاش: $courseId');
          print('🔍 معلومات الدورة الكاملة: ${widget.course}');

          if (courseId != null) {
            print('📦 عدد الفيديوهات قبل حذف الكاش: ${videos.length}');

            // حذف البيانات القديمة من الكاش أولاً (استخدام نفس المفتاح المستخدم في setVideos)
            final deleteResult = await CacheManager.instance
                .removeCache('course_$courseId', type: CacheType.videos);
            print('🗑️ نتيجة حذف الكاش القديم: $deleteResult');

            // ثم حفظ البيانات الجديدة
            final saveResult =
                await CacheManager.instance.setVideos(courseId, videos);
            print('💾 نتيجة حفظ الكاش الجديد: $saveResult');
            print('💾 تم تحديث الكاش بحالة الفيديو الجديدة للدورة: $courseId');
            print('🔍 عدد الفيديوهات في الكاش المحدث: ${videos.length}');

            // تحقق فوري من الكاش
            final verifyCache = await CacheManager.instance.getVideos(courseId);
            if (verifyCache != null) {
              print(
                  '✅ تم التحقق من الكاش - عدد الفيديوهات: ${verifyCache.length}');
              final targetVideo = verifyCache
                  .firstWhere((v) => v['id'] == videoId, orElse: () => null);
              if (targetVideo != null) {
                print(
                    '✅ حالة الفيديو $videoId في الكاش: ${targetVideo['is_completed']}');
              } else {
                print('❌ لم يتم العثور على الفيديو $videoId في الكاش');
              }
            } else {
              print('❌ فشل في استرجاع البيانات من الكاش للتحقق');
            }
          } else {
            print('❌ معرف الدورة غير متوفر للكاش');
          }
        } catch (e) {
          print('❌ خطأ في تحديث الكاش: $e');
        }

        // إظهار رسالة نجاح
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    !currentStatus ? Icons.check_circle : Icons.cancel,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(!currentStatus
                      ? 'تم تسجيل الفيديو كمكتمل'
                      : 'تم إلغاء تسجيل الفيديو كمكتمل'),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // التحقق من وجود كويزات متاحة
        if (responseData['available_quizzes'] != null &&
            responseData['available_quizzes'].isNotEmpty &&
            !currentStatus) {
          // فقط عند إكمال الفيديو وليس إلغاء الإكمال

          final availableQuizzes = responseData['available_quizzes'] as List;
          print('🎯 تم العثور على ${availableQuizzes.length} كويز متاح');

          // عرض الكويزات واحد تلو الآخر
          for (int i = 0; i < availableQuizzes.length; i++) {
            await _showQuizDialog(availableQuizzes[i], videoId: videoId);
            // العداد موجود الآن داخل كل كويز
          }
        }

        // لا حاجة لإعادة تحميل البيانات لأن الحالة تم تحديثها محلياً وفي الكاش
        // _loadVideos(); // تم حذفها لتجنب فقدان التحديثات

        print('=' * 30);
        print('✅ تم إنهاء عملية تبديل حالة الفيديو بنجاح');
        print('🕐 الوقت: ${DateTime.now()}');
        print('=' * 50);
      } else {
        print('❌ فشل في تحديث حالة الفيديو');
        print('📊 كود الاستجابة: ${response.statusCode}');
        print('📄 محتوى الاستجابة: ${response.body}');
        print('📋 headers الاستجابة: ${response.headers}');
        throw Exception('فشل في تحديث حالة الفيديو: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في تبديل حالة إكمال الفيديو: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onError,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('خطأ في تحديث حالة الفيديو: $e'),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // إزالة الفيديو من قائمة التحميل
      if (mounted) {
        setState(() {
          loadingVideoIds.remove(videoId);
        });
      }
    }
  }

  /// دالة التسجيل في الدورة المجانية
  Future<void> _enrollInFreeCourse() async {
    try {
      setState(() {
        _isEnrollingInFreeCourse = true;
      });

      // الحصول على student_id من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getString('student_id');

      if (studentId == null) {
        throw Exception('لم يتم العثور على معرف الطالب');
      }

      final courseId = widget.course['course_id'] ?? widget.course['id'];
      if (courseId == null) {
        throw Exception('معرف الدورة غير متوفر');
      }

      print(
          '🎓 بدء التسجيل في الدورة المجانية - student_id: $studentId, course_id: $courseId');

      final url =
          '${AppConstants.baseUrl}/api/students/$studentId/enroll-free-course';
      final headers = await ApiHeadersManager.instance.getAuthHeaders();

      final body = json.encode({
        'course_id': courseId.toString(),
      });

      print('🚀 إرسال طلب التسجيل إلى: $url');
      print('📤 البيانات المرسلة: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('📊 استجابة التسجيل: ${response.statusCode}');
      print('📄 محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final success = responseData['success'] ?? false;
        final message = responseData['message'] ?? 'تم التسجيل بنجاح!';

        if (success) {
          print('✅ تم التسجيل في الدورة المجانية بنجاح');

          // تحديث حالة الدورة لتصبح مملوكة
          setState(() {
            widget.course['isOwned'] = true;
          });

          // تحديث كاش دورات الطالب لإظهار الدورة الجديدة فوراً
          await _updateStudentCoursesCache();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(message)),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          throw Exception(message);
        }
      } else {
        // معالجة أخطاء HTTP
        final responseData = json.decode(response.body);
        final errorMessage = responseData['message'] ?? 'حدث خطأ في التسجيل';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ خطأ في التسجيل في الدورة المجانية: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('خطأ في التسجيل: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEnrollingInFreeCourse = false;
        });
      }
    }
  }

  /// تحديث كاش دورات الطالب بعد إضافة دورة جديدة
  Future<void> _updateStudentCoursesCache() async {
    try {
      print('🔄 تحديث كاش دورات الطالب...');

      // إجبار تحديث دورات الطالب لإظهار الدورة الجديدة
      await CoursesService.getStudentCourses(forceRefresh: true);

      print('✅ تم تحديث كاش دورات الطالب بنجاح');
    } catch (e) {
      print('⚠️ خطأ في تحديث كاش دورات الطالب: $e');
      // لا نعرض رسالة خطأ للمستخدم لأن التسجيل نجح
    }
  }

  /// عرض كويز في نافذة منبثقة مع نظام محسن
  Future<void> _showQuizDialog(Map<String, dynamic> quiz,
      {String? videoId}) async {
    final quizTitle = quiz['title'] ?? 'كويز';
    final question = quiz['question'] ?? '';
    final options = quiz['options'] as List? ?? [];
    final correctAnswer = quiz['correct_answer'] ?? 0;
    final courseId = widget.course['id']?.toString();

    print('🎮 عرض الكويز: $quizTitle');

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _QuizDialog(
          quizTitle: quizTitle,
          question: question,
          options: options,
          correctAnswer: correctAnswer,
          courseId: courseId,
          videoId: videoId,
        );
      },
    );
  }

  /// تحديث بيانات الدورة (مسح الكاش وإعادة التحميل)
  Future<void> _refreshCourseData() async {
    try {
      final courseId = widget.course['course_id']?.toString() ??
          widget.course['id']?.toString();

      if (courseId != null) {
        print('🔄 بدء تحديث بيانات الدورة $courseId');

        // مسح الكاش القديم
        await CacheManager.instance.clearVideosCache(courseId);
        await CacheManager.instance.clearSummariesCache(courseId);
        print('🗑️ تم مسح الكاش للدورة $courseId');

        // تحديث إعدادات المشغل من الـ API (تحديث الكاش المتعلق بالمشغل)
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('جاري تحديث إعدادات المشغل من الخادم...')),
          );
          await PlayerCacheService.forceUpdateFromAPI();
          print('✅ تم تحديث كاش المشغل من الـ API');
        } catch (e) {
          print('⚠️ فشل تحديث كاش المشغل من الـ API: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('فشل تحديث إعدادات المشغل: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }

        // إعادة تحميل البيانات
        await _loadCourseData();

        // إظهار رسالة نجاح
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('تم تحديث البيانات بنجاح')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ خطأ في تحديث البيانات: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحديث البيانات: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.course['title'] ?? 'تفاصيل الدورة',
          style: const TextStyle(
            fontFamily: 'NotoKufiArabic',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // إرجاع قيمة عند الخروج إذا كان هناك تحديثات
            Navigator.of(context).pop(_hasChanges);
          },
        ),
        actions: [
          // زر التحديث
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _refreshCourseData,
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: Column(
        children: [
          // صورة الدورة الكبيرة مع إمكانية تشغيل الفيديو الترويجي
          GestureDetector(
            onTap: () {
              final promoVideoUrl = widget.course['promo_video_url'];
              if (promoVideoUrl != null &&
                  promoVideoUrl.toString().isNotEmpty) {
                _openVideoLink(promoVideoUrl.toString(),
                    'فيديو ترويجي - ${widget.course['title'] ?? 'الدورة'}');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('لا يوجد فيديو ترويجي متاح لهذه الدورة'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Container(
              height: screenHeight * 0.3,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                image: widget.course['image_url'] != null &&
                        widget.course['image_url'].toString().isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(widget.course['image_url']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: widget.course['image_url'] != null &&
                          widget.course['image_url'].toString().isNotEmpty
                      ? LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.3),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.9),
                            Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.7),
                          ],
                        ),
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      size: 50,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // اسم الدورة
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.course['title'] ?? 'اسم الدورة',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          // زر الشراء أو التسجيل حسب نوع الدورة
          Consumer<SimpleThemeProvider>(
            builder: (context, themeProvider, child) {
              final isOwned = widget.course['isOwned'] == true ||
                  widget.course['id'] == null;
              final isFreeCourseByCourse =
                  widget.course['is_free_course'] == true;

              if (isOwned) {
                return const SizedBox
                    .shrink(); // لا يظهر شيء إذا كانت الدورة مملوكة
              }

              // للدورات المجانية: عرض "مجاناً" وزر "إضافة الدورة"
              if (isFreeCourseByCourse) {
                return Column(
                  children: [
                    // كلمة "مجاناً"
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'مجاناً',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontFamily: 'NotoKufiArabic',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // زر إضافة الدورة
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 4),
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: _isEnrollingInFreeCourse
                              ? null
                              : _enrollInFreeCourse,
                          icon: _isEnrollingInFreeCourse
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                ),
                          label: Text(
                            _isEnrollingInFreeCourse
                                ? 'جاري التسجيل...'
                                : 'إضافة الدورة',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'NotoKufiArabic',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            elevation: 3,
                            shadowColor: Colors.green.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // للدورات المدفوعة: زر الشراء العادي (مع فحص حالة إظهار الأسعار)
              return FutureBuilder<bool>(
                future: PriceStatusService.shouldShowPrices(),
                builder: (context, snapshot) {
                  // في حالة التحميل أو الخطأ، لا نعرض الزر
                  if (!snapshot.hasData || snapshot.data != true) {
                    return const SizedBox.shrink(); // لا نعرض أي شيء
                  }

                  // إذا كانت الحالة true، نعرض زر الشراء
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                    child: SizedBox(
                      height: 40, // ارتفاع أصغر
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // التوجه إلى صفحة تفاصيل الشراء
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CoursePurchaseScreen(course: widget.course),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.shopping_cart_outlined,
                          size: 18, // أيقونة أصغر
                        ),
                        label: const Text(
                          'شراء الدورة',
                          style: TextStyle(
                            fontSize: 14, // خط أصغر
                            fontWeight: FontWeight.w600,
                            fontFamily: 'NotoKufiArabic',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20), // أكثر بيضاوية
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          elevation: 3,
                          shadowColor:
                              themeProvider.primaryColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // الأزرار (للدورات المجانية) أو التبويبات (للدورات العادية)
          widget.course['is_free_course'] == true
              ? _buildButtonsLayout()
              : _buildTabsLayout(),

          // محتوى الدورة
          Expanded(
            child: widget.course['is_free_course'] == true
                ? RefreshIndicator(
                    onRefresh: _refreshCourseData,
                    child:
                        _buildVideosTab(), // الدورات المجانية تعرض الفيديوهات مباشرة
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // تبويبة الفيديوهات
                      RefreshIndicator(
                        onRefresh: _refreshCourseData,
                        child: _buildVideosTab(),
                      ),
                      // تبويبة الملخصات
                      RefreshIndicator(
                        onRefresh: _refreshCourseData,
                        child: _buildSummariesTab(),
                      ),
                      // تبويبة معلومات الدورة
                      RefreshIndicator(
                        onRefresh: _refreshCourseData,
                        child: _buildCourseInfoTab(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideosTab() {
    if (isLoadingVideos) {
      return ListLoadingWidget(
        message: 'جاري تحميل الفيديوهات...',
        size: 120,
        topPadding: MediaQuery.of(context).size.height * 0.2,
      );
    }

    if (videos.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  videosError != null
                      ? Icons.error_outline
                      : Icons.video_library_outlined,
                  size: 64,
                  color: videosError != null
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  videosError != null
                      ? 'فشل في تحميل الفيديوهات'
                      : 'لا توجد فيديوهات متاحة',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: videosError != null
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (videosError != null) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _loadVideos(forceRefresh: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        // التحقق من حالة الفيديو: إذا كان له رابط فهو متاح، وإلا فهو مقفل
        final hasLink = video['link'] != null &&
            video['link'].toString().isNotEmpty &&
            video['link'] != 'null';
        final isFree = video['is_free'] == true ||
            video['is_free'] == 1 ||
            hasLink; // اعتبار الفيديو مجاني إذا كان له رابط

        // تحديد إذا كان الطالب يملك الدورة
        final isOwned = widget.course['isOwned'] == true ||
            widget.course['isStudentCourse'] == true;

        // للدورات المجانية: الفيديو متاح فقط إذا كان له رابط (مثل الدورات المدفوعة)
        final isFreeCourseByCourse = widget.course['is_free_course'] == true;
        final isVideoAvailable = isFreeCourseByCourse
            ? hasLink // الدورات المجانية: متاح فقط مع رابط
            : (isOwned || isFree || hasLink); // الدورات المدفوعة: المنطق الحالي

        // التحقق من حالة إكمال الفيديو
        final isCompleted =
            video['is_completed'] == true || video['is_completed'] == 1;

        // طباعة تشخيصية للدورات المجانية
        if (isFreeCourseByCourse && index < 3) {
          // طباعة أول 3 فيديوهات فقط
          print(
              '🎬 دورة مجانية - فيديو ${index + 1}: ${video['title']} - hasLink: $hasLink - isAvailable: $isVideoAvailable - link: ${video['link']}');
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 28,
              ),
            ),
            title: Text(
              video['title'] ?? 'فيديو ${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration:
                    isCompleted && isOwned ? TextDecoration.lineThrough : null,
                color: isCompleted && isOwned
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : null,
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  isVideoAvailable ? 'متاح للمشاهدة' : 'غير متاح',
                  style: TextStyle(
                    color: isVideoAvailable
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isVideoAvailable) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      // تحديد النص المناسب بناءً على نوع الدورة
                      isFreeCourseByCourse
                          ? 'متاح' // للدورات المجانية
                          : (isOwned ? 'مملوك' : 'مجاني'), // للدورات المدفوعة
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Checkbox للدورات المملوكة أو المجانية المتاحة
                if ((isOwned && !isFreeCourseByCourse) ||
                    (isFreeCourseByCourse && isVideoAvailable)) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: loadingVideoIds.contains(video['id']?.toString())
                        ? null
                        : () async {
                            // Diagnostic log to help find issues with the first item
                            final videoId = video['id']?.toString();
                            print(
                                '🔔 tapped video index=$index id=$videoId title=${video['title']} isCompleted=$isCompleted');

                            if (videoId != null) {
                              // Normal flow: toggle via API
                              _toggleVideoCompletion(videoId, isCompleted);
                            } else {
                              // Fallback: some data sources (e.g. attached course videos)
                              // may not include an 'id'. Allow a local toggle so the UI
                              // responds immediately and update cache if possible.
                              setState(() {
                                videos[index]['is_completed'] = !isCompleted;
                              });

                              // try to update cache for the current course if available
                              try {
                                final courseId =
                                    widget.course['course_id']?.toString() ??
                                        widget.course['id']?.toString();
                                if (courseId != null) {
                                  await CacheManager.instance
                                      .setVideos(courseId, videos);
                                  print(
                                      '💾 saved local toggle to cache for course $courseId (index $index)');
                                }
                              } catch (e) {
                                print(
                                    '❌ failed to save local toggle to cache: $e');
                              }

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Text(
                                                'تم تحديث حالة الفيديو محلياً (معرف الفيديو غير متوفر)')),
                                      ],
                                    ),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: loadingVideoIds.contains(video['id']?.toString())
                            ? Theme.of(context).colorScheme.outline
                            : isCompleted
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: loadingVideoIds.contains(video['id']?.toString())
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.check,
                              color: isCompleted
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Colors.transparent,
                              size: 16,
                            ),
                    ),
                  ),
                ],
                // أيقونة القفل للفيديوهات غير المتاحة
                if ((!isOwned && !isFreeCourseByCourse) ||
                    (isFreeCourseByCourse && !isVideoAvailable)) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isVideoAvailable
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1)
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isVideoAvailable ? Icons.lock_open : Icons.lock,
                      color: isVideoAvailable
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
            onTap: () {
              if (isVideoAvailable) {
                // إذا كان هناك رابط حقيقي، افتحه
                if (hasLink) {
                  _openVideoLink(video['link'], video['title']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.play_circle_filled,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('فتح فيديو: ${video['title']}'),
                          ),
                        ],
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else if (isOwned && !isFreeCourseByCourse) {
                  // إذا كان الطالب يملك الدورة المدفوعة لكن لا يوجد رابط، أظهر رسالة مناسبة
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                                'هذا الفيديو متاح لك - سيتم إضافة الرابط قريباً'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } else {
                // فيديو غير متاح
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Icons.lock,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(isFreeCourseByCourse
                              ? 'هذا الفيديو غير متاح حالياً - لا يوجد رابط'
                              : 'هذا الفيديو غير متاح حالياً'),
                        ),
                      ],
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSummariesTab() {
    return Consumer<SimpleThemeProvider>(
      builder: (context, themeProvider, child) {
        // التحقق من ملكية الدورة
        final isOwned =
            widget.course['isOwned'] == true || widget.course['id'] == null;

        // إذا لم تكن الدورة مملوكة، عرض رسالة القفل
        if (!isOwned) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: themeProvider.isDarkMode
                      ? Colors.white30
                      : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'الملخصات مقفولة',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: themeProvider.isDarkMode
                            ? Colors.white70
                            : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'هذا المحتوى غير متاح حالياً',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: themeProvider.isDarkMode
                            ? Colors.white54
                            : Colors.grey[500],
                      ),
                ),
              ],
            ),
          );
        }

        if (isLoadingSummaries) {
          return ListLoadingWidget(
            message: 'جاري تحميل الملخصات...',
            size: 120,
            topPadding: MediaQuery.of(context).size.height * 0.2,
          );
        }

        if (summaries.isEmpty) {
          return ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      summariesError != null
                          ? Icons.error_outline
                          : Icons.description_outlined,
                      size: 64,
                      color: summariesError != null
                          ? (themeProvider.isDarkMode
                              ? Colors.red[300]
                              : Colors.red)
                          : (themeProvider.isDarkMode
                              ? Colors.white30
                              : Colors.grey[400]),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      summariesError != null
                          ? 'فشل في تحميل الملخصات'
                          : 'لا توجد ملخصات متاحة',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: summariesError != null
                                ? (themeProvider.isDarkMode
                                    ? Colors.red[300]
                                    : Colors.red)
                                : (themeProvider.isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[600]),
                          ),
                    ),
                    if (summariesError != null) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _loadSummaries(forceRefresh: true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: summaries.length,
          itemBuilder: (context, index) {
            final summary = summaries[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: themeProvider.cardGradient,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.description,
                      color: themeProvider.primaryColor,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    summary['title'] ?? 'ملخص ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'ملخص نصي',
                        style: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.white70
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'جاهز للقراءة',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeProvider.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: themeProvider.isDarkMode
                          ? Colors.white70
                          : Colors.grey[600],
                    ),
                  ),
                  onTap: () async {
                    // فتح الملخص في WebView
                    final link = summary['link']?.toString();

                    if (link != null && link.isNotEmpty) {
                      try {
                        // الانتقال إلى شاشة عرض الملخص
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SummaryViewerScreen(
                              summary: summary,
                              courseTitle: widget.course['title'] ?? 'الدورة',
                            ),
                          ),
                        );
                      } catch (e) {
                        print('❌ خطأ في فتح الملخص: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text('حدث خطأ أثناء فتح الملخص'),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      }
                    } else {
                      // لا يوجد رابط
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.info, color: Colors.white),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('الملخص غير متوفر حالياً'),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// بناء تبويبة معلومات الدورة
  Widget _buildCourseInfoTab() {
    return Consumer<SimpleThemeProvider>(
      builder: (context, themeProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان الدورة
              _buildInfoCard(
                title: 'عنوان الدورة',
                content: widget.course['title'] ??
                    widget.course['name'] ??
                    'غير محدد',
                icon: Icons.book,
                themeProvider: themeProvider,
              ),

              // وصف الدورة
              if (widget.course['description'] != null &&
                  widget.course['description'].toString().isNotEmpty)
                _buildInfoCard(
                  title: 'وصف الدورة',
                  content: widget.course['description'].toString(),
                  icon: Icons.description,
                  themeProvider: themeProvider,
                ),

              // اسم الأستاذ
              if (widget.course['instructor_name'] != null)
                _buildInfoCard(
                  title: 'الأستاذ',
                  content: widget.course['instructor_name'].toString(),
                  icon: Icons.person,
                  themeProvider: themeProvider,
                ),

              // عدد المحاضرات
              if (widget.course['lectures_count'] != null)
                _buildInfoCard(
                  title: 'عدد المحاضرات',
                  content: '${widget.course['lectures_count']} محاضرة',
                  icon: Icons.video_library,
                  themeProvider: themeProvider,
                ),

              // نوع الدورة
              _buildInfoCard(
                title: 'نوع الدورة',
                content:
                    widget.course['is_free_course'] == true ? 'مجانية' : 'خاصة',
                icon: widget.course['is_free_course'] == true
                    ? Icons.free_breakfast
                    : Icons.monetization_on,
                themeProvider: themeProvider,
              ),

              // حالة الملكية
              if (widget.course['isOwned'] != null)
                _buildInfoCard(
                  title: 'حالة الدورة',
                  content: widget.course['isOwned'] == true
                      ? 'مملوكة'
                      : 'غير مملوكة',
                  icon: widget.course['isOwned'] == true
                      ? Icons.check_circle
                      : Icons.lock_outline,
                  themeProvider: themeProvider,
                ),

              // تواصل معنا على المنصة الرسمية
              _buildSocialMediaCard(themeProvider),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// بناء كارد معلومات
  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required SimpleThemeProvider themeProvider,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeProvider.isDarkMode
              ? [
                  Colors.grey[800]!.withOpacity(0.3),
                  Colors.grey[900]!.withOpacity(0.1),
                ]
              : [
                  Colors.white.withOpacity(0.9),
                  themeProvider.primaryColor.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : themeProvider.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // أيقونة
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: themeProvider.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // المحتوى
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode
                        ? Colors.white.withOpacity(0.9)
                        : Colors.grey[700],
                    fontFamily: 'NotoKufiArabic',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.isDarkMode
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey[800],
                    fontFamily: 'NotoKufiArabic',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء كارد التواصل مع المنصات الاجتماعية
  Widget _buildSocialMediaCard(SimpleThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeProvider.isDarkMode
              ? [
                  Colors.grey[800]!.withOpacity(0.3),
                  Colors.grey[900]!.withOpacity(0.1),
                ]
              : [
                  Colors.white.withOpacity(0.9),
                  themeProvider.primaryColor.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : themeProvider.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.connect_without_contact,
                  color: themeProvider.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'تواصل معنا على المنصة الرسمية',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode
                      ? Colors.white.withOpacity(0.9)
                      : Colors.grey[700],
                  fontFamily: 'NotoKufiArabic',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // أزرار المنصات الاجتماعية
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // زر Instagram
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          const url = 'https://www.instagram.com/g_raduate';
                          try {
                            final uri = Uri.parse(url);

                            // جرب فتح التطبيق مباشرة
                            bool launched = false;

                            // جرب الرابط الأصلي أولاً
                            try {
                              launched = await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (e) {
                              print('فشل في فتح Instagram مع external app: $e');

                              // جرب في المتصفح
                              try {
                                launched = await launchUrl(
                                  uri,
                                  mode: LaunchMode.inAppWebView,
                                );
                              } catch (e2) {
                                print('فشل في فتح Instagram مع webview: $e2');

                                // جرب الطريقة الافتراضية
                                launched = await launchUrl(uri);
                              }
                            }

                            if (!launched) {
                              throw 'فشل في فتح رابط Instagram';
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('خطأ في فتح Instagram: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: SvgPicture.asset(
                          'images/instagram.svg',
                          color: Colors.white,
                          width: 18,
                          height: 18,
                        ),
                        label: const Text(
                          'Instagram',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'NotoKufiArabic',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFE1306C), // لون Instagram
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          elevation: 3,
                          shadowColor: const Color(0xFFE1306C).withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),

                // فاصل بسيط
                const SizedBox(width: 8),

                // زر Telegram
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          const url = 'https://t.me/g_raduate';
                          try {
                            final uri = Uri.parse(url);

                            // جرب فتح التطبيق مباشرة
                            bool launched = false;

                            // جرب الرابط الأصلي أولاً
                            try {
                              launched = await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (e) {
                              print('فشل في فتح Telegram مع external app: $e');

                              // جرب في المتصفح
                              try {
                                launched = await launchUrl(
                                  uri,
                                  mode: LaunchMode.inAppWebView,
                                );
                              } catch (e2) {
                                print('فشل في فتح Telegram مع webview: $e2');

                                // جرب الطريقة الافتراضية
                                launched = await launchUrl(uri);
                              }
                            }

                            if (!launched) {
                              throw 'فشل في فتح رابط Telegram';
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('خطأ في فتح Telegram: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: SvgPicture.asset(
                          'images/telegram.svg',
                          color: Colors.white,
                          width: 18,
                          height: 18,
                        ),
                        label: const Text(
                          'Telegram',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'NotoKufiArabic',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF0088CC), // لون Telegram
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          elevation: 3,
                          shadowColor: const Color(0xFF0088CC).withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء تخطيط الأزرار للدورات المجانية
  Widget _buildButtonsLayout() {
    return Consumer<SimpleThemeProvider>(
      builder: (context, themeProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // زر الملخصات
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: ElevatedButton(
                    onPressed: () {
                      // عرض رسالة أن الملخصات غير متاحة للدورات المجانية
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'الملخصات متاحة في النسخة المدفوعة من الدورة'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.isDarkMode
                          ? Colors.grey[800]
                          : Colors.grey[300],
                      foregroundColor: themeProvider.isDarkMode
                          ? Colors.white70
                          : Colors.grey[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                    child: const Text(
                      'الملخصات',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        fontFamily: 'NotoKufiArabic',
                      ),
                    ),
                  ),
                ),
              ),
              // زر الفيديوهات
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 4),
                  child: ElevatedButton(
                    onPressed: () {
                      // لا نفعل شيء لأن الفيديوهات معروضة بالفعل
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الفيديوهات معروضة أدناه'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 4,
                      shadowColor: themeProvider.primaryColor.withOpacity(0.4),
                    ),
                    child: const Text(
                      'الفيديوهات',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'NotoKufiArabic',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// بناء تخطيط التبويبات للدورات العادية
  Widget _buildTabsLayout() {
    return Consumer<SimpleThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? Colors.black38 : Colors.grey[200],
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: themeProvider.isDarkMode
                    ? Colors.black26
                    : Colors.grey.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'الفيديوهات'),
              Tab(text: 'الملخصات'),
              Tab(text: 'معلومات الدورة'),
            ],
            indicator: BoxDecoration(
              gradient: themeProvider.primaryGradient,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.primaryColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor:
                themeProvider.isDarkMode ? Colors.white70 : Colors.grey[700],
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'NotoKufiArabic',
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              fontFamily: 'NotoKufiArabic',
            ),
            dividerColor: Colors.transparent,
          ),
        );
      },
    );
  }
}

/// كلاس منفصل لعرض الكويز مع إدارة حالة محسنة
class _QuizDialog extends StatefulWidget {
  final String quizTitle;
  final String question;
  final List options;
  final int correctAnswer;
  final String? courseId; // معرف الدورة لحفظ النتائج في الكاش
  final String? videoId; // معرف الفيديو لحفظ النتائج في الكاش

  const _QuizDialog({
    required this.quizTitle,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.courseId,
    this.videoId,
  });

  @override
  State<_QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<_QuizDialog> {
  int? selectedAnswer;
  bool showAnswer = false;
  bool showCountdown = false;
  bool showQuestionTimer = true; // عداد السؤال
  bool isLoading = false; // حالة التحميل
  int? loadingIndex; // فهرس الخيار الذي يتم تحميله
  int countdown = 5;
  int questionTimer = 300; // 5 دقائق للإجابة على السؤال (300 ثانية)
  Timer? countdownTimer;
  Timer? questionTimerRef;

  @override
  void initState() {
    super.initState();
    startQuestionTimer();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    questionTimerRef?.cancel();
    super.dispose();
  }

  void startQuestionTimer() {
    print('🕐 بدء عداد السؤال - 5 دقائق');
    questionTimerRef?.cancel();
    questionTimerRef = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (questionTimer > 0 && !showAnswer) {
        if (mounted) {
          setState(() {
            questionTimer--;
          });
        } else {
          timer.cancel();
        }
      } else {
        timer.cancel();
        if (mounted && !showAnswer && !isLoading) {
          // حفظ نتيجة عدم الإجابة في الكاش
          _saveTimeoutResult();

          // انتهى الوقت - تظهر الإجابة الصحيحة تلقائياً
          setState(() {
            selectedAnswer = null; // لا توجد إجابة مختارة
            showAnswer = true;
            showQuestionTimer = false;
            isLoading = false; // التأكد من إيقاف التحميل
            loadingIndex = null;
          });
          print('⏰ انتهى الوقت - تم إظهار الإجابة الصحيحة');

          // بدء العداد بعد إظهار النتيجة
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              print('🚀 بدء العداد بعد انتهاء الوقت');
              startCountdown();
            }
          });
        }
      }
    });
  }

  // دالة منفصلة لحفظ نتيجة انتهاء الوقت
  Future<void> _saveTimeoutResult() async {
    try {
      final quizResult = {
        'quiz_title': widget.quizTitle,
        'question': widget.question,
        'selected_answer': null,
        'correct_answer': widget.correctAnswer,
        'is_correct': false,
        'answered_at': DateTime.now().toIso8601String(),
        'course_id': widget.courseId,
        'video_id': widget.videoId,
        'timeout': true,
      };

      if (widget.courseId != null && widget.videoId != null) {
        final cacheKey =
            'quiz_result_${widget.courseId}_${widget.videoId}_${DateTime.now().millisecondsSinceEpoch}';
        final success = await CacheManager.instance.setCache(
          cacheKey,
          quizResult,
          type: CacheType.general,
          expirySeconds: 86400, // يوم واحد
        );

        if (success) {
          print('💾 تم حفظ نتيجة انتهاء الوقت في الكاش: $cacheKey');
        }
      }
    } catch (e) {
      print('❌ خطأ في حفظ نتيجة انتهاء الوقت في الكاش: $e');
    }
  }

  /// دالة إضافية لاسترجاع نتائج الكويز من الكاش (للاستخدام المستقبلي)
  // ignore: unused_element
  static Future<List<Map<String, dynamic>>> getQuizResultsFromCache(
      String courseId, String videoId) async {
    try {
      final results = <Map<String, dynamic>>[];
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      for (final key in allKeys) {
        if (key.startsWith('quiz_result_${courseId}_${videoId}_')) {
          final value = prefs.getString(key);
          if (value != null) {
            final data = json.decode(value);
            if (data['data'] != null) {
              results.add(data['data'] as Map<String, dynamic>);
            }
          }
        }
      }

      print('📊 تم العثور على ${results.length} نتيجة كويز في الكاش');
      return results;
    } catch (e) {
      print('❌ خطأ في استرجاع نتائج الكويز من الكاش: $e');
      return [];
    }
  }

  void startCountdown() {
    print('🕐 بدء العداد التنازلي - تم تحديث setState');
    setState(() {
      showCountdown = true;
      countdown = 5;
    });

    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      print('⏰ العداد: $countdown - تحديث الواجهة');
      if (countdown > 1) {
        if (mounted) {
          setState(() {
            countdown--;
          });
          print('🔄 تم تحديث العداد إلى: $countdown');
        } else {
          timer.cancel();
        }
      } else {
        timer.cancel();
        if (mounted) {
          print('🚪 إغلاق النافذة');
          Navigator.of(context).pop();
        }
      }
    });
  }

  void handleAnswerTap(int index) async {
    print('👆 تم اختيار الإجابة رقم: $index');
    print('✅ الإجابة الصحيحة: ${widget.correctAnswer}');

    // إيقاف عداد السؤال
    questionTimerRef?.cancel();

    // إظهار التحميل
    setState(() {
      isLoading = true;
      loadingIndex = index;
    });

    // إعداد بيانات النتيجة للحفظ في الكاش
    final quizResult = {
      'quiz_title': widget.quizTitle,
      'question': widget.question,
      'selected_answer': index,
      'correct_answer': widget.correctAnswer,
      'is_correct': index == widget.correctAnswer,
      'answered_at': DateTime.now().toIso8601String(),
      'course_id': widget.courseId,
      'video_id': widget.videoId,
    };

    try {
      // حفظ النتيجة في الكاش
      if (widget.courseId != null && widget.videoId != null) {
        final cacheKey =
            'quiz_result_${widget.courseId}_${widget.videoId}_${DateTime.now().millisecondsSinceEpoch}';
        final success = await CacheManager.instance.setCache(
          cacheKey,
          quizResult,
          type: CacheType.general,
          expirySeconds: 86400, // يوم واحد
        );

        if (success) {
          print('💾 تم حفظ نتيجة الكويز في الكاش: $cacheKey');
        } else {
          print('❌ فشل في حفظ نتيجة الكويز في الكاش');
        }
      }
    } catch (e) {
      print('❌ خطأ في حفظ نتيجة الكويز في الكاش: $e');
    }

    // محاكاة معالجة الإجابة (يمكن استبدالها بطلب API حقيقي)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          selectedAnswer = index;
          showAnswer = true;
          showQuestionTimer = false; // إخفاء عداد السؤال
          isLoading = false; // إخفاء التحميل
          loadingIndex = null;
        });

        print('🎯 النتيجة: ${index == widget.correctAnswer ? "صحيح" : "خطأ"}');
        print('🎨 تم تحديث الألوان - showAnswer: $showAnswer');

        // بدء العداد بعد إظهار النتيجة
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            print('🚀 بدء العداد بعد 1.5 ثانية');
            startCountdown();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print(
        '🔧 بناء واجهة الكويز - showAnswer: $showAnswer, showCountdown: $showCountdown');

    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final dialogWidth = isSmallScreen ? screenSize.width * 0.9 : 500.0;
    final dialogMaxHeight = screenSize.height * 0.8;

    return AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      titlePadding: const EdgeInsets.all(16),
      actionsPadding: const EdgeInsets.all(0),
      title: Row(
        children: [
          Icon(
            Icons.quiz,
            color: Theme.of(context).colorScheme.primary,
            size: isSmallScreen ? 20 : 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.quizTitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 16 : 18,
              ),
            ),
          ),
        ],
      ),
      content: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: dialogMaxHeight,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عداد الوقت للسؤال (يظهر قبل الإجابة)
              if (showQuestionTimer && !showAnswer) ...[
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: questionTimer <= 60
                          ? [
                              Colors.red.withOpacity(0.1),
                              Colors.red.withOpacity(0.05)
                            ]
                          : questionTimer <= 120
                              ? [
                                  Colors.orange.withOpacity(0.1),
                                  Colors.orange.withOpacity(0.05)
                                ]
                              : [
                                  Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                      .withOpacity(0.7)
                                ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: questionTimer <= 60
                          ? Colors.red.withOpacity(0.4)
                          : questionTimer <= 120
                              ? Colors.orange.withOpacity(0.4)
                              : Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: questionTimer <= 60
                            ? Colors.red.withOpacity(0.1)
                            : questionTimer <= 120
                                ? Colors.orange.withOpacity(0.1)
                                : Theme.of(context)
                                    .colorScheme
                                    .shadow
                                    .withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                        decoration: BoxDecoration(
                          color: questionTimer <= 60
                              ? Colors.red.withOpacity(0.2)
                              : questionTimer <= 120
                                  ? Colors.orange.withOpacity(0.2)
                                  : Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          questionTimer <= 60
                              ? Icons.timer_off
                              : questionTimer <= 120
                                  ? Icons.timer_3
                                  : Icons.timer,
                          color: questionTimer <= 60
                              ? Colors.red
                              : questionTimer <= 120
                                  ? Colors.orange
                                  : Theme.of(context).colorScheme.primary,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الوقت المتبقي',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 1 : 2),
                          Text(
                            '${(questionTimer ~/ 60).toString().padLeft(2, '0')}:${(questionTimer % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: questionTimer <= 60
                                  ? Colors.red
                                  : questionTimer <= 120
                                      ? Colors.orange
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      // شريط التقدم الدائري
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: isSmallScreen ? 35 : 40,
                            height: isSmallScreen ? 35 : 40,
                            child: CircularProgressIndicator(
                              value: questionTimer / 300,
                              strokeWidth: 3,
                              backgroundColor: Colors.grey.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                questionTimer <= 60
                                    ? Colors.red
                                    : questionTimer <= 120
                                        ? Colors.orange
                                        : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            '${questionTimer ~/ 60}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 8 : 10,
                              fontWeight: FontWeight.bold,
                              color: questionTimer <= 60
                                  ? Colors.red
                                  : questionTimer <= 120
                                      ? Colors.orange
                                      : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // السؤال
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.question,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),

              // رسالة انتهاء الوقت (تظهر في حالة عدم الإجابة)
              if (showAnswer && selectedAnswer == null) ...[
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: Colors.orange[700],
                        size: isSmallScreen ? 20 : 24,
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        child: Text(
                          'انتهى الوقت المحدد للإجابة (5 دقائق)! تم عرض الإجابة الصحيحة أدناه.',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // الخيارات (تظهر دائماً)
              ...widget.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value.toString();

                Color? optionColor;
                Color? textColor;
                Widget? trailingIcon;

                print(
                    '🎨 بناء خيار $index - showAnswer: $showAnswer - selectedAnswer: $selectedAnswer - correctAnswer: ${widget.correctAnswer}');

                if (showAnswer) {
                  if (index == widget.correctAnswer) {
                    optionColor = Colors.green.withOpacity(0.3);
                    textColor = Colors.green[800];
                    trailingIcon = Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: isSmallScreen ? 20 : 24,
                    );
                    print('✅ خيار $index - أخضر (صحيح)');
                  } else if (index == selectedAnswer &&
                      index != widget.correctAnswer) {
                    optionColor = Colors.red.withOpacity(0.3);
                    textColor = Colors.red[800];
                    trailingIcon = Icon(
                      Icons.cancel,
                      color: Colors.red,
                      size: isSmallScreen ? 20 : 24,
                    );
                    print('❌ خيار $index - أحمر (خطأ)');
                  }
                } else if (isLoading && loadingIndex == index) {
                  // إظهار التحميل للخيار المختار
                  optionColor = Theme.of(context).colorScheme.primaryContainer;
                  textColor = Theme.of(context).colorScheme.onPrimaryContainer;
                  trailingIcon = SizedBox(
                    width: isSmallScreen ? 16 : 20,
                    height: isSmallScreen ? 16 : 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                }

                return Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 4 : 8,
                    ),
                    leading: CircleAvatar(
                      radius: isSmallScreen ? 18 : 20,
                      backgroundColor:
                          showAnswer && index == widget.correctAnswer
                              ? Colors.green
                              : showAnswer &&
                                      index == selectedAnswer &&
                                      index != widget.correctAnswer
                                  ? Colors.red
                                  : isLoading && loadingIndex == index
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.secondary,
                      child: isLoading && loadingIndex == index
                          ? SizedBox(
                              width: isSmallScreen ? 12 : 14,
                              height: isSmallScreen ? 12 : 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: TextStyle(
                                color: showAnswer &&
                                        (index == widget.correctAnswer ||
                                            (index == selectedAnswer &&
                                                index != widget.correctAnswer))
                                    ? Colors.white
                                    : isLoading && loadingIndex == index
                                        ? Colors.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                            ),
                    ),
                    title: Text(
                      option,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: textColor,
                        fontWeight: showAnswer && index == widget.correctAnswer
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: trailingIcon,
                    tileColor: optionColor ??
                        Theme.of(context).colorScheme.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: showAnswer && index == widget.correctAnswer
                          ? const BorderSide(color: Colors.green, width: 2)
                          : showAnswer &&
                                  index == selectedAnswer &&
                                  index != widget.correctAnswer
                              ? const BorderSide(color: Colors.red, width: 2)
                              : BorderSide.none,
                    ),
                    onTap: showAnswer || isLoading
                        ? null
                        : () => handleAnswerTap(index),
                  ),
                );
              }).toList(),

              // عداد السؤال التالي (يظهر تحت الخيارات بعد الإجابة)
              if (showCountdown) ...[
                SizedBox(height: isSmallScreen ? 12 : 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 12 : 16,
                    horizontal: isSmallScreen ? 16 : 20,
                  ),
                  margin:
                      EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.7),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Theme.of(context).colorScheme.primary,
                        size: isSmallScreen ? 18 : 20,
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Text(
                        'السؤال سينتهي بعد $countdown ثانية',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
