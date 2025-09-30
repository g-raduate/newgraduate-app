# حل مشكلة تحديث الكاش عند إضافة محاضرات جديدة

## المشكلة
عند إضافة محاضرة جديدة في قاعدة البيانات، لم تكن تظهر في التطبيق فوراً بسبب نظام الكاش. كان المستخدم يحتاج لإعادة تشغيل التطبيق أو تسجيل الخروج والدخول لرؤية المحاضرة الجديدة.

## الحل المطبق

### 1. تحسين إعدادات الكاش
**الملف:** `lib/services/cache_manager.dart`

```dart
// تقليل مدة انتهاء صلاحية الكاش للفيديوهات من 30 دقيقة إلى 15 دقيقة
static const int _shortCacheExpirySeconds = 900; // 15 دقيقة (تم تقليلها من 30 دقيقة)
```

**الفوائد:**
- البيانات ستُحديث تلقائياً كل 15 دقيقة بدلاً من 30 دقيقة
- تقليل الوقت اللازم لظهور المحاضرات الجديدة

### 2. إضافة دوال مسح الكاش
**الملف:** `lib/services/cache_manager.dart`

```dart
// دالة مسح كاش الفيديوهات لدورة معينة
Future<bool> clearVideosCache(String courseId) async {
  return await removeCache('course_$courseId', type: CacheType.videos);
}

// دالة مسح كاش الملخصات لدورة معينة  
Future<bool> clearSummariesCache(String courseId) async {
  return await removeCache('course_$courseId', type: CacheType.summaries);
}
```

**الفوائد:**
- إمكانية مسح الكاش بدقة لدورة محددة
- عدم الحاجة لمسح كامل الكاش

### 3. إضافة زر تحديث في واجهة تفاصيل الدورة
**الملف:** `lib/features/courses/screens/course_detail_screen.dart`

```dart
actions: [
  // زر التحديث
  IconButton(
    icon: Icon(
      Icons.refresh,
      color: Theme.of(context).colorScheme.onSurface,
    ),
    onPressed: _refreshCourseData,
    tooltip: 'تحديث البيانات',
  ),
],
```

**الفوائد:**
- تحديث فوري للبيانات عند الضغط على الزر
- واجهة سهلة ومألوفة للمستخدم

### 4. إضافة دالة التحديث الإجباري
**الملف:** `lib/features/courses/screens/course_detail_screen.dart`

```dart
/// تحديث بيانات الدورة (مسح الكاش وإعادة التحميل)
Future<void> _refreshCourseData() async {
  try {
    final courseId = widget.course['course_id']?.toString() ?? 
                     widget.course['id']?.toString();
    
    if (courseId != null) {
      print('🔄 بدء تحديث بيانات الدورة $courseId');
      
      // مسح الكاش القديم
      await CacheManager.instance.clearVideosCache(courseId);
      await CacheManager.instance.clearSummariesCache(courseId);
      print('🗑️ تم مسح الكاش للدورة $courseId');
      
      // إعادة تحميل البيانات
      await _loadCourseData();
      
      // إظهار رسالة نجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary),
                const SizedBox(width: 8),
                const Expanded(child: Text('تم تحديث البيانات بنجاح')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  } catch (e) {
    // معالجة الأخطاء...
  }
}
```

**الفوائد:**
- مسح الكاش القديم قبل التحميل
- إعادة تحميل البيانات من السيرفر
- رسائل تأكيد للمستخدم

### 5. إضافة Pull-to-Refresh
**الملف:** `lib/features/courses/screens/course_detail_screen.dart`

```dart
// محتوى الدورة
Expanded(
  child: widget.course['is_free_course'] == true
      ? RefreshIndicator(
          onRefresh: _refreshCourseData,
          child: _buildVideosTab(),
        )
      : TabBarView(
          controller: _tabController,
          children: [
            // تبويبة الفيديوهات
            RefreshIndicator(
              onRefresh: _refreshCourseData,
              child: _buildVideosTab(),
            ),
            // تبويبة الملخصات  
            RefreshIndicator(
              onRefresh: _refreshCourseData,
              child: _buildSummariesTab(),
            ),
          ],
        ),
),
```

**الفوائد:**
- السحب لأسفل لتحديث البيانات (تجربة مستخدم مألوفة)
- يعمل في جميع التبويبات
- تفاعل بديهي وسهل

### 6. تحديث دوال التحميل لدعم التحديث الإجباري
**الملف:** `lib/features/courses/screens/course_detail_screen.dart`

```dart
Future<void> _loadCourseData() async {
  await Future.wait([
    _loadVideos(forceRefresh: true),
    _loadSummaries(forceRefresh: true),
  ]);
}

Future<void> _loadSummaries({bool forceRefresh = false}) async {
  // محاولة تحميل البيانات من الكاش أولاً (إلا إذا كان التحديث إجباري)
  if (!forceRefresh) {
    // تحميل من الكاش...
  } else {
    print('🔄 تحديث إجباري للملخصات - تجاهل الكاش');
  }
  // باقي منطق التحميل...
}
```

**الفوائد:**
- مرونة في تحديد متى يتم تجاهل الكاش
- دعم التحديث الإجباري عند الحاجة

### 7. تحسين واجهة حالات التحميل والأخطاء
**الملف:** `lib/features/courses/screens/course_detail_screen.dart`

```dart
// تحويل Center إلى ListView لدعم RefreshIndicator
if (isLoadingVideos) {
  return ListView(
    children: [
      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
      const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل الفيديوهات...'),
          ],
        ),
      ),
    ],
  );
}
```

**الفوائد:**
- تتوافق مع RefreshIndicator
- تجربة مستخدم متسقة

## النتيجة

### ✅ ما تم حله:
1. **التحديث الفوري**: المحاضرات الجديدة تظهر فوراً عند استخدام زر التحديث أو Pull-to-Refresh
2. **التحديث التلقائي**: البيانات تُحديث تلقائياً كل 15 دقيقة بدلاً من 30 دقيقة
3. **تجربة المستخدم**: طرق متعددة وسهلة للتحديث (زر + سحب)
4. **استقرار النظام**: عدم الحاجة لإعادة تشغيل التطبيق أو تسجيل الخروج

### 📱 طرق التحديث المتاحة:
1. **الزر**: الضغط على أيقونة التحديث في شريط التطبيق
2. **Pull-to-Refresh**: السحب لأسفل في قائمة المحاضرات
3. **التلقائي**: التحديث كل 15 دقيقة تلقائياً
4. **إعادة المحاولة**: زر في حالة فشل التحميل

### 🔧 التحسينات التقنية:
- تقليل مدة انتهاء صلاحية الكاش
- دوال متخصصة لمسح الكاش  
- دعم التحديث الإجباري
- معالجة أفضل للأخطاء
- واجهة متجاوبة مع جميع الحالات

## الاستخدام

عند إضافة محاضرة جديدة في قاعدة البيانات، يمكن للمستخدم:

1. **الضغط على زر التحديث** (أيقونة التحديث في الأعلى)
2. **السحب لأسفل** في قائمة المحاضرات  
3. **الانتظار 15 دقيقة** للتحديث التلقائي

وستظهر المحاضرة الجديدة فوراً دون الحاجة لإعادة تشغيل التطبيق.
