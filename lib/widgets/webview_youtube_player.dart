import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:newgraduate/services/user_info_service.dart';
import 'package:newgraduate/utils/touch_blocker_overlay.dart';
import 'package:newgraduate/services/screen_recording_service.dart';
import 'package:newgraduate/widgets/recording_shield.dart';
import 'dart:async';
import 'dart:math';

class WebViewYouTubePlayer extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final bool allowRotation; // التحكم في السماح بدوران الشاشة
  final bool autoPlay; // تشغيل تلقائي
  final bool enableProtection; // تمكين طبقة الحماية/العلامة المائية

  const WebViewYouTubePlayer({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
    this.allowRotation = false, // افتراضياً منع الدوران
    this.autoPlay = false,
    this.enableProtection = true,
  });

  @override
  State<WebViewYouTubePlayer> createState() => _WebViewYouTubePlayerState();
}

class _WebViewYouTubePlayerState extends State<WebViewYouTubePlayer>
    with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _userPhone;
  double _watermarkX = 10.0;
  double _watermarkY = 10.0;
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  final Random _random = Random();
  final ScreenRecordingService _recordingService = ScreenRecordingService();

  @override
  void initState() {
    super.initState();

    // تفعيل الوضع الأفقي إذا كان مسموحاً بالدوران (للدورات فقط)
    if (widget.allowRotation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      });
    }

    _controller = WebViewController();
    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller.setBackgroundColor(Colors.black);
    _controller.setNavigationDelegate(NavigationDelegate(
      onPageFinished: (url) {
        setState(() {
          _isLoading = false;
        });
      },
      onNavigationRequest: (request) {
        return NavigationDecision.navigate;
      },
      onWebResourceError: (err) {
        print('❌ WebView error: ${err.description}');
      },
    ));

    // Load a simple embedded player URL that works with webview
    final embedUrl = _toEmbedUrl(widget.videoUrl);
    _controller.loadRequest(Uri.parse(embedUrl));

    // start watermark flow
    _loadUserPhone();
    _setupWatermarkAnimation();
    _startWatermarkMovement();

    _recordingService.init();
  }

  Future<void> _loadUserPhone() async {
    try {
      String? phone = await UserInfoService.getUserPhone();
      if (phone != null && phone.isNotEmpty) {
        setState(() {
          _userPhone = phone;
        });
        return;
      }

      String? studentId = await UserInfoService.getStudentId();
      if (studentId != null && studentId.isNotEmpty) {
        setState(() {
          _userPhone = studentId;
        });
        return;
      }
    } catch (e) {
      print('⚠️ خطأ في جلب بيانات المستخدم للمحافظة على العلامة المائية: $e');
    }
  }

  void _setupWatermarkAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000), // حركة أبطأ وأكثر سلاسة
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startWatermarkMovement() {
    // انتظار اكتمال بناء الـ widget قبل بدء الحركة مع تأخير إضافي
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // تأخير إضافي للتأكد من توفر MediaQuery
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && context.mounted) {
            _moveWatermark();
          }
        });
      }
    });
  }

  void _moveWatermark() {
    if (!mounted || !context.mounted) return;

    final size = MediaQuery.of(context).size;

    // تحديد المنطقة العلوية للحركة (الثلث العلوي من الشاشة)
    final double topAreaWidth = size.width - 120; // عرض الشاشة مع هامش
    final double topAreaHeight = size.height * 0.33; // الثلث العلوي من الشاشة

    final maxX = topAreaWidth - 100; // مساحة أقل للنص
    final maxY = topAreaHeight - 50; // مساحة أقل للنص

    // ضمان أن الموضع الجديد بعيد عن الحالي داخل المنطقة المحددة
    double newX, newY;
    do {
      newX = _random.nextDouble() * maxX + 10; // إضافة هامش 10 بكسل من اليسار
      newY = _random.nextDouble() * maxY + 40; // إضافة هامش 40 بكسل من الأعلى
    } while (mounted && (newX - _watermarkX).abs() < 50 ||
        (newY - _watermarkY).abs() < 30);

    final currentOffset =
        Offset(_watermarkX / size.width, _watermarkY / size.height);
    final newOffset = Offset(newX / size.width, newY / size.height);

    _offsetAnimation = Tween<Offset>(begin: currentOffset, end: newOffset)
        .animate(CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOutCubic)); // منحنى أكثر سلاسة

    _animationController.forward().then((_) {
      if (mounted) {
        setState(() {
          _watermarkX = newX;
          _watermarkY = newY;
        });
        _animationController.reset();
        // تأخير أطول قبل بدء الحركة التالية لجعل الحركة أبطأ
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _moveWatermark();
        });
      }
    });
  }

  String _toEmbedUrl(String url) {
    // If it's a youtu.be short link or watch URL, convert to embed
    try {
      final uri = Uri.parse(url);
      String? id;
      if (uri.host.contains('youtu.be')) {
        id = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      } else if (uri.host.contains('youtube.com')) {
        id = uri.queryParameters['v'];
        if (id == null && uri.pathSegments.contains('embed')) {
          final idx = uri.pathSegments.indexOf('embed');
          if (idx != -1 && uri.pathSegments.length > idx + 1) {
            id = uri.pathSegments[idx + 1];
          }
        }
      }

      if (id == null || id.isEmpty) return url;
      final auto = widget.autoPlay ? 1 : 0;
      return 'https://www.youtube.com/embed/$id?rel=0&autoplay=$auto&modestbranding=1';
    } catch (e) {
      return url;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _recordingService.dispose();
    // إعادة تعيين الاتجاهات للوضع العمودي فقط عند الخروج
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Protection overlay that wraps the WebView (blocks top/bottom taps)
          if (widget.enableProtection)
            TouchBlockerOverlay(
              topFraction: 0.20,
              bottomFraction: 0.35, // زيادة ارتفاع المنطقة المحمية في الأسفل
              blockTop: true,
              blockBottom: true,
              overlayColor: Colors.transparent,
              child: WebViewWidget(controller: _controller),
            )
          else
            WebViewWidget(controller: _controller),

          // Loading indicator above the WebView
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),

          // watermark above everything
          if (widget.enableProtection && _userPhone != null)
            AnimatedBuilder(
              animation: _offsetAnimation,
              builder: (context, child) {
                final size = MediaQuery.of(context).size;
                final currentOffset = _offsetAnimation.value;
                return Positioned(
                  left: currentOffset.dx * size.width,
                  top: currentOffset.dy * size.height,
                  child: Text(
                    _userPhone!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),

          // Close button on top so it's always clickable
          Positioned(
            top: 20,
            right: 8,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (mounted) Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),

          // Shield against iOS screen recording
          if (widget.enableProtection)
            RecordingShield(listenable: _recordingService.isCaptured),
        ],
      ),
    );
  }
}
