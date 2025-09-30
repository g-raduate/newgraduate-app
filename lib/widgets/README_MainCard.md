# MainCard Widget - الكارت الرئيسي

## نظرة عامة
`MainCard` هو widget مرن وقابل لإعادة الاستخدام يوفر تصميماً جميلاً مع تأثيرات بصرية متطورة للكروت في التطبيق.

## الميزات الرئيسية
✨ **تأثير الطفو الطبيعي** - حركة خفيفة مستمرة  
🎭 **ظلال ثلاثية الأبعاد** - 5 طبقات ظل مختلفة  
🎨 **تدرج لوني متطور** - 4 نقاط توقف للتدرج  
⚡ **تفاعل متقدم** - انتقالات ناعمة عند اللمس  
🔧 **مرونة عالية** - قابل للتخصيص بسهولة  

## المعاملات (Parameters)

### إجبارية (Required)
- `imageUrl`: رابط الصورة
- `title`: النص الرئيسي

### اختيارية (Optional)
- `subtitle`: نص ثانوي (اختياري)
- `onTap`: دالة عند الضغط
- `fallbackIcon`: أيقونة عند فشل تحميل الصورة
- `imageSize`: حجم الصورة (افتراضي: 90)
- `enableFloating`: تفعيل تأثير الطفو (افتراضي: true)
- `primaryColor`: لون أساسي مخصص

## أمثلة الاستخدام

### 1. للأقسام (Departments)
```dart
MainCard(
  imageUrl: department.imageUrl,
  title: department.name,
  fallbackIcon: Icons.school,
  onTap: () => navigateToDepartment(department),
)
```

### 2. للكورسات (Courses)
```dart
MainCard(
  imageUrl: course.thumbnailUrl,
  title: course.name,
  subtitle: course.instructor,
  fallbackIcon: Icons.play_circle,
  primaryColor: Colors.blue,
  onTap: () => navigateToCourse(course),
)
```

### 3. للملف الشخصي (Profile Items)
```dart
MainCard(
  imageUrl: user.avatarUrl,
  title: user.name,
  subtitle: user.role,
  fallbackIcon: Icons.person,
  enableFloating: false, // بدون طفو للملف الشخصي
  onTap: () => showUserProfile(user),
)
```

### 4. للإعدادات (Settings)
```dart
MainCard(
  imageUrl: '', // صورة فارغة لاستخدام الأيقونة
  title: 'الإعدادات',
  subtitle: 'تخصيص التطبيق',
  fallbackIcon: Icons.settings,
  primaryColor: Colors.orange,
  imageSize: 70,
  onTap: () => navigateToSettings(),
)
```

### 5. للإحصائيات (Statistics)
```dart
MainCard(
  imageUrl: '',
  title: '${stats.count}',
  subtitle: stats.label,
  fallbackIcon: Icons.analytics,
  primaryColor: Colors.green,
  enableFloating: true,
  onTap: () => showStatisticsDetail(stats),
)
```

## الحالات المختلفة

### تحميل الصورة
- **نجح التحميل**: عرض الصورة بشكل طبيعي
- **فشل التحميل**: عرض `fallbackIcon` مع خلفية متدرجة
- **جاري التحميل**: عرض loading indicator مع خلفية متدرجة

### التفاعل
- **الحالة العادية**: طفو خفيف مع ظلال كاملة
- **عند الضغط**: تقليص 92% مع ظل أصغر
- **التحرير**: العودة للحالة العادية بسلاسة

## التخصيص المتقدم

### الألوان
يمكن تخصيص الألوان باستخدام `primaryColor` أو الاعتماد على theme الرئيسي

### الأحجام
- `imageSize`: لتحديد حجم الصورة
- المساحات الداخلية ثابتة (16px) لكن يمكن تعديلها

### التأثيرات
- `enableFloating`: لتحكم في تأثير الطفو
- الانتقالات: 250ms مع `Curves.easeOutBack`

## أفضل الممارسات

1. **استخدم أيقونات مناسبة** للـ `fallbackIcon`
2. **اختر ألوان متناسقة** مع theme التطبيق
3. **اجعل النصوص قصيرة** لتجنب التقطيع
4. **استخدم `onTap`** لإضافة التفاعل
5. **اختبر في الوضعين** الفاتح والداكن

## مقارنة مع الكروت الأخرى

| الميزة | MainCard | Card عادي | Container |
|--------|----------|-----------|-----------|
| ظلال ثلاثية الأبعاد | ✅ | ❌ | ❌ |
| تأثير الطفو | ✅ | ❌ | ❌ |
| تفاعل متقدم | ✅ | محدود | ❌ |
| تدرج لوني | ✅ | ❌ | محدود |
| مرونة الاستخدام | ✅ | محدود | ✅ |

هذا التصميم يجعل `MainCard` الخيار الأمثل لجميع احتياجات الكروت في التطبيق! 🚀
