import 'package:newgraduate/services/token_manager.dart';

class ApiHeadersManager {
  static ApiHeadersManager? _instance;

  ApiHeadersManager._();

  static ApiHeadersManager get instance {
    _instance ??= ApiHeadersManager._();
    return _instance!;
  }

  /// الحصول على Headers الأساسية مع التوكن
  Future<Map<String, String>> getAuthHeaders() async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      final tokenManager = await TokenManager.getInstance();
      final token = await tokenManager.getToken();

      print('🔍 ApiHeadersManager - Token متوفر: ${token != null}');
      print('🔍 ApiHeadersManager - Token length: ${token?.length ?? 0}');

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('🔐 تم إضافة Authorization header بنجاح');
        print('🔐 Authorization value: Bearer ${token.substring(0, 20)}...');
      } else {
        print('⚠️ لا يوجد token متوفر في ApiHeadersManager');
      }
    } catch (e) {
      print('⚠️ خطأ في الحصول على token: $e');
    }

    return headers;
  }

  /// Headers بدون مصادقة (للطلبات العامة)
  Map<String, String> getBasicHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Headers مخصصة
  Future<Map<String, String>> getCustomHeaders({
    bool requiresAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    Map<String, String> headers =
        requiresAuth ? await getAuthHeaders() : getBasicHeaders();

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }
}
