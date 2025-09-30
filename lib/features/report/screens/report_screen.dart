import 'package:flutter/material.dart';
import 'package:newgraduate/widgets/video_banner.dart';
import 'package:newgraduate/features/projects/screens/projects_screen.dart';
import 'package:newgraduate/features/report/screens/bsc_report_details_screen.dart';
import 'package:newgraduate/features/report/screens/msc_report_details_screen.dart';
import 'package:newgraduate/features/report/screens/phd_report_details_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 8),
          // VideoBanner
          // ignore: prefer_const_constructors
          VideoBanner(videoId: '6GomxOCJTfU'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.article,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'اختر نوع التقرير',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ProjectTypeCard(
                    arabicTitle: 'تقرير بكالوريوس',
                    englishTitle: 'BSc Report',
                    icon: Icons.article,
                    isSelected: _selectedType == 'bsc',
                    onTap: () {
                      setState(() => _selectedType = 'bsc');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BscReportDetailsScreen(
                            title: 'تقرير بكالوريوس',
                            description:
                                'صفحة مساعدة لكتابة وطلب تقرير بكالوريوس مع أمثلة ونصائح.',
                            examples: [
                              'تقرير حول تأثير الأجهزة الذكية على التعليم الجامعي.',
                              'تقرير حول إدارة الوقت لدى طلبة المرحلة الجامعية.',
                              'تقرير حول تطبيقات الطاقة الشمسية في المنازل.',
                            ],
                            howToWrite: [
                              'الموضوع: قصير وواضح (مثال: التعلم عن بعد في الجامعات العراقية).',
                              'النطاق: حدد الفقرات أو الأقسام الأساسية (مقدمة – مشكلة – حلول – استنتاج).',
                              'عدد الصفحات التقريبي: (5–10 صفحات).',
                              'المصادر: مقالات أو مراجع بسيطة.',
                              'الهدف: عرض فكرة أو دراسة حالة بشكل مختصر.',
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  ProjectTypeCard(
                    arabicTitle: 'تقرير ماجستير',
                    englishTitle: 'MSc Report',
                    icon: Icons.article,
                    isSelected: _selectedType == 'msc',
                    onTap: () {
                      setState(() => _selectedType = 'msc');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MscReportDetailsScreen(
                            title: 'تقرير ماجستير',
                            description:
                                'صفحة مساعدة لكتابة وطلب تقرير ماجستير مع أمثلة ونصائح متقدمة.',
                            examples: [
                              'تقرير عن تحليل أداء الشبكات العصبية في تصنيف الصور.',
                              'تقرير عن الأمن السيبراني في المؤسسات المالية.',
                            ],
                            howToWrite: [
                              'العنوان: محدد ومرتبط بالاختصاص.',
                              'النطاق: حدد فصول التقرير (مقدمة – مراجعة أدبيات – دراسة – نتائج – استنتاجات).',
                              'عدد الصفحات: (20–40 صفحة تقريبًا).',
                              'المصادر: مقالات علمية، رسائل سابقة.',
                              'المخرجات: نتائج واضحة + جداول ورسوم بيانية.',
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  ProjectTypeCard(
                    arabicTitle: 'تقرير دكتوراه',
                    englishTitle: 'PhD Report',
                    icon: Icons.article,
                    isSelected: _selectedType == 'phd',
                    onTap: () {
                      setState(() => _selectedType = 'phd');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PhdReportDetailsScreen(
                            title: 'تقرير دكتوراه',
                            description:
                                'صفحة مساعدة لكتابة وطلب تقرير دكتوراه مع أمثلة ونصائح متقدمة.',
                            examples: [
                              'تقرير عن تطوير خوارزميات هجينة لتحسين أداء أنظمة إنترنت الأشياء.',
                              'تقرير عن التعلم العميق وتطبيقاته في التشخيص الطبي الذكي.',
                            ],
                            howToWrite: [
                              'العنوان: يعكس دراسة عميقة جدًا.',
                              'النطاق: فصل مفصل (مقدمة – مراجعة أدبيات – منهجية – تجارب – نتائج – مناقشة – استنتاج).',
                              'عدد الصفحات: (50+ صفحة).',
                              'المصادر: مجلات محكمة، أوراق مؤتمرات عالمية.',
                              'المخرجات: إسهام علمي جديد + بيانات منشورة/رسوم متقدمة.',
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ]),
          ),
        ]),
      ),
    );
  }
}
