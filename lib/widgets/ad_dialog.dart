import 'dart:async';
import 'package:flutter/material.dart';

class AdDialog extends StatefulWidget {
  final String imageUrl;
  final String? adUrl;
  final VoidCallback? onClose;

  const AdDialog({
    super.key,
    required this.imageUrl,
    this.adUrl,
    this.onClose,
  });

  @override
  State<AdDialog> createState() => _AdDialogState();
}

class _AdDialogState extends State<AdDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  Timer? _timer;
  int _countdown = 5;
  bool _canClose = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _startCountdown();
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
          if (_countdown <= 0) {
            _canClose = true;
            timer.cancel();
          }
        });
      }
    });
  }

  void _closeDialog() {
    if (_canClose) {
      widget.onClose?.call();
      Navigator.of(context).pop();
    }
  }

  void _openAdLink() {
    if (widget.adUrl != null) {
      // TODO: Open URL in browser
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فتح رابط الإعلان'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // صورة الإعلان
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 3 / 2,
                child: GestureDetector(
                  onTap: _openAdLink,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey[300],
                    ),
                    child: widget.imageUrl.isNotEmpty
                        ? Image.network(
                            widget.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholder();
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildPlaceholder();
                            },
                          )
                        : _buildPlaceholder(),
                  ),
                ),
              ),
            ),

            // زر الإغلاق مع مؤشر التقدم
            Positioned(
              top: 10,
              right: 10,
              child: AnimatedOpacity(
                opacity: _canClose ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: _closeDialog,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // مؤشر التقدم الدائري
                        Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                return CircularProgressIndicator(
                                  value: _progressController.value,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _canClose ? Colors.green : Colors.white,
                                  ),
                                  backgroundColor:
                                      Colors.white.withOpacity(0.3),
                                );
                              },
                            ),
                          ),
                        ),
                        // أيقونة الإغلاق أو العداد
                        Center(
                          child: _canClose
                              ? const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : Text(
                                  '$_countdown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // تسمية "إعلان" في الزاوية اليسرى
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'إعلان',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoKufiArabic',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[300],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 60,
            color: Colors.grey[500],
          ),
          const SizedBox(height: 16),
          const Text(
            'إعلان تجاري',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoKufiArabic',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط للمزيد من التفاصيل',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'NotoKufiArabic',
            ),
          ),
        ],
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String imageUrl,
    String? adUrl,
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdDialog(
        imageUrl: imageUrl,
        adUrl: adUrl,
        onClose: onClose,
      ),
    );
  }
}
