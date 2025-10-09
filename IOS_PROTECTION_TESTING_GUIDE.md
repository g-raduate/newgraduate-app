# دليل الاختبار السريع - iOS Privacy Protection

## 🎯 الهدف
التأكد من عمل جميع طرق الحماية على iPhone بشكل صحيح

---

## ⚠️ متطلبات الاختبار

### ضروري:
- ✅ جهاز iPhone حقيقي (ليس محاكي)
- ✅ iOS 11.0 أو أحدث
- ✅ `underDevelopment = false` أو `underDevelopmentOverride = null`
- ✅ التطبيق مبني بوضع Debug أو Release

### اختياري للاختبار الكامل:
- Apple TV أو Mac (لاختبار Screen Mirroring)
- QuickTime Player على Mac (لاختبار Recording)

---

## 📋 قائمة الاختبارات (Checklist)

### ✅ **Test 1: Screen Recording Protection**
**الخطوات:**
1. افتح التطبيق واذهب لأي صفحة تحتوي محتوى حساس
2. افتح Control Center (اسحب من الأعلى/الأسفل)
3. اضغط على زر Screen Recording ⏺️
4. انتظر 3 ثواني
5. أوقف التسجيل
6. افتح تطبيق Photos وشاهد الفيديو

**النتيجة المتوقعة:**
- ✅ الفيديو يعرض شاشة سوداء فقط
- ✅ لا يظهر أي محتوى من التطبيق
- ✅ Console logs تعرض: `📱 iOS Privacy Guard: Screen capture state changed: true`

**إذا فشل:**
- تأكد من `underDevelopment = false`
- تحقق من `IOSPrivacyGuardPlugin` مسجل في AppDelegate
- راجع Console logs

---

### ✅ **Test 2: Screenshot Protection**
**الخطوات:**
1. افتح التطبيق واذهب لصفحة محتوى حساس
2. اضغط Volume Up + Power Button معاً (أو Side Button + Volume Up)
3. افتح تطبيق Photos
4. افتح آخر صورة

**النتيجة المتوقعة:**
- ✅ الصورة تحتوي على شاشة سوداء/مموّهة
- ✅ لا يظهر المحتوى الحقيقي بوضوح
- ✅ Console logs تعرض: `📸 iOS Privacy Guard: Screenshot detected!`

**ملاحظة:**
- قد يظهر blur خفيف بدل السواد الكامل (حسب توقيت الالتقاط)
- هذا طبيعي لأن iOS لا يمنع Screenshot نظامياً

---

### ✅ **Test 3: App Switcher Protection**
**الخطوات:**
1. افتح التطبيق واذهب لصفحة محتوى حساس
2. اسحب من أسفل الشاشة للأعلى وتوقف في المنتصف (iPhone X+)
   - أو اضغط Home Button مرتين (iPhone 8 وأقدم)
3. انظر إلى معاينة التطبيق في App Switcher

**النتيجة المتوقعة:**
- ✅ معاينة التطبيق تظهر شاشة سوداء/مموّهة
- ✅ لا يظهر المحتوى الحساس في المعاينة
- ✅ Console logs تعرض: `⬇️ iOS Privacy Guard: App going to background`

**عند العودة للتطبيق:**
- ✅ الطبقة السوداء تختفي تلقائياً
- ✅ Console logs: `⬆️ iOS Privacy Guard: App coming to foreground`

---

### ✅ **Test 4: Combined Test (Recording + App Switcher)**
**الخطوات:**
1. ابدأ Screen Recording
2. افتح التطبيق
3. افتح App Switcher
4. ارجع للتطبيق
5. أوقف Recording
6. شاهد الفيديو

**النتيجة المتوقعة:**
- ✅ كل الفيديو أسود
- ✅ معاينة App Switcher سوداء في الفيديو
- ✅ لا يظهر أي محتوى في أي لحظة

---

### ✅ **Test 5: Multiple Screenshots (Stress Test)**
**الخطوات:**
1. افتح التطبيق
2. خذ 5 لقطات شاشة متتالية بسرعة
3. افتح Photos وتفقد الصور

