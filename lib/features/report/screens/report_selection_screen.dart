import 'package:flutter/material.dart';
import '../guidance/report_guidance_screen.dart';

class ReportSelectionScreen extends StatelessWidget {
  const ReportSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المشروعات - التقارير')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          ListTile(
              title: const Text('تقرير بكالوريوس'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      const ReportGuidanceScreen(degree: 'بكالوريوس')))),
          const Divider(),
          ListTile(
              title: const Text('تقرير ماجستير'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      const ReportGuidanceScreen(degree: 'ماجستير')))),
          const Divider(),
          ListTile(
              title: const Text('تقرير دكتوراه'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      const ReportGuidanceScreen(degree: 'دكتوراه')))),
        ]),
      ),
    );
  }
}
