// استخدم هذا الكود لاختبار نظام الأمان في أي مكان في التطبيق

/*
استيراد الـ tester:
import 'package:newgraduate/utils/security_tester.dart';

ثم في أي دالة أو زر:

// لاختبار عرض تحذير وضع المطور
SecurityTester.forceShowDeveloperWarning(context);

// لاختبار عرض الشاشة السوداء  
SecurityTester.forceShowBlackScreen(context);

// لاختبار فحص وضع المطور مباشرة
await SecurityTester.testDeveloperModeCheck(context);

*/

// مثال: إضافة زر اختبار في شاشة معينة
/*
ElevatedButton(
  onPressed: () {
    SecurityTester.forceShowDeveloperWarning(context);
  },
  child: Text('اختبار تحذير وضع المطور'),
),

ElevatedButton(
  onPressed: () {
    SecurityTester.forceShowBlackScreen(context);
  },
  child: Text('اختبار الشاشة السوداء'),
),
*/