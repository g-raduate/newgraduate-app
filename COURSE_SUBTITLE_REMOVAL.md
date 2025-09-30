# إزالة الوصف من عرض الدورات

## التغييرات المطبقة

### الملفات المحدثة:

#### 1. `lib/features/courses/screens/instructor_free_courses_screen.dart`
تم إزالة الـ `subtitle` من عرض الدورات المجانية للأستاذ.

**قبل التعديل:**
```dart
return MainCard(
  imageUrl: course['image_url']?.toString() ?? 'https://...',
  title: course['name']?.toString() ?? course['title']?.toString() ?? 'دورة مجانية',
  subtitle: '${widget.instructorName} • ${course['lectures_count'] ?? '0'} محاضرة',
  fallbackIcon: Icons.school,
  onTap: () { ... }
);
```

**بعد التعديل:**
```dart
return MainCard(
  imageUrl: course['image_url']?.toString() ?? 'https://...',
  title: course['name']?.toString() ?? course['title']?.toString() ?? 'دورة مجانية',
  fallbackIcon: Icons.school,
  onTap: () { ... }
);
```

#### 2. `lib/features/instructors/screens/instructor_courses_screen.dart`
تم إزالة الـ `subtitle` من عرض الدورات العادية للأستاذ.

**قبل التعديل:**
```dart
return DepartmentCard(
  imageUrl: course['image_url'] ?? '',
  title: course['title'] ?? 'دورة بدون عنوان',
  subtitle: course['description'] ?? '',
  promoVideoUrl: course['promo_video_url'],
  onTap: () { ... }
);
```

**بعد التعديل:**
```dart
return DepartmentCard(
  imageUrl: course['image_url'] ?? '',
  title: course['title'] ?? 'دورة بدون عنوان',
  promoVideoUrl: course['promo_video_url'],
  onTap: () { ... }
);
```

## النتيجة

✅ **تم إزالة الوصف من جميع عروض الدورات**
✅ **الآن تظهر الدورات بعنوانها فقط بدون نص إضافي**
✅ **التصميم أصبح أكثر نظافة ووضوحاً**
✅ **تم حل مشكلة overflow المحتملة أيضاً**

## ملاحظات

- الملفات التي تعرض **الأساتذة** (مثل free_courses_screen.dart) تم تركها كما هي لأنها تعرض معلومات الأساتذة وليس الدورات
- هذا التغيير يجعل واجهة المستخدم أبسط وأكثر تركيزاً على العناوين الرئيسية للدورات

---
**تاريخ التحديث:** 16 سبتمبر 2025
**الحالة:** ✅ مكتمل
