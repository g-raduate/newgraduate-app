import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import 'package:newgraduate/utils/prefs_keys.dart';
import 'package:newgraduate/features/auth/data/auth_repository.dart';
import 'package:newgraduate/features/auth/state/auth_controller.dart';
import 'package:newgraduate/features/shell/screens/main_shell.dart';
import 'package:newgraduate/features/auth/screens/signup_screen.dart';
import 'package:newgraduate/features/auth/screens/email_confirm_screen.dart';
import 'package:newgraduate/features/auth/screens/forgot_password_screen.dart';
import 'package:newgraduate/config/runtime_config.dart';
import 'package:newgraduate/config/app_constants.dart';
import 'package:newgraduate/services/location_permission_service.dart';
import 'package:newgraduate/widgets/custom_loading_widget.dart';
import 'package:newgraduate/managers/security_manager.dart';
import 'package:newgraduate/services/institute_info_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _cachedBaseUrl;
  // أخطاء الخادم لعرضها تحت الحقول (422)
  String? _serverEmailError;
  String? _serverPasswordError;

  @override
  void initState() {
    super.initState();
    // طلب صلاحية الموقع عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationPermissionService.requestPermissionOnAppStart(context);

      // تهيئة نظام الأمان إذا لم يكن مهيئاً
      if (!SecurityManager.isInitialized) {
        print('🔒 LoginScreen: تهيئة نظام الأمان');
        SecurityManager.initialize(context);
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
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
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // API base URL display removed from UI for production
                    const SizedBox.shrink(),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
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
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(44),
                          child: Image.asset(
                            'images/logo.png',
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.school,
                              color: cs.onPrimaryContainer,
                              size: 44,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'البريد',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
              decoration('ادخل البريد هنا', icon: Icons.email)
                .copyWith(errorText: _serverEmailError),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'يرجى ادخال النص هنا'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'كلمة السر',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration:
                          decoration('ادخل كلمة السر هنا', icon: Icons.lock)
                              .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        errorText: _serverPasswordError,
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'يرجى ادخال النص هنا'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                ),
                            child: const Text('نسيت كلمة السر؟')),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SignupScreen()),
                          ),
                          child: const Text('انشاء حساب جديد'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () async {
                                if (!(_formKey.currentState?.validate() ??
                                    false)) return;

                                final base = await _currentBaseUrl();
                                debugPrint('[Login] Using API Base: $base');
                                // Prompt for location permission/service only if needed before showing the loading overlay
                                await _maybePromptLocationPermission();
                                // تنظيف أخطاء الخادم السابقة قبل المحاولة
                                setState(() {
                                  _serverEmailError = null;
                                  _serverPasswordError = null;
                                });
                                setState(() => _loading = true);
                                try {
                                  final loc = await _safeGetLocation();
                                  if (loc != null) {
                                    debugPrint(
                                        '[Login] Will send location lat=${loc.$1}, lon=${loc.$2}, acc=${loc.$3}m');
                                  } else {
                                    debugPrint(
                                        '[Login] No location available: permission denied/service off or error');
                                  }

                                  // استخدام AuthController بدلاً من repository مباشرة
                                  final authController =
                                      context.read<AuthController>();
                                  final success = await authController.login(
                                    email: _email.text.trim(),
                                    password: _password.text,
                                    latitude: loc?.$1,
                                    longitude: loc?.$2,
                                    accuracy: loc?.$3,
                                    locationSource: loc != null ? 'gps' : null,
                                  );

                                  if (!success) {
                                    if (!mounted) return;
                                    // حالة خاصة: البريد غير مؤكد
                                    if (authController.emailNotVerified) {
                                      final proceed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('الحساب غير مؤكد'),
                                          content: const Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.email_outlined,
                                                size: 48,
                                                color: Colors.orange,
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'الحساب غير مؤكد. نحن لا نسمح بالحسابات الغير مؤكدة بتسجيل الدخول.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              SizedBox(height: 12),
                                              Text(
                                                'هل ترغب بتأكيد بريدك الإلكتروني الآن؟',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('اغلاق'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text('تأكيد الآن'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (proceed == true) {
                                        if (!mounted) return;
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const EmailConfirmScreen()),
                                        );
                                      }
                                      return;
                                    }

                                    // 422: أخطاء التحقق الحقلية
                                    final vErrs =
                                        authController.validationErrors;
                                    if (vErrs != null && vErrs.isNotEmpty) {
                                      setState(() {
                                        _serverEmailError =
                                            vErrs['email']?.first;
                                        _serverPasswordError =
                                            vErrs['password']?.first;
                                      });
                                      final msg = authController.error ??
                                          'يرجى التحقق من المدخلات';
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(msg),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    // 401: بيانات اعتماد غير صحيحة
                                    final err = authController.error ?? '';
                                    if (err.contains('Invalid credentials') ||
                                        err.contains('غير صحيحة') ||
                                        err.contains('Unauthenticated')) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'بيانات اعتماد غير صحيحة (إيميل أو كلمة مرور خاطئة)'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(authController.error ??
                                            'فشل في تسجيل الدخول'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  // إذا كان البريد غير مؤكد، عرض حوار بصري مع خيار الانتقال إلى شاشة التأكيد
                                  if (!authController.isEmailVerified) {
                                    if (!mounted) return;
                                    final go = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('بريدك غير مؤكد'),
                                        content: const Text(
                                            'هل ترغب بتأكيد بريدك الآن؟'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text('لاحقاً'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text('تأكيد الآن'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (go == true) {
                                      if (!mounted) return;
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const EmailConfirmScreen(),
                                        ),
                                      );
                                      return; // stop further navigation
                                    }
                                  }

                                  // Also fetch student's profile to print its response
                                  final repo = context.read<AuthRepository>();
                                  try {
                                    final me = await repo.getMe();
                                    debugPrint(
                                        '[Students] Response JSON: ${me.toString()}');

                                    // حفظ بيانات المعهد إذا كانت متوفرة
                                    if (me['institute'] != null) {
                                      final institute = me['institute']
                                          as Map<String, dynamic>;
                                      await InstituteInfoService
                                          .saveInstituteInfo(
                                        id: institute['id']?.toString(),
                                        name: institute['name']?.toString(),
                                        phone: institute['phone']?.toString(),
                                        email: institute['email']?.toString(),
                                        imageUrl:
                                            institute['image_url']?.toString(),
                                        createdAt:
                                            institute['created_at']?.toString(),
                                      );
                                      debugPrint(
                                          '[Institute] معلومات المعهد محفوظة: ${institute['name']} - ${institute['phone']}');
                                    }
                                  } catch (e) {
                                    debugPrint(
                                        '[Students] Error fetching profile: $e');
                                  }
                                  if (!mounted) return;
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool(kIsLoggedIn, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('تم تسجيل الدخول')),
                                  );
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (_) => const MainScreen()),
                                    (route) => false,
                                  );
                                } catch (e, st) {
                                  debugPrint('[Login] Error: $e\n$st');
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                } finally {
                                  if (mounted) setState(() => _loading = false);
                                }
                              },
                        child: const Text('تسجيل الدخول',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CustomLoadingWidget(
                      message: 'جاري تسجيل الدخول...\nيرجى الانتظار',
                      size: 120,
                      showBackground: false,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Show in-app dialogs to request enabling service/permission only if needed.
  Future<void> _maybePromptLocationPermission() async {
    try {
      // Service check
      var serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        final goSettings = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تشغيل خدمة الموقع'),
            content: const Text(
                'خدمة الموقع غير مفعلة. هل تريد فتح الإعدادات لتفعيلها؟'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('لاحقاً')),
              FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('فتح الإعدادات')),
            ],
          ),
        );
        if (goSettings == true) {
          await Geolocator.openLocationSettings();
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }

      // Permission check
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      } else if (permission == LocationPermission.deniedForever && mounted) {
        final openApp = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('الصلاحية مرفوضة دائماً'),
            content: const Text('يرجى منح صلاحية الموقع من إعدادات التطبيق.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('إلغاء')),
              FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('فتح الإعدادات')),
            ],
          ),
        );
        if (openApp == true) {
          await Geolocator.openAppSettings();
        }
      }
    } catch (e, st) {
      debugPrint('[Location] maybePrompt error: $e\n$st');
    }
  }

  // Returns (lat, lon, accuracyMeters) or null if unavailable
  Future<(double, double, double)?> _safeGetLocation() async {
    try {
      debugPrint('[Location] Starting location fetch...');

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[Location] Service disabled');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      debugPrint('[Location] Permission status: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[Location] Permission after request: $permission');
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[Location] Permission denied');
        return null;
      }

      debugPrint('[Location] Getting current position...');
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // حد زمني للحصول على الموقع
      );

      debugPrint(
          '[Location] Got position: lat=${pos.latitude}, lon=${pos.longitude}, acc=${pos.accuracy}');
      return (pos.latitude, pos.longitude, pos.accuracy);
    } catch (e, st) {
      debugPrint('[Location] Error: $e\n$st');

      // في حالة الخطأ، جرب الحصول على آخر موقع معروف
      try {
        debugPrint('[Location] Trying to get last known position...');
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          debugPrint(
              '[Location] Got last known position: lat=${lastPos.latitude}, lon=${lastPos.longitude}');
          return (lastPos.latitude, lastPos.longitude, lastPos.accuracy);
        }
      } catch (lastError) {
        debugPrint('[Location] Last known position error: $lastError');
      }

      return null;
    }
  }

  Future<String> _currentBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(kApiBaseUrlKey);
    if (saved != null && saved.isNotEmpty) {
      _cachedBaseUrl = saved;
      return saved;
    }
    // استخدام المتغير العالمي من AppConstants
    _cachedBaseUrl = AppConstants.baseUrl;
    return _cachedBaseUrl!;
  }
}
