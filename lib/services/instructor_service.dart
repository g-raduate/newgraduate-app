import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newgraduate/models/instructor.dart';
import 'package:newgraduate/config/app_constants.dart';
import 'package:newgraduate/utils/debug_helper.dart';
import 'package:newgraduate/services/api_headers_manager.dart';
import 'package:newgraduate/services/token_manager.dart';

class InstructorService {
  static const String _baseEndpoint = '/api/instructors';

  static Future<List<Instructor>> getInstructorsByInstitute(
    BuildContext context,
    String instituteId,
  ) async {
    try {
      print('🎓 بدء تحميل الأساتذة للمعهد: $instituteId');

      // إجبار استخدام المتغير العالمي والتأكد من حذف أي URLs مخزنة قديماً
      await DebugHelper.forceUseGlobalUrl();
      await DebugHelper.printCurrentUrls();

      // استخدام المتغير العالمي من AppConstants مباشرة
      final baseUrl = AppConstants.baseUrl;
      print('🔗 baseUrl المستخدم مباشرة: $baseUrl');

      final url = Uri.parse('$baseUrl$_baseEndpoint?institute_id=$instituteId');
      print('📡 URL المطلوب النهائي: $url');

      // استخدام ApiHeadersManager للحصول على headers مع التوكن
      Map<String, String> headers =
          await ApiHeadersManager.instance.getAuthHeaders();

      // تشخيص إضافي للتوكن
      TokenManager tokenManager = await TokenManager.getInstance();
      String? token = await tokenManager.getToken();
      print('🔑 Token للتشخيص: ${token?.substring(0, 20) ?? "لا يوجد"}...');
      bool hasToken = await tokenManager.hasToken();
      print('🔐 حالة التوكن: ${hasToken ? "موجود" : "غير موجود"}');

      print('📋 Headers المرسلة:');
      headers.forEach((key, value) {
        if (key == 'Authorization') {
          print(
              '  $key: ${value.length > 50 ? value.substring(0, 50) + "..." : value}');
        } else {
          print('  $key: $value');
        }
      });

      final response = await http
          .get(
        url,
        headers: headers,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال');
        },
      );

      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        print('✅ Response data structure: ${jsonData.keys}');
        print('📄 Full response body: ${response.body}');

        final instructorsResponse = InstructorsResponse.fromJson(jsonData);
        print('🎯 تم العثور على ${instructorsResponse.data.length} أستاذ');

        // طباعة تفاصيل كل أستاذ للتأكد من صحة البيانات
        for (int i = 0; i < instructorsResponse.data.length; i++) {
          final instructor = instructorsResponse.data[i];
          print(
              '👨‍🏫 أستاذ ${i + 1}: ${instructor.name} - ${instructor.email} - التخصص: ${instructor.specialization ?? "غير محدد"}');
        }

        return instructorsResponse.data;
      } else {
        print('❌ خطأ HTTP: ${response.statusCode}');
        print('❌ Response: ${response.body}');

        // فحص انتهاء الجلسة
        if (response.statusCode == 401 || response.statusCode == 403) {
          print('🔐 تم اكتشاف انتهاء الجلسة في الأساتذة');
        }

        throw Exception('فشل في تحميل الأساتذة: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 خطأ في InstructorService.getInstructorsByInstitute: $e');
      rethrow;
    }
  }

  // بيانات وهمية للاختبار
  static List<Instructor> getDummyInstructors() {
    return [
      Instructor(
        id: '1',
        name: 'د. أحمد محمد سعد',
        email: 'ahmed.saad@university.edu',
        specialization: 'هندسة البرمجيات',
        imageUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
      ),
      Instructor(
        id: '2',
        name: 'د. فاطمة علي حسن',
        email: 'fatima.hassan@university.edu',
        specialization: 'أمن المعلومات',
        imageUrl:
            'https://images.unsplash.com/photo-1494790108755-2616b332e234?w=300',
      ),
      Instructor(
        id: '3',
        name: 'د. محمد عبدالله القحطاني',
        email: 'mohammed.alqahtani@university.edu',
        specialization: 'الذكاء الاصطناعي',
        imageUrl:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=300',
      ),
      Instructor(
        id: '4',
        name: 'د. نور الدين يوسف',
        email: 'nouraldeen.youssef@university.edu',
        specialization: 'شبكات الحاسوب',
        imageUrl:
            'https://images.unsplash.com/photo-1566492031773-4f4e44671d66?w=300',
      ),
    ];
  }
}
