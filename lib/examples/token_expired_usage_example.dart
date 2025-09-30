import 'package:flutter/material.dart';
import 'package:newgraduate/services/token_expired_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// مثال شامل لكيفية استخدام TokenExpiredHandler في أي صفحة
class ExampleUsageScreen extends StatefulWidget {
  const ExampleUsageScreen({super.key});

  @override
  State<ExampleUsageScreen> createState() => _ExampleUsageScreenState();
}

class _ExampleUsageScreenState extends State<ExampleUsageScreen> {
  /// مثال 1: التحقق من انتهاء التوكن بناءً على status code
  Future<void> _exampleApiCall1() async {
    try {
      final response =
          await http.get(Uri.parse('https://api.example.com/data'));

      if (response.statusCode == 401 || response.statusCode == 403) {
        // إدارة انتهاء التوكن
        final handled = await TokenExpiredHandler.handleTokenExpiration(
          context,
          statusCode: response.statusCode,
          errorMessage: response.body,
        );

        if (handled) {
          return; // تم التعامل مع انتهاء التوكن، لا حاجة لمعالجة إضافية
        }
      }

      // معالجة البيانات العادية هنا
      if (response.statusCode == 200) {
        // نجح الطلب
        print('تم تحميل البيانات بنجاح');
      }
    } catch (e) {
      // التحقق من انتهاء التوكن في حالة الخطأ
      final handled = await TokenExpiredHandler.handleTokenExpiration(
        context,
        errorMessage: e.toString(),
      );

      if (!handled) {
        // إذا لم يكن خطأ التوكن، عرض الخطأ العادي
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  /// مثال 2: التحقق من انتهاء التوكن بطريقة مبسطة
  Future<void> _exampleApiCall2() async {
    try {
      final response =
          await http.get(Uri.parse('https://api.example.com/courses'));

      // استخدام الطريقة المبسطة
      if (TokenExpiredHandler.isTokenError(
          response.body, response.statusCode)) {
        await TokenExpiredHandler.handleTokenExpiration(
          context,
          statusCode: response.statusCode,
          errorMessage: response.body,
        );
        return;
      }

      // معالجة البيانات
      print('البيانات: ${response.body}');
    } catch (e) {
      print('خطأ: $e');
    }
  }

  /// مثال 3: طريقة شاملة مع معالجة الأخطاء
  Future<List<Map<String, dynamic>>> _loadDataSafely() async {
    try {
      // طلب API
      final response = await http.get(
        Uri.parse('https://api.example.com/protected-data'),
        headers: {
          'Authorization': 'Bearer your-token-here',
          'Content-Type': 'application/json',
        },
      );

      // فحص شامل لانتهاء التوكن
      if (await TokenExpiredHandler.handleTokenExpiration(
        context,
        statusCode: response.statusCode,
        errorMessage: response.body,
      )) {
        return []; // إرجاع قائمة فارغة في حالة انتهاء التوكن
      }

      if (response.statusCode == 200) {
        // تحويل البيانات
        return List<Map<String, dynamic>>.from(response.body as List);
      } else {
        throw Exception('فشل في تحميل البيانات: ${response.statusCode}');
      }
    } catch (e) {
      // التحقق من انتهاء التوكن في حالة الخطأ
      if (await TokenExpiredHandler.handleTokenExpiration(
        context,
        errorMessage: e.toString(),
      )) {
        return []; // إرجاع قائمة فارغة
      }

      // إعادة رفع الخطأ إذا لم يكن متعلقاً بالتوكن
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مثال استخدام TokenExpiredHandler')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'أمثلة على كيفية استخدام نظام إدارة انتهاء التوكن',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _exampleApiCall1,
              child: const Text('مثال 1: فحص status code'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _exampleApiCall2,
              child: const Text('مثال 2: استخدام isTokenError'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final data = await _loadDataSafely();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم تحميل ${data.length} عنصر')),
                );
              },
              child: const Text('مثال 3: تحميل بيانات آمن'),
            ),
            const SizedBox(height: 30),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملاحظات مهمة:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('• يجب استدعاء handleTokenExpiration في كل طلب API'),
                    Text('• النظام يتعامل مع 401, 403 وكلمات مفتاحية محددة'),
                    Text('• يتم عرض رسالة ودية مع عد تنازلي 5 ثوانٍ'),
                    Text('• يتم مسح جميع البيانات المحفوظة تلقائياً'),
                    Text('• الانتقال التلقائي لصفحة تسجيل الدخول'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// كيفية تطبيق النظام في خدمة API
class ExampleApiService {
  /// طريقة آمنة لإجراء طلبات API
  static Future<Map<String, dynamic>?> safeApiCall({
    required BuildContext context,
    required String url,
    required Map<String, String> headers,
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    try {
      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        // يمكن إضافة المزيد من الطرق
      }

      // فحص انتهاء التوكن
      if (await TokenExpiredHandler.handleTokenExpiration(
        context,
        statusCode: response.statusCode,
        errorMessage: response.body,
      )) {
        return null; // تم التعامل مع انتهاء التوكن
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      // فحص انتهاء التوكن في حالة الخطأ
      if (await TokenExpiredHandler.handleTokenExpiration(
        context,
        errorMessage: e.toString(),
      )) {
        return null;
      }

      rethrow;
    }
  }
}
