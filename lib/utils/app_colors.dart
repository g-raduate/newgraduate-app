import 'package:flutter/material.dart';

class AppColors {
  // ألوان الأقسام الموحدة
  static const Color departmentColor1 = Color(0xFF2196F3);
  static const Color departmentColor2 = Color(0xFF1976D2);
  static const Color departmentColor3 = Color(0xFF0D47A1);

  // ألوان الدورات
  static const Color courseColor1 = Color(0xFF4CAF50);
  static const Color courseColor2 = Color(0xFF388E3C);
  static const Color courseColor3 = Color(0xFF1B5E20);

  // ألوان المشاريع
  static const Color projectColor1 = Color(0xFFFF9800);
  static const Color projectColor2 = Color(0xFFE65100);
  static const Color projectColor3 = Color(0xFFBF360C);

  // ألوان أخرى
  static const Color errorColor = Color(0xFFF44336);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);
}

class CustomBoxDecoration {
  // تدرج للأقسام
  static BoxDecoration departmentGradient = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.departmentColor1,
        AppColors.departmentColor2,
        AppColors.departmentColor3,
      ],
    ),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
  );

  // تدرج للدورات
  static BoxDecoration courseGradient = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.courseColor1,
        AppColors.courseColor2,
        AppColors.courseColor3,
      ],
    ),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
  );

  // تدرج للمشاريع
  static BoxDecoration projectGradient = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.projectColor1,
        AppColors.projectColor2,
        AppColors.projectColor3,
      ],
    ),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
  );

  // تدرج شفاف للبطاقات
  static BoxDecoration cardGradient(Color color) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.6),
          ],
        ),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      );
}
