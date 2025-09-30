import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class SimpleColorPicker extends StatelessWidget {
  final Function(Color) onColorSelected;

  const SimpleColorPicker({
    super.key,
    required this.onColorSelected,
  });

  static const List<Color> colors = [
    // الألوان الأساسية
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.cyan,
    Colors.indigo,

    // ألوان إضافية جميلة
    Color(0xFF6366F1), // بنفسجي فاتح
    Color(0xFF8B5CF6), // بنفسجي متوسط
    Color(0xFFEC4899), // زهري فاتح
    Color(0xFFEF4444), // أحمر فاتح
    Color(0xFFF97316), // برتقالي فاتح
    Color(0xFF10B981), // أخضر زمردي
    Color(0xFF06B6D4), // أزرق فيروزي
    Color(0xFF3B82F6), // أزرق فاتح

    // ألوان جديدة متنوعة
    Color(0xFF8E24AA), // بنفسجي داكن
    Color(0xFF00ACC1), // فيروزي داكن
    Color(0xFF43A047), // أخضر غابات
    Color(0xFFFF7043), // برتقالي محروق
    Color(0xFF5C6BC0), // أزرق بنفسجي
    Color(0xFFAB47BC), // بنفسجي وردي
    Color(0xFF26A69A), // أخضر بحري
    Color(0xFFFFCA28), // أصفر ذهبي

    // ألوان عصرية إضافية
    Color(0xFF7C4DFF), // بنفسجي كهربائي
    Color(0xFF40E0D0), // فيروزي مشرق
    Color(0xFF98FB98), // أخضر نعناعي
    Color(0xFFFF69B4), // زهري صارخ
    Color(0xFF1E88E5), // أزرق محيطي
    Color(0xFF7CB342), // أخضر ليموني
    Color(0xFFFF6F00), // برتقالي غروب
    Color(0xFF6A1B9A), // بنفسجي ملكي

    // ألوان مرشدة ومريحة
    Color(0xFF795548), // بني دافئ
    Color(0xFF546E7A), // رمادي مزرق
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            ResponsiveHelper.getBorderRadius(context, baseBorderRadius: 20)),
      ),
      child: Container(
        width: ResponsiveHelper.getContainerWidth(context,
            widthPercentage: 0.9, maxWidth: 400),
        padding: ResponsiveHelper.getPadding(
          context,
          mobilePadding: const EdgeInsets.all(20),
          tabletPadding: const EdgeInsets.all(24),
          desktopPadding: const EdgeInsets.all(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اختر لون التطبيق',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize:
                        ResponsiveHelper.getFontSize(context, baseFontSize: 20),
                  ),
            ),
            SizedBox(
                height: ResponsiveHelper.getSpacing(context,
                    mobileSpacing: 20, tabletSpacing: 24, desktopSpacing: 28)),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveHelper.getCrossAxisCount(context,
                    mobileCount: 6, tabletCount: 8, desktopCount: 10),
                crossAxisSpacing: ResponsiveHelper.getSpacing(context,
                    mobileSpacing: 10, tabletSpacing: 12, desktopSpacing: 15),
                mainAxisSpacing: ResponsiveHelper.getSpacing(context,
                    mobileSpacing: 10, tabletSpacing: 12, desktopSpacing: 15),
                childAspectRatio: 1,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];
                return GestureDetector(
                  onTap: () {
                    onColorSelected(color);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: ResponsiveHelper.getElevation(context,
                              baseElevation: 8),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(
                height: ResponsiveHelper.getSpacing(context,
                    mobileSpacing: 20, tabletSpacing: 24, desktopSpacing: 28)),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  fontSize:
                      ResponsiveHelper.getFontSize(context, baseFontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
