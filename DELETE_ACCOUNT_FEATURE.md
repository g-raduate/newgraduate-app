# إضافة ميزة حذف الحساب

## نظرة عامة
تم إضافة ميزة حذف الحساب مع تأكيد مزدوج وتنظيف شامل للبيانات وتسجيل خروج تلقائي.

## التحديثات المطبقة

### 1. ProfileScreen.dart

#### Imports جديدة
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:newgraduate/config/app_constants.dart';
import 'package:newgraduate/services/api_headers_manager.dart';
```

#### دالة حذف الحساب (_deleteAccount)
- **تأكيد مزدوج**: dialog تحذيري مع رسالة واضحة
- **مؤشر تحميل**: عرض progress أثناء العملية
- **استدعاء API**: `DELETE /api/users/{id}`
- **تنظيف البيانات**: مسح جميع البيانات المحلية والكاش
- **تسجيل خروج تلقائي**: انتقال لشاشة تسجيل الدخول

#### واجهة المستخدم (_buildDeleteAccountButton)
- **تصميم متميز**: OutlinedButton باللون الأحمر
- **أيقونة واضحة**: `Icons.delete_forever`
- **موضع مناسب**: قبل زر تسجيل الخروج

## تدفق العمل

### 1. الضغط على زر حذف الحساب
```
المستخدم يضغط "حذف الحساب"
↓
إظهار dialog التأكيد الأول
```

### 2. التأكيد الأول
```dart
AlertDialog(
  title: "تأكيد حذف الحساب",
  content: "هل أنت متأكد من حذف الحساب؟\n\nتحذير: هذا الإجراء لا يمكن التراجع عنه وسيتم حذف جميع بياناتك نهائياً.",
  actions: ["إلغاء", "حذف الحساب"]
)
```

### 3. تنفيذ الحذف
```
إظهار مؤشر تحميل "جاري حذف الحساب..."
↓
الحصول على معرف المستخدم من UserInfoService
↓
استدعاء DELETE /api/users/{id}
```

### 4. معالجة الاستجابة
```dart
// عند النجاح
if (response.statusCode == 200 && responseData['message'] == 'User deleted') {
  // تنظيف البيانات
  await UserInfoService.clearUserInfo();
  await CacheManager.instance.clearAllCache();
  await prefs.setBool(kIsLoggedIn, false);
  
  // رسالة نجاح + انتقال لتسجيل الدخول
  Navigator.pushAndRemoveUntil(...);
}
```

## API المستخدم

### Request
```http
DELETE /api/users/{id}
Headers: Authorization + Accept + Content-Type
```

### Response المتوقع
```json
// عند النجاح
{
  "message": "User deleted"
}

// عند الخطأ
{
  "error": "..."
}
```

## معالجة الأخطاء

### 1. عدم وجود معرف مستخدم
```dart
if (userId == null || userId.isEmpty) {
  SnackBar: "خطأ: لا يمكن العثور على معرف المستخدم"
}
```

### 2. فشل API
```dart
if (response.statusCode != 200) {
  SnackBar: "فشل في حذف الحساب: {statusCode}"
}
```

### 3. خطأ في الشبكة
```dart
catch (e) {
  SnackBar: "خطأ في حذف الحساب: {error}"
}
```

## الأمان والحماية

### 1. تأكيد مزدوج
- Dialog تحذيري واضح
- رسالة تحذير بعدم إمكانية التراجع
- زر حذف باللون الأحمر للتأكيد

### 2. تنظيف شامل
```dart
// مسح جميع البيانات المحلية
await UserInfoService.clearUserInfo();

// مسح جميع الكاش
await CacheManager.instance.clearAllCache();

// مسح حالة تسجيل الدخول
await prefs.setBool(kIsLoggedIn, false);
```

### 3. تحقق من الهوية
- استخدام معرف المستخدم الصحيح
- headers المصادقة المطلوبة
- التحقق من صحة الاستجابة

## تجربة المستخدم

### 1. التصميم
```dart
OutlinedButton.icon(
  style: OutlinedButton.styleFrom(
    foregroundColor: cs.error,           // لون أحمر
    side: BorderSide(color: cs.error),   // حدود حمراء
  ),
  icon: Icons.delete_forever,            // أيقونة حذف
  label: "حذف الحساب",                  // نص واضح
)
```

### 2. الرسائل
- **تحذير واضح**: "لا يمكن التراجع عنه"
- **تحميل**: "جاري حذف الحساب..."
- **نجاح**: "تم حذف الحساب بنجاح"
- **خطأ**: رسائل خطأ واضحة

### 3. التنقل
```dart
// بعد نجاح الحذف
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const LoginScreen()),
  (route) => false,  // مسح stack التنقل
);
```

## اختبار الميزة

### 1. السيناريو الإيجابي
1. فتح شاشة الملف الشخصي
2. الضغط على "حذف الحساب"
3. تأكيد الحذف في Dialog
4. انتظار انتهاء العملية
5. التحقق من الانتقال لشاشة تسجيل الدخول

### 2. السيناريو السلبي
1. إلغاء الحذف في Dialog → لا يحدث شيء
2. فشل الشبكة → رسالة خطأ
3. خطأ في API → رسالة خطأ مناسبة

### 3. تحقق من تنظيف البيانات
```bash
# فحص SharedPreferences
# تأكد من مسح جميع مفاتيح المستخدم

# فحص الكاش
# تأكد من مسح جميع ملفات الكاش

# فحص حالة تسجيل الدخول
# تأكد من إزالة kIsLoggedIn
```

## ملاحظات مهمة

### 1. عدم إمكانية التراجع
- الحذف نهائي من قاعدة البيانات
- لا يمكن استرداد الحساب أو البيانات
- يجب تحذير المستخدم بوضوح

### 2. تنظيف البيانات
- مسح جميع البيانات المحلية ضروري
- منع ظهور بيانات المستخدم المحذوف
- ضمان خصوصية البيانات

### 3. متطلبات API
- التأكد من صحة endpoint
- وجود معرف المستخدم
- صحة headers المصادقة

---

**تاريخ الإضافة**: يناير 2025  
**الحالة**: مكتمل ومُختبر  
**مستوى الأمان**: عالي  
**نوع الميزة**: إدارة الحساب
