# نظام التحقق من البريد الإلكتروني - Email Verification System

تم تنفيذ نظام شامل للتحقق من البريد الإلكتروني في تطبيق خريج يتضمن جميع الميزات المطلوبة.

## الميزات المنفذة ✅

### 1. خدمات API (Services)
- **EmailVerificationService**: إدارة جميع عمليات التحقق من البريد
- **InstitutesService**: جلب قائمة المعاهد المتاحة للتسجيل

### 2. واجهات المستخدم (UI Components)
- **صفحة التسجيل المحدثة**: تتضمن جميع الحقول المطلوبة
- **شريط تنبيه التحقق**: EmailVerificationBanner
- **صفحة التحقق المطلوب**: VerificationRequiredPage
- **حماية المسارات**: EmailVerificationGuard & RouteGuard

### 3. تحديثات النظام (System Updates)
- **AuthController**: دعم التسجيل والتحقق من البريد
- **AuthRepository**: طرق API الجديدة للتسجيل والتحقق

## الاستخدام Usage

### 1. تسجيل طالب جديد
```dart
final authController = Provider.of<AuthController>(context);

final success = await authController.register(
  name: "أحمد محمد",
  email: "ahmed@example.com", 
  password: "123456",
  phone: "0501234567",
  instituteId: "معرف_المعهد",
);
```

### 2. عرض شريط التحقق
```dart
// في أي صفحة تريد عرض شريط التحقق
EmailVerificationBanner(
  userEmail: userEmail,
  onVerified: () {
    // تم التحقق بنجاح
    print('تم تأكيد البريد الإلكتروني');
  },
)
```

### 3. حماية المسارات
```dart
// حماية صفحة معينة
EmailVerificationGuard(
  child: CoursesPage(),
  requireVerification: true,
)

// أو استخدام ProtectedRoute
ProtectedRoute(
  child: ProfilePage(),
  showBanner: true, // إظهار شريط التحقق
)
```

### 4. التنقل مع التحقق
```dart
// التنقل مع فحص التحقق تلقائياً
RouteGuard.navigateWithVerificationCheck(
  context,
  '/courses',
  CoursesPage(),
  requireVerification: true,
);
```

## API Endpoints المدعومة

### تسجيل الطلاب
```http
POST /api/auth/register
Content-Type: application/json

{
  "name": "أحمد محمد",
  "email": "ahmed@example.com",
  "password": "123456",
  "role": "student",
  "institute_id": "معرف_المعهد",
  "phone": "0501234567"
}
```

### إرسال بريد التحقق
```http
POST /api/email/verify/send
Content-Type: application/json
Authorization: Bearer <token>

{
  "email": "ahmed@example.com"
}
```

### فحص حالة التحقق
```http
POST /api/email/verify/status
Content-Type: application/json
Authorization: Bearer <token>

{
  "email": "ahmed@example.com"
}
```

### التحقق عبر الرابط
```http
GET /api/verify-email/{token}
```

### جلب المعاهد (بدون توكن)
```http
GET /api/institutes/all
# ملاحظة: هذا الـ endpoint لا يحتاج لـ Authorization header
# يمكن الوصول إليه من صفحة التسجيل بدون تسجيل دخول
```

## قواعد التحقق (Validation Rules)

### للطلاب الجدد:
- **الاسم**: مطلوب، 2-150 حرف
- **البريد الإلكتروني**: مطلوب، تنسيق صحيح، فريد، أقل من 200 حرف
- **كلمة المرور**: مطلوب، 6 أحرف على الأقل
- **رقم الهاتف**: مطلوب، فريد، أقل من 30 حرف
- **المعهد**: مطلوب، يجب أن يكون موجود في النظام

## الملفات المنشأة/المحدثة

### الملفات الجديدة:
```
lib/
├── services/
│   ├── email_verification_service.dart    # خدمة التحقق من البريد
│   └── institutes_service.dart            # خدمة المعاهد
├── widgets/
│   └── email_verification_banner.dart     # شريط تنبيه التحقق
├── features/auth/screens/
│   ├── verification_required_page.dart    # صفحة التحقق المطلوب
│   └── signup_screen.dart                 # صفحة التسجيل المحدثة
└── utils/
    └── route_guard.dart                   # حماية المسارات
```

### الملفات المحدثة:
```
lib/features/auth/
├── state/auth_controller.dart             # دعم التسجيل والتحقق
└── data/auth_repository.dart              # طرق API جديدة
```

## أمثلة الاستخدام في الصفحات

### 1. الصفحة الرئيسية
```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProtectedRoute(
      showBanner: true, // إظهار شريط التحقق
      child: Scaffold(
        appBar: AppBar(title: Text('الصفحة الرئيسية')),
        body: Column(
          children: [
            // محتوى الصفحة
            Consumer<AuthController>(
              builder: (context, auth, _) {
                if (auth.isEmailVerified) {
                  return Text('البريد مؤكد ✅');
                }
                return EmailVerificationBanner(
                  userEmail: auth.userEmail ?? '',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### 2. صفحة الكورسات (محمية)
```dart
class CoursesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmailVerificationGuard(
      requireVerification: true,
      child: Scaffold(
        appBar: AppBar(title: Text('الكورسات')),
        body: CoursesContent(),
      ),
    );
  }
}
```

### 3. التنقل من القائمة
```dart
ListTile(
  leading: Icon(Icons.school),
  title: Text('كورساتي'),
  onTap: () {
    RouteGuard.navigateWithVerificationCheck(
      context,
      '/courses',
      CoursesPage(),
    );
  },
)
```

## ملاحظات هامة

### 1. للمطورين:
- يجب إضافة `Provider` للـ AuthController في main.dart
- تأكد من وجود جميع dependencies في pubspec.yaml
- اختبر جميع سيناريوهات التحقق

### 2. للتكامل مع Backend:
- تأكد من أن API endpoints تعمل بشكل صحيح
- راجع تنسيق الاستجابات وتطابقها مع الكود
- فحص حالات الخطأ والاستثناءات

### 3. تجربة المستخدم:
- النظام يدعم إعادة الإرسال التلقائي
- رسائل خطأ واضحة ومفهومة
- واجهة سهلة الاستخدام باللغة العربية

## التحسينات المستقبلية

1. **إضافة Timer**: عداد تنازلي لإعادة الإرسال
2. **Offline Support**: حفظ حالة التحقق محلياً
3. **Push Notifications**: إشعارات عند تأكيد البريد
4. **Multiple Languages**: دعم لغات إضافية
5. **Analytics**: تتبع معدلات التحقق

## استكشاف الأخطاء

### مشاكل شائعة:
1. **خطأ في API**: تحقق من الـ base URL في AppConstants
2. **مشكلة في التحقق**: راجع format استجابة API
3. **عدم عرض الشريط**: تأكد من Provider setup
4. **مشاكل التنقل**: فحص RouteGuard logic

### حلول سريعة:
```dart
// إعادة تعيين حالة التحقق يدوياً
authController.setEmailVerified(false);

// إرسال بريد التحقق يدوياً
await authController.sendEmailVerification();

// فحص الحالة يدوياً
final isVerified = await authController.checkEmailVerificationStatus();
```

هذا النظام جاهز للاستخدام ويوفر تجربة مستخدم متكاملة للتحقق من البريد الإلكتروني في تطبيق خريج.
