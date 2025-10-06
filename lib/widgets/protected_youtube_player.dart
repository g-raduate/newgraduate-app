import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:newgraduate/services/user_info_service.dart';
import 'package:newgraduate/services/api_headers_manager.dart';
import 'package:newgraduate/config/app_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:newgraduate/services/screen_recording_service.dart';
import 'package:newgraduate/widgets/recording_shield.dart';
import 'package:newgraduate/utils/touch_blocker_overlay.dart';

class ProtectedYouTubePlayer extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final bool allowRotation; // التحكم في السماح بدوران الشاشة
  final bool autoPlay;
  final bool enableProtection;

  const ProtectedYouTubePlayer({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
    this.allowRotation = false, // افتراضياً منع الدوران
    this.autoPlay = false,
    this.enableProtection = true,
  });

  @override
  State<ProtectedYouTubePlayer> createState() => _ProtectedYouTubePlayerState();
}

class _ProtectedYouTubePlayerState extends State<ProtectedYouTubePlayer>
    with TickerProviderStateMixin {
  late YoutubePlayerController _controller;
  String? _userPhone;
  final ScreenRecordingService _recordingService = ScreenRecordingService();

  // لا نستخدم غطاء أسود فوق الفيديو؛ الإقتراحات تبقى مرئية بحسب يوتيوب.

  // متغيرات النص المتحرك
  double _watermarkX = 10.0;
  double _watermarkY = 10.0;
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  final Random _random = Random();

  // متغير نسبة العرض إلى الارتفاع
  double _playerAspectRatio = 16 / 9;

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

    _initializePlayer();
    _loadUserPhone();
    _setupWatermarkAnimation();
    _startWatermarkMovement();
    _recordingService.init();

    // تفعيل الشاشة الكاملة مباشرة عند فتح المشغل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enableFullScreenMode();
    });
  }

  @override
  void dispose() {
    // إعادة تعيين اتجاه الشاشة للوضع العمودي فقط عند إغلاق المشغل
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // إعادة تفعيل شريط الحالة
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _controller.close();
    _animationController.dispose();
    _recordingService.dispose();
    super.dispose();
  }

  void _initializePlayer() {
    final videoId = _extractVideoId(widget.videoUrl);
    if (videoId != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: widget.autoPlay,
        params: YoutubePlayerParams(
          showControls: false,
          mute: false,
          showFullscreenButton: false,
          loop: false,
          enableCaption: true,
          captionLanguage: 'ar',
          color: 'red',
          showVideoAnnotations: false,
        ),
      );

      // مستمع بسيط (ممكن استخدامه مستقبلاً لاحتياجات أخرى)
      _controller.listen((value) {});
    }
  }

  String? _extractVideoId(String url) {
    // استخراج معرف الفيديو من رابط YouTube
    final regex = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  // جلب بيانات الطالب من الـ API
  Future<String?> _fetchStudentDataFromAPI() async {
    try {
      // الحصول على student_id من التخزين المحلي
      String? studentId = await UserInfoService.getStudentId();
      if (studentId == null || studentId.isEmpty) {
        print('❌ لا يوجد student_id محفوظ');
        return null;
      }

      print('🔍 جاري جلب بيانات الطالب من API للـ student_id: $studentId');

      // إنشاء رابط الـ API
      final url = Uri.parse('${AppConstants.apiUrl}/students/$studentId');
      print('🌐 API URL: $url');

      // الحصول على headers مع التوكن
      final apiHeadersManager = ApiHeadersManager.instance;
      final headers = await apiHeadersManager.getAuthHeaders();
      print('📋 Headers: $headers');

      // إرسال الطلب
      final response = await http.get(url, headers: headers);

      print('📡 Response Status: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ تم جلب بيانات الطالب بنجاح: $data');

        // البحث عن رقم الطالب في البيانات
        String? studentNumber;

        if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
          studentNumber = data['phone'].toString();
          print('📱 تم العثور على رقم الهاتف: $studentNumber');
        } else if (data['id'] != null) {
          studentNumber = data['id'].toString();
          print('🆔 تم استخدام معرف الطالب: $studentNumber');
        } else if (data['student_number'] != null) {
          studentNumber = data['student_number'].toString();
          print('🎓 تم العثور على رقم الطالب: $studentNumber');
        }

        return studentNumber;
      } else {
        print('❌ خطأ في API: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('💥 خطأ في جلب بيانات الطالب: $e');
      return null;
    }
  }

  Future<void> _loadUserPhone() async {
    try {
      // أولاً جلب البيانات من الـ API
      String? apiStudentNumber = await _fetchStudentDataFromAPI();
      if (apiStudentNumber != null && apiStudentNumber.isNotEmpty) {
        setState(() {
          _userPhone = apiStudentNumber;
        });
        print('✅ تم استخدام رقم الطالب من API: $apiStudentNumber');
        return;
      }

      // إذا فشل API، استخدم البيانات المحفوظة محلياً
      print('⚠️ فشل جلب البيانات من API، استخدام البيانات المحلية...');

      // أولوية لرقم الطالب (Student ID) من التخزين المحلي
      String? studentId = await UserInfoService.getStudentId();
      if (studentId != null && studentId.isNotEmpty) {
        String studentNumber = _extractStudentNumber(studentId);
        setState(() {
          _userPhone = studentNumber;
        });
        print('📱 تم استخدام student_id المحلي: $studentNumber');
        return;
      }

      // إذا لم يوجد student_id، استخدم رقم الهاتف
      String? phone = await UserInfoService.getUserPhone();
      if (phone != null && phone.isNotEmpty) {
        setState(() {
          _userPhone = phone;
        });
        print('📞 تم استخدام رقم الهاتف المحلي: $phone');
        return;
      }

      // كخيار أخير، استخدم اسم المستخدم
      String? userName = await UserInfoService.getUserName();
      if (userName != null && userName.isNotEmpty) {
        setState(() {
          _userPhone = userName;
        });
        print('👤 تم استخدام اسم المستخدم: $userName');
        return;
      }

      // إنشاء رقم طالب عشوائي إذا لم توجد بيانات
      String randomNumber = _generateRandomStudentNumber();
      setState(() {
        _userPhone = randomNumber;
      });
      print('🎲 تم إنشاء رقم عشوائي: $randomNumber');
    } catch (e) {
      print('💥 خطأ في تحميل بيانات المستخدم: $e');
      String randomNumber = _generateRandomStudentNumber();
      setState(() {
        _userPhone = randomNumber;
      });
    }
  }

  // استخراج رقم طالب من student_id
  String _extractStudentNumber(String studentId) {
    // إزالة جميع الرموز والأحرف والاحتفاظ بالأرقام فقط
    String numbersOnly = studentId.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbersOnly.length >= 6) {
      // أخذ آخر 6 أرقام
      String lastSixDigits = numbersOnly.substring(numbersOnly.length - 6);
      return lastSixDigits;
    } else if (numbersOnly.isNotEmpty) {
      // إذا كان أقل من 6 أرقام، أضف أصفار في البداية
      return numbersOnly.padLeft(6, '0');
    } else {
      // إذا لم توجد أرقام، أنشئ رقم عشوائي
      return _generateRandomStudentNumber();
    }
  }

  // إنشاء رقم طالب عشوائي
  String _generateRandomStudentNumber() {
    final random = Random();
    int number = 100000 + random.nextInt(900000); // رقم من 6 خانات
    return number.toString();
  }

  // تنسيق النص للعلامة المائية
  String _formatWatermarkText(String text) {
    // عرض الرقم فقط بدون نصوص إضافية
    return text;
  }

  // تفعيل وضع الشاشة الكاملة
  void _enableFullScreenMode() {
    // إخفاء شريط الحالة والتنقل
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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

    _offsetAnimation = Tween<Offset>(
      begin: currentOffset,
      end: newOffset,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic, // منحنى أكثر سلاسة للحركة المستمرة
    ));

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

  // دالة للخروج من المشغل وإعادة تعيين الاتجاهات
  // ignore: unused_element
  void _exitPlayer() {
    if (mounted) Navigator.of(context).pop();
  }

  Widget _buildWatermark() {
    if (_userPhone == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        final currentOffset = _offsetAnimation.value;

        return Positioned(
          left: currentOffset.dx * size.width,
          top: currentOffset.dy * size.height,
          child: Text(
            _formatWatermarkText(_userPhone!),
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayer() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: YoutubePlayer(
        controller: _controller,
        aspectRatio: _playerAspectRatio,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _extractVideoId(widget.videoUrl);
    if (videoId == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('خطأ في تحميل الفيديو',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // تفعيل الشاشة الكاملة مباشرة
    // لا نقوم بتفعيل الوضع الأفقي تلقائيًا عند البناء

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Protection overlay that wraps the player (blocks top/bottom taps)
          if (widget.enableProtection)
            TouchBlockerOverlay(
              topFraction: 0.20,
              bottomFraction: 0.35, // ارتفاع المنطقة المحمية في الأسفل
              blockTop: true,
              blockBottom: true,
              overlayColor: Colors.transparent,
              child: SizedBox.expand(child: _buildPlayer()),
            )
          else
            SizedBox.expand(child: _buildPlayer()),
          // النص المتحرك للحماية
          if (widget.enableProtection) _buildWatermark(),
          // لا يوجد غطاء أسود إضافي؛ الاقتراحات تبقى مرئية
          if (widget.enableProtection)
            RecordingShield(listenable: _recordingService.isCaptured),
        ],
      ),
    );
  }
}
