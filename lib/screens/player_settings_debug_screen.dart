import 'package:flutter/material.dart';
import 'package:newgraduate/services/player_cache_service.dart';
import 'package:newgraduate/widgets/smart_youtube_player_manager.dart';

class PlayerSettingsDebugScreen extends StatefulWidget {
  const PlayerSettingsDebugScreen({super.key});

  @override
  State<PlayerSettingsDebugScreen> createState() =>
      _PlayerSettingsDebugScreenState();
}

class _PlayerSettingsDebugScreenState extends State<PlayerSettingsDebugScreen> {
  Map<String, dynamic>? _cacheInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    setState(() => _isLoading = true);
    try {
      final info = await VideoPlayerHelper.getCacheStatus();
      setState(() {
        _cacheInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ خطأ في جلب معلومات الكاش: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إعدادات المشغل والكاش',
          style: TextStyle(fontFamily: 'NotoKufiArabic'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCacheInfo,
            tooltip: 'تحديث المعلومات',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeviceInfoCard(),
                  const SizedBox(height: 16),
                  _buildCacheInfoCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                  const SizedBox(height: 16),
                  _buildTestPlayerCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildDeviceInfoCard() {
    final deviceType = VideoPlayerHelper.getCurrentDeviceType();
    final deviceDisplayName = VideoPlayerHelper.getCurrentDeviceDisplayName();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smartphone, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'معلومات الجهاز',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoKufiArabic',
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('نوع الجهاز', deviceDisplayName),
            _buildInfoRow('رمز المنصة', deviceType.toUpperCase()),
            _buildInfoRow('يدعم API المشغل',
                deviceType == 'android' || deviceType == 'ios' ? 'نعم' : 'لا'),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'معلومات الكاش',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoKufiArabic',
                  ),
                ),
              ],
            ),
            const Divider(),
            if (_cacheInfo != null) ...[
              _buildInfoRow(
                  'يوجد كاش', _cacheInfo!['has_cache'] == true ? 'نعم' : 'لا'),
              if (_cacheInfo!['has_cache'] == true) ...[
                _buildInfoRow(
                    'صالح', _cacheInfo!['is_valid'] == true ? 'نعم' : 'لا'),
                _buildInfoRow(
                    'رقم المشغل المحفوظ', '${_cacheInfo!['operator_number']}'),
                _buildInfoRow('اسم المشغل', '${_cacheInfo!['operator_name']}'),
                _buildInfoRow(
                    'تاريخ الحفظ', _formatDate(_cacheInfo!['cached_at'])),
                _buildInfoRow('منصة الكاش',
                    '${_cacheInfo!['cached_platform']?.toUpperCase()}'),
              ],
            ] else ...[
              const Text(
                'لا توجد معلومات متاحة',
                style: TextStyle(fontFamily: 'NotoKufiArabic'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'إجراءات الكاش',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoKufiArabic',
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _forceRefreshCache,
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'تحديث من API',
                      style: TextStyle(fontFamily: 'NotoKufiArabic'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearCache,
                    icon: const Icon(Icons.delete),
                    label: const Text(
                      'مسح الكاش',
                      style: TextStyle(fontFamily: 'NotoKufiArabic'),
                    ),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestPlayerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'اختبار المشغل',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoKufiArabic',
                  ),
                ),
              ],
            ),
            const Divider(),
            // الصف الأول: المشغل 1 و 2
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testPlayer1,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'مشغل 1',
                      style: TextStyle(fontFamily: 'NotoKufiArabic'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testPlayer2,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'مشغل 2',
                      style: TextStyle(fontFamily: 'NotoKufiArabic'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // الصف الثاني: المشغل 3 والنظام الذكي
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testPlayer3,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'مشغل 3',
                      style: TextStyle(fontFamily: 'NotoKufiArabic'),
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testSmartPlayer,
                    icon: const Icon(Icons.smart_toy),
                    label: const Text(
                      'نظام ذكي',
                      style: TextStyle(fontFamily: 'NotoKufiArabic'),
                    ),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'NotoKufiArabic',
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontFamily: 'NotoKufiArabic'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _forceRefreshCache() async {
    setState(() => _isLoading = true);

    try {
      await PlayerCacheService.forceUpdateFromAPI();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم تحديث الكاش بنجاح من API',
            style: TextStyle(fontFamily: 'NotoKufiArabic'),
          ),
        ),
      );

      await _loadCacheInfo();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل في تحديث الكاش: $e',
            style: const TextStyle(fontFamily: 'NotoKufiArabic'),
          ),
        ),
      );
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تأكيد المسح',
          style: TextStyle(fontFamily: 'NotoKufiArabic'),
        ),
        content: const Text(
          'هل أنت متأكد من مسح الكاش؟ سيتم جلب الإعدادات من API في المرة القادمة.',
          style: TextStyle(fontFamily: 'NotoKufiArabic'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('مسح'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await VideoPlayerHelper.clearPlayerCache();
      await _loadCacheInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم مسح الكاش بنجاح',
              style: TextStyle(fontFamily: 'NotoKufiArabic'),
            ),
          ),
        );
      }
    }
  }

  void _testPlayer1() {
    final player = VideoPlayerHelper.createPlayerByNumber(
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      videoTitle: 'اختبار المشغل رقم 1',
      playerNumber: 1,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => player),
    );
  }

  void _testPlayer2() {
    final player = VideoPlayerHelper.createPlayerByNumber(
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      videoTitle: 'اختبار المشغل رقم 2',
      playerNumber: 2,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => player),
    );
  }

  void _testPlayer3() {
    final player = VideoPlayerHelper.createPlayerByNumber(
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      videoTitle: 'اختبار المشغل رقم 3 - Pod Player',
      playerNumber: 3,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => player),
    );
  }

  void _testSmartPlayer() {
    final player = VideoPlayerHelper.createSmartPlayer(
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      videoTitle: 'اختبار النظام الذكي - تحديد تلقائي',
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => player),
    );
  }
}
