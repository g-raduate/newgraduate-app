import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:newgraduate/config/app_constants.dart';
import 'package:newgraduate/services/api_headers_manager.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _emailSent = false;
  int _countdown = 0;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint, {IconData? icon}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    return null;
  }

  Future<void> _sendForgotPasswordRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      print('🔄 إرسال طلب استعادة كلمة المرور...');

      final headers = ApiHeadersManager.instance.getBasicHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/password/forgot'),
        headers: headers,
        body: json.encode({
          'email': _emailController.text.trim(),
        }),
      );

      print('📊 استجابة API:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _emailSent = true;
          _countdown = 60; // بدء العد التنازلي
        });
        _startCountdown();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'فشل في إرسال الطلب');
      }
    } catch (e) {
      print('❌ خطأ في إرسال طلب استعادة كلمة المرور: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getErrorMessage(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _getErrorMessage(String error) {
    if (error.contains('not found') || error.contains('غير موجود')) {
      return 'البريد الإلكتروني غير مسجل في النظام';
    } else if (error.contains('invalid') || error.contains('غير صحيح')) {
      return 'البريد الإلكتروني غير صحيح';
    } else if (error.contains('500') || error.contains('فشل')) {
      return 'فشل في إرسال الطلب. يرجى المحاولة مرة أخرى';
    } else if (error.contains('network') || error.contains('شبكة')) {
      return 'خطأ في الاتصال. تحقق من الإنترنت';
    }
    return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('نسيت كلمة المرور'),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                // شعار التطبيق مع حركة
                Center(
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            cs.primaryContainer,
                            cs.primary.withOpacity(0.3),
                          ],
                        ),
                        border: Border.all(
                          color: cs.primary.withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(56),
                        child: Image.asset(
                          'images/logo.png',
                          width: 112,
                          height: 112,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.lock_reset,
                            color: cs.onPrimaryContainer,
                            size: 56,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // العنوان
                Text(
                  _emailSent ? 'تم الإرسال!' : 'استعادة كلمة المرور',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _emailSent ? Colors.green : cs.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // الوصف
                Text(
                  _emailSent
                      ? 'تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني. تحقق من صندوق الوارد أو مجلد الرسائل المزعجة.'
                      : 'أدخل بريدك الإلكتروني وسنرسل لك رابط لاستعادة كلمة المرور',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.7),
                        height: 1.4,
                      ),
                ),

                const SizedBox(height: 32),

                if (!_emailSent) ...[
                  // حقل البريد الإلكتروني
                  Text(
                    'البريد الإلكتروني',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decoration(
                      'أدخل البريد الإلكتروني هنا',
                      icon: Icons.email,
                    ),
                    validator: _validateEmail,
                    enabled: !_loading,
                  ),

                  const SizedBox(height: 32),

                  // زر الإرسال
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _sendForgotPasswordRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'إرسال رابط الاستعادة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ] else ...[
                  // رسالة النجاح مع أيقونة
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.mark_email_read,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'تحقق من بريدك الإلكتروني',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _emailController.text.trim(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurface.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // زر إعادة الإرسال مع عداد
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _countdown > 0
                          ? null
                          : () {
                              setState(() {
                                _emailSent = false;
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _countdown > 0 ? cs.surfaceVariant : cs.secondary,
                        foregroundColor: _countdown > 0
                            ? cs.onSurfaceVariant
                            : cs.onSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _countdown > 0
                            ? 'إعادة الإرسال بعد $_countdown ثانية'
                            : 'إعادة الإرسال',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // رابط العودة لتسجيل الدخول
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'العودة إلى تسجيل الدخول',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // نصائح إضافية
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: cs.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'نصائح مهمة:',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTip('• تحقق من مجلد الرسائل المزعجة (Spam)'),
                      const SizedBox(height: 6),
                      _buildTip('• الرابط صالح لمدة 24 ساعة فقط'),
                      const SizedBox(height: 6),
                      _buildTip('• استخدم البريد المسجل في حسابك'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            height: 1.3,
          ),
    );
  }
}
