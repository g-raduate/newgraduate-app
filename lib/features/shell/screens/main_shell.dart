import 'package:flutter/material.dart';
import 'package:newgraduate/features/home/screens/home_screen.dart' as home;
import 'package:newgraduate/features/departments/screens/departments_screen.dart';
import 'package:newgraduate/features/profile/screens/profile_screen.dart';
import 'package:newgraduate/widgets/location_aware_courses_screen.dart';
import 'package:newgraduate/managers/security_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // تهيئة نظام الأمان بعد دخول الشاشة الرئيسية
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!SecurityManager.isInitialized) {
        print('🔒 MainScreen: تهيئة نظام الأمان');
        SecurityManager.initialize(context);
      }
    });
  }

  final List<Widget> _screens = [
    home.HomeScreen(), // سنستخدم الشاشة الأصلية مؤقتاً
    const DepartmentsScreen(),
    const LocationAwareCoursesScreen(), // الشاشة الجديدة مع فحص الموقع
    const ProfileScreen(), // الشاشة المحسنة
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'الرئيسية',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.category),
      label: 'الأقسام',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.video_library),
      label: 'دوراتك',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'الحساب',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E1E1E),
                    Color(0xFF121212),
                  ],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? Colors.transparent : colorScheme.surface,
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurfaceVariant,
            selectedFontSize: 12,
            unselectedFontSize: 10,
            selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontFamily: 'NotoKufiArabic'),
            unselectedLabelStyle: const TextStyle(fontFamily: 'NotoKufiArabic'),
            elevation: 0,
            items: _bottomNavItems.map((item) {
              final index = _bottomNavItems.indexOf(item);
              final isSelected = _currentIndex == index;

              return BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Container(
                          width: 30,
                          height: 3,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(isSelected ? 6 : 0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer
                                  .withOpacity(isDark ? 0.25 : 0.6)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          (item.icon as Icon).icon,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                          size: isSelected ? 26 : 24,
                        ),
                      ),
                    ],
                  ),
                ),
                label: item.label!,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
