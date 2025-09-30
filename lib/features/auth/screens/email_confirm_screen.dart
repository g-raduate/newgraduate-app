import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:newgraduate/features/auth/state/auth_controller.dart';
import 'package:newgraduate/features/auth/data/auth_repository.dart';
import 'package:newgraduate/features/auth/screens/email_sent_screen.dart';

class EmailConfirmScreen extends StatefulWidget {
  const EmailConfirmScreen({super.key});

  @override
  State<EmailConfirmScreen> createState() => _EmailConfirmScreenState();
}

class _EmailConfirmScreenState extends State<EmailConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    _emailController = TextEditingController(text: auth.userEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
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

  Future<void> _resendEmailVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final repository = context.read<AuthRepository>();
      await repository.resendEmailVerification(_emailController.text.trim());

      if (!mounted) return;

      // التنقل إلى شاشة تأكيد الإرسال
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              EmailSentScreen(email: _emailController.text.trim()),
        ),
      );
    } catch (e) {
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

  String _getErrorMessage(String error) {
    if (error.contains('already verified') || error.contains('مؤكد مسبقاً')) {
      return 'تم تأكيد البريد الإلكتروني مسبقاً';
    } else if (error.contains('invalid') || error.contains('غير صحيحة')) {
      return 'البريد الإلكتروني غير صحيح أو غير موجود';
    } else if (error.contains('500') || error.contains('فشل')) {
      return 'فشل في إرسال بريد التأكيد. يرجى المحاولة مرة أخرى';
    }
    return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد البريد الإلكتروني'),
        centerTitle: true,
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
                Center(
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: cs.primaryContainer,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(56),
                      child: Image.asset(
                        'images/logo.png',
                        width: 112,
                        height: 112,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.email_outlined,
                          color: cs.onPrimaryContainer,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'تأكيد البريد الإلكتروني',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'أدخل بريدك الإلكتروني لإعادة إرسال رابط التأكيد',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 32),
                Text(
                  'البريد الإلكتروني',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      _decoration('أدخل بريدك الإلكتروني', icon: Icons.email),
                  validator: _validateEmail,
                  enabled: !_loading,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _resendEmailVerification,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('إرسال رابط التأكيد'),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: cs.surfaceVariant.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: cs.primary,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'تحقق من صندوق الوارد والرسائل المرفوضة في بريدك الإلكتروني',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
