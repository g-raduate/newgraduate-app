import 'package:flutter/material.dart';
import 'package:newgraduate/widgets/smart_youtube_player_manager.dart';

class VideoPlayerExample extends StatelessWidget {
  const VideoPlayerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'أمثلة المشغلات',
          style: TextStyle(fontFamily: 'NotoKufiArabic'),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'اختبار مشغلات الفيديو',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoKufiArabic',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // مثال مع النظام الذكي
            _buildPlayerButton(
              context,
              title: 'المشغل الذكي (موصى به)',
              description: 'يحدد المشغل المناسب من قاعدة البيانات حسب المنصة',
              color: Colors.green,
              onPressed: () => _openSmartPlayer(context),
            ),

            const SizedBox(height: 16),

            // مثال مع المشغل رقم 1
            _buildPlayerButton(
              context,
              title: 'المشغل رقم 1 (youtube_player_flutter)',
              description: 'المشغل الاحتياطي - مرونة أكبر',
              color: Colors.blue,
              onPressed: () => _openPlayerNumber1(context),
            ),

            const SizedBox(height: 16),

            // مثال مع المشغل رقم 2
            _buildPlayerButton(
              context,
              title: 'المشغل رقم 2 (youtube_player_iframe)',
              description: 'المشغل الأساسي - ميزات حديثة',
              color: Colors.orange,
              onPressed: () => _openPlayerNumber2(context),
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ملاحظات مهمة:',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoKufiArabic',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoPoint('جميع المشغلات تحتوي على نفس ميزات الحماية'),
                  _buildInfoPoint(
                      'النظام الذكي يجلب إعدادات المشغل من قاعدة البيانات'),
                  _buildInfoPoint(
                      'المشغل رقم 1: youtube_player_flutter (مرونة أكبر)'),
                  _buildInfoPoint(
                      'المشغل رقم 2: youtube_player_iframe (ميزات حديثة)'),
                  _buildInfoPoint(
                      'التشغيل في وضع الشاشة الكاملة مع حماية من التسجيل'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerButton(
    BuildContext context, {
    required String title,
    required String description,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoKufiArabic',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontFamily: 'NotoKufiArabic',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'NotoKufiArabic',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSmartPlayer(BuildContext context) {
    final player = VideoPlayerHelper.createSmartPlayer(
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // مثال
      videoTitle: 'مثال على المشغل الذكي - يحدد المشغل حسب قاعدة البيانات',
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => player),
    );
  }

  void _openPlayerNumber1(BuildContext context) {
    final player = VideoPlayerHelper.createPlayerByNumber(
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // مثال
      videoTitle: 'مثال على المشغل رقم 1 (youtube_player_flutter)',
      playerNumber: 1,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => player),
    );
  }

  void _openPlayerNumber2(BuildContext context) {
    final player = VideoPlayerHelper.createPlayerByNumber(
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // مثال
      videoTitle: 'مثال على المشغل رقم 2 (youtube_player_iframe)',
      playerNumber: 2,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => player),
    );
  }
}

// مثال على كيفية الاستخدام في كود موجود
class ExampleUsageInExistingCode {
  // مثال 1: في صفحة تفاصيل الكورس
  static void openVideoFromCourse(
      BuildContext context, String videoUrl, String title) {
    final player = VideoPlayerHelper.createSmartPlayer(
      videoUrl: videoUrl,
      videoTitle: title,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => player),
    );
  }

  // مثال 2: مع التحقق من صحة الرابط
  static void openVideoSafely(
      BuildContext context, String videoUrl, String title) {
    if (!VideoPlayerHelper.isValidYouTubeUrl(videoUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'رابط الفيديو غير صحيح',
            style: TextStyle(fontFamily: 'NotoKufiArabic'),
          ),
        ),
      );
      return;
    }

    final player = VideoPlayerHelper.createSmartPlayer(
      videoUrl: videoUrl,
      videoTitle: title,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => player),
    );
  }

  // مثال 3: مع اختيار المشغل حسب نوع الجهاز
  static void openVideoWithDeviceOptimization(
      BuildContext context, String videoUrl, String title) {
    // استخدام النظام الذكي الذي يجلب الإعدادات من قاعدة البيانات
    // لن نحتاج لمنطق اختيار محلي لأن API يحدد المشغل المناسب

    final player = VideoPlayerHelper.createSmartPlayer(
      videoUrl: videoUrl,
      videoTitle: title,
      // يمكن إضافة fallbackPlayer إذا لزم الأمر
      // fallbackPlayer: PlayerType.backup,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => player),
    );
  }
}
