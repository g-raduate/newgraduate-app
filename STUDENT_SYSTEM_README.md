# نظام إدارة معلومات الطلاب - Student Management System

## نظرة عامة
نظام متكامل لإدارة معلومات الطلاب يتم تفعيله تلقائياً عند تسجيل الدخول، مع التكامل الكامل مع نظام الحماية للفيديوهات.

## الميزات الرئيسية

### 🎓 جلب معلومات الطالب التلقائي
- **تفعيل تلقائي**: يتم جلب معلومات الطالب تلقائياً عند تسجيل الدخول الناجح
- **استخدام Student ID**: يستخدم student_id من استجابة تسجيل الدخول
- **API التكامل**: يستدعي `/api/students/{student_id}` للحصول على المعلومات الكاملة
- **حفظ محلي**: يحفظ المعلومات محلياً لسرعة الوصول

### 🔐 التكامل مع نظام الحماية
- **هوية الطالب**: معلومات الطالب تستخدم في العلامة المائية
- **حماية الفيديوهات**: ربط كل فيديو بهوية طالب محددة
- **تتبع المشاهدة**: إمكانية تتبع من شاهد أي فيديو

### 📱 واجهات المستخدم
- **عرض مدمج**: widget لعرض معلومات الطالب في أي مكان
- **معلومات كاملة**: شاشة تفصيلية لجميع بيانات الطالب
- **AppBar Widget**: عرض سريع في شريط التطبيق

## الملفات والخدمات

### `StudentService` - الخدمة الرئيسية
```dart
// جلب معلومات الطالب
Map<String, dynamic>? studentInfo = await StudentService.getStudentInfo(studentId);

// التحقق من وجود معلومات محلية
bool hasInfo = await StudentService.hasLocalStudentInfo();

// جلب المعلومات المحفوظة محلياً
Map<String, String?> localInfo = await StudentService.getLocalStudentInfo();
```

### `UserInfoService` - إدارة البيانات المحلية (محدث)
```dart
// حفظ معرف الطالب
await UserInfoService.saveStudentId("student_id_here");

// الحصول على معرف الطالب
String? studentId = await UserInfoService.getStudentId();

// حفظ جميع المعلومات
await UserInfoService.saveUserInfo(
  phone: "+964XXXXXXXXX",
  userName: "اسم الطالب",
  studentId: "student_id_here",
);
```

### `StudentInfoWidget` - واجهة العرض
```dart
// عرض مدمج بسيط
StudentInfoWidget()

// عرض كامل مع جميع التفاصيل
StudentInfoWidget(showFullInfo: true)

// widget للـ AppBar
StudentInfoAppBarWidget()
```

## التكامل مع AuthController

### تحديث عملية تسجيل الدخول
```dart
// في دالة login()
final response = await _repo.loginAndGetResponse(...);

// استدعاء معلومات الطالب تلقائياً
await StudentService.loadStudentInfoFromLogin(response);
```

### تنظيف البيانات عند تسجيل الخروج
```dart
// في دالة logout()
await StudentService.clearLocalStudentInfo();
```

## استجابة API المتوقعة

