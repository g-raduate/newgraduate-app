import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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

class BackupYouTubePlayer extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final bool allowRotation; // التحكم في السماح بدوران الشاشة

  const BackupYouTubePlayer({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
    this.allowRotation = false, // افتراضياً منع الدوران
  });

  @override
  State<BackupYouTubePlayer> createState() => _BackupYouTubePlayerState();
}

class _BackupYouTubePlayerState extends State<BackupYouTubePlayer>
    with TickerProviderStateMixin {
  late YoutubePlayerController _controller;
  String? _userPhone;
  final ScreenRecordingService _recordingService = ScreenRecordingService();

  // متغيرات النص المتحرك
  double _watermarkX = 10.0;
  double _watermarkY = 10.0;
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  final Random _random = Random();

  bool _isPlayerReady = false;
  bool _isFullScreen = false;

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
        _enableFullScreenMode();
      });
    }

    _initializePlayer();
    _loadUserPhone();
    _setupWatermarkAnimation();
    _startWatermarkMovement();
    _recordingService.init();
  }

  @override
  void dispose() {
    // إعادة تعيين اتجاه الشاشة للوضع العمودي فقط عند إغلاق المشغل
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // إعادة تفعيل شريط الحالة
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _controller.dispose();
    _animationController.dispose();
    _recordingService.dispose();
    super.dispose();
  }

  void _initializePlayer() {
    final videoId = _extractVideoId(widget.videoUrl);
    if (videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          controlsVisibleAtStart: true,
          loop: false,
          isLive: false,
          forceHD: true,
          enableCaption: true,
          captionLanguage: 'ar',
          showLiveFullscreenButton: false,
          startAt: 0,
          hideThumbnail: false,
          disableDragSeek: false,
        ),
      );

      _controller.addListener(_listener);
    }
  }

  void _listener() {
    if (!mounted) return;

    if (_controller.value.isReady && !_isPlayerReady) {
      setState(() {
        _isPlayerReady = true;
      });
    }

    if (_controller.value.isFullScreen != _isFullScreen) {
      setState(() {
        _isFullScreen = _controller.value.isFullScreen;
      });
    }
  }

  String? _extractVideoId(String url) {
    return YoutubePlayer.convertUrlToId(url);
  }

  // نفس دوال الحماية من المشغل الأصلي
  Future<String?> _fetchStudentDataFromAPI() async {
    try {
      String? studentId = await UserInfoService.getStudentId();
      if (studentId == null || studentId.isEmpty) {
        print('❌ لا يوجد student_id محفوظ');
        return null;
      }

      print('🔍 جاري جلب بيانات الطالب من API للـ student_id: $studentId');

      final url = Uri.parse('${AppConstants.apiUrl}/students/$studentId');
      print('🌐 API URL: $url');

      final apiHeadersManager = ApiHeadersManager.instance;
      final headers = await apiHeadersManager.getAuthHeaders();
      print('📋 Headers: $headers');

      final response = await http.get(url, headers: headers);

      print('📡 Response Status: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ تم جلب بيانات الطالب بنجاح: $data');

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
      String? apiStudentNumber = await _fetchStudentDataFromAPI();
      if (apiStudentNumber != null && apiStudentNumber.isNotEmpty) {
        setState(() {
          _userPhone = apiStudentNumber;
        });
        print('✅ تم استخدام رقم الطالب من API: $apiStudentNumber');
        return;
      }

      print('⚠️ فشل جلب البيانات من API، استخدام البيانات المحلية...');

      String? studentId = await UserInfoService.getStudentId();
      if (studentId != null && studentId.isNotEmpty) {
        String studentNumber = _extractStudentNumber(studentId);
        setState(() {
          _userPhone = studentNumber;
        });
        print('📱 تم استخدام student_id المحلي: $studentNumber');
        return;
      }

      String? phone = await UserInfoService.getUserPhone();
      if (phone != null && phone.isNotEmpty) {
        setState(() {
          _userPhone = phone;
        });
        print('📞 تم استخدام رقم الهاتف المحلي: $phone');
        return;
      }

      String? userName = await UserInfoService.getUserName();
      if (userName != null && userName.isNotEmpty) {
        setState(() {
          _userPhone = userName;
        });
        print('👤 تم استخدام اسم المستخدم: $userName');
        return;
      }

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

  String _extractStudentNumber(String studentId) {
    String numbersOnly = studentId.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbersOnly.length >= 6) {
      String lastSixDigits = numbersOnly.substring(numbersOnly.length - 6);
      return lastSixDigits;
    } else if (numbersOnly.isNotEmpty) {
      return numbersOnly.padLeft(6, '0');
    } else {
      return _generateRandomStudentNumber();
    }
  }

  String _generateRandomStudentNumber() {
    final random = Random();
    int number = 100000 + random.nextInt(900000);
    return number.toString();
  }

  String _formatWatermarkText(String text) {
    return text;
  }

  void _enableFullScreenMode() {
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

  void _exitPlayer() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (mounted) {
      Navigator.of(context).pop();
    }
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
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
        onReady: () {
          print('🎥 Backup YouTube Player جاهز');
        },
        onEnded: (data) {
          print('🔚 انتهى الفيديو');
        },
      ),
    );
  }

  Widget _buildPlayerUI() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Stack(
        children: [
          // Protection overlay that wraps the player (blocks top only)
          TouchBlockerOverlay(
            topFraction: 0.20,
            bottomFraction: 0.0, // لا توجد حماية في الأسفل للمشغل رقم 1
            blockTop: true,
            blockBottom: false, // تعطيل الحماية السفلى
            overlayColor: Colors.transparent,
            child: _buildPlayer(),
          ),
          RecordingShield(listenable: _recordingService.isCaptured),
        ],
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
              Text(
                'خطأ في تحميل الفيديو',
                style:
                    TextStyle(color: Colors.grey, fontFamily: 'NotoKufiArabic'),
              ),
            ],
          ),
        ),
      );
    }

    // لا نقوم بتفعيل الوضع الأفقي تلقائيًا عند البناء

    return Scaffold(
      backgroundColor: Colors.black,
      body: WillPopScope(
        onWillPop: () async {
          _exitPlayer();
          return false;
        },
        child: Stack(
          children: [
            SizedBox.expand(child: _buildPlayerUI()),
            _buildWatermark(),
            // زر الإغلاق
            Positioned(
              top: 40,
              right: 20,
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
                  onPressed: _exitPlayer,
                ),
              ),
            ),
            // مؤشر التحميل
            if (!_isPlayerReady)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
