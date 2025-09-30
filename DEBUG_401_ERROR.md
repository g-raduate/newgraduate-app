# تشخيص مشكلة خطأ 401 (Unauthorized)

## المشكلة
```
📊 Response status: 401
❌ خطأ HTTP: 401
```

## الأسباب المحتملة

### 1. **مشكلة في التوكن**
- التوكن منتهي الصلاحية
- التوكن غير موجود في storage
- تنسيق التوكن غير صحيح

### 2. **مشكلة في Headers**
- عدم إرسال Authorization header
- تنسيق خاطئ للـ Bearer token
- Headers مفقودة مطلوبة من الخادم

### 3. **مشكلة في API endpoint**
- المسار غير صحيح
- المعلمات المطلوبة مفقودة
- إعدادات الخادم

## التشخيص المُضاف

### 1. **في InstructorService**
```dart
// تشخيص التوكن مباشرة
TokenManager tokenManager = await TokenManager.getInstance();
String? token = await tokenManager.getToken();
print('🔑 Token للتشخيص: ${token?.substring(0, 20) ?? "لا يوجد"}...');
bool hasToken = await tokenManager.hasToken();
print('🔐 حالة التوكن: ${hasToken ? "موجود" : "غير موجود"}');
```

### 2. **في ApiHeadersManager**
```dart
print('🔍 ApiHeadersManager - Token متوفر: ${token != null}');
print('🔍 ApiHeadersManager - Token length: ${token?.length ?? 0}');
print('🔐 Authorization value: Bearer ${token.substring(0, 20)}...');
```

## خطوات التحقق

### 1. **تحقق من وجود التوكن**
- هل يظهر "🔐 حالة التوكن: موجود"؟
- هل Token length أكبر من 0؟

### 2. **تحقق من تنسيق Headers**
- هل يظهر "🔐 تم إضافة Authorization header بنجاح"؟
- هل Authorization header موجود في القائمة المطبوعة؟

### 3. **مقارنة مع الخدمات الأخرى**
- هل InstituteService يعمل بنفس التوكن؟
- هل هناك فرق في تنسيق الطلبات؟

## الحلول المحتملة

### إذا كان التوكن مفقود:
```dart
// إعادة تسجيل الدخول
await authController.logout();
// انتقال لشاشة تسجيل الدخول
```

### إذا كان التوكن موجود لكن منتهي الصلاحية:
```dart
// التحقق من response body للحصول على تفاصيل الخطأ
print('📄 Response body: ${response.body}');
```

### إذا كانت مشكلة في تنسيق API:
```dart
// مقارنة URL مع الخدمات الأخرى
print('🔗 مقارنة URLs:');
print('  Institute: ${AppConstants.apiUrl}/institutes');
print('  Instructor: $baseUrl$_baseEndpoint?institute_id=$instituteId');
```

## الخطوة التالية
قم بتشغيل التطبيق ومشاركة الـ logs الجديدة للحصول على تشخيص دقيق للمشكلة.
