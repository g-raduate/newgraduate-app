import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Widget مخصص لعرض تحميل Lottie Animation جميل
class CustomLoadingWidget extends StatelessWidget {
  final String? message;
  final double size;
  final Color? backgroundColor;
  final bool showBackground;

  const CustomLoadingWidget({
    super.key,
    this.message,
    this.size = 150,
    this.backgroundColor,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Lottie Animation
        Lottie.asset(
          'images/loading.json',
          width: size,
          height: size,
          fit: BoxFit.contain,
          repeat: true,
          animate: true,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'NotoKufiArabic',
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (!showBackground) {
      return widget;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor ??
            Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget,
    );
  }
}

/// Widget للتحميل المركزي في الشاشة
class CenterLoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const CenterLoadingWidget({
    super.key,
    this.message,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomLoadingWidget(
        message: message,
        size: size,
        showBackground: true,
      ),
    );
  }
}

/// Widget للتحميل الصغير (inline)
class InlineLoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const InlineLoadingWidget({
    super.key,
    this.message,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return CustomLoadingWidget(
      message: message,
      size: size,
      showBackground: false,
    );
  }
}

/// Widget للتحميل داخل ListView (متوافق مع RefreshIndicator)
class ListLoadingWidget extends StatelessWidget {
  final String? message;
  final double size;
  final double topPadding;

  const ListLoadingWidget({
    super.key,
    this.message,
    this.size = 120,
    this.topPadding = 100,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: topPadding),
        Center(
          child: CustomLoadingWidget(
            message: message,
            size: size,
            showBackground: true,
          ),
        ),
        SizedBox(height: topPadding),
      ],
    );
  }
}
