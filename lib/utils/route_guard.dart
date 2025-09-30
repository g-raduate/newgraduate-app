import 'package:flutter/material.dart';
import 'package:newgraduate/features/auth/state/auth_controller.dart';
import 'package:newgraduate/features/auth/screens/verification_required_page.dart';
import 'package:provider/provider.dart';

class EmailVerificationGuard extends StatelessWidget {
  final Widget child;
  final bool requireVerification;
  final Widget? customVerificationPage;

  const EmailVerificationGuard({
    super.key,
    required this.child,
    this.requireVerification = true,
    this.customVerificationPage,
  });

  @override
  Widget build(BuildContext context) {
    if (!requireVerification) {
      return child;
    }

    return Consumer<AuthController>(
      builder: (context, authController, _) {
        // إذا لم يكن المستخدم مسجل الدخول، عرض الصفحة العادية
        if (authController.token == null || authController.token!.isEmpty) {
          return child;
        }

        // إذا كان البريد مؤكد، عرض الصفحة المطلوبة
        if (authController.isEmailVerified) {
          return child;
        }

        // إذا لم يكن البريد مؤكد، عرض صفحة التحقق
        return customVerificationPage ??
            VerificationRequiredPage(
              userEmail: authController.userEmail ?? 'غير محدد',
              onVerified: () {
                authController.setEmailVerified(true);
              },
            );
      },
    );
  }
}

class RouteGuard {
  /// التحقق من تأكيد البريد قبل التنقل
  static bool canAccessRoute(
    BuildContext context,
    String routeName, {
    List<String> protectedRoutes = const [
      '/courses',
      '/profile',
      '/settings',
      '/quiz',
    ],
  }) {
    final authController = Provider.of<AuthController>(context, listen: false);

    // إذا كان المسار غير محمي
    if (!protectedRoutes.contains(routeName)) {
      return true;
    }

    // إذا لم يكن المستخدم مسجل الدخول
    if (authController.token == null || authController.token!.isEmpty) {
      return false;
    }

    // إذا كان البريد مؤكد
    return authController.isEmailVerified;
  }

  /// التنقل مع التحقق من تأكيد البريد
  static Future<void> navigateWithVerificationCheck(
    BuildContext context,
    String routeName,
    Widget page, {
    bool requireVerification = true,
  }) async {
    final authController = Provider.of<AuthController>(context, listen: false);

    // إذا لم يكن التحقق مطلوب، انتقل مباشرة
    if (!requireVerification) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );
      return;
    }

    // إذا لم يكن المستخدم مسجل الدخول
    if (authController.token == null || authController.token!.isEmpty) {
      // يمكن توجيه المستخدم لصفحة تسجيل الدخول
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    // إذا لم يكن البريد مؤكد
    if (!authController.isEmailVerified) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerificationRequiredPage(
            userEmail: authController.userEmail ?? 'غير محدد',
            onVerified: () {
              authController.setEmailVerified(true);
              Navigator.of(context).pop(); // إغلاق صفحة التحقق
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => page),
              );
            },
          ),
        ),
      );
      return;
    }

    // إذا كان كل شيء صحيح، انتقل للصفحة
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// عرض حوار التحقق من البريد
  static Future<bool> showVerificationDialog(
    BuildContext context, {
    String? userEmail,
  }) async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final email = userEmail ?? authController.userEmail ?? 'غير محدد';

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('تحقق من بريدك الإلكتروني'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 48,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  'يجب تأكيد بريدك الإلكتروني ($email) للوصول لهذه الصفحة.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop(true);
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VerificationRequiredPage(
                        userEmail: email,
                        onVerified: () {
                          authController.setEmailVerified(true);
                        },
                      ),
                    ),
                  );
                },
                child: const Text('تأكيد البريد'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// Wrapper للصفحات التي تتطلب تحقق البريد الإلكتروني
class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final String? routeName;
  final bool showBanner;

  const ProtectedRoute({
    super.key,
    required this.child,
    this.routeName,
    this.showBanner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        final isLoggedIn =
            authController.token != null && authController.token!.isNotEmpty;

        if (!isLoggedIn) {
          return child; // إذا لم يكن مسجل الدخول، عرض الصفحة العادية
        }

        final isVerified = authController.isEmailVerified;

        if (!isVerified && showBanner) {
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.orange[100],
                child: Row(
                  children: [
                    Icon(Icons.warning_amber,
                        color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'يرجى تأكيد بريدك الإلكتروني لاستخدام جميع المميزات',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VerificationRequiredPage(
                              userEmail: authController.userEmail ?? 'غير محدد',
                              onVerified: () {
                                authController.setEmailVerified(true);
                              },
                            ),
                          ),
                        );
                      },
                      child: const Text('تأكيد'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          );
        }

        return child;
      },
    );
  }
}
