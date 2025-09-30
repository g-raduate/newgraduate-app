import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kApiBaseUrlKey = 'api_base_url';
const String kUnderDevKey = 'under_development_flag';

class RuntimeConfig extends ChangeNotifier {
  RuntimeConfig() {
    _load();
  }

  String? _apiBaseUrl; // nullable => fall back to ApiClient default
  String? get apiBaseUrl => _apiBaseUrl;

  bool _underDevelopment = false;
  bool get underDevelopment => _underDevelopment;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _apiBaseUrl = prefs.getString(kApiBaseUrlKey);
    _underDevelopment = prefs.getBool(kUnderDevKey) ?? false;
    notifyListeners();
  }

  Future<void> setApiBaseUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.isEmpty) {
      await prefs.remove(kApiBaseUrlKey);
      _apiBaseUrl = null;
    } else {
      await prefs.setString(kApiBaseUrlKey, url);
      _apiBaseUrl = url;
    }
    notifyListeners();
  }

  Future<void> setUnderDevelopment(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _underDevelopment = value;
    await prefs.setBool(kUnderDevKey, value);
    notifyListeners();
  }
}
