import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:newgraduate/utils/prefs_keys.dart';
import 'package:newgraduate/features/shell/screens/main_shell.dart';
import 'package:newgraduate/features/auth/screens/login_screen.dart';

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  bool isAccepted = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('سياسة الاستخدام'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Icon(
                          Icons.privacy_tip,
                          size: 64,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'مرحباً بك في تطبيق خريج',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoKufiArabic',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle('1. مقدمة'),
                      _buildSectionText(
                        'يوفر تطبيق "تطبيق خريج" منصة تعليمية شاملة تهدف إلى تطوير مهارات الخريجين الجدد وتأهيلهم لسوق العمل من خلال دورات تدريبية متخصصة ومحتوى تعليمي عالي الجودة.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('2. الاستخدام المقبول'),
                      _buildSectionText(
                        '• يجب استخدام التطبيق للأغراض التعليمية فقط\n'
                        '• عدم مشاركة حساب المستخدم مع أشخاص آخرين\n'
                        '• احترام حقوق الملكية الفكرية للمحتوى المقدم\n'
                        '• عدم تسجيل أو إعادة توزيع المحتوى التعليمي',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('3. الخصوصية'),
                      _buildSectionText(
                        'نحن ملتزمون بحماية خصوصيتك. جميع البيانات الشخصية التي تقدمها محمية ولن يتم مشاركتها مع أطراف ثالثة دون موافقتك الصريحة.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('4. المحتوى التعليمي'),
                      _buildSectionText(
                        '• جميع الدورات والمواد التعليمية محمية بحقوق الطبع والنشر\n'
                        '• يحق لك الوصول للمحتوى للاستخدام الشخصي التعليمي\n'
                        '• التطبيق يوفر شهادات إتمام معتمدة للدورات',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('5. الدعم والمساعدة'),
                      _buildSectionText(
                        'فريق الدعم متاح لمساعدتك في أي استفسارات تتعلق بالتطبيق أو المحتوى التعليمي. يمكنك التواصل معنا من خلال قسم الدعم في التطبيق.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('6. التحديثات'),
                      _buildSectionText(
                        'قد نقوم بتحديث هذه الشروط من وقت لوقت. سيتم إشعارك بأي تغييرات مهمة عبر التطبيق.',
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          'بالمتابعة، فإنك توافق على شروط الاستخدام وسياسة الخصوصية المذكورة أعلاه.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'NotoKufiArabic',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isAccepted,
                      onChanged: (value) {
                        setState(() {
                          isAccepted = value ?? false;
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    const Expanded(
                      child: Text(
                        'أوافق على شروط الاستخدام وسياسة الخصوصية',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'NotoKufiArabic',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isAccepted
                        ? () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool(kPolicyAccepted, true);
                            final loggedIn =
                                prefs.getBool(kIsLoggedIn) ?? false;
                            if (!mounted) return;
                            if (loggedIn) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const MainScreen(),
                                ),
                              );
                            } else {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isAccepted ? 4 : 0,
                    ),
                    child: const Text(
                      'متابعة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoKufiArabic',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          fontFamily: 'NotoKufiArabic',
        ),
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        height: 1.6,
        fontFamily: 'NotoKufiArabic',
      ),
      textAlign: TextAlign.justify,
    );
  }
}