**النتيجة المتوقعة:**
- ✅ جميع الصور محمية
- ✅ لا crash أو lag
- ✅ Console logs تعرض 5 مرات: `📸 Screenshot detected!`

---

### 🔄 **Test 6: Protection Toggle (Optional)**
**الخطوات:**
1. في الكود، غيّر `underDevelopmentOverride = true`
2. أعد تشغيل التطبيق
3. حاول التسجيل/Screenshot

**النتيجة المتوقعة:**
- ✅ التسجيل يعمل عادياً (بدون حماية)
- ✅ Screenshots تعرض المحتوى الحقيقي
- ✅ Console logs: `⚠️ iOS Privacy Guard: Protection disabled`

**ثم:**
4. أرجع `underDevelopmentOverride = false` أو `null`
5. أعد التشغيل
6. اختبر مرة أخرى

**النتيجة المتوقعة:**
- ✅ الحماية تعود للعمل
- ✅ Console logs: `✅ iOS Privacy Guard: Protection enabled`

---

### 📱 **Test 7: Screen Mirroring (إذا كان لديك Apple TV)**
**الخطوات:**
1. وصّل iPhone بـ Apple TV عبر AirPlay
2. فعّل Screen Mirroring
3. افتح التطبيق على iPhone
4. انظر للشاشة الكبيرة

**النتيجة المتوقعة:**
- ✅ الشاشة الكبيرة تعرض سواد
- ✅ iPhone نفسه يعمل عادياً (اختياري حسب التطبيق)
- ✅ Console logs: `📱 Screen capture state changed: true`

---

### 💻 **Test 8: QuickTime Recording (إذا كان لديك Mac)**
**الخطوات:**
1. وصّل iPhone بـ Mac
2. افتح QuickTime Player
3. File → New Movie Recording
4. اختر iPhone كمصدر
5. ابدأ التسجيل
6. افتح التطبيق على iPhone
7. أوقف التسجيل وشاهد الفيديو

**النتيجة المتوقعة:**
- ✅ الفيديو يعرض شاشة سوداء للتطبيق
- ✅ Console logs: `📱 Screen capture state changed: true`

---

## 🔍 استكشاف الأخطاء (Troubleshooting)

### ❌ **Problem: الحماية لا تعمل أبداً**

**Solution:**
```dart
// 1. تأكد من إعدادات التطوير
// في app_constants.dart أو runtime_config
underDevelopmentOverride = null  // أو false

// 2. تحقق من Console logs
// يجب أن ترى:
✅ iOS Privacy Guard Plugin registered successfully
✅ iOS Privacy Guard: تم تفعيل جميع الحمايات

// 3. تأكد من تشغيل على جهاز حقيقي
// المحاكي لا يدعم isCaptured API
```

---

### ❌ **Problem: الحماية تعمل لكن الشاشة تبقى سوداء**

**Solution:**
```dart
// يحدث أحياناً إذا لم يتم إزالة الـ overlay
// في IOSPrivacyGuard.swift تحقق من:

private func hideProtectionOverlay() {
  blurView?.removeFromSuperview()
  blurView = nil
  
  // إضافة هذا السطر للتأكيد
  mainWindow?.subviews.filter { $0.tag == 999999 }.forEach { $0.removeFromSuperview() }
}
```

---

### ❌ **Problem: Screenshot تعرض المحتوى أحياناً**

**Explanation:**
- هذا طبيعي لأن iOS لا يمنع Screenshot نظامياً
- الحماية تعتمد على سرعة استجابة الـ notification
- في 90% من الحالات ستكون محمية

**Workaround للمحتوى الحساس جداً:**
```dart
// استخدم DRM للفيديوهات المدفوعة
// FairPlay Streaming على iOS
// هذا يمنع التسجيل على مستوى OS نفسه
```

---

### ❌ **Problem: App Switcher يعرض محتوى للحظة**

**Solution:**
```swift
// في IOSPrivacyGuard.swift
// تأكد من استخدام willResignActiveNotification
// وليس didEnterBackgroundNotification

backgroundObserver = NotificationCenter.default.addObserver(
  forName: UIApplication.willResignActiveNotification,  // ← هذا الصحيح
  ...
)
```

