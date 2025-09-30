import 'package:flutter/material.dart';
import 'package:newgraduate/services/email_verification_service.dart';

class EmailVerificationBanner extends StatefulWidget {
  final String userEmail;
  final VoidCallback? onVerified;
  final bool showDismiss;

  const EmailVerificationBanner({
    super.key,
    required this.userEmail,
    this.onVerified,
    this.showDismiss = true,
  });

  @override
  State<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool _isResending = false;
  bool _isDismissed = false;
  bool _isCheckingStatus = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تحقق من بريدك الإلكتروني',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'يجب تفعيل بريدك الإلكتروني للوصول لجميع مميزات التطبيق',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showDismiss)
                  IconButton(
                    onPressed: () => setState(() => _isDismissed = true),
                    icon: Icon(
                      Icons.close,
                      color: Colors.orange[600],
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _isResending ? null : _resendVerificationEmail,
                    icon: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.email_outlined),
                    label: Text(
                        _isResending ? 'جاري الإرسال...' : 'إعادة الإرسال'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange[700],
                      backgroundColor: Colors.orange[100],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed:
                        _isCheckingStatus ? null : _checkVerificationStatus,
                    icon: _isCheckingStatus
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_isCheckingStatus
                        ? 'جاري التحقق...'
                        : 'تحقق من الحالة'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      backgroundColor: Colors.blue[100],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// إعادة إرسال بريد التحقق
  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);
    try {
      await EmailVerificationService.sendVerificationEmail(
        email: widget.userEmail,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال بريد التحقق بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال البريد: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isResending = false);
    }
  }

  /// التحقق من حالة التحقق
  Future<void> _checkVerificationStatus() async {
    setState(() => _isCheckingStatus = true);
    try {
      final result = await EmailVerificationService.checkVerificationStatus(
        email: widget.userEmail,
      );

      if (mounted) {
        final isVerified =
            result['verified'] == true || result['is_verified'] == true;

        if (isVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تأكيد البريد الإلكتروني بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );

          // إخفاء البانر
          setState(() => _isDismissed = true);

          // استدعاء callback إذا كان متاحاً
          if (widget.onVerified != null) {
            widget.onVerified!();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم تأكيد البريد الإلكتروني بعد'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحقق من الحالة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCheckingStatus = false);
    }
  }
}

/// بانر مبسط للاستخدام السريع
class SimpleEmailVerificationBanner extends StatelessWidget {
  final String userEmail;

  const SimpleEmailVerificationBanner({
    super.key,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange[100],
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'يرجى تأكيد بريدك الإلكتروني',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await EmailVerificationService.sendVerificationEmail(
                  email: userEmail,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إرسال بريد التحقق')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e')),
                  );
                }
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }
}
