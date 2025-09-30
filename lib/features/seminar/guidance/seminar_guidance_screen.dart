import 'package:flutter/material.dart';
import '../../common/contact_sheets.dart';

class SeminarGuidanceScreen extends StatelessWidget {
  final String degree;
  const SeminarGuidanceScreen({super.key, required this.degree});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إرشادات الندوات')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('المطلوب', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
              'العنوان، الهدف، المحاور، المدة، الوسائط، الجمهور المستهدف.'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
              onPressed: () => showSeminarContactSheet(context, degree: degree),
              icon: const Icon(Icons.message),
              label: const Text('تواصل معنا')),
        ]),
      ),
    );
  }
}
