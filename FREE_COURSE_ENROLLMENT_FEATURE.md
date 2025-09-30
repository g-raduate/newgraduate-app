# إضافة زر التسجيل في الدورات المجانية

## 📋 المطلوب
إضافة زر "إضافة الدورة" للدورات المجانية مع:
- كلمة "مجاناً" فوق الزر
- إرسال طلب التسجيل لـ API عند الضغط
- تحديث حالة الدورة لتصبح مملوكة بعد التسجيل الناجح

## 🎯 الهدف
توفير طريقة للطلاب لتسجيل أنفسهم في الدورات المجانية بدلاً من اعتبارها مملوكة افتراضياً.

## 🔧 التحديثات المنجزة

### 1. إضافة متغير حالة التحميل
**الملف:** `lib/features/courses/screens/course_detail_screen.dart`

```dart
bool _isEnrollingInFreeCourse = false; // متتبع حالة التسجيل في الدورة المجانية
```

### 2. إضافة دالة التسجيل في الدورة المجانية
```dart
Future<void> _enrollInFreeCourse() async {
  try {
    setState(() {
      _isEnrollingInFreeCourse = true;
    });

    // الحصول على student_id من SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('student_id');
    
    if (studentId == null) {
      throw Exception('لم يتم العثور على معرف الطالب');
    }

    final courseId = widget.course['course_id'] ?? widget.course['id'];
    if (courseId == null) {
      throw Exception('معرف الدورة غير متوفر');
    }

    print('🎓 بدء التسجيل في الدورة المجانية - student_id: $studentId, course_id: $courseId');

    final url = '${AppConstants.baseUrl}/api/students/$studentId/enroll-free-course';
    final headers = await ApiHeadersManager.instance.getAuthHeaders();
    
    final body = json.encode({
      'course_id': courseId.toString(),
    });

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      final success = responseData['success'] ?? false;
      final message = responseData['message'] ?? 'تم التسجيل بنجاح!';

      if (success) {
        // تحديث حالة الدورة لتصبح مملوكة
        setState(() {
          widget.course['isOwned'] = true;
        });

        // تحديث كاش دورات الطالب لإظهار الدورة الجديدة فوراً  
        await _updateStudentCoursesCache();

        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception(message);
      }
    } else {
      final responseData = json.decode(response.body);
      final errorMessage = responseData['message'] ?? 'حدث خطأ في التسجيل';
      throw Exception(errorMessage);
    }
  } catch (e) {
    // عرض رسالة خطأ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('خطأ في التسجيل: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() {
      _isEnrollingInFreeCourse = false;
    });
  }
}
```

### 4. دالة تحديث كاش دورات الطالب
```dart
/// تحديث كاش دورات الطالب بعد إضافة دورة جديدة
Future<void> _updateStudentCoursesCache() async {
  try {
    print('🔄 تحديث كاش دورات الطالب...');
    
    // إجبار تحديث دورات الطالب لإظهار الدورة الجديدة
    await CoursesService.getStudentCourses(forceRefresh: true);
    
    print('✅ تم تحديث كاش دورات الطالب بنجاح');
  } catch (e) {
    print('⚠️ خطأ في تحديث كاش دورات الطالب: $e');
    // لا نعرض رسالة خطأ للمستخدم لأن التسجيل نجح
  }
}
```

### 5. تحديث واجهة المستخدم للدورات المجانية
```dart
// للدورات المجانية: عرض "مجاناً" وزر "إضافة الدورة"
if (isFreeCourseByCourse) {
  return Column(
    children: [
      // كلمة "مجاناً"
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'مجاناً',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
            fontFamily: 'NotoKufiArabic',
          ),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 8),
      // زر إضافة الدورة
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
        child: SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            onPressed: _isEnrollingInFreeCourse ? null : _enrollInFreeCourse,
            icon: _isEnrollingInFreeCourse 
                ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                : const Icon(Icons.add_circle_outline, size: 18),
            label: Text(
              _isEnrollingInFreeCourse ? 'جاري التسجيل...' : 'إضافة الدورة',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoKufiArabic',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 3,
              shadowColor: Colors.green.withOpacity(0.3),
            ),
          ),
        ),
      ),
    ],
  );
}
```

