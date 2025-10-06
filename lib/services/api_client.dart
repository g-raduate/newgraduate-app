import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:newgraduate/config/runtime_config.dart';
import 'package:newgraduate/config/app_constants.dart';

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? _defaultBaseUrl();

  final http.Client _client;
  final String baseUrl;
  String? _bearer;

  void setBearer(String? token) {
    _bearer = token;
  }

  Map<String, String> _headers({Map<String, String>? extra}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json', // مطلوب من الباك إند
      // إضافة User-Agent قد يقلل من حظر بعض مزودات الحماية (مثل Cloudflare)
      'User-Agent': 'GraduateApp/1.0 (Flutter; Android/iOS)',
      if (_bearer?.isNotEmpty == true) 'Authorization': 'Bearer $_bearer',
    };
    if (extra != null) h.addAll(extra);
    return h;
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body,
      {Map<String, String>? headers}) async {
    final resolved = await _overrideOr(baseUrl);
    final uri = Uri.parse('$resolved$path');
    debugPrint('[ApiClient] POST ${uri.toString()}');
    debugPrint('[ApiClient] Request headers: ${_headers(extra: headers)}');
    debugPrint('[ApiClient] Request body: ${jsonEncode(body)}');

    final res = await _client.post(uri,
        headers: _headers(extra: headers), body: jsonEncode(body));

    debugPrint('[ApiClient] <- ${res.statusCode}');
    debugPrint('[ApiClient] Response headers: ${res.headers}');
    debugPrint('[ApiClient] Response body length: ${res.body.length}');

    // فحص إذا كانت الاستجابة HTML بدلاً من JSON
    if (res.body.trim().startsWith('<')) {
      debugPrint('[ApiClient] ⚠️ Response is HTML, not JSON!');
      debugPrint('[ApiClient] HTML Response: ${res.body.substring(0, 500)}...');
    } else {
      debugPrint('[ApiClient] Response body: ${res.body}');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      // تأكد أن الاستجابة JSON وليست صفحة HTML (مثل صفحة حماية Cloudflare)
      final contentType = res.headers['content-type'] ?? '';
      final bodyTrim = res.body.trim();
      final looksHtml = bodyTrim.startsWith('<!DOCTYPE html') ||
          bodyTrim.startsWith('<html') ||
          contentType.contains('text/html');
      if (looksHtml) {
        debugPrint(
            '[ApiClient] ⚠️ 2xx لكن المحتوى HTML (قد تكون صفحة حماية أو إعادة توجيه).');
        final snippet =
            bodyTrim.length > 200 ? bodyTrim.substring(0, 200) : bodyTrim;
        throw HttpException(
            res.statusCode, 'Non-JSON HTML response received: $snippet');
      }
      try {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('[ApiClient] ❌ Failed to parse JSON: $e');
        debugPrint('[ApiClient] Response was: ${res.body}');
        throw HttpException(
            res.statusCode, 'Invalid JSON response: ${res.body}');
      }
    }

    // معالجة خاصة لإعادة التوجيه HTTP 302
    if (res.statusCode == 302) {
      debugPrint('[ApiClient] 🔄 HTTP 302 Redirect detected');
      debugPrint('[ApiClient] Location header: ${res.headers['location']}');
      throw HttpException(res.statusCode,
          'Server returned redirect instead of API response. Location: ${res.headers['location']}');
    }

    // معالجة خاصة لحالة البريد غير المؤكد (403 مع error_code)
    if (res.statusCode == 403) {
      try {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) {
          final code = body['error_code'] as String?;
          if (code == 'EMAIL_NOT_VERIFIED') {
            final msg = body['message'] as String? ?? 'Email not verified';
            final userId = body['user_id'];
            final email = body['email'] as String?;
            debugPrint(
                '[ApiClient] 🔒 Email not verified response detected: $body');
            throw EmailNotVerifiedException(msg, userId: userId, email: email);
          }
        }
      } catch (e) {
        // لا نفشل هنا — سنقذف استثناء عادي أدناه
        debugPrint('[ApiClient] Error parsing 403 body: $e');
      }
    }

    throw HttpException(res.statusCode, res.body);
  }

  Future<Map<String, dynamic>> getJson(String path,
      {Map<String, String>? headers}) async {
    final resolved = await _overrideOr(baseUrl);
    final uri = Uri.parse('$resolved$path');
    debugPrint('[ApiClient] GET ${uri.toString()}');
    final res = await _client.get(uri, headers: _headers(extra: headers));
    debugPrint('[ApiClient] <- ${res.statusCode}');
    debugPrint('[ApiClient] Response headers: ${res.headers}');
    if (res.body.trim().startsWith('<')) {
      debugPrint(
          '[ApiClient] ⚠️ Response is HTML for GET: ${res.body.substring(0, res.body.length.clamp(0, 500))}');
    } else {
      debugPrint('[ApiClient] Response body: ${res.body}');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final contentType = res.headers['content-type'] ?? '';
      final bodyTrim = res.body.trim();
      final looksHtml = bodyTrim.startsWith('<!DOCTYPE html') ||
          bodyTrim.startsWith('<html') ||
          contentType.contains('text/html');
      if (looksHtml) {
        final snippet =
            bodyTrim.length > 200 ? bodyTrim.substring(0, 200) : bodyTrim;
        throw HttpException(
            res.statusCode, 'Non-JSON HTML response received: $snippet');
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw HttpException(res.statusCode, res.body);
  }
}

String _defaultBaseUrl() {
  // Allow overriding at build time: --dart-define=API_BASE_URL=http://192.168.1.10:8000
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;

  if (kIsWeb) return 'http://192.168.0.167:8000';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      // استخدام المتغير العالمي من AppConstants
      return AppConstants.baseUrl;
    default:
      return AppConstants.baseUrl;
  }
}

Future<String> _overrideOr(String fallback) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final base = prefs.getString(kApiBaseUrlKey);
    if (base != null && base.isNotEmpty) return base;
  } catch (_) {}
  return fallback;
}

class HttpException implements Exception {
  final int statusCode;
  final String body;
  HttpException(this.statusCode, this.body);
  @override
  String toString() => 'HttpException($statusCode): $body';
}

/// خاص بحالة البريد غير مؤكد (HTTP 403 مع error_code EMAIL_NOT_VERIFIED)
class EmailNotVerifiedException implements Exception {
  final String message;
  final dynamic userId;
  final String? email;
  EmailNotVerifiedException(this.message, {this.userId, this.email});
  @override
  String toString() =>
      'EmailNotVerifiedException: $message (userId=$userId, email=$email)';
}
