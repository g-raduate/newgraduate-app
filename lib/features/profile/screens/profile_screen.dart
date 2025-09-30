import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:newgraduate/widgets/custom_app_bar.dart';
import 'package:newgraduate/widgets/simple_color_picker.dart';
import 'package:newgraduate/providers/simple_theme_provider.dart';
import 'package:newgraduate/utils/responsive_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:newgraduate/utils/prefs_keys.dart';
import 'package:newgraduate/features/auth/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:newgraduate/services/student_service.dart';
import 'package:newgraduate/services/user_info_service.dart';
import 'package:newgraduate/services/cache_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:newgraduate/config/app_constants.dart';
import 'package:newgraduate/services/api_headers_manager.dart';
import 'package:newgraduate/widgets/custom_loading_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userImageUrl = '';
  bool _isLoadingStudentInfo = true;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
  }

  // تحميل معلومات الطالب الحقيقية من API
  Future<void> _loadStudentInfo() async {
    try {
      setState(() {
        _isLoadingStudentInfo = true;
      });

      // الحصول على student_id من التخزين المحلي
      String? studentId = await UserInfoService.getStudentId();

      if (studentId != null && studentId.isNotEmpty) {
        // أولاً، محاولة الحصول على البيانات من الكاش
        print('� البحث عن معلومات الطالب في الكاش...');
        Map<String, dynamic>? cachedStudentInfo =
            await CacheManager.instance.getStudentInfo(studentId);

        if (cachedStudentInfo != null) {
          setState(() {
            _userName = cachedStudentInfo['name'] ?? _userName;
            _userEmail = cachedStudentInfo['email'] ?? _userEmail;
            _userPhone = cachedStudentInfo['phone'] ?? _userPhone;
            _userImageUrl = cachedStudentInfo['image_url'] ?? '';
            _nameController.text = _userName;
            _isLoadingStudentInfo = false;
          });
          print(
              '✅ تم تحميل معلومات الطالب من الكاش: $_userName, $_userEmail, $_userPhone, صورة: $_userImageUrl');
          return;
        }

        print('�📚 جاري تحميل معلومات الطالب من API...');

        // جلب معلومات الطالب من API
        Map<String, dynamic>? studentData =
            await StudentService.getStudentInfo(studentId);

        if (studentData != null) {
          // حفظ البيانات في الكاش
          await CacheManager.instance.setStudentInfo(studentId, studentData);
          print('💾 تم حفظ معلومات الطالب في الكاش');

          setState(() {
            // استخدام البيانات الحقيقية من API
            _userName = studentData['name'] ?? _userName;
            _userEmail = studentData['email'] ?? _userEmail;
            _userPhone = studentData['phone'] ?? _userPhone;
            _userImageUrl = studentData['image_url'] ?? '';
            _nameController.text = _userName;
            _isLoadingStudentInfo = false;
          });

          print(
              '✅ تم تحميل معلومات الطالب: $_userName, $_userEmail, $_userPhone, صورة: $_userImageUrl');
        } else {
          // إذا فشل API، استخدم البيانات المحلية
          print('⚠️ فشل في جلب البيانات من API، استخدام البيانات المحلية...');
          await _loadLocalStudentInfo();
        }
      } else {
        // إذا لم يوجد student_id، عرض رسالة للمستخدم
        print('⚠️ لا يوجد student_id، المستخدم غير مسجل دخول');
        setState(() {
          _userName = 'غير مسجل دخول';
          _userEmail = 'يرجى تسجيل الدخول';
          _userPhone = 'غير متوفر';
          _isLoadingStudentInfo = false;
        });
      }
    } catch (e) {
      print('❌ خطأ في تحميل معلومات الطالب: $e');
      await _loadLocalStudentInfo();
    }
  }

  // تحميل البيانات المحفوظة محلياً كبديل
  Future<void> _loadLocalStudentInfo() async {
    try {
      Map<String, String?> localInfo =
          await StudentService.getLocalStudentInfo();

      setState(() {
        if (localInfo['userName'] != null &&
            localInfo['userName']!.isNotEmpty) {
          _userName = localInfo['userName']!;
          _nameController.text = _userName;
        } else {
          _userName = 'غير محدد';
        }

        if (localInfo['phone'] != null && localInfo['phone']!.isNotEmpty) {
          _userPhone = localInfo['phone']!;
        } else {
          _userPhone = 'غير محدد';
        }

        if (localInfo['imageUrl'] != null &&
            localInfo['imageUrl']!.isNotEmpty) {
          _userImageUrl = localInfo['imageUrl']!;
        } else {
          _userImageUrl = '';
        }

        // البريد الإلكتروني من البيانات المحلية إذا توفر
        _userEmail = 'غير محدد';

        _isLoadingStudentInfo = false;
      });

      print('✅ تم تحميل البيانات المحلية: $_userName, $_userPhone');
    } catch (e) {
      print('❌ خطأ في تحميل البيانات المحلية: $e');
      setState(() {
        _isLoadingStudentInfo = false;
      });
    }
  }

  // حذف الحساب
  Future<void> _deleteAccount() async {
    print('🔥 بدء عملية حذف الحساب...');
    try {
      // إظهار dialog التأكيد
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تأكيد حذف الحساب'),
          content: const Text(
            'هل أنت متأكد من حذف الحساب؟\n\nتحذير: هذا الإجراء لا يمكن التراجع عنه وسيتم حذف جميع بياناتك نهائياً.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('حذف الحساب'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      print('✅ المستخدم أكد حذف الحساب، جاري المتابعة...');

      // إظهار مؤشر التحميل
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: InlineLoadingWidget(
            message: 'جاري حذف الحساب...',
            size: 60,
          ),
        ),
      );

      // استدعاء api/auth/me للحصول على الـ id الصحيح
      print('🔍 جاري استدعاء api/auth/me للحصول على المعرف الصحيح...');

      final meHeaders = await ApiHeadersManager.instance.getAuthHeaders();
      final meResponse = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/auth/me'),
        headers: meHeaders,
      );

      print('📊 استجابة api/auth/me:');
      print('   - Status Code: ${meResponse.statusCode}');
      print('   - Body: ${meResponse.body}');

      if (meResponse.statusCode != 200) {
        if (!mounted) return;
        Navigator.of(context).pop(); // إغلاق dialog التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'خطأ في الحصول على معرف المستخدم: ${meResponse.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // استخراج id من الاستجابة
      final meData = json.decode(meResponse.body);
      final correctUserId = meData['id'] as String?;

      print('🆔 المعرف المستخرج من api/auth/me: $correctUserId');

      if (correctUserId == null || correctUserId.isEmpty) {
        if (!mounted) return;
        Navigator.of(context).pop(); // إغلاق dialog التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ: لا يمكن العثور على معرف المستخدم الصحيح'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // استخدام المعرف الصحيح للحذف
      print('🗑️ جاري إرسال طلب حذف الحساب...');
      print('📍 URL: ${AppConstants.baseUrl}/api/users/$correctUserId');
      print('🎯 استخدام المعرف الصحيح: $correctUserId');

      final headers = await ApiHeadersManager.instance.getAuthHeaders();
      print('📋 Headers المُرسلة: $headers');

      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/api/users/$correctUserId'),
        headers: headers,
      );

      print('📊 استجابة حذف الحساب:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Headers: ${response.headers}');
      print('   - Body: ${response.body}');
      print('=' * 50);

      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق dialog التحميل

      if (response.statusCode == 200) {
        print('✅ تم حذف الحساب بنجاح بالمعرف: $correctUserId');

        final responseData = json.decode(response.body);
        print('✅ تم تحليل response بنجاح: $responseData');

        if (responseData['message'] == 'User deleted') {
          print('✅ تأكيد حذف الحساب من الخادم');
          // نجح الحذف - تنظيف البيانات المحلية
          await UserInfoService.clearUserInfo();
          await CacheManager.instance.clearAllCache();

          // حذف معلومات تسجيل الدخول
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(kIsLoggedIn, false);

          if (!mounted) return;

          // إظهار رسالة نجاح
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الحساب بنجاح'),
              backgroundColor: Colors.green,
            ),
          );

          // الانتقال لشاشة تسجيل الدخول
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } else {
          print('⚠️ رسالة غير متوقعة في response: ${responseData['message']}');
          throw Exception(
              'استجابة غير متوقعة من الخادم: ${responseData['message'] ?? 'غير محدد'}');
        }
      } else {
        print('❌ فشل حذف الحساب - Status Code: ${response.statusCode}');
        print('❌ Response Body: ${response.body}');
        throw Exception(
            'فشل في حذف الحساب: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ خطأ عام في عملية حذف الحساب: $e');
      print('❌ نوع الخطأ: ${e.runtimeType}');
      if (mounted) {
        Navigator.of(context).pop(); // إغلاق dialog التحميل إذا كان مفتوحاً
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف الحساب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: CustomAppBarWidget(
            title: 'الحساب',
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
            child: SingleChildScrollView(
              padding: ResponsiveHelper.getPadding(context),
              child: Column(
                children: [
                  _buildProfileHeader(themeProvider),
                  SizedBox(
                      height: ResponsiveHelper.getSpacing(context,
                          mobileSpacing: 32,
                          tabletSpacing: 40,
                          desktopSpacing: 48)),
                  _buildThemeSettingsCard(themeProvider),
                  SizedBox(
                      height: ResponsiveHelper.getSpacing(context,
                          mobileSpacing: 20,
                          tabletSpacing: 24,
                          desktopSpacing: 28)),
                  _buildAccountInfo(),
                  SizedBox(
                      height: ResponsiveHelper.getSpacing(context,
                          mobileSpacing: 24,
                          tabletSpacing: 28,
                          desktopSpacing: 32)),
                  _buildSupportSection(),
                  SizedBox(
                      height: ResponsiveHelper.getSpacing(context,
                          mobileSpacing: 24,
                          tabletSpacing: 28,
                          desktopSpacing: 32)),
                  _buildLogoutButton(themeProvider),
                  SizedBox(
                      height: ResponsiveHelper.getSpacing(context,
                          mobileSpacing: 24,
                          tabletSpacing: 28,
                          desktopSpacing: 32)),
                  _buildSocialLinks(),
                  SizedBox(
                      height: ResponsiveHelper.getSpacing(context,
                          mobileSpacing: 16,
                          tabletSpacing: 20,
                          desktopSpacing: 24)),
                  _buildDeleteAccountButton(themeProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(SimpleThemeProvider themeProvider) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: themeProvider.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: themeProvider.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: ClipOval(
              child: _userImageUrl.isNotEmpty
                  ? Image.network(
                      _userImageUrl,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'images/student_picture.jpg',
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        );
                      },
                    )
                  : Image.asset(
                      'images/student_picture.jpg',
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _userName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: themeProvider.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: themeProvider.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Text(
            'طالب متميز',
            style: TextStyle(
              color: themeProvider.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSettingsCard(SimpleThemeProvider themeProvider) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              themeProvider.primaryColor.withOpacity(0.1),
              themeProvider.primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.palette,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'إعدادات الثيم',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildThemeOption(
              title: 'اختيار لون التطبيق',
              subtitle: 'اضغط لاختيار لونك المفضل',
              icon: Icons.color_lens,
              themeProvider: themeProvider,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => SimpleColorPicker(
                    onColorSelected: (color) {
                      themeProvider.setPrimaryColor(color);
                    },
                  ),
                );
              },
              trailing: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: themeProvider.primaryGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildThemeOption(
              title:
                  themeProvider.isDarkMode ? 'الوضع النهاري' : 'الوضع الليلي',
              subtitle: themeProvider.isDarkMode
                  ? 'التبديل إلى الوضع الفاتح'
                  : 'التبديل إلى الوضع الداكن',
              icon:
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              themeProvider: themeProvider,
              onTap: () {
                themeProvider.toggleDarkMode();
              },
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleDarkMode();
                },
                activeColor: themeProvider.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required SimpleThemeProvider themeProvider,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: themeProvider.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: themeProvider.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: themeProvider.isDarkMode
                              ? Colors.white70
                              : Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Consumer<SimpleThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: themeProvider.cardGradient,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'معلومات الحساب',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                      ),
                      const Spacer(),
                      if (_isLoadingStudentInfo)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              themeProvider.primaryColor,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: _loadStudentInfo,
                          icon: Icon(
                            Icons.refresh,
                            color: themeProvider.primaryColor,
                          ),
                          tooltip: 'تحديث البيانات',
                          iconSize: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTile(
                    icon: Icons.person,
                    title: 'الاسم',
                    value:
                        _isLoadingStudentInfo ? 'جاري التحميل...' : _userName,
                    onEdit: _isLoadingStudentInfo ? null : _editName,
                    themeProvider: themeProvider,
                  ),
                  _buildInfoTile(
                    icon: Icons.email,
                    title: 'البريد الإلكتروني',
                    value:
                        _isLoadingStudentInfo ? 'جاري التحميل...' : _userEmail,
                    themeProvider: themeProvider,
                  ),
                  _buildInfoTile(
                    icon: Icons.phone,
                    title: 'رقم الهاتف',
                    value:
                        _isLoadingStudentInfo ? 'جاري التحميل...' : _userPhone,
                    themeProvider: themeProvider,
                  ),
                  // زر تسجيل الدخول عند عدم وجود بيانات
                  if (!_isLoadingStudentInfo && _userName == 'غير مسجل دخول')
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.login),
                          label: const Text('تسجيل الدخول'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required SimpleThemeProvider themeProvider,
    VoidCallback? onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: themeProvider.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeProvider.isDarkMode
                            ? Colors.white70
                            : Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: Icon(
                Icons.edit,
                size: 20,
                color: themeProvider.primaryColor,
              ),
              onPressed: onEdit,
              style: IconButton.styleFrom(
                backgroundColor: themeProvider.primaryColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Consumer<SimpleThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: themeProvider.cardGradient,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الدعم والمساعدة',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildSupportTile(
                    icon: Icons.contact_support,
                    color: themeProvider.primaryColor.withOpacity(0.8),
                    title: 'تواصل معنا',
                    subtitle: 'راسلنا للحصول على المساعدة',
                    themeProvider: themeProvider,
                    onTap: () {
                      _showSupportDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required SimpleThemeProvider themeProvider,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: themeProvider.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: themeProvider.isDarkMode
                              ? Colors.white70
                              : Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color:
                  themeProvider.isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks() {
    return Consumer<SimpleThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: themeProvider.cardGradient,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تابعنا على',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // أزرار وسائل التواصل
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // زر Instagram
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            child: SizedBox(
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  const url =
                                      'https://www.instagram.com/g_raduate';
                                  await _launchUrl(url);
                                },
                                icon: SvgPicture.asset(
                                  'images/instagram.svg',
                                  color: Colors.white,
                                  width: 18,
                                  height: 18,
                                ),
                                label: const Text(
                                  'Instagram',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'NotoKufiArabic',
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE1306C),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  elevation: 3,
                                  shadowColor:
                                      const Color(0xFFE1306C).withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // فاصل بسيط
                        const SizedBox(width: 8),

                        // زر Telegram
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 4),
                            child: SizedBox(
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  const url = 'https://t.me/g_raduate';
                                  await _launchUrl(url);
                                },
                                icon: SvgPicture.asset(
                                  'images/telegram.svg',
                                  color: Colors.white,
                                  width: 18,
                                  height: 18,
                                ),
                                label: const Text(
                                  'Telegram',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'NotoKufiArabic',
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0088CC),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  elevation: 3,
                                  shadowColor:
                                      const Color(0xFF0088CC).withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _editName() {
    final themeProvider =
        Provider.of<SimpleThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            themeProvider.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'تعديل الاسم',
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: _nameController,
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            labelText: 'الاسم الجديد',
            labelStyle: TextStyle(
              color:
                  themeProvider.isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: themeProvider.primaryColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: themeProvider.primaryColor,
                width: 2,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor:
                  themeProvider.isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _userName = _nameController.text;
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    final themeProvider =
        Provider.of<SimpleThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            themeProvider.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'تواصل معنا',
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'يمكنك التواصل معنا عبر:',
              style: TextStyle(
                color:
                    themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // أزرار وسائل التواصل
            _buildSocialContactButton(
              icon: 'images/instagram.svg',
              text: 'Instagram',
              color: const Color(0xFFE1306C),
              themeProvider: themeProvider,
              onTap: () async {
                const url = 'https://www.instagram.com/g_raduate';
                await _launchUrl(url);
              },
            ),
            const SizedBox(height: 8),

            _buildSocialContactButton(
              icon: 'images/telegram.svg',
              text: 'Telegram',
              color: const Color(0xFF0088CC),
              themeProvider: themeProvider,
              onTap: () async {
                const url = 'https://t.me/g_raduate';
                await _launchUrl(url);
              },
            ),
            const SizedBox(height: 8),

            _buildSocialContactButton(
              icon: 'images/whatsapp.svg',
              text: 'WhatsApp',
              color: const Color(0xFF25D366),
              themeProvider: themeProvider,
              onTap: () async {
                const url = 'https://wa.me/96407748687725';
                await _launchUrl(url);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: themeProvider.primaryColor,
            ),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountButton(SimpleThemeProvider themeProvider) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete_forever),
            label: const Text(
              'حذف الحساب',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(SimpleThemeProvider themeProvider) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: cs.errorContainer,
              foregroundColor: cs.onErrorContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('تأكيد تسجيل الخروج'),
                  content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('تأكيد'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                print('🔄 بدء عملية تسجيل الخروج...');

                // حذف جميع البيانات المحلية والكاش
                print('🗑️ حذف البيانات المحلية...');
                await UserInfoService.clearUserInfo();

                print('🗑️ حذف الكاش...');
                await CacheManager.instance.clearAllCache();

                print('🗑️ حذف حالة تسجيل الدخول...');
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(kIsLoggedIn, false);

                print('✅ تم إكمال تسجيل الخروج وحذف جميع البيانات');

                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text(
              'تسجيل الخروج',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  /// دالة لفتح الروابط
  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      bool launched = false;

      // جرب فتح التطبيق مباشرة
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        // جرب في المتصفح
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
          );
        } catch (e2) {
          // جرب الطريقة الافتراضية
          launched = await launchUrl(uri);
        }
      }

      if (!launched) {
        throw 'فشل في فتح الرابط';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في فتح الرابط: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// بناء زر التواصل الاجتماعي مع SVG
  Widget _buildSocialContactButton({
    required String icon,
    required String text,
    required Color color,
    required SimpleThemeProvider themeProvider,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                icon,
                width: 20,
                height: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: themeProvider.isDarkMode ? Colors.white54 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
