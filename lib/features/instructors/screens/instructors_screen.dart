import 'package:flutter/material.dart';
import 'package:newgraduate/widgets/custom_app_bar.dart';
import 'package:newgraduate/widgets/department_card.dart';
import 'package:newgraduate/models/instructor.dart';
import 'package:newgraduate/services/instructor_service.dart';
import 'package:newgraduate/services/token_expired_handler.dart';
import 'package:newgraduate/features/instructors/screens/instructor_courses_screen.dart';
import 'package:newgraduate/widgets/custom_loading_widget.dart';

class InstructorsScreen extends StatefulWidget {
  final String instituteId;
  final String instituteName;

  const InstructorsScreen({
    super.key,
    required this.instituteId,
    required this.instituteName,
  });

  @override
  State<InstructorsScreen> createState() => _InstructorsScreenState();
}

class _InstructorsScreenState extends State<InstructorsScreen> {
  List<Instructor> instructors = [];
  List<Instructor> filteredInstructors = [];
  bool isLoading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInstructors();
  }

  void _filterInstructors(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        filteredInstructors = instructors;
      } else {
        filteredInstructors = instructors.where((instructor) {
          return instructor.name.toLowerCase().contains(query.toLowerCase()) ||
              (instructor.specialization
                      ?.toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstructors() async {
    try {
      print('🎓 بدء تحميل الأساتذة للمعهد: ${widget.instituteName}');
      setState(() {
        isLoading = true;
        error = null;
      });

      final fetchedInstructors =
          await InstructorService.getInstructorsByInstitute(
        context,
        widget.instituteId,
      );

      print('✅ تم الحصول على ${fetchedInstructors.length} أستاذ بنجاح');

      setState(() {
        instructors = fetchedInstructors;
        filteredInstructors = fetchedInstructors;
        isLoading = false;
      });

      print('🎯 تم تحديث الحالة بنجاح');
    } catch (e) {
      print('❌ خطأ في تحميل الأساتذة: $e');

      // التحقق من انتهاء التوكن
      if (await TokenExpiredHandler.handleTokenExpiration(
        context,
        errorMessage: e.toString(),
      )) {
        return; // تم التعامل مع انتهاء التوكن
      }

      setState(() {
        error = e.toString();
        isLoading = false;
        // استخدام البيانات الوهمية في حالة الخطأ
        instructors = InstructorService.getDummyInstructors();
        filteredInstructors = instructors;
      });
      print('🔄 تم التبديل للبيانات الوهمية: ${instructors.length} أستاذ');
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
        title: 'أساتذة ${widget.instituteName}',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const CenterLoadingWidget(
                message: 'جاري تحميل الأساتذة...',
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
                          onPressed: _loadInstructors,
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
                              Icons.school_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا يوجد أساتذة في هذا المعهد',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'قد يتم إضافة أساتذة لاحقاً',
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
                                onChanged: _filterInstructors,
                                textDirection: TextDirection.rtl,
                                textAlignVertical: TextAlignVertical.center,
                                style: TextStyle(fontSize: searchFontSize),
                                decoration: InputDecoration(
                                  hintText: 'ابحث عن أستاذ...',
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
                                            _filterInstructors('');
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
                                    'نتائج البحث: ${filteredInstructors.length} من ${instructors.length}',
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
                          // شبكة الأساتذة
                          Expanded(
                            child: filteredInstructors.isEmpty &&
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
                                    onRefresh: _loadInstructors,
                                    child: GridView.builder(
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
                                        return DepartmentCard(
                                          imageUrl: instructor.imageUrl ?? '',
                                          title: instructor.name,
                                          subtitle: instructor.specialization,
                                          onTap: () {
                                            print(
                                                '🔍 تم الضغط على الأستاذ: ${instructor.name}');
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    InstructorCoursesScreen(
                                                  instructor: instructor,
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
