# APIs فيديوهات الدورات المستخدمة في النظام

## نظرة عامة
هذا ملف يوثق جميع APIs المستخدمة لجلب وإدارة فيديوهات الدورات في مسار: الأقسام → الأساتذة → الدورات → الفيديوهات

## مسار الوصول للفيديوهات
```
الأقسام (departments_screen.dart)
    ↓
الأساتذة (instructors_screen.dart) 
    ↓
دورات الأستاذ (instructor_courses_screen.dart)
    ↓
تفاصيل الدورة (course_detail_screen.dart)
    ↓
الفيديوهات
```

## APIs المستخدمة

### 1. API جلب فيديوهات الدورة الرئيسي
```
GET /api/courses/{courseId}/videos/previews
```

**الاستخدام:**
- **الملف**: `lib/features/courses/screens/course_detail_screen.dart`
- **الدالة**: `_loadVideos()`
- **السطر**: 168

**الوصف:**
- يجلب جميع فيديوهات الدورة مع معاينات
- يُستخدم عندما لا توجد فيديوهات في الكاش
- يحفظ النتيجة في الكاش لاستخدام لاحق

**مثال الكود:**
```dart
final url = '${AppConstants.baseUrl}/api/courses/$courseId/videos/previews';
final headers = await ApiHeadersManager.instance.getAuthHeaders();
final response = await http.get(Uri.parse(url), headers: headers);
```

**هيكل الاستجابة المتوقعة:**
```json
// إما List مباشرة
[
  {
    "id": "video_id",
    "title": "عنوان الفيديو",
    "link": "youtube_url",
    "is_free": false,
    "is_completed": false
  }
]

// أو Map تحتوي على data
{
  "data": [
    {
      "id": "video_id", 
      "title": "عنوان الفيديو",
      // ...
    }
  ]
}
```

### 2. API تبديل حالة إكمال الفيديو
```
POST /api/videos/{videoId}/toggle
```

**الاستخدام:**
- **الملف**: `lib/features/courses/screens/course_detail_screen.dart`
- **الدالة**: `_toggleVideoCompletion()`
- **السطر**: 433

**الوصف:**
- يُبدل حالة إكمال الفيديو (مكتمل ↔ غير مكتمل)
- يُستخدم عند النقر على checkbox الفيديو
- يحدث الكاش المحلي بعد نجاح العملية

**مثال الكود:**
```dart
final String apiUrl = '${AppConstants.baseUrl}/api/videos/$videoId/toggle';
final headers = await ApiHeadersManager.instance.getAuthHeaders();
final response = await http.post(Uri.parse(apiUrl), headers: headers);
```

## خصائص النظام

### 1. إدارة الكاش الذكية
- **التحقق من الكاش أولاً**: قبل استدعاء API
- **حفظ في الكاش**: بعد نجاح API
- **تحديث إجباري**: إمكانية تجاهل الكاش

```dart
// التحقق من الكاش
List<dynamic>? cachedVideos = await CacheManager.instance.getVideos(courseId.toString());

// حفظ في الكاش
await CacheManager.instance.setVideos(courseId.toString(), finalVideos);
```

### 2. دعم دورات الطلاب
- **البيانات المُرفقة**: استخدام فيديوهات مُرسلة مع بيانات الدورة
- **التحقق الذكي**: التحقق من الكاش حتى للدورات المُرفقة

```dart
if (isStudentCourse && widget.course['videos'] != null) {
  final courseVideos = widget.course['videos'] as List<dynamic>;
  // استخدام البيانات المرفقة
}
```

### 3. معالجة الأخطاء
- **انتهاء الجلسة**: كشف وتوجيه تلقائي لصفحة تسجيل الدخول
- **إعادة المحاولة**: إمكانية إعادة تحميل الفيديوهات
- **رسائل خطأ واضحة**: للمستخدم والمطور

```dart
if (mounted && await TokenExpiredHandler.handleTokenExpiration(
  context,
  statusCode: response.statusCode,
  errorMessage: response.body,
)) {
  return; // تم التعامل مع انتهاء التوكن
}
```

## Headers المستخدمة
جميع الطلبات تستخدم Headers مُدارة مركزياً:

```dart
final headers = await ApiHeadersManager.instance.getAuthHeaders();
```

**تشمل عادة:**
- `Authorization`: Bearer token
- `Content-Type`: application/json
- `Accept`: application/json

## معرفات مهمة

### معرف الدورة
```dart
final courseId = widget.course['course_id'] ?? widget.course['id'];
```
- يُستخدم `course_id` أولاً، ثم `id` كبديل

### معرف الفيديو
```dart
final videoId = video['id'] ?? video['video_id'];
```
- يُستخدم في API تبديل الإكمال

## إحصائيات وطباعة تفصيلية

النظام يطبع معلومات مفصلة للمطورين:

```dart
print('🎥 جاري تحميل فيديوهات المعاينة من API: $url');
print('📊 استجابة الفيديوهات: ${response.statusCode}');
print('✅ تم تحميل ${finalVideos.length} فيديو من API');
print('💾 تم حفظ ${finalVideos.length} فيديو في الكاش');
```

## أمثلة عملية

### 1. تحميل فيديوهات دورة معينة
```
GET /api/courses/abc123/videos/previews
```

### 2. تبديل إكمال فيديو معين  
```
POST /api/videos/video456/toggle
```

## ملاحظات مهمة

1. **API الفيديوهات الوحيد**: يوجد API واحد فقط لجلب فيديوهات الدورة
2. **لا يوجد API منفصل للفيديوهات الكاملة**: جميع الفيديوهات تأتي من `/previews`
3. **التحديث التلقائي**: الكاش يُحدث تلقائياً عند تغيير حالة الإكمال
4. **دعم الحالات المختلفة**: دورات الطلاب والدورات العادية

## التاريخ
- **تاريخ التوثيق**: 15 سبتمبر 2025
- **الملف المرجعي**: `course_detail_screen.dart`
- **المطور**: نظام إدارة التعلم الإلكتروني
