# إضافة حذف الكاش عند تسجيل الخروج

## نظرة عامة
تم إضافة حذف شامل للكاش والبيانات المحلية عند تسجيل الخروج لضمان عدم بقاء أي بيانات للمستخدم السابق.

## التحديثات المطبقة

### 1. ProfileScreen.dart - زر تسجيل الخروج

#### قبل التحديث:
```dart
if (confirm == true) {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kIsLoggedIn, false);
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}
```

#### بعد التحديث:
```dart
if (confirm == true) {
  print('🔄 بدء عملية تسجيل الخروج...');
  
  // حذف جميع البيانات المحلية والكاش
  print('🗑️ حذف البيانات المحلية...');
  await UserInfoService.clearUserInfo();
  
  print('🗑️ حذف الكاش...');
  await CacheManager.instance.clearAllCache();
  
  print('🗑️ حذف حالة تسجيل الدخول...');
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kIsLoggedIn, false);
  
  print('✅ تم إكمال تسجيل الخروج وحذف جميع البيانات');
  
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}
```

### 2. AuthController.dart - دالة logout()

#### إضافة imports جديدة:
```dart
import 'package:newgraduate/services/cache_manager.dart';
import 'package:newgraduate/services/user_info_service.dart';
```

#### قبل التحديث:
```dart
Future<void> logout() async {
  await _initTokenManager();
  await _tokenManager!.clearAll();
  await StudentService.clearLocalStudentInfo();
  
  _token = null;
  _studentId = null;
  _error = null;
  
  notifyListeners();
}
```

#### بعد التحديث:
```dart
Future<void> logout() async {
  print('🔄 بدء عملية تسجيل الخروج من AuthController...');
  
  await _initTokenManager();
  
  // حذف البيانات من TokenManager
  print('🗑️ حذف tokens والبيانات من TokenManager...');
  await _tokenManager!.clearAll();

  // حذف معلومات الطالب المحفوظة محلياً
  print('🗑️ حذف معلومات الطالب المحفوظة محلياً...');
  await StudentService.clearLocalStudentInfo();
  
  // حذف جميع بيانات المستخدم من UserInfoService
  print('🗑️ حذف بيانات المستخدم من UserInfoService...');
  await UserInfoService.clearUserInfo();
  
  // حذف جميع البيانات من الكاش
  print('🗑️ حذف جميع بيانات الكاش...');
  await CacheManager.instance.clearAllCache();

  _token = null;
  _studentId = null;
  _error = null;

  notifyListeners();
  print('✅ تم إكمال تسجيل الخروج وحذف جميع البيانات من AuthController');
}
```

## ما يتم حذفه عند تسجيل الخروج

### 1. TokenManager
```dart
await _tokenManager!.clearAll();
```
- Auth tokens
- Student ID
- Institute ID
- أي بيانات أخرى محفوظة في TokenManager

### 2. UserInfoService
```dart
await UserInfoService.clearUserInfo();
```
- user_phone
- user_id  
- user_name
- student_id
- user_image_url

### 3. StudentService
```dart
await StudentService.clearLocalStudentInfo();
```
- معلومات الطالب المحفوظة محلياً
- أي بيانات إضافية متعلقة بالطالب

### 4. CacheManager
```dart
await CacheManager.instance.clearAllCache();
```
- جميع ملفات الكاش
- بيانات الدورات المخزنة مؤقتاً
- صور وفيديوهات مخزنة مؤقتاً
- معلومات الطالب المخزنة مؤقتاً
- أي بيانات أخرى في الكاش

### 5. SharedPreferences
```dart
await prefs.setBool(kIsLoggedIn, false);
```
- حالة تسجيل الدخول

## مخرجات التشخيص المتوقعة

### عند تسجيل الخروج من ProfileScreen:
```
🔄 بدء عملية تسجيل الخروج...
🗑️ حذف البيانات المحلية...
🗑️ حذف الكاش...
🗑️ حذف حالة تسجيل الدخول...
✅ تم إكمال تسجيل الخروج وحذف جميع البيانات
```

### عند تسجيل الخروج من AuthController:
```
🔄 بدء عملية تسجيل الخروج من AuthController...
🗑️ حذف tokens والبيانات من TokenManager...
🗑️ حذف معلومات الطالب المحفوظة محلياً...
🗑️ حذف بيانات المستخدم من UserInfoService...
🗑️ حذف جميع بيانات الكاش...
✅ تم إكمال تسجيل الخروج وحذف جميع البيانات من AuthController
```

## الفوائد

### 1. الأمان والخصوصية
- عدم بقاء أي بيانات للمستخدم السابق
- حماية معلومات المستخدم الشخصية
- منع الوصول غير المصرح لبيانات المستخدم

### 2. مساحة التخزين
- تحرير مساحة من ملفات الكاش
- حذف الصور والفيديوهات المخزنة مؤقتاً
- تنظيف SharedPreferences

### 3. الأداء
- بداية نظيفة للمستخدم الجديد
- عدم تضارب البيانات
- تحسين أداء التطبيق

## اختبار التحديث

### 1. قبل تسجيل الخروج
```dart
// تحقق من وجود بيانات
final userId = await UserInfoService.getUserId();
final cacheStats = await CacheManager.instance.getCacheStats();
print('البيانات قبل الخروج: UserId=$userId, Cache=${cacheStats.totalFiles}');
```

### 2. بعد تسجيل الخروج
```dart
// تحقق من حذف البيانات
final userId = await UserInfoService.getUserId();
final cacheStats = await CacheManager.instance.getCacheStats();
print('البيانات بعد الخروج: UserId=$userId, Cache=${cacheStats.totalFiles}');
```

### 3. النتيجة المتوقعة
- `UserId` يجب أن يكون `null`
- `Cache` يجب أن يكون `0` أو قريب من الصفر
- عدم ظهور بيانات المستخدم السابق عند تسجيل دخول جديد

## نصائح للمطورين

### عند إضافة بيانات جديدة
تأكد من إضافة حذفها في:
1. `UserInfoService.clearUserInfo()`
2. `AuthController.logout()`
3. أي مكان آخر يحفظ بيانات المستخدم

### عند تشخيص المشاكل
راقب logs تسجيل الخروج للتأكد من:
- تنفيذ جميع خطوات الحذف
- عدم ظهور أخطاء في العملية
- اكتمال العملية بنجاح

---

**تاريخ التحديث**: يناير 2025  
**نوع التحديث**: تحسين الأمان والخصوصية  
**الهدف**: حذف شامل للبيانات عند تسجيل الخروج ✅
