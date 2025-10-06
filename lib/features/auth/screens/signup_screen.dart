import 'package:flutter/material.dart';
import 'dart:convert';
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
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isLoading = false;
  bool _isEmailVerificationSent = false;

  List<Institute> _institutes = [];
  Institute? _selectedInstitute;
  bool _isLoadingInstitutes = false;
  // أخطاء الخادم لعرضها تحت الحقول
  String? _serverEmailError;
  String? _serverPhoneError;
  String? _serverPasswordError;
  String? _serverConfirmError;

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
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  /// جلب قائمة المعاهد مع إعادة محاولة واحدة في حال الفشل
  Future<void> _loadInstitutes({int attempt = 1}) async {
    if (attempt == 1) setState(() => _isLoadingInstitutes = true);
    try {
      final institutes = await InstitutesService.getAllInstitutes();
      print('📱 SignupScreen: تم استلام ${institutes.length} معهد');
      if (!mounted) return;
      setState(() {
        _institutes = institutes;
        _isLoadingInstitutes = false;
      });
    } catch (e) {
      print('📱 SignupScreen: خطأ في جلب المعاهد (محاولة $attempt): $e');
      // إعادة محاولة تلقائية مرة واحدة
      if (attempt < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تعذر جلب المعاهد، سيتم إعادة المحاولة...'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        await Future.delayed(const Duration(milliseconds: 800));
        await _loadInstitutes(attempt: attempt + 1);
        return;
      }

      if (mounted) {
        setState(() => _isLoadingInstitutes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب المعاهد: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: () => _loadInstitutes(),
            ),
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

    // تنظيف أخطاء الخادم السابقة قبل المحاولة
    setState(() {
      _serverEmailError = null;
      _serverPhoneError = null;
      _serverPasswordError = null;
      _serverConfirmError = null;
    });

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
        passwordConfirmation: _confirm.text.trim(),
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
      final errorType = RegistrationErrorHandler.getErrorType(e);
      print('🔍 نوع الخطأ: $errorType');

      String errorMessage = RegistrationErrorHandler.getErrorMessage(e);

      // ترجمة نوع الخطأ لعرضه للمستخدم
      String errorTypeLabel;
      switch (errorType) {
        case 'VALIDATION_ERROR':
          errorTypeLabel = 'خطأ في التحقق من البيانات';
          break;
        case 'CONFLICT_ERROR':
          errorTypeLabel = 'تعارض في البيانات';
          break;
        case 'SERVER_ERROR':
          errorTypeLabel = 'خطأ في الخادم';
          break;
        case 'BAD_REQUEST':
          errorTypeLabel = 'طلب غير صحيح';
          break;
        case 'NETWORK_ERROR':
          errorTypeLabel = 'مشكلة في الاتصال';
          break;
        case 'TIMEOUT_ERROR':
          errorTypeLabel = 'انتهت مهلة الطلب';
          break;
        default:
          errorTypeLabel = 'خطأ غير معروف';
      }

      // تحديد لون الرسالة بناءً على نوع الخطأ
      Color backgroundColor = Colors.red;
      if (RegistrationErrorHandler.mightBeSuccessfulRegistration(e)) {
        backgroundColor = Colors.orange; // لون تحذيري بدلاً من خطأ
      }

      // محاولة إسقاط أخطاء محددة تحت الحقول (باستخراج JSON إن وُجد أو عبر عبارات عربية/إنجليزية)
      final eStr = e.toString();
      bool setAny = false;
      // 1) جرّب استخراج JSON من النص
      try {
        final start = eStr.indexOf('{');
        if (start != -1) {
          final jsonPart = eStr.substring(start);
          final decoded = jsonDecode(jsonPart);
          if (decoded is Map<String, dynamic> &&
              decoded['errors'] is Map<String, dynamic>) {
            final errs = decoded['errors'] as Map<String, dynamic>;
            if (errs['email'] is List && (errs['email'] as List).isNotEmpty) {
              _serverEmailError = 'البريد الإلكتروني مستخدم من قبل';
              setAny = true;
            }
            if (errs['phone'] is List && (errs['phone'] as List).isNotEmpty) {
              _serverPhoneError = 'رقم الهاتف مستخدم من قبل';
              setAny = true;
            }
            if (errs['password'] is List &&
                (errs['password'] as List).isNotEmpty) {
              _serverPasswordError =
                  (errs['password'] as List).first.toString();
              setAny = true;
            }
            if (errs['password_confirmation'] is List &&
                (errs['password_confirmation'] as List).isNotEmpty) {
              _serverConfirmError =
                  (errs['password_confirmation'] as List).first.toString();
              setAny = true;
            }
          }
        }
      } catch (_) {}

      // 2) تطابق نصي عربي/إنجليزي إذا لم نجد JSON
      if (!setAny) {
        final hasUnique = eStr.contains('validation.unique') ||
            eStr.contains('مستخدم') ||
            eStr.contains('مستخدمة') ||
            eStr.contains('taken');
        if (hasUnique) {
          if (eStr.contains('email') || eStr.contains('البريد')) {
            _serverEmailError = 'البريد الإلكتروني مستخدم من قبل';
            setAny = true;
          }
          if (eStr.contains('phone') ||
              eStr.contains('الهاتف') ||
              eStr.contains('رقم الهاتف')) {
            _serverPhoneError = 'رقم الهاتف مستخدم من قبل';
            setAny = true;
          }
        }
        if (eStr.contains('password_confirmation') ||
            eStr.contains('تأكيد كلمة السر')) {
          _serverConfirmError = 'تأكيد كلمة السر غير مطابق';
          setAny = true;
        }
      }

      if (mounted) {
        setState(() {});
        // أعد التحقق لإظهار أخطاء الحقول مباشرة
        _formKey.currentState?.validate();
        // تركيز على أول حقل يحتوي خطأ من الخادم لسهولة التصحيح
        Future.microtask(() {
          if (_serverEmailError != null) {
            _emailFocus.requestFocus();
          } else if (_serverPhoneError != null) {
            _phoneFocus.requestFocus();
          } else if (_serverConfirmError != null) {
            _confirmFocus.requestFocus();
          } else if (_serverPasswordError != null) {
            _passwordFocus.requestFocus();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('نوع الخطأ: $errorType ($errorTypeLabel)\n$errorMessage'),
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
        child: (_isLoadingInstitutes && _institutes.isEmpty)
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    InlineLoadingWidget(size: 48),
                    SizedBox(height: 12),
                    Text('جاري تحميل المعاهد...')
                  ],
                ),
              )
            : (!_isLoadingInstitutes && _institutes.isEmpty)
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined,
                              size: 64, color: cs.outline),
                          const SizedBox(height: 12),
                          const Text(
                            'تعذر تحميل قائمة المعاهد',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'يرجى التحقق من الاتصال ثم المحاولة مرة أخرى',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoadingInstitutes
                                ? null
                                : () => _loadInstitutes(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة تحميل المعاهد'),
                          )
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                            decoration:
                                decoration('اكتب اسمك هنا', icon: Icons.person),
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
                            focusNode: _emailFocus,
                            decoration: decoration('ادخل البريد الإلكتروني هنا',
                                icon: Icons.email),
                            onChanged: (v) {
                              if (_serverEmailError != null) {
                                setState(() => _serverEmailError = null);
                              }
                            },
                            validator: (v) {
                              if (_serverEmailError != null)
                                return _serverEmailError;
                              if (v == null || v.trim().isEmpty) {
                                return 'يرجى ادخال البريد الإلكتروني';
                              }
                              if (v.trim().length > 200) {
                                return 'البريد الإلكتروني أطول من المسموح';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(v.trim())) {
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
                            focusNode: _phoneFocus,
                            decoration: decoration('ادخل رقم الهاتف',
                                icon: Icons.phone),
                            onChanged: (v) {
                              if (_serverPhoneError != null) {
                                setState(() => _serverPhoneError = null);
                              }
                            },
                            validator: (v) {
                              if (_serverPhoneError != null)
                                return _serverPhoneError;
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
                            decoration:
                                decoration('اختر المعهد', icon: Icons.school),
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
                            validator: (v) =>
                                v == null ? 'يرجى اختيار المعهد' : null,
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
                          if (!_isLoadingInstitutes && _institutes.isEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _isLoadingInstitutes
                                    ? null
                                    : () => _loadInstitutes(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('إعادة تحميل المعاهد'),
                              ),
                            ),
                          ],
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
                            focusNode: _passwordFocus,
                            decoration: decoration('ادخل كلمة السر هنا',
                                    icon: Icons.lock)
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_obscure1
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () =>
                                    setState(() => _obscure1 = !_obscure1),
                              ),
                            ),
                            onChanged: (v) {
                              bool changed = false;
                              if (_serverPasswordError != null) {
                                _serverPasswordError = null;
                                changed = true;
                              }
                              if (_serverConfirmError != null &&
                                  _confirm.text == v) {
                                _serverConfirmError = null;
                                changed = true;
                              }
                              if (changed) setState(() {});
                            },
                            validator: (v) {
                              if (_serverPasswordError != null)
                                return _serverPasswordError;
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
                            focusNode: _confirmFocus,
                            decoration: decoration('اعد كتابة كلمة السر',
                                    icon: Icons.lock_outline)
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_obscure2
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () =>
                                    setState(() => _obscure2 = !_obscure2),
                              ),
                            ),
                            onChanged: (v) {
                              if (_serverConfirmError != null) {
                                setState(() => _serverConfirmError = null);
                              }
                            },
                            validator: (v) =>
                                _serverConfirmError ??
                                ((v != _password.text)
                                    ? 'كلمتا السر غير متطابقتين'
                                    : null),
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
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
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
                                  Icon(Icons.email,
                                      color: Colors.blue, size: 32),
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
