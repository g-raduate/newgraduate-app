import 'package:flutter/material.dart';
import 'package:newgraduate/widgets/custom_app_bar.dart';
import 'package:newgraduate/widgets/main_card.dart';
import 'package:newgraduate/config/app_constants.dart';
import 'package:newgraduate/services/api_headers_manager.dart';
import 'package:newgraduate/services/token_expired_handler.dart';
import 'package:newgraduate/features/courses/screens/course_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InstructorFreeCoursesScreen extends StatefulWidget {
  final String instructorId;
  final String instructorName;

  const InstructorFreeCoursesScreen({
    super.key,
    required this.instructorId,
    required this.instructorName,
  });

  @override
  State<InstructorFreeCoursesScreen> createState() =>
      _InstructorFreeCoursesScreenState();
}

class _InstructorFreeCoursesScreenState
    extends State<InstructorFreeCoursesScreen> {
  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> filteredCourses = [];
  bool isLoading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInstructorFreeCourses();
  }

  void _filterCourses(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        filteredCourses = courses;
      } else {
        filteredCourses = courses.where((course) {
          final lowerQuery = query.toLowerCase();
          return course['title']
                      ?.toString()
                      .toLowerCase()
                      .contains(lowerQuery) ==
                  true ||
              course['name']?.toString().toLowerCase().contains(lowerQuery) ==
                  true ||
              course['description']
                      ?.toString()
                      .toLowerCase()
                      .contains(lowerQuery) ==
                  true;
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstructorFreeCourses() async {
    try {
      print('🎓 بدء تحميل الدورات المجانية للأستاذ: ${widget.instructorName}');
      setState(() {
        isLoading = true;
        error = null;
      });

      // بناء رابط الـ API
      final String apiUrl =
          '${AppConstants.baseUrl}/api/instructors/${widget.instructorId}/free-courses-simple';
      print('🔗 رابط الـ API: $apiUrl');

      // استخدام ApiHeadersManager للحصول على Headers
      final headers = await ApiHeadersManager.instance.getAuthHeaders();
      final response = await http
          .get(Uri.parse(apiUrl), headers: headers)
          .timeout(const Duration(seconds: 30));

      print('📊 حالة الاستجابة: ${response.statusCode}');
      print('📄 محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        print('🔍 نوع البيانات المستلمة: ${responseData.runtimeType}');
        print('📋 البيانات الكاملة: $responseData');

        List<Map<String, dynamic>> fetchedCourses;

        if (responseData is List) {
          print('📝 البيانات على شكل List مباشرة');
          fetchedCourses = List<Map<String, dynamic>>.from(responseData);
        } else if (responseData is Map<String, dynamic>) {
          print('📝 البيانات على شكل Map، البحث عن مفتاح data');
          print('🔑 مفاتيح الـ Map: ${responseData.keys.toList()}');

          if (responseData.containsKey('data')) {
            final dataContent = responseData['data'];
            print('📄 محتوى data: $dataContent');
            fetchedCourses = List<Map<String, dynamic>>.from(dataContent ?? []);
          } else if (responseData.containsKey('free_courses')) {
            final coursesContent = responseData['free_courses'];
            print('📄 محتوى free_courses: $coursesContent');
            fetchedCourses =
                List<Map<String, dynamic>>.from(coursesContent ?? []);
          } else {
            // استخدام البيانات الأساسية
            print(
                '⚠️ لا يوجد مفتاح data أو free_courses، استخدام البيانات الأساسية');
            fetchedCourses = [responseData];
          }
        } else {
          throw Exception('تنسيق غير متوقع للبيانات');
        }

        print('✅ تم الحصول على ${fetchedCourses.length} دورة مجانية للأستاذ');

        // طباعة تفاصيل كل دورة
        for (int i = 0; i < fetchedCourses.length; i++) {
          final course = fetchedCourses[i];
          print('📚 دورة ${i + 1}:');
          print(
              '  - العنوان: ${course['name'] ?? course['title'] ?? 'غير محدد'}');
          print('  - الوصف: ${course['description'] ?? 'غير محدد'}');
          print('  - الصورة: ${course['image_url'] ?? 'غير محددة'}');
          print('  - مجانية: ${course['is_free'] ?? 'غير محدد'}');
          print('  - جميع المفاتيح: ${course.keys.toList()}');
          print('  ---');
        }

        setState(() {
          courses = fetchedCourses;
          filteredCourses = fetchedCourses;
          isLoading = false;
        });

        print('🎯 تم تحديث الحالة بنجاح');
      } else {
        // التحقق من انتهاء التوكن
        if (mounted &&
            await TokenExpiredHandler.handleTokenExpiration(
              context,
              statusCode: response.statusCode,
              errorMessage: response.body,
            )) {
          return; // تم التعامل مع انتهاء التوكن
        }

        throw Exception(
            'فشل في تحميل دورات الأستاذ المجانية: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في تحميل دورات الأستاذ المجانية: $e');

      // التحقق من انتهاء التوكن في حالة الخطأ
      if (mounted &&
          await TokenExpiredHandler.handleTokenExpiration(
            context,
            errorMessage: e.toString(),
          )) {
        return; // تم التعامل مع انتهاء التوكن
      }

      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
          courses = [];
          filteredCourses = [];
        });
        print('❌ فشل في تحميل البيانات، لن يتم عرض بيانات وهمية');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 2 : 3;

    // متغيرات متجاوبة للتصميم
    final bool isSmallScreen = screenWidth < 400;
    final bool isMediumScreen = screenWidth >= 400 && screenWidth < 600;

    // أبعاد متجاوبة لمربع البحث
    final double searchPaddingHorizontal = isSmallScreen
        ? 12
        : isMediumScreen
            ? 16
            : 20;
    final double searchPaddingVertical = isSmallScreen ? 8 : 12;
    final double searchBorderRadius = isSmallScreen ? 20 : 25;
    final double searchIconSize = isSmallScreen ? 18 : 20;
    final double searchFontSize = isSmallScreen ? 14 : 16;
    final double searchContentPaddingH = isSmallScreen ? 8 : 12;
    final double searchContentPaddingV = isSmallScreen ? 8 : 12;
    final double searchMarginBottom = isSmallScreen ? 16 : 20;

    return Scaffold(
      appBar: CustomAppBarWidget(
        title: 'دورات ${widget.instructorName}',
      ),
      body: RefreshIndicator(
        onRefresh: _loadInstructorFreeCourses,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري تحميل الدورات المجانية...'),
                    ],
                  ),
                )
              : error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'حدث خطأ في تحميل البيانات',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'تعذر الاتصال بالخادم',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadInstructorFreeCourses,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    )
                  : courses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد دورات مجانية للأستاذ',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'تحقق لاحقاً للحصول على دورات جديدة',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // شريط البحث
                            Container(
                              margin:
                                  EdgeInsets.only(bottom: searchMarginBottom),
                              padding: EdgeInsets.symmetric(
                                horizontal: searchPaddingHorizontal,
                                vertical: searchPaddingVertical,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.grey[100],
                                borderRadius:
                                    BorderRadius.circular(searchBorderRadius),
                                border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[600]!
                                      : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Colors.grey[600],
                                    size: searchIconSize,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      style:
                                          TextStyle(fontSize: searchFontSize),
                                      decoration: InputDecoration(
                                        hintText: 'ابحث عن دورة...',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: searchFontSize,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: searchContentPaddingH,
                                          vertical: searchContentPaddingV,
                                        ),
                                      ),
                                      onChanged: _filterCourses,
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        _filterCourses('');
                                      },
                                      child: Icon(
                                        Icons.clear,
                                        color: Colors.grey[600],
                                        size: searchIconSize,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // عرض النتائج
                            Expanded(
                              child: filteredCourses.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.search_off,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'لم يتم العثور على نتائج',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'جرب البحث بكلمات مختلفة',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: 0.8,
                                      ),
                                      itemCount: filteredCourses.length,
                                      itemBuilder: (context, index) {
                                        final course = filteredCourses[index];
                                        return MainCard(
                                          imageUrl: course['image_url']
                                                  ?.toString() ??
                                              'https://nulpgduzktpozubpbiqf.supabase.co/storage/v1/object/public/Images/Courses/Default.png',
                                          title: course['name']?.toString() ??
                                              course['title']?.toString() ??
                                              'دورة مجانية',
                                          fallbackIcon: Icons.school,
                                          onTap: () {
                                            print(
                                                '🎯 تم النقر على الدورة: ${course['name'] ?? course['title']}');

                                            // إضافة معلومة أن هذه دورة مجانية
                                            final courseWithFreeFlag =
                                                Map<String, dynamic>.from(
                                                    course);
                                            courseWithFreeFlag[
                                                'is_free_course'] = true;
                                            // لا نضع isOwned = true هنا لنعطي فرصة للطالب للتسجيل

                                            // الانتقال إلى صفحة تفاصيل الدورة
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CourseDetailScreen(
                                                  course: courseWithFreeFlag,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }
}
