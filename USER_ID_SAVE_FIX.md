# إصلاح حفظ user_id لحذف الحساب

## المشكلة المحددة
- API حذف الحساب يتطلب `DELETE /api/users/{id}` 
- التطبيق كان يحفظ `student_id` فقط من تسجيل الدخول
- لم يكن يحفظ `user_id` المطلوب لحذف الحساب

## الحلول المطبقة

### 1. تحديث StudentService.loadStudentInfoFromLogin() ✅

#### قبل الإصلاح:
```dart
// كان يحفظ student_id فقط
if (studentId != null && studentId.isNotEmpty) {
  await UserInfoService.saveStudentId(studentId);
}
```

#### بعد الإصلاح:
```dart
// يحفظ كلاً من student_id و user_id
String? studentId;
String? userId;

// البحث عن student_id
if (loginResponse.containsKey('student_id')) {
  studentId = loginResponse['student_id']?.toString();
} else if (loginResponse.containsKey('user') &&
    loginResponse['user'] is Map &&
    loginResponse['user']['student_id'] != null) {
  studentId = loginResponse['user']['student_id']?.toString();
}

// البحث عن user_id  
if (loginResponse.containsKey('user_id')) {
  userId = loginResponse['user_id']?.toString();
} else if (loginResponse.containsKey('user') &&
    loginResponse['user'] is Map &&
    loginResponse['user']['id'] != null) {
  userId = loginResponse['user']['id']?.toString();
}

// حفظ كلا المعرفين
if (studentId != null && studentId.isNotEmpty) {
  await UserInfoService.saveStudentId(studentId);
}

if (userId != null && userId.isNotEmpty) {
  await UserInfoService.saveUserId(userId);
}
```

### 2. تأكيد استخدام user_id في حذف الحساب ✅

```dart
// في ProfileScreen._deleteAccount()
String? userId = await UserInfoService.getUserId();
print('🆔 معرف المستخدم المسترجع: $userId');

final response = await http.delete(
  Uri.parse('${AppConstants.baseUrl}/api/users/$userId'),
  headers: headers,
);
```

## مخرجات التشخيص المحسنة

### عند تسجيل الدخول:
```
🆔 معرفات مستخرجة من تسجيل الدخول:
  👤 Student ID: 383454ae-abb6-4b81-89d8-b5ac93de7a2b
  🆔 User ID: 12345
✅ تم حفظ student_id: 383454ae-abb6-4b81-89d8-b5ac93de7a2b
✅ تم حفظ user_id: 12345
```

### عند حذف الحساب:
```
🆔 معرف المستخدم المسترجع: 12345
📍 URL: http://192.168.0.167:8000/api/users/12345
📋 Headers المُرسلة: {Accept: application/json, Authorization: Bearer ...}
```

## مصادر user_id المحتملة في response

### الخيار 1: مباشرة في الـ response
```json
{
  "token": "...",
  "student_id": "383454ae-abb6-4b81-89d8-b5ac93de7a2b", 
  "user_id": "12345",
  "user": {...}
}
```

### الخيار 2: داخل user object
```json
{
  "token": "...",
  "student_id": "383454ae-abb6-4b81-89d8-b5ac93de7a2b",
  "user": {
    "id": "12345",
    "institute_id": "...",
    "..."
  }
}
```

## خطوات التحقق من الإصلاح

### 1. اختبار تسجيل دخول جديد
```bash
# راقب console للتأكد من ظهور:
🆔 معرفات مستخرجة من تسجيل الدخول:
  👤 Student ID: [UUID]
  🆔 User ID: [رقم]
✅ تم حفظ student_id: [UUID]
✅ تم حفظ user_id: [رقم]
```

### 2. اختبار حذف الحساب
```bash
# راقب console للتأكد من:
🆔 معرف المستخدم المسترجع: [رقم وليس null]
📍 URL: .../api/users/[رقم صحيح]
📊 استجابة حذف الحساب:
   - Status Code: 200 (وليس 404)
   - Body: {"message":"User deleted"}
```

## إذا استمر الخطأ 404

### تحقق من structure response تسجيل الدخول:
1. راجع logs تسجيل الدخول في AuthController
2. ابحث عن structure user object
3. تأكد من وجود user_id أو user.id

### احتمالات أخرى:
```dart
// قد يكون المعرف في مكان آخر
if (loginResponse.containsKey('id')) {
  userId = loginResponse['id']?.toString();
}

// أو في user object بمسمى مختلف
if (loginResponse['user']?['user_id'] != null) {
  userId = loginResponse['user']['user_id']?.toString();
}
```

## نصائح إضافية

### 1. فحص SharedPreferences يدوياً
```dart
// أضف هذا في أي مكان للفحص
final userId = await UserInfoService.getUserId();
final studentId = await UserInfoService.getStudentId();
print('📱 البيانات المحفوظة حالياً:');
print('  🆔 User ID: $userId');
print('  👤 Student ID: $studentId');
```

### 2. فحص response تسجيل الدخول
راجع logs `AuthController` في:
```
📋 Response كامل من تسجيل الدخول:
📄 Raw Response:
[هنا ستجد structure الحقيقي]
```

### 3. إذا لم يوجد user_id في response
قد تحتاج لاستعمال student_id مع endpoint مختلف:
```dart
// استخدام students endpoint للحذف
final response = await http.delete(
  Uri.parse('${AppConstants.baseUrl}/api/students/$studentId'),
  headers: headers,
);
```

---

**تاريخ الإصلاح**: يناير 2025  
**المشكلة**: 404 User not found  
**السبب**: عدم حفظ user_id من تسجيل الدخول  
**الحل**: استخراج وحفظ user_id من login response ✅
