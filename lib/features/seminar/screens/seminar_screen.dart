import 'package:flutter/material.dart';
import 'package:newgraduate/widgets/video_banner.dart';
import 'package:newgraduate/features/projects/screens/projects_screen.dart';
import 'package:newgraduate/features/seminar/screens/bsc_seminar_details_screen.dart';
import 'package:newgraduate/features/seminar/screens/msc_seminar_details_screen.dart';
import 'package:newgraduate/features/seminar/screens/phd_seminar_details_screen.dart';

class SeminarScreen extends StatefulWidget {
  const SeminarScreen({super.key});

  @override
  State<SeminarScreen> createState() => _SeminarScreenState();
}

class _SeminarScreenState extends State<SeminarScreen> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('الندوات')),
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
                        Icons.videocam,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'اختر نوع الندوة',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ProjectTypeCard(
                    arabicTitle: 'سمنار بكالوريوس',
                    englishTitle: 'BSc Seminar',
                    icon: Icons.school,
                    isSelected: _selectedType == 'bsc',
                    onTap: () {
                      setState(() => _selectedType = 'bsc');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BscSeminarDetailsScreen(
                            title: 'سمنار بكالوريوس',
                            description:
                                'سمنار بكالوريوس يساعدك في إعداد عرضك وتحديد الموضوعات المناسبة.',
                            examples: [
                              'تحليل حالة دراسية لتطبيق عملي',
                              'مراجعة أدبية لموضوع محدد',
                              'تطبيق منهجية بحث بسيطة على بيانات محلية',
                            ],
                            howToWrite: [
                              'حدد موضوع واضح ومحدد',
                              'اعد مسودة مختصرة للأهداف والمنهجية',
                              'أضف المراجع الأساسية التي ستستخدمها',
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  ProjectTypeCard(
                    arabicTitle: 'سمنار ماجستير',
                    englishTitle: 'MSc Seminar',
                    icon: Icons.school,
                    isSelected: _selectedType == 'msc',
                    onTap: () {
                      setState(() => _selectedType = 'msc');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MscSeminarDetailsScreen(
                            title: 'سمنار ماجستير',
                            description:
                                'سمنار ماجستير يتطلب إعداداً أكاديمياً أعمق مع خطة واضحة للبحث.',
                            examples: [
                              'مراجعة نقدية للأدبيات المتعلقة بموضوع جديد',
                              'تطبيق نموذج تجريبي وتحليل النتائج',
                              'تقديم إطار نظري مبتكر لمشكلة بحثية',
                            ],
                            howToWrite: [
                              'اكتب ملخصاً يحدد المشكلة البحثية بوضوح',
                              'حدد الأسئلة البحثية والمنهجية المتبعة',
                              'اذكر الإسهامات المتوقعة والموارد المطلوبة',
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  ProjectTypeCard(
                    arabicTitle: 'سمنار دكتوراه',
                    englishTitle: 'PhD Seminar',
                    icon: Icons.school,
                    isSelected: _selectedType == 'phd',
                    onTap: () {
                      setState(() => _selectedType = 'phd');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PhdSeminarDetailsScreen(
                            title: 'سمنار دكتوراه',
                            description:
                                'سمنار دكتوراه يركز على أسئلة بحثية متقدمة وإسهامات علمية واضحة.',
                            examples: [
                              'مقترح لأطروحة يشتمل على فرضيات جديدة',
                              'تجارب متقدمة مع تحليل إحصائي موسع',
                              'تطوير نموذج نظري أو منهجي جديد',
                            ],
                            howToWrite: [
                              'وضح الإشكالية البحثية والإطار النظري المتكامل',
                              'حدد المنهجيات المتقدمة وأدوات القياس',
                              'اشرح الإسهام العلمي والنتائج المتوقعة',
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
