import 'package:flutter/material.dart';
import 'package:newgraduate/features/common/contact_sheets.dart';

class BscReportDetailsScreen extends StatelessWidget {
  final String title;
  final String description;
  final List<String> examples;
  final List<String> howToWrite;

  const BscReportDetailsScreen({
    super.key,
    required this.title,
    required this.description,
    required this.examples,
    required this.howToWrite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              color: theme.colorScheme.primaryContainer.withOpacity(0.15),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primaryContainer.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.article,
                        size: 36, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.justify),
                  const SizedBox(height: 20),

                  // Examples
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: theme.colorScheme.primaryContainer, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('أمثلة',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.lightbulb,
                                    color: theme.colorScheme.primary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...examples.map((e) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 8.0, right: 4.0),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('🔹',
                                        style: theme.textTheme.bodyLarge),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(e,
                                            style: theme.textTheme.bodyLarge))
                                  ]),
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // How to write
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: theme.colorScheme.primaryContainer, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('كيف تكتب/تطلب تقرير بكالوريوس؟',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.edit_note,
                                      color: theme.colorScheme.primary))
                            ]),
                        const SizedBox(height: 12),
                        ...howToWrite.map((h) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 8.0, right: 4.0),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('🔹', style: theme.textTheme.bodyLarge),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(h,
                                          style: theme.textTheme.bodyLarge))
                                ]))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: ElevatedButton.icon(
                        onPressed: () => showReportContactSheet(context,
                            degree: 'بكالوريوس'),
                        icon: const Icon(Icons.message_outlined),
                        label: const Text('تواصل معنا',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
