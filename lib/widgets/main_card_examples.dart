// مثال لاستخدام MainCard في شاشة الكورسات
import 'package:flutter/material.dart';
import 'package:newgraduate/widgets/main_card.dart';

class CoursesGridExample extends StatelessWidget {
  const CoursesGridExample({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleCourses = [
      {
        'title': 'Flutter المتقدم',
        'subtitle': 'د. أحمد محمد',
        'imageUrl': 'https://example.com/flutter.png',
        'icon': Icons.mobile_friendly,
        'color': Colors.blue,
      },
      {
        'title': 'تطوير الويب',
        'subtitle': 'م. فاطمة علي',
        'imageUrl': 'https://example.com/web.png',
        'icon': Icons.web,
        'color': Colors.green,
      },
      {
        'title': 'قواعد البيانات',
        'subtitle': 'د. محمد سعد',
        'imageUrl': 'https://example.com/database.png',
        'icon': Icons.storage,
        'color': Colors.orange,
      },
      {
        'title': 'الذكاء الاصطناعي',
        'subtitle': 'د. نور حسن',
        'imageUrl': 'https://example.com/ai.png',
        'icon': Icons.psychology,
        'color': Colors.purple,
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الكورسات')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: sampleCourses.length,
          itemBuilder: (context, index) {
            final course = sampleCourses[index];
            return MainCard(
              imageUrl: course['imageUrl'] as String,
              title: course['title'] as String,
              subtitle: course['subtitle'] as String,
              fallbackIcon: course['icon'] as IconData,
              primaryColor: course['color'] as Color,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم اختيار: ${course['title']}'),
                    backgroundColor: course['color'] as Color,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// مثال آخر للملف الشخصي
class ProfileItemsExample extends StatelessWidget {
  const ProfileItemsExample({super.key});

  @override
  Widget build(BuildContext context) {
    final profileItems = [
      {
        'title': 'الملف الشخصي',
        'subtitle': 'عرض وتعديل البيانات',
        'icon': Icons.person,
        'color': Colors.blue,
      },
      {
        'title': 'الإعدادات',
        'subtitle': 'تخصيص التطبيق',
        'icon': Icons.settings,
        'color': Colors.grey,
      },
      {
        'title': 'الإحصائيات',
        'subtitle': '24 كورس مكتمل',
        'icon': Icons.analytics,
        'color': Colors.green,
      },
      {
        'title': 'المساعدة',
        'subtitle': 'الدعم والمساندة',
        'icon': Icons.help,
        'color': Colors.orange,
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: profileItems.length,
          itemBuilder: (context, index) {
            final item = profileItems[index];
            return MainCard(
              imageUrl: '', // بدون صورة لاستخدام الأيقونة
              title: item['title'] as String,
              subtitle: item['subtitle'] as String,
              fallbackIcon: item['icon'] as IconData,
              primaryColor: item['color'] as Color,
              imageSize: 60, // حجم أصغر للأيقونات
              enableFloating: index.isEven, // طفو للعناصر الزوجية فقط
              onTap: () {
                print('تم اختيار: ${item['title']}');
              },
            );
          },
        ),
      ),
    );
  }
}
