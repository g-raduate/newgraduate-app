import 'package:flutter/material.dart';
import 'package:newgraduate/services/institutes_service.dart';
import 'package:newgraduate/services/email_verification_service.dart';
import 'package:newgraduate/services/api_client.dart';
import 'package:newgraduate/features/auth/data/auth_repository.dart';
import 'package:newgraduate/features/auth/utils/registration_error_handler.dart';
import 'package:newgraduate/features/auth/screens/email_sent_screen.dart';
import 'package:newgraduate/widgets/custom_loading_widget.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isLoading = false;
  bool _isEmailVerificationSent = false;

  List<Institute> _institutes = [];
  Institute? _selectedInstitute;
  bool _isLoadingInstitutes = false;

  @override
  void initState() {
    super.initState();
    _loadInstitutes();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// جلب قائمة المعاهد
  Future<void> _loadInstitutes() async {
    setState(() => _isLoadingInstitutes = true);
    try {
      final institutes = await InstitutesService.getAllInstitutes();
      print('📱 SignupScreen: تم استلام ${institutes.length} معهد');
      setState(() {
        _institutes = institutes;
        _isLoadingInstitutes = false;
      });
    } catch (e) {
      print('📱 SignupScreen: خطأ في جلب المعاهد: $e');
      setState(() => _isLoadingInstitutes = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب المعاهد: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// تسجيل طالب جديد
  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInstitute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار المعهد'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // تحضير البيانات
      final registrationData = {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text.trim(),
        'phone': _phone.text.trim(),
        'institute_id': _selectedInstitute!.id,
        'role': 'student',
      };

      print('📝 بيانات التسجيل: $registrationData');

      // استخدام AuthRepository بدلاً من ApiClient مباشرة
      final authRepository = AuthRepository(ApiClient());

      final response = await authRepository.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text.trim(),
        phone: _phone.text.trim(),
        instituteId: _selectedInstitute!.id,
      );

      print('✅ نجح التسجيل: $response');

      // إرسال بريد التحقق
      await EmailVerificationService.sendVerificationEmail(
        email: _email.text.trim(),
      );

      setState(() => _isEmailVerificationSent = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الحساب بنجاح! تم إرسال بريد التحقق.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // التوجه إلى شاشة تأكيد البريد
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmailSentScreen(email: _email.text.trim()),
          ),
        );
      }
    } catch (e) {
      print('❌ خطأ في التسجيل: $e');
      print('🔍 نوع الخطأ: ${RegistrationErrorHandler.getErrorType(e)}');

      String errorMessage = RegistrationErrorHandler.getErrorMessage(e);

      // تحديد لون الرسالة بناءً على نوع الخطأ
      Color backgroundColor = Colors.red;
      if (RegistrationErrorHandler.mightBeSuccessfulRegistration(e)) {
        backgroundColor = Colors.orange; // لون تحذيري بدلاً من خطأ
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 5), // مدة أطول للرسائل المهمة
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    InputDecoration decoration(String hint, {IconData? icon}) =>
        InputDecoration(
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          filled: true,
          fillColor: cs.surfaceVariant.withOpacity(0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: cs.error),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب'), centerTitle: true),
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
                    radius: 44,
                    backgroundColor: cs.secondaryContainer,
                    child: Icon(Icons.person_add,
                        color: cs.onSecondaryContainer, size: 44),
                  ),
                ),
                const SizedBox(height: 28),
                Text('الاسم الكامل',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _name,
                  decoration: decoration('اكتب اسمك هنا', icon: Icons.person),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return 'الاسم يجب أن يكون حرفين على الأقل';
                    }
                    if (v.trim().length > 150) {
                      return 'الاسم يجب أن يكون أقل من 150 حرف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('البريد الإلكتروني',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: decoration('ادخل البريد الإلكتروني هنا',
                      icon: Icons.email),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'يرجى ادخال البريد الإلكتروني';
                    }
                    if (v.trim().length > 200) {
                      return 'البريد الإلكتروني أطول من المسموح';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'تنسيق البريد الإلكتروني غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('رقم الهاتف',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: decoration('ادخل رقم الهاتف', icon: Icons.phone),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'رقم الهاتف مطلوب';
                    }
                    if (v.trim().length > 30) {
                      return 'رقم الهاتف أطول من المسموح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('المعهد',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                DropdownButtonFormField<Institute>(
                  value: _selectedInstitute,
                  decoration: decoration('اختر المعهد', icon: Icons.school),
                  items: _institutes.map((institute) {
                    return DropdownMenuItem<Institute>(
                      value: institute,
                      child: Text(institute.name),
                    );
                  }).toList(),
                  onChanged: _isLoadingInstitutes
                      ? null
                      : (Institute? value) {
                          setState(() => _selectedInstitute = value);
                        },
                  validator: (v) => v == null ? 'يرجى اختيار المعهد' : null,
                  isExpanded: true,
                  hint: _isLoadingInstitutes
                      ? const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: InlineLoadingWidget(
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('جاري تحميل المعاهد...'),
                          ],
                        )
                      : const Text('اختر المعهد'),
                ),
                const SizedBox(height: 16),
                Text('كلمة السر',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure1,
                  decoration: decoration('ادخل كلمة السر هنا', icon: Icons.lock)
                      .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure1 ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'يرجى ادخال كلمة السر';
                    }
                    if (v.length < 6) {
                      return 'كلمة السر يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('تأكيد كلمة السر',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure2,
                  decoration: decoration('اعد كتابة كلمة السر',
                          icon: Icons.lock_outline)
                      .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure2 ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  validator: (v) =>
                      (v != _password.text) ? 'كلمتا السر غير متطابقتين' : null,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerStudent,
                    child: _isLoading
                        ? const InlineLoadingWidget(
                            size: 30,
                          )
                        : const Text('إنشاء الحساب',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                if (_isEmailVerificationSent) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.email, color: Colors.blue, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'تم إرسال بريد التحقق',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'يرجى فحص بريدك الإلكتروني والنقر على رابط التحقق لتفعيل حسابك',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
