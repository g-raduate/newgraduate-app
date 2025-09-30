import 'package:flutter/material.dart';
import 'package:newgraduate/services/cache_manager.dart';
import 'package:newgraduate/widgets/custom_app_bar.dart';

/// شاشة إدارة الكاش
/// تتيح للمستخدم مراقبة وإدارة البيانات المخزنة مؤقتاً
class CacheManagementScreen extends StatefulWidget {
  const CacheManagementScreen({super.key});

  @override
  State<CacheManagementScreen> createState() => _CacheManagementScreenState();
}

class _CacheManagementScreenState extends State<CacheManagementScreen> {
  Map<String, dynamic> cacheInfo = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      final info = await CacheManager.instance.getCacheInfo();
      setState(() {
        cacheInfo = info;
        isLoading = false;
      });
    } catch (e) {
      print('❌ خطأ في تحميل معلومات الكاش: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _clearCache(CacheType? type) async {
    // إظهار تأكيد للمستخدم
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد مسح البيانات'),
        content: Text(type == null
            ? 'هل أنت متأكد من مسح جميع البيانات المحفوظة؟\nسيؤدي هذا إلى إبطاء التطبيق مؤقتاً.'
            : 'هل أنت متأكد من مسح بيانات ${_getCacheTypeName(type)}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('مسح'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        isLoading = true;
      });

      try {
        bool success;
        if (type == null) {
          success = await CacheManager.instance.clearAllCache();
        } else {
          success = await CacheManager.instance.clearCacheByType(type);
        }

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(type == null
                  ? 'تم مسح جميع البيانات بنجاح'
                  : 'تم مسح بيانات ${_getCacheTypeName(type)} بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('فشل في المسح');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في المسح: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        await _loadCacheInfo();
      }
    }
  }

  String _getCacheTypeName(CacheType type) {
    switch (type) {
      case CacheType.courses:
        return 'الدورات';
      case CacheType.videos:
        return 'الفيديوهات';
      case CacheType.summaries:
        return 'الملخصات';
      case CacheType.studentInfo:
        return 'معلومات الطالب';
      case CacheType.instructors:
        return 'المدرسين';
      case CacheType.departments:
        return 'الأقسام';
      case CacheType.image:
        return 'الصور';
      case CacheType.general:
        return 'عام';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarWidget(
        title: 'إدارة البيانات المحفوظة',
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل معلومات البيانات...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  _buildCacheTypesSection(),
                  const SizedBox(height: 20),
                  _buildDangerZone(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'معلومات عامة',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'الحجم الإجمالي',
              '${cacheInfo['total_size_mb'] ?? '0'} ميجابايت',
              Icons.storage,
            ),
            _buildInfoRow(
              'عدد العناصر',
              '${cacheInfo['total_items'] ?? '0'} عنصر',
              Icons.format_list_numbered,
            ),
            _buildInfoRow(
              'آخر تنظيف',
              cacheInfo['last_cleanup'] ?? 'لم يتم التنظيف بعد',
              Icons.cleaning_services,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'البيانات المحفوظة تساعد في تسريع التطبيق وتقليل استهلاك الإنترنت',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheTypesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'مسح بيانات محددة',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCacheTypeOption(
              'بيانات الدورات',
              'معلومات الدورات والمناهج',
              Icons.school,
              CacheType.courses,
            ),
            _buildCacheTypeOption(
              'فيديوهات الدروس',
              'قوائم الفيديوهات وروابطها',
              Icons.video_library,
              CacheType.videos,
            ),
            _buildCacheTypeOption(
              'الملخصات',
              'ملخصات الدروس والمحاضرات',
              Icons.description,
              CacheType.summaries,
            ),
            _buildCacheTypeOption(
              'معلومات الطالب',
              'بيانات الملف الشخصي',
              Icons.person,
              CacheType.studentInfo,
            ),
            _buildCacheTypeOption(
              'معلومات المدرسين',
              'بيانات المعلمين والأساتذة',
              Icons.people,
              CacheType.instructors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheTypeOption(
    String title,
    String subtitle,
    IconData icon,
    CacheType type,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () => _clearCache(type),
        tooltip: 'مسح $title',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'منطقة خطر',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'مسح جميع البيانات سيؤدي إلى إبطاء التطبيق مؤقتاً حتى يتم إعادة تحميل البيانات من الخادم.',
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _clearCache(null),
                icon: const Icon(Icons.delete_forever),
                label: const Text('مسح جميع البيانات المحفوظة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
