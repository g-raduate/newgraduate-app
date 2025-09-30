# نظام الأمان المتقدم - Security System

## الوصف
نظام حماية متقدم يحمي التطبيق من:
1. **Screen Mirroring/Cable Display**: عرض الشاشة عبر كابل أو لاسلكي
2. **Developer Mode**: وضع المطور المفعل في الجهاز

## المكونات

### 1. SecurityService (`lib/services/security_service.dart`)
الخدمة الأساسية للكشف عن التهديدات:
- **فحص وضع المطور**: يكتشف إذا كان ADB أو Developer Settings مفعل
- **فحص عرض الشاشة**: يكتشف وجود شاشات إضافية (Screen Mirroring)
- **الشاشة السوداء**: يعرض شاشة سوداء عند اكتشاف عرض الشاشة
- **تحذير وضع المطور**: يعرض رسالة تحذير ويغلق التطبيق بعد 5 ثواني

### 2. SecurityManager (`lib/managers/security_manager.dart`)
مدير الأمان الرئيسي:
- **تهيئة النظام**: `initialize(BuildContext context)`
- **فحص فوري**: `performImmediateCheck()`
- **إيقاف النظام**: `stop()`
- **مراقبة مستمرة**: فحص كل ثانيتين

### 3. Platform Channel (`android/.../MainActivity.kt`)
التواصل مع Android:
- **Channel**: `security_channel`
- **Methods**:
  - `isDeveloperModeEnabled`: فحص وضع المطور
  - `isScreenMirroring`: فحص عرض الشاشة

## التكامل

### في main.dart:
```dart
// تهيئة مدير الأمان
if (!SecurityManager.isInitialized) {
  SecurityManager.initialize(context);
}
```

## السلوك

### وضع المطور مفعل:
1. يعرض رسالة تحذير
2. يعرض كيفية إيقاف وضع المطور
3. يغلق التطبيق بعد 5 ثواني

### عرض الشاشة (Screen Mirroring):
1. يعرض شاشة سوداء مع أيقونة أمان
2. يختفي تلقائياً عند إيقاف العرض

### وضع التطوير (AppConstants.underDevelopmentOverride = true):
- **يتم تعطيل جميع فحوصات الأمان**
- يطبع رسائل في الـ console تؤكد التعطيل

## الاختبار

### ملف الاختبار (`lib/utils/security_tester.dart`):
```dart
// اختبار النظام
await SecurityTester.testSecuritySystem();

// إيقاف للاختبار
SecurityTester.testStopSecurity();

// بدء للاختبار
SecurityTester.testStartSecurity(context);
```

## المراقبة والسجلات

### رسائل Console:
- `🔧 وضع التطوير مفعل - تجاهل فحوصات الأمان`
- `🔒 تم تفعيل الشاشة السوداء بسبب اكتشاف عرض الشاشة`
- `⚠️ تم عرض تحذير وضع المطور - سيتم إغلاق التطبيق خلال 5 ثواني`
- `🚪 إغلاق التطبيق بسبب وضع المطور`

## الأداء

### تكرار الفحص:
- **كل ثانيتين** للمراقبة المستمرة
- **Platform Channel** سريع ولا يؤثر على الأداء
- **Overlay** يستخدم ذاكرة قليلة

## التخصيص

### تعديل زمن الإغلاق:
```dart
// في SecurityService._showDeveloperModeWarning()
_developerModeTimer = Timer(const Duration(seconds: 5), () {
  _exitApp();
});
```

### تعديل تكرار الفحص:
```dart
// في SecurityService.startPeriodicSecurityCheck()
Timer.periodic(const Duration(seconds: 2), (timer) {
  // ...
});
```

## الأمان

### الحماية من التحايل:
- **فحص متعدد المستويات** لوضع المطور
- **فحص Display Manager** لاكتشاف الشاشات الإضافية
- **إغلاق فوري** للتطبيق عند اكتشاف التهديد

### التحديد الذكي:
- **لا يؤثر على وضع التطوير** الخاص بك
- **فحص دوري غير مزعج** للمستخدم العادي
- **رسائل واضحة** للمستخدم المخالف

## الاستخدام

### تفعيل الحماية:
```dart
// في app_constants.dart
static const bool? underDevelopmentOverride = false; // أو null
```

### إيقاف الحماية (للتطوير):
```dart
// في app_constants.dart  
static const bool? underDevelopmentOverride = true;
```

## الملاحظات

1. **يعمل على Android فقط** حالياً
2. **لا يؤثر على المحاكيات** العادية
3. **يحترم إعداد التطوير** في AppConstants
4. **آمن وموثوق** لا يسبب crashes