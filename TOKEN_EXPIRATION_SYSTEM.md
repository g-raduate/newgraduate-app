# نظام إدارة انتهاء صلاحية التوكن - Token Expiration Handler

## 🎯 الهدف

نظام شامل لإدارة انتهاء صلاحية التوكن في التطبيق مع رسائل ودية للمستخدم وتسجيل خروج تلقائي.

## ✨ المميزات

### 🔐 **كشف تلقائي لانتهاء التوكن**
- رموز HTTP: `401`, `403`
- رسائل الخطأ: `Unauthorized`, `Token expired`, `Invalid token`
- تحقق ذكي من محتوى الاستجابة

### 💬 **رسائل ودية للمستخدم**
- رسالة واضحة عن انتهاء الجلسة
- عد تنازلي بصري (5 ثوانٍ)
- تصميم جذاب مع أيقونات
- إمكانية تسجيل الخروج الفوري

### 🧹 **تنظيف شامل للبيانات**
- مسح جميع التوكنز المحفوظة
- حذف معلومات المستخدم
- تنظيف الكاش
- إعادة تعيين حالة التطبيق

### 🔄 **انتقال سلس**
- انتقال تلقائي لصفحة تسجيل الدخول
- رسالة وداع لطيفة
- عدم تعطيل تجربة المستخدم

## 🚀 كيفية الاستخدام

### 1. **استيراد النظام**
```dart
import 'package:newgraduate/services/token_expired_handler.dart';
```

### 2. **الطريقة الأساسية**
```dart
Future<void> loadData() async {
  try {
    final response = await http.get(apiUrl, headers: headers);
    
    // فحص انتهاء التوكن
    if (await TokenExpiredHandler.handleTokenExpiration(
      context,
      statusCode: response.statusCode,
      errorMessage: response.body,
    )) {
      return; // تم التعامل مع انتهاء التوكن
    }
    
    // معالجة البيانات العادية
    if (response.statusCode == 200) {
      // نجح الطلب
    }
    
  } catch (e) {
    // فحص انتهاء التوكن في حالة الخطأ
    if (await TokenExpiredHandler.handleTokenExpiration(
      context,
      errorMessage: e.toString(),
    )) {
      return;
    }
    
    // معالجة أخطاء أخرى
  }
}
```

### 3. **الطريقة المبسطة**
```dart
// فحص سريع لأخطاء التوكن
if (TokenExpiredHandler.isTokenError(response.body, response.statusCode)) {
  await TokenExpiredHandler.handleTokenExpiration(context, 
    statusCode: response.statusCode,
    errorMessage: response.body,
  );
  return;
}
```

### 4. **في خدمات API**
```dart
class MyApiService {
  static Future<Map<String, dynamic>?> fetchData(BuildContext context) async {
    try {
      final response = await http.get(url, headers: headers);
      
      // تطبيق النظام
      if (await TokenExpiredHandler.handleTokenExpiration(
        context,
        statusCode: response.statusCode,
        errorMessage: response.body,
      )) {
        return null; // تم التعامل مع انتهاء التوكن
      }
      
      return json.decode(response.body);
    } catch (e) {
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
```

## 📋 الحالات المُدعومة

### رموز HTTP
- `401 Unauthorized`
- `403 Forbidden`

### رسائل الخطأ
- `"Unauthorized"`
- `"Token expired"`
- `"Invalid token"`
- `"authentication failed"`
- `"access denied"`

### أنواع الأخطاء
- أخطاء HTTP Response
- أخطاء Exception
- أخطاء الشبكة
- أخطاء انتهاء المهلة الزمنية

## 🎨 تخصيص الرسائل

### النص الأساسي
```dart
'لقد انتهت صلاحية جلسة العمل الخاصة بك لأسباب أمنية'
```

### رسالة العد التنازلي
```dart
'سيتم تسجيل خروجك تلقائياً خلال: X ثانية'
```

### رسالة الوداع
```dart
'يرجى إعادة تسجيل الدخول للمتابعة 😊'
```

### إشعار تسجيل الخروج
```dart
'تم تسجيل خروجك بنجاح. نراك قريباً! 👋'
```

## 🔧 الملفات المحدثة

### الملفات الجديدة
- `lib/services/token_expired_handler.dart` - النظام الأساسي
- `lib/examples/token_expired_usage_example.dart` - أمثلة الاستخدام

### الملفات المحدثة
- `lib/features/courses/screens/free_courses_screen.dart`
- `lib/features/instructors/screens/instructors_screen.dart`
- `lib/features/home/screens/home_screen.dart`

## ⚡ التحسينات المُطبقة

### 🎯 **في صفحة الدورات المجانية**
```dart
// في _loadFreeCourses()
if (await TokenExpiredHandler.handleTokenExpiration(
  context,
  statusCode: response.statusCode,
  errorMessage: response.body,
)) {
  return; // تم التعامل مع انتهاء التوكن
}
```

### 🎓 **في صفحة الأساتذة**
```dart
// في _loadInstructors()
if (await TokenExpiredHandler.handleTokenExpiration(
  context,
  errorMessage: e.toString(),
)) {
  return; // تم التعامل مع انتهاء التوكن
}
```

### 🏠 **في الصفحة الرئيسية**
```dart
// في _loadPopularCourses()
if (await TokenExpiredHandler.handleTokenExpiration(
  context,
  statusCode: response.statusCode,
  errorMessage: response.body,
)) {
  return []; // إرجاع قائمة فارغة
}
```

## 🧪 كيفية الاختبار

### 1. **محاكاة انتهاء التوكن**
```dart
// إرسال توكن منتهي الصلاحية أو فارغ
headers['Authorization'] = 'Bearer expired-token';
```

### 2. **محاكاة خطأ 401**
```dart
// التأكد من عرض الرسالة والعد التنازلي
// التحقق من تسجيل الخروج التلقائي
// التحقق من الانتقال لصفحة تسجيل الدخول
```

### 3. **فحص تنظيف البيانات**
```dart
// التأكد من مسح جميع البيانات المحفوظة
final token = await TokenManager.getInstance().getToken();
assert(token == null); // يجب أن يكون فارغاً
```

## ⚠️ ملاحظات مهمة

1. **استخدام Context**: يجب توفر BuildContext صالح عند استدعاء النظام
2. **معالجة Return Values**: تحقق من القيم المُرجعة لتجنب معالجة مضاعفة
3. **تطبيق شامل**: استخدم النظام في جميع طلبات API
4. **اختبار دوري**: اختبر النظام بانتظام لضمان عمله الصحيح

## 🎉 النتائج المُحققة

✅ **تجربة مستخدم محسنة** - رسائل واضحة وودية  
✅ **أمان محسن** - تسجيل خروج تلقائي عند انتهاء التوكن  
✅ **تنظيف شامل** - مسح جميع البيانات الحساسة  
✅ **سهولة التطبيق** - واجهة برمجية بسيطة ومرنة  
✅ **قابلية الصيانة** - كود مركزي وقابل للإعادة  

---

**المطور**: GitHub Copilot  
**التاريخ**: سبتمبر 2025  
**الحالة**: مُكتمل ومُختبر ✅
