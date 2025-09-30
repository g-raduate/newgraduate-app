import 'package:flutter/material.dart';
import 'package:newgraduate/widgets/video_banner.dart';
import 'package:newgraduate/features/projects/screens/projects_screen.dart';
import 'package:newgraduate/features/research/screens/masters_research_details_screen.dart';
import 'package:newgraduate/features/research/screens/phd_research_details_screen.dart';

class ResearchScreen extends StatefulWidget {
  const ResearchScreen({super.key});

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('البحوث')),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                          Icons.menu_book,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'اختر نوع البحث',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ProjectTypeCard(
                      arabicTitle: 'بحوث ماجستير',
                      englishTitle: 'Master Research',
                      icon: Icons.school,
                      isSelected: _selectedType == 'masters',
                      onTap: () {
                        setState(() => _selectedType = 'masters');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MastersResearchDetailsScreen(
                              title: 'بحوث الماجستير',
                              description:
                                  'البحوث التي تُقدم لمستوى الماجستير عادة ما تكون أطول وتطلب منهجية بحثية واضحة مع نتائج قابلة للتقييم.',
                              examples: [
                                'تحليل تأثير الذكاء الاصطناعي على كشف الأعطال في شبكات الطاقة.',
                                'نظام توصية ذكي للكتب باستخدام خوارزميات التعلم الآلي.',
                                'تقييم أداء بروتوكولات إنترنت الأشياء في البيئات المنزلية الذكية.',
                              ],
                              howToWrite: [
                                'العنوان المقترح: واضح ومحدد (مثال: التنبؤ بالأحمال الكهربائية باستخدام LSTM).',
                                'المجال/التخصص: (ذكاء اصطناعي/اتصالات/طاقة…).',
                                'المشكلة/الهدف: ماذا ستحل أو تثبت؟',
                                'المنهجية الأولية: مراجعة أدبيات، تصميم تجريبي، جمع بيانات، أدوات التحليل.',
                                'الأدوات المتوقعة: Python, MATLAB, Simulink, TensorFlow…',
                                'المخرجات: نتائج، جداول، رسوم بيانية، توصيات.',
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    ProjectTypeCard(
                      arabicTitle: 'بحوث دكتوراه',
                      englishTitle: 'PhD Research',
                      icon: Icons.menu_book,
                      isSelected: _selectedType == 'phd',
                      onTap: () {
                        setState(() => _selectedType = 'phd');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PhdResearchDetailsScreen(
                              title: 'بحوث الدكتوراه',
                              description:
                                  'البحوث للدكتوراه تركز على إسهام علمي أصيل ومنهجية صارمة مع نتائج منشورة.',
                              examples: [
                                'إطار عمل هجين لتحسين كفاءة الشبكات العصبية الكبيرة على العتاد المدمج.',
                                'نموذج كشف شذوذ زمني عالي الدقة لشبكات الاستشعار الصناعية.',
                                'منهجية تقييم أمان أنظمة إنترنت الأشياء في بيئات مدن ذكية.',
                              ],
                              howToWrite: [
                                'فجوة بحثية موثّقة: أين النقص في الأدبيات؟',
                                'الإسهام العلمي المتوقع: ما الجديد الذي ستضيفه؟',
                                'منهجية صارمة: تصميم تجارب/نماذج نظرية، بروتوكول تقييم واضح.',
                                'مجموعة بيانات/بيئة اختبار: مصدر، حجم، ترخيص.',
                                'خطة زمنية تقريبية: مراحل العمل الرئيسة.',
                                'مخرجات علمية: نشر ورقة/مؤتمر، برمجيات مفتوحة المصدر، قاعدة بيانات.',
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
