import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:newgraduate/services/auth_service.dart';
import 'package:newgraduate/config/app_constants.dart';
import 'package:newgraduate/services/api_headers_manager.dart';
import 'package:newgraduate/services/token_manager.dart';

class Institute {
  final String id;
  final String name;
  final String? imageUrl;

  Institute({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory Institute.fromJson(Map<String, dynamic> json) {
    return Institute(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image_url'],
    );
  }
}

class InstituteService {
  static Future<List<Institute>> getInstitutes(BuildContext context) async {
    try {
      // الحصول على headers مع التوكن المحفوظ
      TokenManager tokenManager = await TokenManager.getInstance();

      // التحقق من وجود توكن أولاً
      bool hasToken = await tokenManager.hasToken();
      print('🔐 حالة التوكن: ${hasToken ? "موجود" : "غير موجود"}');

      if (!hasToken) {
        print('❌ لا يوجد توكن محفوظ - المستخدم غير مسجل دخول');
        throw Exception('User not authenticated - no token found');
      }

      // الحصول على معرف المعهد والطالب
      String? instituteId = await tokenManager.getInstituteId();
      String? studentId = await tokenManager.getStudentId();

      print('🔍 التحقق من جميع البيانات المحفوظة:');
      print('  👤 Student ID: ${studentId ?? "لا يوجد"}');
      print('  🏢 Institute ID: ${instituteId ?? "لا يوجد"}');

      String url;
      if (studentId == null) {
        // إذا لم يوجد student_id، فالطالب لا ينتمي لمعهد محدد - عرض جميع المعاهد
        url = '${AppConstants.apiUrl}/institutes';
        print('👥 الطالب لا ينتمي لمعهد محدد - سيتم عرض جميع المعاهد');
      } else if (instituteId == null || instituteId.isEmpty) {
        print('❌ لا يوجد معرف معهد محفوظ');
        throw Exception('No institute ID found for user');
      } else {
        // بناء الرابط مع معرف المعهد المحدد
        url = '${AppConstants.apiUrl}/institutes/$instituteId';
        print('🏢 الطالب ينتمي لمعهد محدد - سيتم جلب المعهد: $instituteId');
      }

      print('📡 الـ API endpoint المستخدم: $url');

      // استخدام ApiHeadersManager للحصول على headers مع التوكن
      Map<String, String> headers =
          await ApiHeadersManager.instance.getAuthHeaders();
      print('📋 Headers المرسلة:');
      headers.forEach((key, value) {
        if (key == 'Authorization') {
          print(
              '  $key: ${value.length > 50 ? value.substring(0, 50) + "..." : value}');
        } else {
          print('  $key: $value');
        }
      });

      print('📡 إرسال الطلب إلى: $url');
      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10)); // timeout أطول للتشخيص

      print('📊 حالة الاستجابة: ${response.statusCode}');
      print('📡 الـ URL المُرسَل إليه: $url');
      print('📄 محتوى الاستجابة الكامل للمعاهد:');
      print('=' * 70);
      print(response.body);
      print('=' * 70);

      if (response.statusCode == 200) {
        print('🎉 نجح الطلب! حالة الاستجابة: ${response.statusCode}');

        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ تم فك تشفير JSON بنجاح');
        print('🔍 البيانات المستخرجة (مُنسقة):');
        print(const JsonEncoder.withIndent('  ').convert(data));

        if (studentId == null) {
          // معالجة البيانات كقائمة معاهد (جميع المعاهد)
          final List<dynamic> institutesData = data['data'] ?? [];
          print('📦 عدد المعاهد: ${institutesData.length}');

          // طباعة تفاصيل كل معهد
          for (int i = 0; i < institutesData.length; i++) {
            print('🏢 المعهد ${i + 1}: ${institutesData[i]}');
          }

          final institutes = institutesData
              .map((instituteJson) => Institute.fromJson(instituteJson))
              .toList();

          print('🏢 المعاهد المُحولة (${institutes.length} معهد):');
          for (var institute in institutes) {
            print(
                '  - ID: ${institute.id}, الاسم: ${institute.name}, الصورة: ${institute.imageUrl}');
          }

          print('✨ تم إنجاز العملية بنجاح!');
          return institutes;
        } else {
          // معالجة البيانات كمعهد واحد وليس قائمة
          final instituteData = data['data'] ?? data;
          print('🏢 بيانات المعهد الواحد:');
          print(const JsonEncoder.withIndent('  ').convert(instituteData));

          final institute = Institute.fromJson(instituteData);
          print(
              '🏢 المعهد المُحول: ID: ${institute.id}, الاسم: ${institute.name}, الصورة: ${institute.imageUrl}');

          print('✨ تم إنجاز العملية بنجاح!');
          return [institute]; // إرجاع قائمة تحتوي على معهد واحد
        }
      } else if (response.statusCode == 401) {
        print('🔒 خطأ مصادقة - التوكن غير صالح');
        print('📄 تفاصيل خطأ المصادقة: ${response.body}');
        // معالجة حالة عدم المصادقة
        AuthService.handleAuthResponse(response, context);
        throw Exception('Unauthorized: Token expired or invalid');
      } else {
        print('❌ خطأ HTTP: ${response.statusCode}');
        print('📄 تفاصيل الخطأ الكامل: ${response.body}');
        print('📋 Headers المُرسلة عند الخطأ:');
        headers.forEach((key, value) => print('  $key: $value'));
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('💥 خطأ عام في InstituteService: $e');
      print('📍 مكان الخطأ: ${e.runtimeType}');
      rethrow; // إعادة رمي الخطأ الأصلي
    }
  }
}
