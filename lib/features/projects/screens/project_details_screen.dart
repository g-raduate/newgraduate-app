import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final String type;
  final String title;
  final String description;
  final List<String> examples;
  final List<String> howToWrite;
  final String? whatsappMessage;

  const ProjectDetailsScreen({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    required this.examples,
    required this.howToWrite,
    this.whatsappMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              color: theme.colorScheme.primaryContainer.withOpacity(0.15),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primaryContainer.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      type == 'software'
                          ? Icons.computer_rounded
                          : type == 'hardware'
                              ? Icons.memory_rounded
                              : Icons.hub_rounded,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    theme,
                    'أمثلة',
                    examples,
                    Icons.lightbulb_outline,
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    theme,
                    'كيف تكتب مشروعك للمبرمج/المشرف؟',
                    howToWrite,
                    Icons.edit_note,
                  ),
                  const SizedBox(height: 32),
                  // Centered contact button with max width
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: ElevatedButton.icon(
                        onPressed: () => _showContactDialog(context),
                        icon: const Icon(Icons.message_outlined),
                        label: const Text(
                          'تواصل معنا',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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

  Widget _buildSection(
    ThemeData theme,
    String title,
    List<String> items,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primaryContainer,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Use Expanded to avoid overflow for long Arabic titles
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items
              .map((item) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 12, right: 4, left: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔹',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        // Dialog stateful builder to manage radio selection and conditional fields
        int selection = 0; // 0 = fill form, 1 = only name, 2 = no idea
        final TextEditingController studentNameController =
            TextEditingController();
        final TextEditingController projectNameController =
            TextEditingController();
        final TextEditingController mainIdeaController =
            TextEditingController();
        final TextEditingController requiredFeaturesController =
            TextEditingController();
        final TextEditingController targetUsersController =
            TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('تواصل عبر واتساب'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Radio options
                    RadioListTile<int>(
                      value: 0,
                      groupValue: selection,
                      onChanged: (v) => setState(() => selection = v ?? 0),
                      title: const Text('ملء النموذج'),
                    ),
                    RadioListTile<int>(
                      value: 1,
                      groupValue: selection,
                      onChanged: (v) => setState(() => selection = v ?? 1),
                      title: const Text('لدي اسم المشروع فقط'),
                    ),
                    RadioListTile<int>(
                      value: 2,
                      groupValue: selection,
                      onChanged: (v) => setState(() => selection = v ?? 2),
                      title: const Text('لا أملك فكرة حالياً'),
                    ),

                    const SizedBox(height: 8),

                    // Conditional fields
                    if (selection == 0) ...[
                      const Text('اسم الطالب'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: studentNameController,
                        decoration: InputDecoration(
                          hintText: 'مثال: أحمد علي',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('اسم المشروع'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: projectNameController,
                        decoration: InputDecoration(
                          hintText: 'مثال: نظام إطفاء ذكي للمنازل',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('الفكرة الرئيسية باختصار'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: mainIdeaController,
                        decoration: InputDecoration(
                          hintText:
                              'مثال: إنشاء نظام لرصد الحريق وتشغيل الإنذار تلقائيًا',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('الوظائف المطلوبة'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: requiredFeaturesController,
                        decoration: InputDecoration(
                          hintText:
                              'مثال: تسجيل الدخول، إضافة بيانات، تقارير...',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('المستخدمون المستهدفون'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: targetUsersController,
                        decoration: InputDecoration(
                          hintText: 'مثال: طلاب، مواطنون، موظفون',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ),
                    ] else if (selection == 1) ...[
                      const Text('اسم المشروع'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: projectNameController,
                        decoration: InputDecoration(
                          hintText: 'مثال: نظام إطفاء ذكي للمنازل',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ),
                    ] else ...[
                      const Text('لن تحتاج لإدخال أي معلومات الآن.'),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    studentNameController.dispose();
                    projectNameController.dispose();
                    mainIdeaController.dispose();
                    requiredFeaturesController.dispose();
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Build the message depending on selection
                    String message = '';
                    if (selection == 2) {
                      message = 'المستخدم لا يملك فكرة حالياً.';
                    } else if (selection == 1) {
                      final name = projectNameController.text.trim();
                      final target = targetUsersController.text.trim();
                      message =
                          'اسم المشروع: ${name.isEmpty ? '(لم يُدخل اسم)' : name}';
                      if (target.isNotEmpty) {
                        message += '\nالمستخدمون المستهدفون: $target';
                      }
                    } else {
                      final student = studentNameController.text.trim();
                      final project = projectNameController.text.trim();
                      final idea = mainIdeaController.text.trim();
                      final features = requiredFeaturesController.text.trim();
                      final target = targetUsersController.text.trim();
                      message =
                          'اسم الطالب: ${student.isEmpty ? '(غير محدد)' : student}\n'
                          'اسم المشروع: ${project.isEmpty ? '(غير محدد)' : project}\n'
                          'الفكرة الرئيسية: ${idea.isEmpty ? '(غير محدد)' : idea}\n'
                          'الوظائف المطلوبة: ${features.isEmpty ? '(غير محدد)' : features}';
                      if (target.isNotEmpty) {
                        message += '\nالمستخدمون المستهدفون: $target';
                      }
                    }

                    // Convert provided local number to international — assumption: country code +964 (Iraq)
                    const String whatsappNumber = '+9647748687725';
                    // If a template whatsappMessage is provided for this project, prepend it
                    String finalMessage = '';
                    if (whatsappMessage != null &&
                        whatsappMessage!.isNotEmpty) {
                      finalMessage = '${whatsappMessage!}\n\n$message';
                    } else {
                      finalMessage = message;
                    }

                    final encoded = Uri.encodeComponent(finalMessage);
                    final Uri whatsappUri = Uri.parse(
                        'https://api.whatsapp.com/send?phone=$whatsappNumber&text=$encoded');

                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                    }

                    // Try to launch WhatsApp URL; if fails show the message in a SnackBar
                    launchUrl(whatsappUri).then((ok) {
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('تعذر فتح واتساب. الرسالة:\n$message')),
                        );
                      }
                    }).catchError((_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('تعذر فتح واتساب. الرسالة:\n$message')),
                        );
                      }
                    }).whenComplete(() {
                      studentNameController.dispose();
                      projectNameController.dispose();
                      mainIdeaController.dispose();
                      requiredFeaturesController.dispose();
                      targetUsersController.dispose();
                    });
                  },
                  child: const Text('إرسال'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
