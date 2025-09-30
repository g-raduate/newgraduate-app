import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:newgraduate/widgets/custom_app_bar.dart';
import 'package:newgraduate/widgets/simple_color_picker.dart';
import 'package:newgraduate/widgets/custom_loading_widget.dart';
import 'package:newgraduate/providers/simple_theme_provider.dart';
import 'package:newgraduate/utils/data_service.dart';
import 'package:newgraduate/utils/responsive_helper.dart';
import 'package:newgraduate/services/token_manager.dart';
import 'package:newgraduate/config/app_constants.dart';
import 'package:newgraduate/services/api_headers_manager.dart';
import 'package:newgraduate/services/token_expired_handler.dart';
import 'package:newgraduate/features/instructors/screens/instructors_screen.dart';
import 'package:newgraduate/features/projects/screens/projects_screen.dart';
import 'package:newgraduate/features/departments/screens/departments_screen.dart';
import 'package:newgraduate/features/courses/screens/free_courses_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:newgraduate/features/projects/screens/project_details_screen.dart';
import 'package:newgraduate/features/research/screens/research_screen.dart';
import 'package:newgraduate/features/seminar/screens/seminar_screen.dart';
import 'package:newgraduate/features/report/screens/report_screen.dart';
import 'package:newgraduate/services/cache_manager.dart';
import 'package:newgraduate/features/courses/screens/course_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _promoPageController = PageController();
  int _promoPageIndex = 0;
  Timer? _promoTimer;

  final List<Map<String, String>> _promoCards = [
    {
      'title': 'ابدأ رحلتك التعليمية اليوم',
      'body':
          'ابدأ رحلتك التعليمية اليوم واكتشف مجموعة واسعة من الدورات والمشاريع التي ستساعدك في تطوير مهاراتك المهنية',
    },
    {
      'title': '🚀 مع تطبيق خريج',
      'body':
          'مع تطبيق خريج، راح تقدر تتعلم من أفضل الدورات، تختار مشروع تخرجك بسهولة، وتجهّز بحوثك وتقاريرك بخطوات واضحة. هنا تلقى كل شيء تحتاجه حتى ترفع مهاراتك وتكمل طريقك الأكاديمي والمِهني بثقة.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _promoTimer = Timer.periodic(const Duration(seconds: 14), (t) {
      if (_promoCards.isEmpty) return;
      final next = (_promoPageIndex + 1) % _promoCards.length;
      _promoPageController.animateToPage(next,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: CustomAppBarWidget(
            title: 'خريج',
            actions: [
              IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: ResponsiveHelper.getIconSize(context, baseIconSize: 24),
                ),
                onPressed: () {
                  themeProvider.toggleDarkMode();
                },
                tooltip: 'تبديل الثيم',
              ),
              IconButton(
                icon: Icon(
                  Icons.palette,
                  size: ResponsiveHelper.getIconSize(context, baseIconSize: 24),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => SimpleColorPicker(
                      onColorSelected: (color) {
                        themeProvider.setPrimaryColor(color);
                      },
                    ),
                  );
                },
                tooltip: 'اختيار اللون',
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
            child: SingleChildScrollView(
              padding: ResponsiveHelper.getPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(themeProvider),
                  SizedBox(height: ResponsiveHelper.getSpacing(context)),
                  _buildQuickAccessSection(themeProvider),
                  SizedBox(
                    height: ResponsiveHelper.getSpacing(
                      context,
                      mobileSpacing: 32,
                      tabletSpacing: 40,
                      desktopSpacing: 48,
                    ),
                  ),
                  _buildPopularCoursesSection(themeProvider),
                  SizedBox(
                    height: ResponsiveHelper.getSpacing(
                      context,
                      mobileSpacing: 16, // تقليل من 32 إلى 16
                      tabletSpacing: 20, // تقليل من 40 إلى 20
                      desktopSpacing: 24, // تقليل من 48 إلى 24
                    ),
                  ),
                  _buildProjectsSection(themeProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(SimpleThemeProvider themeProvider) {
    return Container(
      width: ResponsiveHelper.getContainerWidth(context),
      padding: ResponsiveHelper.getPadding(
        context,
        mobilePadding: const EdgeInsets.all(20),
        tabletPadding: const EdgeInsets.all(28),
        desktopPadding: const EdgeInsets.all(32),
      ),
      decoration: BoxDecoration(
        gradient: themeProvider.primaryGradient,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getBorderRadius(context, baseBorderRadius: 20),
        ),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withOpacity(0.3),
            blurRadius: ResponsiveHelper.getElevation(
              context,
              baseElevation: 20,
            ),
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  ResponsiveHelper.getSpacing(
                    context,
                    mobileSpacing: 12,
                    tabletSpacing: 14,
                    desktopSpacing: 16,
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getBorderRadius(
                      context,
                      baseBorderRadius: 12,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.waving_hand,
                  color: Colors.white,
                  size: ResponsiveHelper.getIconSize(context, baseIconSize: 32),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getSpacing(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً بك في',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.getFontSize(
                          context,
                          baseFontSize: 16,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'تطبيق خريج',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.getFontSize(
                          context,
                          baseFontSize: 24,
                          scaleFactor: 1.2,
                        ),
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),
          // Promo carousel (two cards) - made responsive
          LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = MediaQuery.of(context).size.height;
              final maxHeight = (screenHeight * 0.25).clamp(120.0, 180.0);

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                  minHeight: 100.0,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _promoPageController,
                        itemCount: _promoCards.length,
                        onPageChanged: (idx) =>
                            setState(() => _promoPageIndex = idx),
                        itemBuilder: (ctx, idx) {
                          final card = _promoCards[idx];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveHelper.isDesktop(context)
                                    ? 18
                                    : 12,
                                vertical: ResponsiveHelper.isDesktop(context)
                                    ? 16
                                    : 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.18)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (idx == 0)
                                        Text('🎓',
                                            style: TextStyle(
                                              fontSize:
                                                  ResponsiveHelper.getFontSize(
                                                      context,
                                                      baseFontSize: 16),
                                            )),
                                      if (idx == 0) const SizedBox(width: 6),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Text(
                                            card['body'] ?? '',
                                            textAlign: TextAlign.center,
                                            maxLines: null,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize:
                                                  ResponsiveHelper.getFontSize(
                                                      context,
                                                      baseFontSize: 15),
                                              height: 1.3,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 6),
                    // Indicators - smaller on mobile
                    SafeArea(
                      top: false,
                      bottom: true,
                      minimum: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_promoCards.length, (i) {
                          final active = i == _promoPageIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 14 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection(SimpleThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.flash_on,
              color: themeProvider.primaryColor,
              size: ResponsiveHelper.getIconSize(context, baseIconSize: 28),
            ),
            SizedBox(
              width: ResponsiveHelper.getSpacing(
                context,
                mobileSpacing: 8,
                tabletSpacing: 12,
                desktopSpacing: 16,
              ),
            ),
            Text(
              'الوصول السريع',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      baseFontSize: 20,
                    ),
                  ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context)),
        Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final cs = theme.colorScheme;
            final w = MediaQuery.of(context).size.width;
            final circleSize = w < 360 ? 56.0 : (w < 600 ? 64.0 : 72.0);
            final iconSize = circleSize * 0.48;

            // Two rows, three items each (no scroll), RTL order
            final itemBox = (Widget child) => SizedBox(
                  width: circleSize + 40,
                  child: child,
                );

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  textDirection: TextDirection.rtl,
                  children: [
                    itemBox(_buildCircleQuickItem(
                      size: circleSize,
                      iconSize: iconSize,
                      bgColor: cs.primary,
                      icon: Icons.storefront,
                      label: 'مشاريع التخرج',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProjectsScreen(),
                          ),
                        );
                      },
                    )),
                    itemBox(_buildCircleQuickItem(
                      size: circleSize,
                      iconSize: iconSize,
                      bgColor: cs.primary,
                      icon: Icons.school,
                      label: 'الدورات المجانية',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FreeCoursesScreen(),
                          ),
                        );
                      },
                    )),
                    itemBox(_buildCircleQuickItem(
                      size: circleSize,
                      iconSize: iconSize,
                      bgColor: cs.primary,
                      icon: Icons.category,
                      label: 'الأقسام',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DepartmentsScreen(),
                          ),
                        );
                      },
                    )),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getSpacing(context)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  textDirection: TextDirection.rtl,
                  children: [
                    itemBox(_buildCircleQuickItem(
                      size: circleSize,
                      iconSize: iconSize,
                      bgColor: cs.primary,
                      icon: Icons.menu_book,
                      label: 'بحوث',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ResearchScreen()));
                      },
                    )),
                    itemBox(_buildCircleQuickItem(
                      size: circleSize,
                      iconSize: iconSize,
                      bgColor: cs.primary,
                      icon: Icons.videocam, // use camera/film icon for seminar
                      label: 'سمنار Seminar',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SeminarScreen()));
                      },
                    )),
                    itemBox(_buildCircleQuickItem(
                      size: circleSize,
                      iconSize: iconSize,
                      bgColor: cs.primary,
                      icon: Icons.article,
                      label: 'تقارير',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ReportScreen()));
                      },
                    )),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCircleQuickItem({
    required double size,
    required double iconSize,
    required Color bgColor,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return StatefulBuilder(
      builder: (context, setSB) {
        bool pressed = false;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: bgColor.withOpacity(isDark ? 0.25 : 0.18),
          highlightColor: bgColor.withOpacity(isDark ? 0.15 : 0.12),
          onHighlightChanged: (v) => setSB(() => pressed = v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (_) {
                  Color container;
                  Color onContainer;
                  if (bgColor.value == cs.primary.value) {
                    container = cs.primaryContainer;
                    onContainer = cs.onPrimaryContainer;
                  } else if (bgColor.value == cs.secondary.value) {
                    container = cs.secondaryContainer;
                    onContainer = cs.onSecondaryContainer;
                  } else if (bgColor.value == cs.tertiary.value) {
                    container = cs.tertiaryContainer;
                    onContainer = cs.onTertiaryContainer;
                  } else {
                    container = cs.surfaceVariant;
                    onContainer = cs.onSurfaceVariant;
                  }

                  return AnimatedScale(
                    duration: const Duration(milliseconds: 140),
                    scale: pressed ? 0.96 : 1.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.15),
                          radius: 0.95,
                          colors: [
                            container,
                            Color.alphaBlend(
                              bgColor.withOpacity(isDark ? 0.14 : 0.10),
                              container,
                            ),
                          ],
                        ),
                        border: Border.all(
                          color: cs.outlineVariant.withOpacity(
                            isDark ? 0.25 : 0.18,
                          ),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.25 : 0.08,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(icon, size: iconSize, color: onContainer),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(
                height: ResponsiveHelper.getSpacing(
                  context,
                  mobileSpacing: 10,
                  tabletSpacing: 12,
                  desktopSpacing: 14,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopularCoursesSection(SimpleThemeProvider themeProvider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadPopularCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSection(themeProvider, 'الدورات الأكثر شهرة');
        }

        if (snapshot.hasError) {
          return _buildErrorSection(
            themeProvider,
            'الدورات الأكثر شهرة',
            snapshot.error.toString(),
          );
        }

        final courses = snapshot.data ?? [];
        if (courses.isEmpty) {
          return _buildEmptySection(
            themeProvider,
            'الدورات الأكثر شهرة',
            'لا توجد دورات متاحة',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: themeProvider.primaryColor,
                      size: ResponsiveHelper.getIconSize(
                        context,
                        baseIconSize: 28,
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveHelper.getSpacing(
                        context,
                        mobileSpacing: 8,
                        tabletSpacing: 12,
                        desktopSpacing: 16,
                      ),
                    ),
                    Text(
                      'الدورات الأكثر شهرة',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getFontSize(
                              context,
                              baseFontSize: 20,
                            ),
                          ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () async {
                    try {
                      // الحصول على معرف المعهد من TokenManager
                      final tokenManager = await TokenManager.getInstance();
                      final instituteId = await tokenManager.getInstituteId();

                      if (instituteId != null && instituteId.isNotEmpty) {
                        // الانتقال إلى صفحة الأساتذة مع تمرير المعاملات عبر Navigator.push
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InstructorsScreen(
                              instituteId: instituteId,
                              instituteName: 'المعهد التقنية المتقدمة',
                            ),
                          ),
                        );
                      } else {
                        // في حالة عدم وجود معرف المعهد، عرض رسالة خطأ
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('لا يمكن الوصول إلى معلومات المعهد'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      print('❌ خطأ في الانتقال إلى صفحة الأساتذة: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('حدث خطأ، يرجى المحاولة مرة أخرى'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    Icons.arrow_forward,
                    size: ResponsiveHelper.getIconSize(
                      context,
                      baseIconSize: 18,
                    ),
                  ),
                  label: Text(
                    'عرض الكل',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(
                        context,
                        baseFontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
                height: ResponsiveHelper.getSpacing(context) *
                    0.5), // تقليل المسافة
            SizedBox(
              height: ResponsiveHelper.isMobile(context)
                  ? 155 // تقليل من 180 إلى 155
                  : ResponsiveHelper.isTablet(context)
                      ? 170 // تقليل من 200 إلى 170
                      : 185, // تقليل من 220 إلى 185
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getSpacing(
                    context,
                    mobileSpacing: 8,
                    tabletSpacing: 12,
                    desktopSpacing: 16,
                  ),
                ),
                itemCount: courses.length,
                separatorBuilder: (context, index) =>
                    SizedBox(width: ResponsiveHelper.getSpacing(context)),
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return _buildHorizontalCourseCard(course, themeProvider);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalCourseCard(
    Map<String, dynamic> course,
    SimpleThemeProvider themeProvider,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(
              course: course,
            ),
          ),
        );
      },
      child: Container(
        width: ResponsiveHelper.isMobile(context)
            ? 300 // زيادة العرض قليلاً لاستيعاب الزر
            : ResponsiveHelper.isTablet(context)
                ? 340
                : 380,
        child: Card(
          elevation: 8, // زيادة الظل للعمق
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // زوايا أكثر دائرية
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  themeProvider.primaryColor.withOpacity(0.08),
                  themeProvider.primaryColor.withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              // إضافة حدود ناعمة
              border: Border.all(
                color: themeProvider.primaryColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12), // تقليل من 16 إلى 12
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // إضافة هذا لتقليل الحجم
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // تغيير إلى start
                    children: [
                      // صورة الدورة مع تحسينات
                      Container(
                        width: ResponsiveHelper.isMobile(context)
                            ? 70
                            : 80, // تقليل الحجم قليلاً
                        height: ResponsiveHelper.isMobile(context) ? 70 : 80,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(16), // زوايا أكثر دائرية
                          boxShadow: [
                            BoxShadow(
                              color:
                                  themeProvider.primaryColor.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: course['image_url'] != null &&
                                  course['image_url'].toString().isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(course['image_url']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          gradient: course['image_url'] == null ||
                                  course['image_url'].toString().isEmpty
                              ? themeProvider.primaryGradient
                              : null,
                        ),
                        child: course['image_url'] == null ||
                                course['image_url'].toString().isEmpty
                            ? Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: ResponsiveHelper.getIconSize(
                                  context,
                                  baseIconSize: 30, // تقليل حجم الأيقونة
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // اسم الدورة
                            Text(
                              course['title'] ?? 'دورة غير محددة',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14, // تقليل حجم الخط قليلاً
                                    color: themeProvider.primaryColor,
                                    height: 1.2, // تقليل المسافة بين الأسطر
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6), // تقليل المسافة

                            // خط فاصل أنيق (أصغر)
                            Container(
                              width: 45, // تقليل العرض
                              height: 2,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1),
                                gradient: LinearGradient(
                                  colors: [
                                    themeProvider.primaryColor.withOpacity(0.8),
                                    themeProvider.primaryColor.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6), // تقليل المسافة

                            // اسم الأستاذ
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 12, // تقليل حجم الأيقونة
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    course['instructor_name'] ??
                                        'أستاذ غير محدد',
                                    style: TextStyle(
                                      fontSize: 11, // تقليل حجم الخط
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3), // تقليل المسافة

                            // عدد المحاضرات
                            Row(
                              children: [
                                Icon(
                                  Icons.video_library,
                                  size: 12, // تقليل حجم الأيقونة
                                  color: themeProvider.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${course['lectures_count'] ?? 15} محاضرة',
                                  style: TextStyle(
                                    fontSize: 11, // تقليل حجم الخط
                                    color: themeProvider.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8), // تقليل المسافة من 12 إلى 8

                  // زر CTA أنيق (أصغر)
                  Container(
                    width: double.infinity,
                    height: 32, // تقليل الارتفاع
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(16), // تقليل نصف القطر
                      gradient: LinearGradient(
                        colors: [
                          themeProvider.primaryColor,
                          themeProvider.primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.primaryColor.withOpacity(0.3),
                          blurRadius: 6, // تقليل الظل
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourseDetailScreen(
                                course: course,
                              ),
                            ),
                          );
                        },
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 16, // تقليل حجم الأيقونة
                              ),
                              SizedBox(width: 4),
                              Text(
                                'ابدأ الآن',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12, // تقليل حجم الخط
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ), // إغلاق Container الداخلي
        ), // إغلاق Card
      ), // إغلاق Container الخارجي
    ); // إغلاق GestureDetector
  }

  Widget _buildProjectsSection(SimpleThemeProvider themeProvider) {
    // Show featured projects (those with id starting with 'featured_')
    final projects = DataService.getDummyProjects()
        .where((p) => p.id.startsWith('featured_'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.work,
              color: themeProvider.primaryColor,
              size: ResponsiveHelper.getIconSize(context, baseIconSize: 28),
            ),
            SizedBox(
              width: ResponsiveHelper.getSpacing(
                context,
                mobileSpacing: 8,
                tabletSpacing: 12,
                desktopSpacing: 16,
              ),
            ),
            Text(
              'مشاريع مميزة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      baseFontSize: 20,
                    ),
                  ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context)),
        SizedBox(
          height: ResponsiveHelper.getContainerHeight(
            context,
            heightPercentage: 0.25,
            minHeight: 200,
            maxHeight: 300,
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Container(
                width: ResponsiveHelper.getContainerWidth(
                  context,
                  widthPercentage: 0.8,
                  maxWidth: 320,
                ),
                margin: EdgeInsets.only(
                  left: ResponsiveHelper.getSpacing(context),
                ),
                child: Card(
                  elevation: ResponsiveHelper.getElevation(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getBorderRadius(context),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getBorderRadius(context),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          themeProvider.primaryColor.withOpacity(0.1),
                          themeProvider.primaryColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: ResponsiveHelper.getPadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(
                                ResponsiveHelper.getSpacing(
                                  context,
                                  mobileSpacing: 8,
                                  tabletSpacing: 10,
                                  desktopSpacing: 12,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: themeProvider.primaryColor,
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getBorderRadius(
                                    context,
                                    baseBorderRadius: 8,
                                  ),
                                ),
                              ),
                              child: Icon(
                                Icons.code,
                                color: Colors.white,
                                size: ResponsiveHelper.getIconSize(
                                  context,
                                  baseIconSize: 20,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: ResponsiveHelper.getSpacing(
                                context,
                                mobileSpacing: 12,
                                tabletSpacing: 14,
                                desktopSpacing: 16,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                project.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: ResponsiveHelper.getFontSize(
                                        context,
                                        baseFontSize: 16,
                                      ),
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getSpacing(
                            context,
                            mobileSpacing: 12,
                            tabletSpacing: 14,
                            desktopSpacing: 16,
                          ),
                        ),
                        Text(
                          project.description,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: ResponsiveHelper.getFontSize(
                                      context,
                                      baseFontSize: 14,
                                    ),
                                  ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveHelper.getSpacing(
                                  context,
                                  mobileSpacing: 8,
                                  tabletSpacing: 10,
                                  desktopSpacing: 12,
                                ),
                                vertical: ResponsiveHelper.getSpacing(
                                  context,
                                  mobileSpacing: 4,
                                  tabletSpacing: 6,
                                  desktopSpacing: 8,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: themeProvider.primaryColor.withOpacity(
                                  0.2,
                                ),
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getBorderRadius(
                                    context,
                                    baseBorderRadius: 8,
                                  ),
                                ),
                              ),
                              child: Text(
                                'متوسط',
                                style: TextStyle(
                                  color: themeProvider.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: ResponsiveHelper.getFontSize(
                                    context,
                                    baseFontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // If featured project, show custom bottom sheet with details
                                if (project.id.startsWith('featured_')) {
                                  _showFeaturedDetailsSheet(context, project);
                                  return;
                                }

                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (ctx) => ProjectDetailsScreen(
                                    type: project.id,
                                    title: project.title,
                                    description: project.description,
                                    examples: project.examples,
                                    howToWrite: project.howToWrite,
                                  ),
                                ));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeProvider.primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveHelper.getSpacing(
                                    context,
                                  ),
                                  vertical: ResponsiveHelper.getSpacing(
                                    context,
                                    mobileSpacing: 8,
                                    tabletSpacing: 10,
                                    desktopSpacing: 12,
                                  ),
                                ),
                              ),
                              child: Text(
                                'عرض',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getFontSize(
                                    context,
                                    baseFontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFeaturedDetailsSheet(BuildContext context, dynamic project) {
    final theme = Theme.of(context);

    // Local mapping for the detailed content per featured id (do not modify DataService)
    final Map<String, Map<String, dynamic>> featuredContent = {
      'featured_ecommerce': {
        'features': [
          'حساب مستخدم (تسجيل/تسجيل دخول/استرجاع كلمة المرور).',
          'عربة تسوّق ومفضّلة مع حفظ العناصر.',
          'فلاتر بحث متقدّمة (سعر، فئة، علامة تجارية، تقييم).',
          'بوابة دفع إلكتروني ومحافظ محلية وتتبّع الطلب.',
          'مراجعات وتقييمات المنتجات + تنبيهات إشعارات.',
        ],
        'goals': [
          'تمكين البيع أونلاين وإدارة الطلبات بكفاءة.',
          'تحسين تجربة الشراء وتقليل التسرّب قبل الدفع.',
          'توفير لوحة تحكّم للتجار لإدارة المنتجات والمخزون.',
          'تقديم تقارير مبيعات مبسّطة لدعم القرار.',
          'قابلية توسّع مستقبلية (عروض، كوبونات، شركات شحن).',
        ],
        'whatsapp':
            'مرحبا 👋\nأرغب ببناء متجر إلكتروني متكامل. ممكن تفاصيل إضافية؟'
      },
      'featured_clothing': {
        'features': [
          'كتالوج أزياء مع مقاسات وألوان وصور لكل متغير.',
          'جدول مقاسات تفاعلي ونصائح اختيار القياس.',
          'كوبونات وخصومات موسمية وبانرات عروض.',
          'سلة + دفع إلكتروني + تتبع الشحن.',
          'لوحة إدارة للمخزون والفئات (رجالي/نسائي/أطفال).',
        ],
        'goals': [
          'عرض المنتجات بطريقة جذّابة تقلّل الاسترجاع بسبب المقاس.',
          'تسهيل عملية الشراء من الموبايل.',
          'إدارة المخزون والطلبيات بأقل جهد.',
          'بناء ولاء العملاء عبر العروض والتنبيهات.',
          'قابلية ربطه مع سوق/إنستغرام شوب مستقبلًا.',
        ],
        'whatsapp': 'مرحبا 👋\nأرغب ببناء موقع لمتجر ملابس. ممكن تفاصيل إضافية؟'
      },
      'featured_phones': {
        'features': [
          'قاعدة مواصفات للأجهزة (RAM/Storage/Camera/5G…).',
          'مقارنة حتى 3 هواتف جنبًا إلى جنب.',
          'ربط الهاتف بإكسسوارات متوافقة.',
          'حجز مسبق (Pre-Order) وفواتير وضمان إلكتروني.',
          'لوحة إدارة للمواصفات واستيراد CSV للأجهزة.',
        ],
        'goals': [
          'مساعدة العميل على اتخاذ قرار شراء عبر المقارنة السريعة.',
          'زيادة المبيعات بإظهار الإكسسوارات المتوافقة.',
          'أتمتة الضمان والفواتير وتقليل الأخطاء اليدوية.',
          'دعم الحملات (حجوزات) للأجهزة الجديدة.',
          'سهولة تحديث المواصفات بكميات كبيرة.',
        ],
        'whatsapp':
            'مرحبا 👋\nأرغب ببناء موقع لمتجر هواتف مع مقارنة مواصفات. ممكن تفاصيل إضافية؟'
      },
      'featured_robot': {
        'features': [
          'أوضاع تشغيل: تتبّع خط / تجنّب عوائق / تحكّم يدوي.',
          'تحكّم عبر تطبيق موبايل (Bluetooth/Wi-Fi).',
          'خوارزمية PID لنعومة الحركة.',
          'قراءة حساسات (IR/Ultrasonic/IMU) مع عرض مباشر في التطبيق.',
          'بطارية Li-ion قابلة للشحن مع حماية.',
        ],
        'goals': [
          'بناء نموذج عملي يدمج العتاد + البرمجيات.',
          'تعلّم أساسيات التحكم والـPID والحساسات.',
          'تقديم إثبات جدوى (Demo) قابل للتوسعة.',
          'توثيق كامل: كود، مخطط دائرة، BOM، دليل تشغيل.',
          'إتاحة تطوير ميزات لاحقة (تسجيل مسار/شاسيه 3D).',
        ],
        'whatsapp':
            'مرحبا 👋\nأرغب بتنفيذ مشروع روبوت ذكي (تتبع خط/تجنب عوائق). ممكن تفاصيل إضافية؟'
      },
    };

    final content = featuredContent[project.id] ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16))),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                        child: Text(project.title,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold))),
                    const SizedBox(height: 12),
                    Text(project.description, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    Text('مميزات المشروع',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (content['features'] != null)
                      ...List<Widget>.from((content['features'] as List).map(
                          (f) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(children: [
                                const Text('🔹'),
                                const SizedBox(width: 8),
                                Expanded(child: Text(f))
                              ])))),
                    const SizedBox(height: 12),
                    Text('أهداف المشروع',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (content['goals'] != null)
                      ...List<Widget>.from((content['goals'] as List).map((g) =>
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(children: [
                                const Text('•'),
                                const SizedBox(width: 8),
                                Expanded(child: Text(g))
                              ])))),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final number = '9647748687725';
                        final msg = content['whatsapp'] ??
                            'مرحبا 👋\nأريد تفاصيل عن المشروع.';
                        final encoded = Uri.encodeComponent(msg);
                        final url = 'https://wa.me/$number?text=$encoded';
                        final uri = Uri.parse(url);
                        try {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        } catch (_) {
                          await launchUrl(uri);
                        }
                      },
                      icon: const Icon(Icons.message_outlined),
                      label: const Text('تواصل معنا'),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // تحميل الدورات الشائعة من API مع دعم الكاش
  Future<List<Map<String, dynamic>>> _loadPopularCourses() async {
    try {
      final tokenManager = await TokenManager.getInstance();
      final instituteId = await tokenManager.getInstituteId();

      if (instituteId == null || instituteId.isEmpty) {
        throw Exception('معرف المعهد غير متوفر');
      }

      // البحث في الكاش أولاً
      final cacheManager = CacheManager.instance;
      await cacheManager.initialize();

      final cacheKey = 'popular_courses_$instituteId';
      final cachedCourses = await cacheManager.getCourses(cacheKey);

      if (cachedCourses != null && cachedCourses.isNotEmpty) {
        print('📦 تم تحميل ${cachedCourses.length} دورات شائعة من الكاش');
        return cachedCourses.cast<Map<String, dynamic>>();
      }

      final url = '${AppConstants.baseUrl}/api/institutes/$instituteId/courses';
      final headers = await ApiHeadersManager.instance.getAuthHeaders();

      print('🔄 جاري تحميل الدورات الشائعة من API: $url');

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final allCourses = jsonData['data'] as List<dynamic>;

        // فلترة الدورات المدفوعة فقط (استبعاد الدورات المجانية)
        final paidCourses = allCourses.where((course) {
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

        print(
            '🔍 تم فلترة ${allCourses.length - paidCourses.length} دورة مجانية من الدورات الشائعة، متبقي ${paidCourses.length} دورة مدفوعة');

        // ترتيب الدورات حسب عدد الطلاب (الأكثر شهرة أولاً)
        paidCourses.sort((a, b) {
          final studentsCountA = (a['students_count'] ?? 0) as int;
          final studentsCountB = (b['students_count'] ?? 0) as int;
          return studentsCountB.compareTo(studentsCountA);
        });

        // جلب أسماء الأساتذة للدورات الـ 5 الأولى فقط
        final coursesWithInstructors = <Map<String, dynamic>>[];

        for (var course in paidCourses.take(5)) {
          final instructorName = await _getInstructorName(
            course['instructor_id'],
          );
          final courseData = Map<String, dynamic>.from(course);
          courseData['instructor_name'] = instructorName;
          // حساب عدد المحاضرات (افتراضي بناءً على عدد الطلاب)
          courseData['lectures_count'] = (course['students_count'] ?? 10) + 5;
          coursesWithInstructors.add(courseData);
        }

        // حفظ في الكاش
        await cacheManager.setCourses(cacheKey, coursesWithInstructors);

        print(
          '✅ تم تحميل ${coursesWithInstructors.length} دورات شائعة من API وحفظها في الكاش (أقصى 5 دورات مرتبة حسب الشهرة)',
        );
        return coursesWithInstructors;
      } else {
        // التحقق من انتهاء التوكن
        if (await TokenExpiredHandler.handleTokenExpiration(
          context,
          statusCode: response.statusCode,
          errorMessage: response.body,
        )) {
          return []; // إرجاع قائمة فارغة في حالة انتهاء التوكن
        }

        throw Exception('فشل في تحميل الدورات: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في تحميل الدورات الشائعة: $e');

      // التحقق من انتهاء التوكن في حالة الخطأ
      if (await TokenExpiredHandler.handleTokenExpiration(
        context,
        errorMessage: e.toString(),
      )) {
        return []; // إرجاع قائمة فارغة في حالة انتهاء التوكن
      }

      throw e;
    }
  }

  // جلب اسم الأستاذ بواسطة معرفه
  Future<String> _getInstructorName(String instructorId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/instructors/$instructorId';
      final headers = await ApiHeadersManager.instance.getAuthHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final instructorData = json.decode(response.body);
        return instructorData['name'] ?? 'أستاذ غير محدد';
      } else {
        // التحقق من انتهاء التوكن
        await TokenExpiredHandler.handleTokenExpiration(
          context,
          statusCode: response.statusCode,
          errorMessage: response.body,
        );
        return 'أستاذ غير محدد';
      }
    } catch (e) {
      print('⚠️ خطأ في جلب اسم الأستاذ: $e');

      // التحقق من انتهاء التوكن
      await TokenExpiredHandler.handleTokenExpiration(
        context,
        errorMessage: e.toString(),
      );

      return 'أستاذ غير محدد';
    }
  }

  // بناء قسم التحميل
  Widget _buildLoadingSection(SimpleThemeProvider themeProvider, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              color: themeProvider.primaryColor,
              size: ResponsiveHelper.getIconSize(context, baseIconSize: 28),
            ),
            SizedBox(
              width: ResponsiveHelper.getSpacing(
                context,
                mobileSpacing: 8,
                tabletSpacing: 12,
                desktopSpacing: 16,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      baseFontSize: 20,
                    ),
                  ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context)),
        Container(
          height: 120,
          child: const InlineLoadingWidget(
            message: 'جاري تحميل الدورات...',
            size: 80,
          ),
        ),
      ],
    );
  }

  // بناء قسم الخطأ
  Widget _buildErrorSection(
    SimpleThemeProvider themeProvider,
    String title,
    String error,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              color: themeProvider.primaryColor,
              size: ResponsiveHelper.getIconSize(context, baseIconSize: 28),
            ),
            SizedBox(
              width: ResponsiveHelper.getSpacing(
                context,
                mobileSpacing: 8,
                tabletSpacing: 12,
                desktopSpacing: 16,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      baseFontSize: 20,
                    ),
                  ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context)),
        Container(
          height: 120,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color:
                      themeProvider.isDarkMode ? Colors.red[300] : Colors.red,
                ),
                SizedBox(height: 8),
                Text(
                  'فشل في تحميل الدورات',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // بناء قسم فارغ
  Widget _buildEmptySection(
    SimpleThemeProvider themeProvider,
    String title,
    String message,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              color: themeProvider.primaryColor,
              size: ResponsiveHelper.getIconSize(context, baseIconSize: 28),
            ),
            SizedBox(
              width: ResponsiveHelper.getSpacing(
                context,
                mobileSpacing: 8,
                tabletSpacing: 12,
                desktopSpacing: 16,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      baseFontSize: 20,
                    ),
                  ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context)),
        Container(
          height: 120,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 48,
                  color: themeProvider.isDarkMode
                      ? Colors.white30
                      : Colors.grey[400],
                ),
                SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
