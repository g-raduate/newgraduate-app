import 'package:flutter/material.dart';
import '../../common/contact_sheets.dart';

class ReportGuidanceScreen extends StatelessWidget {
  final String degree;
  const ReportGuidanceScreen({super.key, required this.degree});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إرشادات التقارير')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ما المطلوب؟', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
              'الموضوع، النطاق، عدد الصفحات التقريبي، المصادر، الموعد النهائي.'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
              onPressed: () => showReportContactSheet(context, degree: degree),
              icon: const Icon(Icons.message),
              label: const Text('تواصل معنا')),
        ]),
      ),
    );
  }
}
