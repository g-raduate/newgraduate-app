import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:newgraduate/features/auth/state/auth_controller.dart';
import 'package:newgraduate/features/auth/data/auth_repository.dart';

class EmailSentScreen extends StatefulWidget {
  final String email;

  const EmailSentScreen({super.key, required this.email});

  @override
  State<EmailSentScreen> createState() => _EmailSentScreenState();
}

class _EmailSentScreenState extends State<EmailSentScreen>
    with TickerProviderStateMixin {
  late AnimationController _clockController;
  late AnimationController _pulseController;
  late Animation<double> _clockAnimation;
  late Animation<double> _pulseAnimation;

  int _countdown = 30;
  bool _canResend = false;
  bool _resending = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    // أنيميشن الساعة
    _clockController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _clockAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _clockController,
      curve: Curves.linear,
    ));

    // أنيميشن النبضة
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _startCountdown();
    _clockController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _startCountdown() {
    _countdown = 30;
    _canResend = false;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
        });

        if (_countdown <= 0) {
          timer.cancel();
          setState(() {
            _canResend = true;
          });
          _clockController.stop();
          _pulseController.stop();
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_resending) return;

    setState(() => _resending = true);

    try {
      final authRepo = context.read<AuthRepository>();
      final response = await authRepo.resendEmailVerification(widget.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'تم إعادة إرسال رابط التأكيد'),
            backgroundColor: Colors.green,
          ),
        );

        // إعادة تشغيل العداد
        _clockController.repeat();
        _pulseController.repeat(reverse: true);
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _resending = false);
      }
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

  void _onEmailConfirmed() {
    final auth = context.read<AuthController>();
    auth.setEmailVerified(true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تأكيد البريد بنجاح! يمكنك تسجيل الدخول الآن'),
        backgroundColor: Colors.green,
      ),
    );

    // العودة إلى شاشة تسجيل الدخول
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _clockController.dispose();
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تم إرسال البريد'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Logo
                Center(
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: cs.primaryContainer,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(
                          'images/logo.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.email_outlined,
                            color: cs.onPrimaryContainer,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Success message
                Text(
                  'تم إرسال رابط التأكيد!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  'تم إرسال رابط التأكيد إلى:',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 6),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    widget.email,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 20),

                // Countdown Timer مع أنيميشن الساعة
                if (!_canResend)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // أنيميشن الساعة
                        AnimatedBuilder(
                          animation: _clockAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _clockAnimation.value,
                              child: Icon(
                                Icons.access_time,
                                size: 30,
                                color: cs.primary,
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'يمكنك إعادة الإرسال خلال:',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '$_countdown ثانية',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Resend Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _canResend && !_resending ? _resendEmail : null,
                    icon: _resending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_resending
                        ? 'جاري الإرسال...'
                        : 'إعادة إرسال رابط التأكيد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _canResend ? cs.primary : cs.surfaceVariant,
                      foregroundColor:
                          _canResend ? cs.onPrimary : cs.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Confirmed Button
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _onEmailConfirmed,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('لقد قمت بتأكيد البريد الإلكتروني'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Info Card
                Card(
                  color: cs.surfaceVariant.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: cs.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'نصائح مهمة:',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '• تحقق من صندوق الوارد والرسائل المرفوضة\n• الرابط صالح لمدة 24 ساعة\n• اضغط على الرابط في البريد لتأكيد حسابك',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
