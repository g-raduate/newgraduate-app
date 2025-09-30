import 'package:flutter/material.dart';
import 'package:newgraduate/widgets/custom_app_bar.dart';
import 'package:newgraduate/utils/data_service.dart';
import 'package:newgraduate/widgets/main_card.dart';
import 'package:newgraduate/services/institute_service.dart';
import 'package:newgraduate/features/instructors/screens/instructors_screen.dart';
import 'package:newgraduate/widgets/custom_loading_widget.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  List<Institute> institutes = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadInstitutes();
  }

  Future<void> _loadInstitutes() async {
    try {
      print('🏁 بدء تحميل الأقسام في DepartmentsScreen...');
      setState(() {
        isLoading = true;
        error = null;
      });

      final fetchedInstitutes = await InstituteService.getInstitutes(context);
      print('✅ تم الحصول على ${fetchedInstitutes.length} قسم بنجاح');

      setState(() {
        institutes = fetchedInstitutes;
        isLoading = false;
      });

      print('🎯 تم تحديث الحالة بنجاح');
    } catch (e) {
      print('❌ خطأ في تحميل الأقسام: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
        // استخدام البيانات الوهمية في حالة الخطأ
        institutes = DataService.getDummyDepartments()
            .map((dept) => Institute(
                  id: dept.id,
                  name: dept.name,
                  imageUrl: dept.imageUrl,
                ))
            .toList();
      });
      print('🔄 تم التبديل للبيانات الوهمية: ${institutes.length} قسم');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 2 : 3;

    return Scaffold(
      appBar: const CustomAppBarWidget(
        title: 'الأقسام',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const CenterLoadingWidget(
                message: 'جاري تحميل الأقسام...',
              )
            : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 50, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('حدث خطأ في تحميل البيانات'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadInstitutes,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : institutes.isEmpty
                    ? const Center(child: Text('لا توجد أقسام متاحة'))
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: institutes.length,
                        itemBuilder: (context, index) {
                          final institute = institutes[index];
                          return MainCard(
                            imageUrl: institute.imageUrl ??
                                'https://nulpgduzktpozubpbiqf.supabase.co/storage/v1/object/public/Images/Courses/Computer_Engineering.png',
                            title: institute.name,
                            fallbackIcon: Icons.school,
                            onTap: () {
                              // الانتقال إلى شاشة الأساتذة
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InstructorsScreen(
                                    instituteId: institute.id,
                                    instituteName: institute.name,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}