### 6. تحديث منطق عرض الدورات المجانية
**الملف:** `lib/features/courses/screens/instructor_free_courses_screen.dart`

```dart
// إزالة isOwned = true لنعطي فرصة للطالب للتسجيل
final courseWithFreeFlag = Map<String, dynamic>.from(course);
courseWithFreeFlag['is_free_course'] = true;
// لا نضع isOwned = true هنا لنعطي فرصة للطالب للتسجيل
```

## 📡 API المستخدم

### طلب التسجيل
```http
POST /api/students/{student_id}/enroll-free-course
Content-Type: application/json
Authorization: Bearer {token}

{
  "course_id": "course-uuid"
}
```

### استجابة ناجحة
```json
{
  "success": true,
  "message": "🎉 تم تسجيلك في الدورة المجانية بنجاح!",
  "enrollment": {
    "id": "enrollment-uuid",
    "enrolled_at": "2025-09-15T10:30:00.000000Z",
    "course": {
      "id": "course-uuid",
      "title": "مقدمة في البرمجة",
      "instructor_name": "أحمد محمد",
      "instructor_specialization": "هندسة البرمجيات"
    }
  }
}
```

## 🎨 تجربة المستخدم

### قبل التسجيل:
- 🔴 **النص**: "مجاناً" (أخضر، بارز)
- 🔘 **الزر**: "إضافة الدورة" (أخضر مع أيقونة +)
- 🎬 **الفيديوهات**: المتاحة فقط (التي لها رابط)

### أثناء التسجيل:
- ⏳ **الزر**: "جاري التسجيل..." (مع مؤشر تحميل)
- 🚫 **التفاعل**: الزر معطل حتى انتهاء العملية

### بعد التسجيل الناجح:
- ✅ **رسالة نجاح**: "🎉 تم تسجيلك في الدورة المجانية بنجاح!"
- 🔄 **تحديث الحالة**: `isOwned = true`
- 👻 **الزر**: يختفي (لأن الدورة أصبحت مملوكة)
- 🎬 **الفيديوهات**: جميعها متاحة مع checkbox للتتبع

### عند حدوث خطأ:
- ❌ **رسالة خطأ**: تفاصيل الخطأ من السيرفر
- 🔄 **الزر**: يعود لحالته الطبيعية للمحاولة مرة أخرى

## 🧪 اختبار التحديثات
1. انتقل إلى "أساتذة الدورات المجانية"
2. اختر أي أستاذ
3. ادخل على دورة مجانية لم تسجل بها من قبل
4. تحقق من:
   - ظهور كلمة "مجاناً" أعلى الزر
   - ظهور زر "إضافة الدورة" باللون الأخضر
   - عند الضغط يظهر "جاري التسجيل..." مع مؤشر التحميل
   - بعد النجاح: رسالة نجاح + اختفاء الزر + ظهور جميع الفيديوهات كمتاحة

## 📝 ملاحظات تقنية
- يتم حفظ `student_id` في SharedPreferences
- الدالة تتعامل مع أخطاء الشبكة والسيرفر
- التحديث يحافظ على التوافق مع الدورات المدفوعة
- الواجهة متجاوبة مع حالات التحميل والأخطاء
- **تم حل مشكلة عدم ظهور الدورة في قائمة "دوراتك"**: الآن يتم تحديث الكاش فوراً بعد التسجيل الناجح

## 🔧 تحديث الكاش التلقائي
بعد إضافة الدورة المجانية بنجاح، يتم:
1. **مسح الكاش القديم**: إزالة قائمة دورات الطالب المحفوظة
2. **إعادة التحميل**: جلب قائمة محدثة تتضمن الدورة الجديدة  
3. **التحديث الفوري**: الدورة تظهر في قائمة "دوراتك" بدون الحاجة لتسجيل خروج/دخول

هذا يضمن أن المستخدم يرى الدورة فوراً في قائمة دوراته بعد التسجيل الناجح.
