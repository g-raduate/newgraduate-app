import 'package:flutter/material.dart';
import 'package:newgraduate/widgets/custom_app_bar.dart';
import 'package:newgraduate/widgets/main_card.dart';
import 'package:newgraduate/config/app_constants.dart';
import 'package:newgraduate/services/api_headers_manager.dart';
import 'package:newgraduate/services/token_manager.dart';
import 'package:newgraduate/services/token_expired_handler.dart';
import 'package:newgraduate/features/courses/screens/instructor_free_courses_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FreeCoursesScreen extends StatefulWidget {
  const FreeCoursesScreen({super.key});

  @override
  State<FreeCoursesScreen> createState() => _FreeCoursesScreenState();
}

class _FreeCoursesScreenState extends State<FreeCoursesScreen> {
  List<Map<String, dynamic>> instructors = [];
  List<Map<String, dynamic>> filteredInstructors = [];
  bool isLoading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFreeCoursesInstructors();
  }

  void _filterInstructors(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        filteredInstructors = instructors;
      } else {
        filteredInstructors = instructors.where((instructor) {
          final lowerQuery = query.toLowerCase();
          return instructor['instructor_name']
                      ?.toString()
                      .toLowerCase()
                      .contains(lowerQuery) ==
                  true ||
              instructor['name']
                      ?.toString()
                      .toLowerCase()
                      .contains(lowerQuery) ==
                  true ||
              instructor['email']
                      ?.toString()
                      .toLowerCase()
                      .contains(lowerQuery) ==
                  true ||
              instructor['specialization']
                      ?.toString()
                      .toLowerCase()
                      .contains(lowerQuery) ==
                  true ||
              instructor['institute']?['name']
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

  Future<void> _loadFreeCoursesInstructors() async {
    try {
      print('🎓 بدء تحميل أساتذة الدورات المجانية...');
      setState(() {
        isLoading = true;
        error = null;
      });

      // الحصول على معرف المعهد من TokenManager
      final tokenManager = await TokenManager.getInstance();
      final instituteId = await tokenManager.getInstituteId();

      if (instituteId == null || instituteId.isEmpty) {
        throw Exception('لا يمكن الحصول على معرف المعهد');
      }

      print('🏢 معرف المعهد: $instituteId');

      // بناء رابط الـ API - استخدام نفس الـ API السابق
      final String apiUrl =
          '${AppConstants.baseUrl}/api/institutes/$instituteId/instructors/fr_courses';
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

        List<Map<String, dynamic>> fetchedInstructors;

        if (responseData is List) {
          print('📝 البيانات على شكل List مباشرة');
          fetchedInstructors = List<Map<String, dynamic>>.from(responseData);
        } else if (responseData is Map<String, dynamic>) {
          print('📝 البيانات على شكل Map، البحث عن مفتاح data');
          print('🔑 مفاتيح الـ Map: ${responseData.keys.toList()}');

          if (responseData.containsKey('data')) {
            final dataContent = responseData['data'];
            print('📄 محتوى data: $dataContent');
            fetchedInstructors =
                List<Map<String, dynamic>>.from(dataContent ?? []);
          } else {
            // استخدام البيانات الأساسية
            print('⚠️ لا يوجد مفتاح data، استخدام البيانات الأساسية');
            fetchedInstructors = [responseData];
          }
        } else {
          throw Exception('تنسيق غير متوقع للبيانات');
        }

        print(
            '✅ تم الحصول على ${fetchedInstructors.length} أستاذ لديه دورات مجانية');

        // طباعة تفاصيل كل أستاذ
        for (int i = 0; i < fetchedInstructors.length; i++) {
          final instructor = fetchedInstructors[i];
          print('👨‍🏫 أستاذ ${i + 1}:');
          print(
              '  - الاسم: ${instructor['name'] ?? instructor['instructor_name'] ?? 'غير محدد'}');
          print('  - الإيميل: ${instructor['email'] ?? 'غير محدد'}');
          print('  - التخصص: ${instructor['specialization'] ?? 'غير محدد'}');
          print(
              '  - المعهد: ${instructor['institute']?['name'] ?? 'غير محدد'}');
          print('  - الصورة: ${instructor['image_url'] ?? 'غير محددة'}');
          print(
              '  - العدد الإجمالي للدورات المجانية: ${instructor['total_free_courses'] ?? 'غير محدد'}');
          print('  - جميع المفاتيح: ${instructor.keys.toList()}');

          // إضافة اسم الأستاذ إذا لم يوجد
          if (instructor['instructor_name'] == null &&
              instructor['name'] != null) {
            instructor['instructor_name'] = instructor['name'];
            print('  - تم إضافة اسم الأستاذ: ${instructor['instructor_name']}');
          }

          print('  ---');
        }

        setState(() {
          instructors = fetchedInstructors;
          filteredInstructors = fetchedInstructors;
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
            'فشل في تحميل أساتذة الدورات المجانية: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في تحميل أساتذة الدورات المجانية: $e');

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
          // استخدام البيانات الوهمية في حالة الخطأ
          instructors = _getDummyFreeCoursesInstructors();
          filteredInstructors = instructors;
        });
        print('🔄 تم التبديل للبيانات الوهمية: ${instructors.length} أستاذ');
      }
    }
  }

  List<Map<String, dynamic>> _getDummyFreeCoursesInstructors() {
    return [
      {
        'id': '1',
        'name': 'د. أحمد محمد سعد',
        'instructor_name': 'د. أحمد محمد سعد',
        'email': 'ahmed.saad@university.edu',
        'specialization': 'هندسة البرمجيات',
        'image_url':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
        'total_free_courses': '3',
      },
      {
        'id': '2',
        'name': 'د. فاطمة علي حسن',
        'instructor_name': 'د. فاطمة علي حسن',
        'email': 'fatima.hassan@university.edu',
        'specialization': 'أمن المعلومات',
        'image_url':
            'https://images.unsplash.com/photo-1494790108755-2616b332e234?w=300',
        'total_free_courses': '2',
      },
      {
        'id': '3',
        'name': 'د. محمد عبدالله القحطاني',
        'instructor_name': 'د. محمد عبدالله القحطاني',
        'email': 'mohammed.alqahtani@university.edu',
        'specialization': 'الذكاء الاصطناعي',
        'image_url':
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=300',
        'total_free_courses': '4',
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
      appBar: const CustomAppBarWidget(
        title: 'أساتذة الدورات المجانية',
      ),
      body: RefreshIndicator(
        onRefresh: _loadFreeCoursesInstructors,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري تحميل أساتذة الدورات المجانية...'),
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadFreeCoursesInstructors,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    )
                  : instructors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا يوجد أساتذة لديهم دورات مجانية',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'تحقق لاحقاً للحصول على أساتذة جدد',
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
                                        hintText: 'ابحث عن أستاذ...',
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
                                      onChanged: _filterInstructors,
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        _filterInstructors('');
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
                              child: filteredInstructors.isEmpty
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
                                      itemCount: filteredInstructors.length,
                                      itemBuilder: (context, index) {
                                        final instructor =
                                            filteredInstructors[index];
                                        return MainCard(
                                          imageUrl: instructor['image_url']
                                                  ?.toString() ??
                                              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
                                          title:
                                              instructor['name']?.toString() ??
                                                  instructor['instructor_name']
                                                      ?.toString() ??
                                                  'أستاذ',
                                          subtitle:
                                              '${instructor['specialization']?.toString() ?? 'تخصص غير محدد'} • ${instructor['total_free_courses'] ?? '0'} دورة مجانية',
                                          fallbackIcon: Icons.person,
                                          onTap: () {
                                            final instructorId =
                                                instructor['id']?.toString();
                                            final instructorName = instructor[
                                                        'name']
                                                    ?.toString() ??
                                                instructor['instructor_name']
                                                    ?.toString() ??
                                                'أستاذ';

                                            if (instructorId != null) {
                                              print(
                                                  '🎯 تم النقر على الأستاذ: $instructorName');
                                              // الانتقال إلى صفحة دورات الأستاذ المجانية
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      InstructorFreeCoursesScreen(
                                                    instructorId: instructorId,
                                                    instructorName:
                                                        instructorName,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              print('❌ لا يوجد معرف للأستاذ');
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'خطأ في معرف الأستاذ'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
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
