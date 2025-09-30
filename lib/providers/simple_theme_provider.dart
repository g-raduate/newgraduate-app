import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleThemeProvider extends ChangeNotifier {
  static const _kThemeColorKey = 'theme_seed_color';
  static const _kDarkModeKey = 'theme_dark_mode';

  Color _primaryColor =
      const Color(0xFF2196F3); // اللون الأزرق الموضح في الصورة
  bool _isDarkMode = true; // جعل الثيم الداكن افتراضياً
  SharedPreferences? _prefs;

  // الألوان المتاحة
  static const Map<String, Color> availableColors = {
    'أزرق': Color(0xFF2196F3), // اللون الأزرق الافتراضي الجديد
    'أزرق فاتح': Colors.blue,
    'أحمر': Colors.red,
    'أخضر': Colors.green,
    'بنفسجي': Colors.purple,
    'برتقالي': Colors.orange,
    'زهري': Colors.pink,
    'سماوي': Colors.cyan,
    'ذهبي': Colors.amber,
    'بني': Colors.brown,
    'رمادي': Colors.grey,
    'نيلي': Colors.indigo,
    'ليموني': Colors.lime,
    'أزرق داكن': Color(0xFF1976D2),
    'أحمر داكن': Color(0xFFD32F2F),
    'أخضر داكن': Color(0xFF388E3C),
    'بنفسجي داكن': Color(0xFF7B1FA2),
    'برتقالي داكن': Color(0xFFF57C00),
    'زهري داكن': Color(0xFFC2185B),
  };

  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _isDarkMode;

  SimpleThemeProvider() {
    _loadFromPrefs();
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    _saveToPrefs();
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveToPrefs();
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'NotoKufiArabic',
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'NotoKufiArabic',
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  LinearGradient get backgroundGradient {
    if (_isDarkMode) {
      return const LinearGradient(
        colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else {
      return LinearGradient(
        colors: [Colors.grey[50]!, Colors.white],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
  }

  LinearGradient get primaryGradient {
    return LinearGradient(
      colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  LinearGradient get cardGradient {
    return LinearGradient(
      colors: [
        _primaryColor.withOpacity(0.1),
        _primaryColor.withOpacity(0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Future<void> _loadFromPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    final colorValue = _prefs!.getInt(_kThemeColorKey);
    final dark = _prefs!.getBool(_kDarkModeKey);

    // تطبيق القيم المحفوظة أو الافتراضية
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    } else {
      // إذا لم توجد قيمة محفوظة، احفظ اللون الافتراضي الجديد
      _primaryColor = const Color(0xFF2196F3);
    }

    if (dark != null) {
      _isDarkMode = dark;
    } else {
      // إذا لم توجد قيمة محفوظة، احفظ الوضع الداكن كافتراضي
      _isDarkMode = true;
    }

    // احفظ القيم الافتراضية إذا لم تكن محفوظة مسبقاً
    if (colorValue == null || dark == null) {
      await _saveToPrefs();
    }

    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(_kThemeColorKey, _primaryColor.value);
    await _prefs!.setBool(_kDarkModeKey, _isDarkMode);
  }
}
