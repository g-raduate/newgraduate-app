import 'package:flutter/material.dart';
import '../../common/contact_sheets.dart';

class ResearchGuidanceScreen extends StatelessWidget {
  final String degree;
  const ResearchGuidanceScreen({super.key, required this.degree});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إرشادات البحوث')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ما الذي نحتاجه؟',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
              'العنوان، المجال، الهدف، المنهجية الأولية، مصادر أساسية/جامعة.'),
          const SizedBox(height: 12),
          const Text('أمثلة عناوين مختصرة:'),
          const SizedBox(height: 6),
          const Text('- الكشف المبكر عن حرائق الغابات باستخدام رؤية حاسوبية'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
              onPressed: () =>
                  showResearchContactSheet(context, degree: degree),
              icon: const Icon(Icons.message),
              label: const Text('تواصل معنا')),
        ]),
      ),
    );
  }
}
