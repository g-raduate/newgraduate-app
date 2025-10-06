import 'package:flutter/material.dart';
import 'package:newgraduate/widgets/backup_youtube_player.dart';
import 'package:newgraduate/widgets/protected_youtube_player.dart';
import 'package:newgraduate/widgets/webview_youtube_player.dart';
import 'package:newgraduate/services/platform_operator_service.dart';
import 'package:newgraduate/services/player_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmartYouTubePlayerManager extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final PlayerType? initialPlayer; // جعله اختياري لأننا سنجلب من API
  final bool allowRotation; // التحكم في السماح بدوران الشاشة
  final bool autoPlay; // تشغيل تلقائي للفيديو
  final bool enableProtection; // تمكين طبقة الحماية/العلامة المائية

  const SmartYouTubePlayerManager({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
    this.initialPlayer, // لن يُستخدم إلا في حالة فشل API
    this.allowRotation = false, // افتراضياً منع الدوران (عمودي)
    this.autoPlay = false,
    this.enableProtection = true,
  });

  @override
  State<SmartYouTubePlayerManager> createState() =>
      _SmartYouTubePlayerManagerState();
}

class _SmartYouTubePlayerManagerState extends State<SmartYouTubePlayerManager> {
  PlayerType _currentPlayerType = PlayerType.backup; // افتراضي: المشغل رقم 1
  bool _isLoadingOperatorSettings = true;
  String _platformName = '';

  @override
  void initState() {
    super.initState();
    _platformName = PlayerCacheService.getCurrentPlatformDisplayName();
    _loadPlatformOperatorSettingsWithCache();
  }

  /// جلب إعدادات المشغل مع نظام الكاش الذكي
  Future<void> _loadPlatformOperatorSettingsWithCache() async {
    try {
      print('🔍 بدء تحديد المشغل المناسب للمنصة: $_platformName');
      print('🔧 فحص نوع الجهاز والكاش...');

      // استخدام الكاش الذكي
      final playerType = await PlayerCacheService.getPlayerTypeWithSmartCache();

      // الحصول على معلومات إضافية
      final cacheInfo = await PlayerCacheService.getCacheInfo();

      print('📊 معلومات الكاش:');
      print('   يوجد كاش: ${cacheInfo['has_cache']}');
      if (cacheInfo['has_cache'] == true) {
        print('   صالح: ${cacheInfo['is_valid']}');
        print('   رقم المشغل: ${cacheInfo['operator_number']}');
        print('   اسم المشغل: ${cacheInfo['operator_name']}');
      }

      final operatorNumber = playerType == PlayerType.backup ? 1 : 2;
      final operatorName =
          PlatformOperatorService.getOperatorName(operatorNumber);

      print('✅ تم تحديد المشغل النهائي:');
      print('   المنصة: $_platformName');
      print('   نوع الجهاز: ${PlayerCacheService.getCurrentPlatformType()}');
      print('   رقم المشغل: $operatorNumber');
      print('   نوع المشغل: $operatorName');

      setState(() {
        _currentPlayerType = playerType;
        _isLoadingOperatorSettings = false;
      });
    } catch (e) {
      print('❌ خطأ في تحديد المشغل: $e');

      // استخدام المشغل الافتراضي
      PlayerType fallbackPlayer = widget.initialPlayer ?? PlayerType.backup;

      print(
          '⚠️ استخدام المشغل الاحتياطي: ${PlatformOperatorService.getOperatorName(fallbackPlayer == PlayerType.backup ? 1 : 2)}');

      setState(() {
        _currentPlayerType = fallbackPlayer;
        _isLoadingOperatorSettings = false;
      });
    }
  }

  // التبديل إلى المشغل الاحتياطي
  void _switchToBackupPlayer() {
    setState(() {
      _currentPlayerType = PlayerType.backup;
    });

    // إشعار للمطور
    print('🔄 تم التبديل من المشغل الأصلي إلى الاحتياطي');
  }

  // التبديل إلى المشغل الأصلي
  void _switchToPrimaryPlayer() {
    setState(() {
      _currentPlayerType = PlayerType.primary;
    });

    print('🔄 تم التبديل من المشغل الاحتياطي إلى الأصلي');
  }

  Widget _buildCurrentPlayer() {
    switch (_currentPlayerType) {
      case PlayerType.primary:
        return _buildPrimaryPlayerWithErrorHandling();
      case PlayerType.backup:
        return _buildBackupPlayerWithErrorHandling();
      case PlayerType.webview:
        return _buildWebViewPlayerWithErrorHandling();
    }
  }

