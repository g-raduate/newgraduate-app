import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:newgraduate/config/app_constants.dart';

class Institute {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final bool isActive;

  Institute({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.isActive = true,
  });

  factory Institute.fromJson(Map<String, dynamic> json) {
    return Institute(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      location: json['location']?.toString(),
      // إذا لم يكن is_active موجود، اعتبره نشط افتراضياً
      isActive: json['is_active'] == true ||
          json['is_active'] == 1 ||
          !json.containsKey('is_active'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'is_active': isActive,
    };
  }

  @override
  String toString() => name;
}

class InstitutesService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// جلب قائمة جميع المعاهد المتاحة
  /// GET /api/institutes/all
  static Future<List<Institute>> getAllInstitutes() async {
    try {
      print('🏢 جاري جلب قائمة المعاهد...');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/institutes/all'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('🏢 جلب المعاهد - Status: ${response.statusCode}');
      print('🏢 Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> institutesJson;

        // التعامل مع أشكال مختلفة من الاستجابة
        if (responseData is List) {
          institutesJson = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          institutesJson = responseData['data'] as List;
        } else if (responseData is Map &&
            responseData.containsKey('institutes')) {
          institutesJson = responseData['institutes'] as List;
        } else {
          throw Exception('تنسيق غير متوقع للاستجابة');
        }

        final institutes = institutesJson
            .map((json) => Institute.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ تم جلب ${institutes.length} معهد بنجاح');
        for (final institute in institutes) {
          print('🏢 معهد: ${institute.name} (ID: ${institute.id})');
        }
        return institutes;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'فشل في جلب المعاهد');
      }
    } catch (e) {
      print('❌ خطأ في جلب المعاهد: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  /// جلب معلومات معهد محدد
  /// GET /api/institutes/{id}
  static Future<Institute> getInstituteById(String instituteId) async {
    try {
      print('🏢 جاري جلب معلومات المعهد: $instituteId');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/institutes/$instituteId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('🏢 جلب المعهد - Status: ${response.statusCode}');
      print('🏢 Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // التعامل مع أشكال مختلفة من الاستجابة
        Map<String, dynamic> instituteJson;
        if (responseData is Map && responseData.containsKey('data')) {
          instituteJson = responseData['data'] as Map<String, dynamic>;
        } else if (responseData is Map &&
            responseData.containsKey('institute')) {
          instituteJson = responseData['institute'] as Map<String, dynamic>;
        } else if (responseData is Map) {
          instituteJson = Map<String, dynamic>.from(responseData);
        } else {
          throw Exception('تنسيق غير متوقع للاستجابة');
        }

        final institute = Institute.fromJson(instituteJson);
        print('✅ تم جلب معلومات المعهد: ${institute.name}');
        return institute;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'فشل في جلب معلومات المعهد');
      }
    } catch (e) {
      print('❌ خطأ في جلب معلومات المعهد: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  /// البحث في المعاهد
  static Future<List<Institute>> searchInstitutes(String searchTerm) async {
    try {
      final allInstitutes = await getAllInstitutes();

      if (searchTerm.isEmpty) {
        return allInstitutes;
      }

      final searchLower = searchTerm.toLowerCase();
      return allInstitutes.where((institute) {
        return institute.name.toLowerCase().contains(searchLower) ||
            (institute.description?.toLowerCase().contains(searchLower) ??
                false) ||
            (institute.location?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    } catch (e) {
      print('❌ خطأ في البحث في المعاهد: $e');
      throw Exception('خطأ في البحث: $e');
    }
  }

  /// التحقق من صحة معرف المعهد
  static Future<bool> validateInstituteId(String instituteId) async {
    try {
      await getInstituteById(instituteId);
      return true;
    } catch (e) {
      print('⚠️ معرف المعهد غير صحيح: $instituteId');
      return false;
    }
  }
}
