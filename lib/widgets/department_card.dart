import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:newgraduate/widgets/smart_youtube_player_manager.dart';
import 'package:newgraduate/widgets/user_info_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class DepartmentCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final String? promoVideoUrl;
  final VoidCallback? onImageTap;

  const DepartmentCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.onTap,
    this.promoVideoUrl,
    this.onImageTap,
  });

  @override
  State<DepartmentCard> createState() => _DepartmentCardState();
}

class _DepartmentCardState extends State<DepartmentCard>
    with TickerProviderStateMixin {
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

    // بدء التأثير المتكرر
    _floatingController.repeat(reverse: true);
  }

  Future<void> _openPromoVideo() async {
    if (widget.promoVideoUrl == null || widget.promoVideoUrl!.isEmpty) {
      return;
    }

    try {
      // التحقق من أن الرابط يحتوي على YouTube
      if (widget.promoVideoUrl!.contains('youtube.com') ||
          widget.promoVideoUrl!.contains('youtu.be')) {
        // التحقق من معلومات المستخدم أولاً
        final hasUserInfo = await showUserInfoDialog(context);
        if (!hasUserInfo) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    const Text('يجب إدخال معلومات المستخدم لمشاهدة الفيديو'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }

        // فتح المشغل الذكي الجديد - يحدد المشغل المناسب من قاعدة البيانات
        if (mounted) {
          final smartPlayer = VideoPlayerHelper.createSmartPlayer(
            videoUrl: widget.promoVideoUrl!,
            videoTitle: 'فيديو ترويجي - ${widget.title}',
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => smartPlayer,
              fullscreenDialog: true,
            ),
          );
        }
      } else {
        // للروابط الأخرى، استخدم المتصفح الخارجي
        final uri = Uri.parse(widget.promoVideoUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'لا يمكن فتح الرابط: ${widget.promoVideoUrl}';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في فتح الفيديو الترويجي: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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

    // إنشاء تدرج لوني أكثر عمقاً وجمالاً
    final gradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.3, 0.7, 1.0],
            colors: [
              theme.colorScheme.surface.withOpacity(0.6),
              theme.colorScheme.surface.withOpacity(0.4),
              theme.colorScheme.primary.withOpacity(0.2),
              theme.colorScheme.primary.withOpacity(0.1),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.2, 0.6, 1.0],
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.8),
              theme.colorScheme.primary.withOpacity(0.12),
              theme.colorScheme.primary.withOpacity(0.18),
            ],
          );

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        print('🎯 DepartmentCard onTap تم استدعاؤه');
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            transform: Matrix4.identity()
              ..scale(_isPressed ? 0.92 : 1.0)
              ..translate(
                  0.0,
                  (_isPressed ? 12.0 : -2.0) +
                      _floatingAnimation.value), // إضافة التأثير الطافي
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(28), // زوايا أكثر نعومة
              boxShadow: _isPressed
                  ? [
                      // ظل عند الضغط
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.5)
                            : theme.colorScheme.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      // الظل الرئيسي الكبير (يحاكي الطفو)
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.6)
                            : theme.colorScheme.primary.withOpacity(0.25),
                        blurRadius: 35 +
                            (_floatingAnimation.value.abs() *
                                2), // تغيير الظل مع الحركة
                        offset: Offset(0, 18 + _floatingAnimation.value),
                        spreadRadius: -5,
                      ),
                      // ظل ثانوي لمزيد من العمق
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.4)
                            : theme.colorScheme.primary.withOpacity(0.15),
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
                            : theme.colorScheme.primary.withOpacity(0.12),
                        blurRadius: 18,
                        offset: const Offset(8, 8),
                        spreadRadius: -4,
                      ),
                      // ظل إضافي للحصول على تأثير طبقي
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.2)
                            : theme.colorScheme.primary.withOpacity(0.08),
                        blurRadius: 45,
                        offset: const Offset(0, 25),
                        spreadRadius: -8,
                      ),
                    ],
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.8),
                width: 2.0, // حدود أسمك قليلاً
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // حاوية للصورة مع ظل إضافي محسن
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        // ظل رئيسي للصورة
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                          spreadRadius: -3,
                        ),
                        // ظل ثانوي لمزيد من العمق
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.5)
                              : theme.colorScheme.primary.withOpacity(0.2),
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
                    child: GestureDetector(
                      onTap: () {
                        if (widget.onImageTap != null) {
                          widget.onImageTap!();
                        } else if (widget.promoVideoUrl != null &&
                            widget.promoVideoUrl!.isNotEmpty) {
                          _openPromoVideo();
                        }
                      },
                      child: ClipOval(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            children: [
                              ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: widget.imageUrl,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary
                                              .withOpacity(0.3),
                                          theme.colorScheme.primary
                                              .withOpacity(0.1),
                                        ],
                                      ),
                                    ),
                                    child: const CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary
                                              .withOpacity(0.3),
                                          theme.colorScheme.primary
                                              .withOpacity(0.1),
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.school,
                                      size: 40,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              // أيقونة تشغيل إذا كان هناك فيديو ترويجي
                              if (widget.promoVideoUrl != null &&
                                  widget.promoVideoUrl!.isNotEmpty)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                    child: const Icon(
                                      Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // النص مع تأثير بصري
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
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
                  // التخصص (إذا كان موجوداً)
                  if (widget.subtitle != null &&
                      widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: 11,
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
          ); // إغلاق AnimatedContainer
        }, // إغلاق AnimatedBuilder
      ),
    );
  }
}