  Widget _buildPrimaryPlayerWithErrorHandling() {
    return Builder(
      builder: (context) {
        try {
          return ProtectedYouTubePlayer(
            videoUrl: widget.videoUrl,
            videoTitle: widget.videoTitle,
            allowRotation: widget.allowRotation,
            autoPlay: widget.autoPlay,
            enableProtection: widget.enableProtection,
          );
        } catch (e) {
          print('❌ خطأ في المشغل الأصلي: $e');
          // التبديل التلقائي للمشغل الاحتياطي
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _switchToBackupPlayer();
          });
          return _buildLoadingScreen();
        }
      },
    );
  }

  Widget _buildBackupPlayerWithErrorHandling() {
    return Builder(
      builder: (context) {
        try {
          return BackupYouTubePlayer(
            videoUrl: widget.videoUrl,
            videoTitle: widget.videoTitle,
            allowRotation: widget.allowRotation,
            autoPlay: widget.autoPlay,
            enableProtection: widget.enableProtection,
          );
        } catch (e) {
          print('❌ خطأ في المشغل الاحتياطي: $e');
          return _buildErrorScreen();
        }
      },
    );
  }

  Widget _buildWebViewPlayerWithErrorHandling() {
    return Builder(
      builder: (context) {
        try {
          return WebViewYouTubePlayer(
            videoUrl: widget.videoUrl,
            videoTitle: widget.videoTitle,
            allowRotation: widget.allowRotation,
            autoPlay: widget.autoPlay,
            enableProtection: widget.enableProtection,
          );
        } catch (e) {
          print('❌ خطأ في WebView Player: $e');
          // التبديل التلقائي للمشغل الاحتياطي
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _switchToBackupPlayer();
          });
          return _buildLoadingScreen();
        }
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'جاري تحميل المشغل...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'NotoKufiArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'خطأ في تشغيل الفيديو',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoKufiArabic',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'لا يمكن تشغيل الفيديو حالياً\nيرجى المحاولة مرة أخرى لاحقاً',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontFamily: 'NotoKufiArabic',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_currentPlayerType == PlayerType.backup) {
                        _switchToPrimaryPlayer();
                      } else {
                        _switchToBackupPlayer();
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _currentPlayerType == PlayerType.backup
                          ? 'المشغل الأصلي'
                          : 'المشغل الاحتياطي',
                      style: const TextStyle(fontFamily: 'NotoKufiArabic'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text(
                      'إغلاق',
                      style: TextStyle(fontFamily: 'NotoKufiArabic'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // عرض شاشة تحميل أثناء جلب إعدادات المشغل من API
    if (_isLoadingOperatorSettings) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'جاري تحميل إعدادات المشغل...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'NotoKufiArabic',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'المنصة: $_platformName',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontFamily: 'NotoKufiArabic',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        _buildCurrentPlayer(),
        // إزالة مؤشر نوع المشغل - الاكتفاء بالـ console فقط
      ],
    );
  }
}

// دالة مساعدة لإنشاء مشغل ذكي
class VideoPlayerHelper {
  /// إنشاء مشغل فيديو ذكي مع جلب الإعدادات من API
  /// يتم تحديد المشغل المناسب حسب المنصة (Android/iOS) من قاعدة البيانات
  static Widget createSmartPlayer({
    required String videoUrl,
    required String videoTitle,
    PlayerType? fallbackPlayer, // مشغل احتياطي في حالة فشل API
    bool allowRotation = false, // السماح بالدوران للوضع الأفقي (للدورات فقط)
  }) {
    return SmartYouTubePlayerManager(
      videoUrl: videoUrl,
      videoTitle: videoTitle,
      initialPlayer: fallbackPlayer, // سيتم تجاهله إلا في حالة فشل API
      allowRotation: allowRotation,
    );
  }

  /// إنشاء مشغل احتياطي مباشرة (المشغل رقم 1)
  static Widget createBackupPlayer({
    required String videoUrl,
    required String videoTitle,
  }) {
    return BackupYouTubePlayer(
      videoUrl: videoUrl,
      videoTitle: videoTitle,
      allowRotation: false, // Default to portrait mode
    );
  }

  /// إنشاء المشغل الأصلي مباشرة (المشغل رقم 2)
  static Widget createPrimaryPlayer({
    required String videoUrl,
    required String videoTitle,
  }) {
    return ProtectedYouTubePlayer(
      videoUrl: videoUrl,
      videoTitle: videoTitle,
      allowRotation: false, // Default to portrait mode
    );
  }

  /// إنشاء Pod Player مباشرة (المشغل رقم 3)
  static Widget createPodPlayer({
    required String videoUrl,
    required String videoTitle,
  }) {
    return WebViewYouTubePlayer(
      videoUrl: videoUrl,
      videoTitle: videoTitle,
      allowRotation: false, // Default to portrait mode
    );
  }

