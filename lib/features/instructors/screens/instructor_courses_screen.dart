import 'package:flutter/material.dart';
import 'package:newgraduate/widgets/custom_app_bar.dart';
import 'package:newgraduate/widgets/department_card.dart';
import 'package:newgraduate/models/instructor.dart';
import 'package:newgraduate/config/app_constants.dart';
import 'package:newgraduate/services/api_headers_manager.dart';
import 'package:newgraduate/services/token_expired_handler.dart';
import 'package:newgraduate/features/courses/screens/course_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InstructorCoursesScreen extends StatefulWidget {
  final Instructor instructor;

  const InstructorCoursesScreen({
    super.key,
    required this.instructor,
  });

  @override
  State<InstructorCoursesScreen> createState() =>
      _InstructorCoursesScreenState();
}

class _InstructorCoursesScreenState extends State<InstructorCoursesScreen> {
  List<dynamic> courses = [];
  List<dynamic> filteredCourses = [];
  bool isLoading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInstructorCourses();
  }

  void _filterCourses(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        filteredCourses = courses;
      } else {
        filteredCourses = courses.where((course) {
          final title = course['title']?.toString().toLowerCase() ?? '';
          final description =
              course['description']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return title.contains(searchLower) ||
              description.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstructorCourses() async {
    try {
      print('🎓 بدء تحميل دورات الأستاذ: ${widget.instructor.name}');
      setState(() {
        isLoading = true;
        error = null;
      });

      // بناء رابط الـ API
      final String apiUrl =
          '${AppConstants.baseUrl}/api/courses?instructor_id=${widget.instructor.id}';
      print('🔗 رابط الـ API: $apiUrl');

      // استخدام ApiHeadersManager للحصول على Headers
      final headers = await ApiHeadersManager.instance.getAuthHeaders();

      final response = await http
          .get(
            Uri.parse(apiUrl),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('📡 كود الاستجابة: ${response.statusCode}');
      print('📄 محتوى الاستجابة: ${response.body}');
      print('🔍 Headers الاستجابة: ${response.headers}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ تم استلام البيانات: $data');

        setState(() {
          // استخدام data['data'] بناءً على بنية الاستجابة المرئية
          final allCourses = data['data'] ?? [];

          // فلترة الدورات المدفوعة فقط (استبعاد الدورات المجانية)
          courses = allCourses.where((course) {
            final price = course['price'];
            final isFree = course['is_free'];

            // إذا كان is_free موجود، استخدمه
            if (isFree != null) {
              return !isFree; // عرض الدورات غير المجانية فقط
            }

            // إذا لم يكن is_free موجود، تحقق من السعر
            if (price != null) {
              // تحويل السعر إلى رقم للمقارنة
              double coursePrice = 0.0;
              if (price is String) {
                coursePrice = double.tryParse(price) ?? 0.0;
              } else if (price is num) {
                coursePrice = price.toDouble();
              }

              return coursePrice > 0; // عرض الدورات المدفوعة فقط
            }

            // في حالة عدم وجود معلومات السعر أو is_free، عرض الدورة
            return true;
          }).toList();

          filteredCourses = courses;
          isLoading = false;

          print(
              '✅ تم تحميل ${courses.length} دورة مدفوعة للأستاذ (تم استبعاد ${allCourses.length - courses.length} دورة مجانية)');
        });

        print('🎯 تم تحميل ${courses.length} دورة للأستاذ');
      } else {
        print('❌ فشل في تحميل دورات الأستاذ: ${response.statusCode}');
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

        throw Exception('فشل في تحميل الدورات: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في تحميل دورات الأستاذ: $e');

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
          error = e.toString();
          isLoading = false;
          // استخدام بيانات وهمية في حالة الخطأ
          courses = _getDummyCourses();
          filteredCourses = courses;
        });
        print('🔄 تم التبديل للبيانات الوهمية: ${courses.length} دورة');
      }
    }
  }

  List<dynamic> _getDummyCourses() {
    return [
      {
        'id': 1,
        'title': 'أساسيات البرمجة',
        'description': 'مقدمة في البرمجة باستخدام Python',
        'duration': '4 أسابيع',
        'level': 'مبتدئ',
        'image': '',
      },
      {
        'id': 2,
        'title': 'تطوير تطبيقات الويب',
        'description': 'تعلم HTML, CSS, JavaScript',
        'duration': '6 أسابيع',
        'level': 'متوسط',
        'image': '',
      },
      {
        'id': 3,
        'title': 'قواعد البيانات',
        'description': 'تصميم وإدارة قواعد البيانات',
        'duration': '5 أسابيع',
        'level': 'متقدم',
        'image': '',
      },
    ];
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
        ? 6
        : isMediumScreen
            ? 8
            : 12;
    final double searchPaddingVertical = isSmallScreen
        ? 3
        : isMediumScreen
            ? 4
            : 6;
    final double searchContentPaddingH = isSmallScreen
        ? 6
        : isMediumScreen
            ? 8
            : 10;
    final double searchContentPaddingV = isSmallScreen
        ? 3
        : isMediumScreen
            ? 4
            : 5;
    final double searchBorderRadius = isSmallScreen
        ? 8
        : isMediumScreen
            ? 10
            : 12;
    final double searchMarginBottom = isSmallScreen
        ? 8
        : isMediumScreen
            ? 12
            : 16;
    final double searchIconSize = isSmallScreen
        ? 20
        : isMediumScreen
            ? 22
            : 24;
    final double searchFontSize = isSmallScreen
        ? 14
        : isMediumScreen
            ? 15
            : 16;

    return Scaffold(
      appBar: CustomAppBarWidget(
        title: 'دورات ${widget.instructor.name}',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحميل الدورات...'),
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
                          'يتم عرض بيانات تجريبية',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadInstructorCourses,
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
                              Icons.book_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد دورات لهذا الأستاذ',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'قد يتم إضافة دورات لاحقاً',
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
                          // حقل البحث
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: searchPaddingHorizontal,
                                  vertical: searchPaddingVertical),
                              margin:
                                  EdgeInsets.only(bottom: searchMarginBottom),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant,
                                borderRadius:
                                    BorderRadius.circular(searchBorderRadius),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: _filterCourses,
                                textDirection: TextDirection.rtl,
                                textAlignVertical: TextAlignVertical.center,
                                style: TextStyle(fontSize: searchFontSize),
                                decoration: InputDecoration(
                                  hintText: 'ابحث عن دورة...',
                                  hintStyle: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: searchFontSize,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: searchIconSize,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            size: searchIconSize,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            _filterCourses('');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: searchContentPaddingH,
                                    vertical: searchContentPaddingV,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // نتائج البحث
                          if (_searchQuery.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_outlined,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'نتائج البحث: ${filteredCourses.length} من ${courses.length}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          // شبكة الدورات
                          Expanded(
                            child: filteredCourses.isEmpty &&
                                    _searchQuery.isNotEmpty
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
                                          'لا توجد نتائج للبحث',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'جرب البحث بكلمات مختلفة',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.grey[500],
                                              ),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadInstructorCourses,
                                    child: GridView.builder(
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
                                        return DepartmentCard(
                                          imageUrl: course['image_url'] ?? '',
                                          title: course['title'] ??
                                              'دورة بدون عنوان',
                                          promoVideoUrl:
                                              course['promo_video_url'],
                                          onTap: () {
                                            print(
                                                '🔍 تم الضغط على الدورة: ${course['title']}');
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CourseDetailScreen(
                                                  course: course,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
      ),
    );
  }
}