### من تسجيل الدخول `/api/auth/login`
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
  "user": {
    "id": "55de4c2d-7685-422f-a91d-787d2ac8109",
    "name": "محمد علي الخريجي",
    "email": "student4@tech.edu.sa",
    "institute_id": "1cc39749-b6e8-4b43-b813-7668fd172418"
  },
  "student_id": "29465db3-6d1f-4158-8db5-177276b9e722"
}
```

### من معلومات الطالب `/api/students/{student_id}`
```json
{
  "id": "29465db3-6d1f-4158-8db5-177276b9e722",
  "name": "محمد علي الخريجي",
  "email": "student4@tech.edu.sa",
  "phone": "+966517539654",
  "institute_id": "1cc39749-b6e8-4b43-b813-7668fd172418",
  "status": "active",
  "last_latitude": 33.3743428,
  "last_longitude": 44.4883112,
  "last_accuracy": 20,
  "last_location_source": "gps",
  "last_device_info": "PostmanRuntime/7.42.0",
  "last_user_agent": "PostmanRuntime/7.42.0",
  "last_ip_address": "192.168.0.167",
  "last_seen_at": "2025-08-19 13:59:44",
  "created_at": "2025-08-19T13:30:16.000000Z"
}
```

## آلية العمل

### 1. عند تسجيل الدخول
```dart
1. المستخدم يدخل email و password
2. يتم إرسال الطلب إلى /api/auth/login
3. الاستجابة تحتوي على student_id
4. يتم استدعاء StudentService.loadStudentInfoFromLogin()
5. يتم جلب المعلومات من /api/students/{student_id}
6. يتم حفظ المعلومات محلياً في SharedPreferences
```

### 2. في نظام الحماية
```dart
// في ProtectedYouTubePlayer
String protectionId = await UserInfoService.getProtectionId();
// يعطي: رقم الهاتف أو "طالب-{student_id}" أو اسم المستخدم
```

### 3. عرض المعلومات
```dart
// في أي شاشة
StudentInfoWidget() // عرض بسيط
StudentInfoWidget(showFullInfo: true) // عرض كامل
```

## الفوائد

### للمطورين
- **تكامل تلقائي**: لا حاجة لاستدعاءات يدوية
- **بيانات محلية**: سرعة في الوصول للمعلومات
- **مرونة**: يمكن استخدام المعلومات في أي جزء من التطبيق

### للمستخدمين
- **تجربة سلسة**: المعلومات تُجلب تلقائياً
- **حماية مخصصة**: العلامة المائية تحتوي على معلومات حقيقية
- **خصوصية**: البيانات محفوظة محلياً فقط

### للإدارة
- **تتبع دقيق**: معرفة هوية كل مشاهد للفيديوهات
- **أمان عالي**: ربط المحتوى بهويات حقيقية
- **بيانات شاملة**: معلومات كاملة عن كل طالب

## أمثلة الاستخدام

### في الشاشة الرئيسية
```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الصفحة الرئيسية'),
        actions: [
          StudentInfoAppBarWidget(), // عرض معلومات الطالب
        ],
      ),
      body: Column(
        children: [
          StudentInfoWidget(), // عرض مدمج للمعلومات
          // باقي محتوى الشاشة
        ],
      ),
    );
  }
}
```

### في إعدادات الملف الشخصي
```dart
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          StudentInfoWidget(showFullInfo: true), // عرض كامل
          // إعدادات أخرى
        ],
      ),
    );
  }
}
```

### تحديث معلومات الطالب
```dart
// تحديث رقم الهاتف
bool success = await StudentService.updateStudentInfo(
  studentId,
  {'phone': '+964XXXXXXXXX'}
);
```

## نصائح التطوير

### 1. التحقق من وجود المعلومات
```dart
if (await StudentService.hasLocalStudentInfo()) {
  // المعلومات موجودة
} else {
  // عرض رسالة أو إعادة توجيه لتسجيل الدخول
}
```

### 2. التعامل مع الأخطاء
```dart
try {
  final info = await StudentService.getStudentInfo(studentId);
  if (info == null) {
    // فشل في جلب المعلومات
  }
} catch (e) {
  // معالجة الخطأ
}
```

### 3. تحديث واجهة المستخدم
```dart
// استخدم FutureBuilder للتحديث التلقائي
FutureBuilder<Map<String, String?>>(
  future: StudentService.getLocalStudentInfo(),
  builder: (context, snapshot) {
    // بناء الواجهة حسب البيانات
  },
)
```

---

هذا النظام يوفر تكاملاً كاملاً بين معلومات الطلاب ونظام الحماية، مما يضمن تجربة مستخدم ممتازة مع أمان عالي. 🎓🔒✨
