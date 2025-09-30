import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MainCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final IconData? fallbackIcon;
  final double? imageSize;
  final bool enableFloating;
  final Color? primaryColor;

  const MainCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.onTap,
    this.fallbackIcon,
    this.imageSize,
    this.enableFloating = true,
    this.primaryColor,
  });

  @override
  State<MainCard> createState() => _MainCardState();
}

class _MainCardState extends State<MainCard> with TickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    // إنشاء تأثير طفو خفيف
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // بدء التأثير المتكرر إذا كان مفعلاً
    if (widget.enableFloating) {
      _floatingController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = widget.primaryColor ?? theme.colorScheme.primary;
    final imageSize = widget.imageSize ?? 90.0;

    // إنشاء تدرج لوني أكثر عمقاً وجمالاً
    final gradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.3, 0.7, 1.0],
            colors: [
              theme.colorScheme.surface.withOpacity(0.6),
              theme.colorScheme.surface.withOpacity(0.4),
              primaryColor.withOpacity(0.2),
              primaryColor.withOpacity(0.1),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.2, 0.6, 1.0],
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.8),
              primaryColor.withOpacity(0.12),
              primaryColor.withOpacity(0.18),
            ],
          );

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          final floatingOffset =
              widget.enableFloating ? _floatingAnimation.value : 0.0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            transform: Matrix4.identity()
              ..scale(_isPressed ? 0.92 : 1.0)
              ..translate(0.0, (_isPressed ? 12.0 : -2.0) + floatingOffset),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: _isPressed
                  ? [
                      // ظل عند الضغط
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.5)
                            : primaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      // الظل الرئيسي الكبير (يحاكي الطفو)
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.6)
                            : primaryColor.withOpacity(0.25),
                        blurRadius: 35 + (floatingOffset.abs() * 2),
                        offset: Offset(0, 18 + floatingOffset),
                        spreadRadius: -5,
                      ),
                      // ظل ثانوي لمزيد من العمق
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.4)
                            : primaryColor.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 12),
                        spreadRadius: -3,
                      ),
                      // الإضاءة من الأعلى اليسار
                      BoxShadow(
                        color: isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.white.withOpacity(0.9),
                        blurRadius: 20,
                        offset: const Offset(-8, -8),
                        spreadRadius: -2,
                      ),
                      // ظل من الأسفل اليمين
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.3)
                            : primaryColor.withOpacity(0.12),
                        blurRadius: 18,
                        offset: const Offset(8, 8),
                        spreadRadius: -4,
                      ),
                      // ظل إضافي للحصول على تأثير طبقي
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.2)
                            : primaryColor.withOpacity(0.08),
                        blurRadius: 45,
                        offset: const Offset(0, 25),
                        spreadRadius: -8,
                      ),
                    ],
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.8),
                width: 2.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12), // تقليل من 16 إلى 12
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // حاوية للصورة مع ظل إضافي محسن
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        // ظل رئيسي للصورة
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                          spreadRadius: -3,
                        ),
                        // ظل ثانوي لمزيد من العمق
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.5)
                              : primaryColor.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                          spreadRadius: -1,
                        ),
                        // إضاءة من الأعلى للصورة
                        BoxShadow(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.white.withOpacity(0.6),
                          blurRadius: 12,
                          offset: const Offset(-4, -4),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Container(
                        width: imageSize,
                        height: imageSize,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: primaryColor.withOpacity(0.2),
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: widget.imageUrl,
                            width: imageSize,
                            height: imageSize,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: imageSize,
                              height: imageSize,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.3),
                                    primaryColor.withOpacity(0.1),
                                  ],
                                ),
                              ),
                              child: const CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.3),
                                    primaryColor.withOpacity(0.1),
                                  ],
                                ),
                              ),
                              child: Icon(
                                widget.fallbackIcon ?? Icons.image,
                                size: imageSize * 0.4,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8), // تقليل من 12 إلى 8
                  // النص الرئيسي
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4), // تقليل من 8 إلى 4
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 13, // تقليل من 14 إلى 13
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withOpacity(0.9)
                            : theme.colorScheme.onSurface.withOpacity(0.8),
                        shadows: [
                          Shadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.white.withOpacity(0.8),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // النص الثانوي (اختياري)
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2), // تقليل من 4 إلى 2
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4), // تقليل من 8 إلى 4
                      child: Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: 11, // تقليل من 12 إلى 11
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
