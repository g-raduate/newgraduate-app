# شاشة إعدادات المشغل للمطور

تم إنشاء نظام متكامل لمراقبة وإدارة إعدادات المشغل والكاش للمطورين.

## الملفات المضافة

### 1. شاشة المطور الرئيسية
`lib/screens/player_settings_debug_screen.dart`
- شاشة شاملة تعرض معلومات مفصلة عن الكاش والمشغل
- تتضمن أدوات لاختبار النظام وإدارة الكاش

### 2. أداة الوصول للمطور
`lib/widgets/developer_access_widget.dart`
- طرق سهلة للوصول لشاشة المطور من أي مكان في التطبيق
- دوال مساعدة لعرض معلومات سريعة

## الميزات

### معلومات الجهاز
- نوع الجهاز (أندرويد/آيفون/غير محدد)
- رمز المنصة
- دعم API المشغل

### معلومات الكاش
- حالة وجود الكاش
- صحة الكاش (صالح/منتهي الصلاحية)
- رقم واسم المشغل المحفوظ
- تاريخ الحفظ
- منصة الكاش

### أدوات إدارة الكاش
- تحديث من API بالقوة
- مسح الكاش بالكامل
- تحديث المعلومات

### اختبار المشغلين
- اختبار المشغل رقم 1 (youtube_player_flutter)
- اختبار المشغل رقم 2 (youtube_player_iframe)
- اختبار النظام الذكي (تحديد تلقائي)

## طريقة الاستخدام

### 1. إضافة أيقونة مخفية في شاشة الإعدادات

```dart
import 'package:newgraduate/widgets/developer_access_widget.dart';

// في أي شاشة إعدادات أو عن التطبيق
AppBar(
  title: Text('الإعدادات'),
  actions: [
    // أيقونة مخفية للمطورين
    DeveloperAccessWidget(),
  ],
)
```

### 2. الوصول المباشر

```dart
import 'package:newgraduate/widgets/developer_access_widget.dart';

// فتح الشاشة مباشرة
DeveloperDebugHelper.showPlayerDebugScreen(context);

// عرض معلومات سريعة
DeveloperDebugHelper.showQuickPlayerInfo(context);
DeveloperDebugHelper.showCacheStatus(context);
```

### 3. منطقة مخفية للنقر

```dart
// منطقة شفافة للنقر المخفي
InkWell(
  onTap: () => DeveloperDebugHelper.showPlayerDebugScreen(context),
  child: Container(
    width: 50,
    height: 50,
    color: Colors.transparent,
  ),
)
```

## أمثلة الاستخدام

### في شاشة عن التطبيق

```dart
class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('عن التطبيق'),
        // أيقونة مطور مخفية
        actions: [DeveloperAccessWidget()],
      ),
      body: Column(
        children: [
          // معلومات التطبيق العادية
          Text('اسم التطبيق: خريج جديد'),
          Text('الإصدار: 0.6'),
          
          // منطقة مخفية للمطورين (5 نقرات متتالية)
          GestureDetector(
            onTap: () => _handleDeveloperAccess(),
            child: Container(
              height: 50,
              color: Colors.transparent,
              child: Center(child: Text('معلومات إضافية')),
            ),
          ),
        ],
      ),
    );
  }
  
  int _tapCount = 0;
  void _handleDeveloperAccess() {
    _tapCount++;
    if (_tapCount >= 5) {
      _tapCount = 0;
      DeveloperDebugHelper.showPlayerDebugScreen(context);
    }
  }
}
```

### في شاشة الإعدادات

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإعدادات'),
        actions: [
          // أيقونة مطور مخفية للمطورين فقط
          if (kDebugMode) DeveloperAccessWidget(),
        ],
      ),
      body: ListView(
        children: [
          // إعدادات عادية
          ListTile(title: Text('الإشعارات')),
          ListTile(title: Text('اللغة')),
          
          // في النهاية - زر مخفي للمطورين
          if (kDebugMode)
            ListTile(
              leading: Icon(Icons.developer_mode),
              title: Text('إعدادات المطور'),
              onTap: () => DeveloperDebugHelper.showPlayerDebugScreen(context),
            ),
        ],
      ),
    );
  }
}
```

## الفوائد للمطور

### مراقبة الأداء
- تتبع استخدام الكاش
- التحقق من صحة استجابات API
- مراقبة اختيار المشغل الصحيح

### استكشاف الأخطاء
- اختبار كل مشغل على حدة
- مسح الكاش لإعادة الاختبار
- عرض رسائل الأخطاء التفصيلية

### تطوير الميزات
- تجربة إعدادات مختلفة بسرعة
- التحقق من تطابق السلوك مع التصميم
- اختبار سيناريوهات الفشل

## الأمان

- الشاشة مخفية عن المستخدمين العاديين
- يمكن إخفاؤها في بيئة الإنتاج باستخدام `kDebugMode`
- لا تؤثر على أداء التطبيق العادي

## تنبيهات

- استخدام شاشة المطور يمكن أن يؤثر على حالة الكاش
- مسح الكاش قد يؤدي لطلبات API إضافية
- اختبار المشغلين بفيديو تجريبي قد يستهلك بيانات

## استكشاف الأخطاء المتوقعة

### "لا توجد معلومات متاحة"
- تحقق من أن الكاش يعمل بشكل صحيح
- جرب "تحديث من API" لإعادة جلب البيانات

### فشل اختبار المشغل
- تأكد من وجود اتصال إنترنت
- تحقق من صحة رابط الفيديو التجريبي
- جرب الرابط في متصفح ويب

### خطأ في API
- تحقق من إعدادات الخادم
- تأكد من صحة endpoints
- راجع headers المطلوبة

هذا النظام يوفر رؤية شاملة وتحكم كامل في نظام المشغل للمطورين مع الحفاظ على الأمان وسهولة الاستخدام.