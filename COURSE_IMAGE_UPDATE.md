# تحديث تصميم صورة الدورة

## التغييرات المُنفذة

### قبل التحديث:
- صورة الدورة تظهر في الخلفية
- عند عدم وجود صورة، يظهر gradient ملون
- زر التشغيل يختلف حسب وجود الصورة

### بعد التحديث:
- ✅ صورة الدورة تُستخدم دائماً كخلفية
- ✅ زر التشغيل يظهر دائماً في المنتصف
- ✅ overlay شفاف أسود خفيف لتحسين وضوح الزر
- ✅ زر تشغيل محسن بدائرة بيضاء وسهم أسود

## تفاصيل التحديث

### 1. استخدام صورة الدورة
```dart
// استخدام image_url من بيانات الدورة
image: widget.course['image_url'] != null &&
       widget.course['image_url'].toString().isNotEmpty
    ? DecorationImage(
        image: NetworkImage(widget.course['image_url']),
        fit: BoxFit.cover,
      )
    : null,
```

### 2. Overlay موحد
```dart
// overlay شفاف لتحسين وضوح الزر
gradient: widget.course['image_url'] != null &&
         widget.course['image_url'].toString().isNotEmpty
    ? LinearGradient(
        colors: [
          Colors.black.withOpacity(0.3),
          Colors.black.withOpacity(0.3),
        ],
      )
    : LinearGradient(
        // gradient ملون للحالات بدون صورة
      )
```

### 3. زر تشغيل محسن
```dart
// زر تشغيل بتصميم أنيق
Container(
  width: 80,
  height: 80,
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.9),
    shape: BoxShape.circle,
  ),
  child: Icon(
    Icons.play_arrow,
    size: 50,
    color: Colors.black87,
  ),
)
```

## النتيجة
- الآن صورة الدورة تملأ المنطقة بالكامل
- زر التشغيل واضح ومرئي على جميع الخلفيات
- تصميم موحد ومطابق للصورة المرجعية
- تجربة مستخدم محسنة
