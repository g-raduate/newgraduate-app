import 'package:flutter/material.dart';

class ResponsiveHelper {
  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // تحديد نوع الجهاز
  static bool isMobile(BuildContext context) {
    return getWidth(context) < 600;
  }

  static bool isTablet(BuildContext context) {
    return getWidth(context) >= 600 && getWidth(context) < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return getWidth(context) >= 1200;
  }

  // حساب عدد الأعمدة حسب حجم الشاشة
  static int getCrossAxisCount(
    BuildContext context, {
    int mobileCount = 2,
    int tabletCount = 3,
    int desktopCount = 4,
  }) {
    if (isMobile(context)) return mobileCount;
    if (isTablet(context)) return tabletCount;
    return desktopCount;
  }

  // حساب النسب حسب حجم الشاشة
  static double getAspectRatio(
    BuildContext context, {
    double mobileRatio = 1.2,
    double tabletRatio = 1.1,
    double desktopRatio = 1.0,
  }) {
    if (isMobile(context)) return mobileRatio;
    if (isTablet(context)) return tabletRatio;
    return desktopRatio;
  }

  // حساب الحشوة حسب حجم الشاشة
  static EdgeInsets getPadding(
    BuildContext context, {
    EdgeInsets? mobilePadding,
    EdgeInsets? tabletPadding,
    EdgeInsets? desktopPadding,
  }) {
    mobilePadding ??= const EdgeInsets.all(16);
    tabletPadding ??= const EdgeInsets.all(24);
    desktopPadding ??= const EdgeInsets.all(32);

    if (isMobile(context)) return mobilePadding;
    if (isTablet(context)) return tabletPadding;
    return desktopPadding;
  }

  // حساب المسافة بين العناصر
  static double getSpacing(
    BuildContext context, {
    double mobileSpacing = 16,
    double tabletSpacing = 20,
    double desktopSpacing = 24,
  }) {
    if (isMobile(context)) return mobileSpacing;
    if (isTablet(context)) return tabletSpacing;
    return desktopSpacing;
  }

  // حساب حجم الخط
  static double getFontSize(
    BuildContext context, {
    double baseFontSize = 14,
    double scaleFactor = 1.0,
  }) {
    double screenWidth = getWidth(context);
    double scale = 1.0;

    if (screenWidth < 600) {
      scale = 1.0; // الهواتف
    } else if (screenWidth < 1200) {
      scale = 1.2; // التابلت
    } else {
      scale = 1.4; // الحاسوب
    }

    return baseFontSize * scale * scaleFactor;
  }

  // حساب حجم الأيقونات
  static double getIconSize(
    BuildContext context, {
    double baseIconSize = 24,
  }) {
    if (isMobile(context)) return baseIconSize;
    if (isTablet(context)) return baseIconSize * 1.2;
    return baseIconSize * 1.4;
  }

  // حساب عرض الحاوية
  static double getContainerWidth(
    BuildContext context, {
    double widthPercentage = 0.9,
    double? maxWidth,
  }) {
    double screenWidth = getWidth(context);
    double calculatedWidth = screenWidth * widthPercentage;

    if (maxWidth != null && calculatedWidth > maxWidth) {
      return maxWidth;
    }

    return calculatedWidth;
  }

  // حساب ارتفاع الحاوية
  static double getContainerHeight(
    BuildContext context, {
    double heightPercentage = 0.3,
    double? maxHeight,
    double? minHeight,
  }) {
    double screenHeight = getHeight(context);
    double calculatedHeight = screenHeight * heightPercentage;

    if (maxHeight != null && calculatedHeight > maxHeight) {
      calculatedHeight = maxHeight;
    }

    if (minHeight != null && calculatedHeight < minHeight) {
      calculatedHeight = minHeight;
    }

    return calculatedHeight;
  }

  // حساب نصف قطر الحواف
  static double getBorderRadius(
    BuildContext context, {
    double baseBorderRadius = 16,
  }) {
    if (isMobile(context)) return baseBorderRadius;
    if (isTablet(context)) return baseBorderRadius * 1.2;
    return baseBorderRadius * 1.4;
  }

  // حساب الارتفاع للكروت
  static double getElevation(
    BuildContext context, {
    double baseElevation = 8,
  }) {
    if (isMobile(context)) return baseElevation;
    if (isTablet(context)) return baseElevation * 1.2;
    return baseElevation * 1.4;
  }
}
