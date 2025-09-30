import 'package:flutter/material.dart';
import 'package:newgraduate/widgets/smart_youtube_player_manager.dart';

/// مثال على كيفية دمج النظام الجديد مع الكود الموجود
class IntegrationExample {
  /// الطريقة الجديدة الموصى بها - تستخدم إعدادات قاعدة البيانات
  static void openVideoWithDatabaseSettings(
      BuildContext context, String videoUrl, String title) {
    final player = VideoPlayerHelper.createSmartPlayer(
      videoUrl: videoUrl,
      videoTitle: title,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => player,
        fullscreenDialog: true, // للحصول على تجربة شاشة كاملة
      ),
    );
  }

  /// طريقة مؤقتة للانتقال التدريجي - مع إمكانية اختيار المشغل يدوياً
  static void openVideoWithManualSelection(
      BuildContext context, String videoUrl, String title,
      {int? preferredPlayerNumber}) {
    Widget player;

    if (preferredPlayerNumber != null) {
      // استخدام مشغل محدد
      player = VideoPlayerHelper.createPlayerByNumber(
        videoUrl: videoUrl,
        videoTitle: title,
        playerNumber: preferredPlayerNumber,
      );
    } else {
      // استخدام النظام الذكي
      player = VideoPlayerHelper.createSmartPlayer(
        videoUrl: videoUrl,
        videoTitle: title,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => player),
    );
  }

  /// مثال متقدم - مع معالجة الأخطاء وValidation
  static Future<void> openVideoAdvanced(
    BuildContext context,
    String videoUrl,
    String title, {
    bool showLoadingDialog = true,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    // التحقق من صحة الرابط أولاً
    if (!VideoPlayerHelper.isValidYouTubeUrl(videoUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'رابط الفيديو غير صحيح أو غير مدعوم',
            style: TextStyle(fontFamily: 'NotoKufiArabic'),
          ),
        ),
      );
      onError?.call();
      return;
    }

    try {
      // عرض dialog تحميل إذا طُلب
      if (showLoadingDialog) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              backgroundColor: Colors.black87,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'جاري تحضير مشغل الفيديو...',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'NotoKufiArabic',
                    ),
                  ),
                ],
              ),
            );
          },
        );

        // انتظار لمحاكاة التحضير
        await Future.delayed(const Duration(milliseconds: 500));

        // إغلاق dialog التحميل
        Navigator.of(context, rootNavigator: true).pop();
      }

      // إنشاء وفتح المشغل
      final player = VideoPlayerHelper.createSmartPlayer(
        videoUrl: videoUrl,
        videoTitle: title,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => player),
      );

      onSuccess?.call();
    } catch (e) {
      // إغلاق dialog التحميل في حالة وجوده
      if (showLoadingDialog) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في تشغيل الفيديو: ${e.toString()}',
            style: const TextStyle(fontFamily: 'NotoKufiArabic'),
          ),
        ),
      );
      onError?.call();
    }
  }
}

/// Widget مساعد لقائمة الفيديوهات مع دعم المشغل الجديد
class VideoListTile extends StatelessWidget {
  final String videoUrl;
  final String videoTitle;
  final String? thumbnailUrl;
  final String? duration;
  final VoidCallback? onPlayPressed;

  const VideoListTile({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
    this.thumbnailUrl,
    this.duration,
    this.onPlayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 80,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
            image: thumbnailUrl != null
                ? DecorationImage(
                    image: NetworkImage(thumbnailUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Stack(
            children: [
              if (thumbnailUrl == null)
                const Center(
                  child: Icon(Icons.video_library, color: Colors.grey),
                ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          videoTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoKufiArabic',
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: duration != null
            ? Text(
                'المدة: $duration',
                style: const TextStyle(fontFamily: 'NotoKufiArabic'),
              )
            : null,
        trailing: IconButton(
          icon: Icon(
            Icons.play_circle_filled,
            color: Theme.of(context).primaryColor,
            size: 32,
          ),
          onPressed: () {
            onPlayPressed?.call();
            _openVideo(context);
          },
        ),
        onTap: () => _openVideo(context),
      ),
    );
  }

  void _openVideo(BuildContext context) {
    IntegrationExample.openVideoWithDatabaseSettings(
      context,
      videoUrl,
      videoTitle,
    );
  }
}

/// مثال على صفحة كاملة مع قائمة فيديوهات
class VideoListPage extends StatelessWidget {
  final List<Map<String, String>> videos = [
    {
      'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      'title': 'مقدمة في البرمجة - الدرس الأول',
      'duration': '15:30',
    },
    {
      'url': 'https://www.youtube.com/watch?v=example2',
      'title': 'أساسيات Flutter - الجزء الأول',
      'duration': '22:45',
    },
    {
      'url': 'https://www.youtube.com/watch?v=example3',
      'title': 'تطوير تطبيقات الهاتف المحمول',
      'duration': '18:20',
    },
  ];

  VideoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'قائمة الفيديوهات',
          style: TextStyle(fontFamily: 'NotoKufiArabic'),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'جميع الفيديوهات تستخدم النظام الذكي الجديد\nالمشغل يتم اختياره تلقائياً من قاعدة البيانات',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontFamily: 'NotoKufiArabic',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return VideoListTile(
                  videoUrl: video['url']!,
                  videoTitle: video['title']!,
                  duration: video['duration'],
                  onPlayPressed: () {
                    print('▶️ تشغيل الفيديو: ${video['title']}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
