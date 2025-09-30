import 'package:flutter/material.dart';

class EmulatorBlockScreen extends StatelessWidget {
  const EmulatorBlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phonelink_erase,
                  color: Colors.white70, size: 64),
              const SizedBox(height: 16),
              const Text(
                'لا نسمح بتشغيل التطبيق على المحاكيات',
                style: TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'يرجى استخدام جهاز حقيقي لمتابعة الاستخدام',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
