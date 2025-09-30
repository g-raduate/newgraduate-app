import 'package:flutter/material.dart';
import '../guidance/research_guidance_screen.dart';

class ResearchSelectionScreen extends StatelessWidget {
  const ResearchSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المشروعات - البحوث')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          ListTile(
              title: const Text('بحوث ماجستير'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      const ResearchGuidanceScreen(degree: 'ماجستير')))),
          const Divider(),
          ListTile(
              title: const Text('بحوث دكتوراه'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      const ResearchGuidanceScreen(degree: 'دكتوراه')))),
        ]),
      ),
    );
  }
}