---

### ❌ **Problem: Console Logs لا تظهر**

**Solution:**
1. افتح Xcode
2. Window → Devices and Simulators
3. اختر جهازك
4. اضغط على Open Console
5. Filter: `iOS Privacy Guard`

---

## 📊 نتائج الاختبار المتوقعة

### ✅ **All Tests Pass:**
```
✅ Test 1: Screen Recording      → PASS
✅ Test 2: Screenshot            → PASS
✅ Test 3: App Switcher          → PASS
✅ Test 4: Combined              → PASS
✅ Test 5: Multiple Screenshots  → PASS
✅ Test 6: Protection Toggle     → PASS
✅ Test 7: Screen Mirroring      → PASS (optional)
✅ Test 8: QuickTime Recording   → PASS (optional)

النتيجة النهائية: ✅ النظام يعمل بشكل مثالي
```

### ⚠️ **Partial Pass:**
```
✅ Test 1: Screen Recording      → PASS
⚠️ Test 2: Screenshot            → PARTIAL (1-2 من 5 تعرض محتوى)
✅ Test 3: App Switcher          → PASS
✅ Test 4: Combined              → PASS
✅ Test 5: Multiple Screenshots  → PARTIAL
⚠️ Test 6: Protection Toggle     → SKIP
❌ Test 7: Screen Mirroring      → SKIP (no device)
❌ Test 8: QuickTime Recording   → SKIP (no Mac)

النتيجة النهائية: ⚠️ النظام يعمل لكن Screenshot غير موثوق 100%
تفسير: هذا طبيعي لقيود iOS - الحماية من Screenshot جزئية
```

### ❌ **Tests Fail:**
```
❌ Test 1: Screen Recording      → FAIL
❌ Test 2: Screenshot            → FAIL
❌ Test 3: App Switcher          → FAIL

النتيجة النهائية: ❌ مشكلة في التنفيذ
الحل: راجع Troubleshooting أعلاه
```

---

## 📝 تقرير الاختبار (Test Report Template)

```markdown
## iOS Privacy Protection - Test Report

**التاريخ:** [التاريخ]
**المختبر:** [الاسم]
**الجهاز:** iPhone [الموديل] - iOS [الإصدار]
**Build:** [Debug/Release]

### نتائج الاختبار:
- [ ] Test 1: Screen Recording - [PASS/FAIL]
- [ ] Test 2: Screenshot - [PASS/PARTIAL/FAIL]
- [ ] Test 3: App Switcher - [PASS/FAIL]
- [ ] Test 4: Combined - [PASS/FAIL]
- [ ] Test 5: Stress Test - [PASS/FAIL]
- [ ] Test 6: Toggle - [PASS/SKIP]
- [ ] Test 7: Mirroring - [PASS/SKIP]
- [ ] Test 8: QuickTime - [PASS/SKIP]

### الملاحظات:
[أي ملاحظات أو مشاكل]

### التوصية:
[ ] ✅ جاهز للإنتاج
[ ] ⚠️ يحتاج تحسينات بسيطة
[ ] ❌ غير جاهز - يحتاج إصلاحات
```

---

## 🚀 بعد الاختبار الناجح

### للنشر (Production):
1. ✅ تأكد أن جميع الاختبارات PASS
2. ✅ غيّر `underDevelopmentOverride = null` أو `false`
3. ✅ بناء Release Build
4. ✅ اختبر مرة أخيرة على جهاز حقيقي
5. ✅ ارفع على App Store

### للمراقبة:
```dart
// أضف analytics لمراقبة محاولات التسجيل
_iosChannel.setMethodCallHandler((call) {
  if (call.method == 'onScreenCaptureStarted') {
    // أرسل حدث للـ analytics
    logEvent('screen_recording_detected');
  }
});
```

---

**آخر تحديث:** 2025-01-09  
**الحالة:** ✅ جاهز للاختبار  
**المدة المتوقعة:** 15-20 دقيقة (للاختبارات الأساسية)