  /// إنشاء مشغل بناءً على رقم محدد
  static Widget createPlayerByNumber({
    required String videoUrl,
    required String videoTitle,
    required int playerNumber,
  }) {
    switch (playerNumber) {
      case 1:
        return createBackupPlayer(videoUrl: videoUrl, videoTitle: videoTitle);
      case 2:
        return createPrimaryPlayer(videoUrl: videoUrl, videoTitle: videoTitle);
      case 3:
        return createPodPlayer(videoUrl: videoUrl, videoTitle: videoTitle);
      default:
        print('⚠️ رقم مشغل غير صالح: $playerNumber، استخدام المشغل رقم 1');
        return createBackupPlayer(videoUrl: videoUrl, videoTitle: videoTitle);
    }
  }

  /// التحقق من صحة رابط YouTube
  static bool isValidYouTubeUrl(String url) {
    final regex = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    return regex.hasMatch(url);
  }

  /// الحصول على معلومات الكاش للمطور
  static Future<Map<String, dynamic>> getCacheStatus() async {
    try {
      final cacheService = PlayerCacheService();
      final cachedPlayer = await cacheService.getCachedPlayer();

      Map<String, dynamic> result = {
        'has_cache': false,
        'is_valid': false,
        'operator_number': null,
        'operator_name': null,
        'cached_at': null,
        'cached_platform': null,
      };

      if (cachedPlayer != null) {
        result['has_cache'] = true;
        result['operator_number'] = cachedPlayer;
        result['operator_name'] = cachedPlayer == 1
            ? 'youtube_player_flutter'
            : cachedPlayer == 2
                ? 'youtube_player_iframe'
                : cachedPlayer == 3
                    ? 'webview_player'
                    : 'مشغل غير معروف';

        // التحقق من صحة الكاش
        final cachedSettings = await PlayerCacheService.getPlayerSettings();
        final isValid = cachedSettings != null;
        result['is_valid'] = isValid;

        // الحصول على تفاصيل إضافية
        final prefs = await SharedPreferences.getInstance();
        final cacheExpiry = prefs.getString('cache_expiry');
        result['cached_at'] = cacheExpiry ?? 'غير محدد';
        result['cached_platform'] =
            prefs.getString('platform_name') ?? 'غير محدد';
      }

      return result;
    } catch (e) {
      print('❌ خطأ في الحصول على معلومات الكاش: $e');
      return {
        'has_cache': false,
        'is_valid': false,
        'operator_number': null,
        'operator_name': null,
        'cached_at': null,
        'cached_platform': null,
      };
    }
  }

  /// مسح الكاش للمطور
  static Future<void> clearPlayerCache() async {
    try {
      await PlayerCacheService.clearCache();
      print('✅ تم مسح الكاش بنجاح');
    } catch (e) {
      print('❌ فشل مسح الكاش: $e');
    }
  }

  /// الحصول على نوع الجهاز الحالي
  static String getCurrentDeviceType() {
    return PlatformOperatorService.getDeviceType();
  }

  /// الحصول على اسم الجهاز بالعربية
  static String getCurrentDeviceDisplayName() {
    return PlatformOperatorService.getDeviceDisplayName();
  }

  /// استخراج معرف الفيديو من الرابط
  static String? extractVideoId(String url) {
    final regex = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  /// إجبار تحديث كاش المشغل من قاعدة البيانات
  static Future<Widget> createSmartPlayerWithRefresh({
    required String videoUrl,
    required String videoTitle,
  }) async {
    print('🔄 تحديث إعدادات المشغل من قاعدة البيانات...');

    try {
      // إجبار التحديث من API
      final playerType = await PlayerCacheService.forceUpdateFromAPI();

      // إنشاء المشغل المناسب
      switch (playerType) {
        case PlayerType.backup:
          print('🎯 تم اختيار المشغل رقم 1 بعد التحديث');
          return createBackupPlayer(videoUrl: videoUrl, videoTitle: videoTitle);
        case PlayerType.primary:
          print('🎯 تم اختيار المشغل رقم 2 بعد التحديث');
          return createPrimaryPlayer(
              videoUrl: videoUrl, videoTitle: videoTitle);
        case PlayerType.webview:
          print('🎯 تم اختيار المشغل رقم 3 بعد التحديث');
          return createPodPlayer(videoUrl: videoUrl, videoTitle: videoTitle);
      }
    } catch (e) {
      print('❌ فشل في تحديث الكاش: $e');
      print('🔄 استخدام النظام العادي...');

      // استخدام النظام العادي في حالة الفشل
      return createSmartPlayer(videoUrl: videoUrl, videoTitle: videoTitle);
    }
  }
}
