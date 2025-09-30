import 'package:flutter/material.dart';
import '../guidance/seminar_guidance_screen.dart';

class SeminarSelectionScreen extends StatelessWidget {
  const SeminarSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المشروعات - السمنارات')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          ListTile(
              title: const Text('سمنار بكالوريوس'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      const SeminarGuidanceScreen(degree: 'بكالوريوس')))),
          const Divider(),
          ListTile(
              title: const Text('سمنار ماجستير'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      const SeminarGuidanceScreen(degree: 'ماجستير')))),
          const Divider(),
          ListTile(
              title: const Text('سمنار دكتوراه'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      const SeminarGuidanceScreen(degree: 'دكتوراه')))),
        ]),
      ),
    );
  }
}
