import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const String kWhatsAppNumber = '+9647748687725';

Future<void> _launchWhatsApp(BuildContext context, String message) async {
  final encoded = Uri.encodeComponent(message);
  final Uri whatsappUri = Uri.parse(
      'https://api.whatsapp.com/send?phone=$kWhatsAppNumber&text=$encoded');
  try {
    final ok = await launchUrl(whatsappUri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح واتساب. الرسالة:\n$message')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح واتساب. الرسالة:\n$message')));
    }
  }
}

void showResearchContactSheet(BuildContext context,
    {required String degree, bool isPhd = false}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      int selection = 0; // 0 fill,1 title only,2 no idea
      final student = TextEditingController();
      final title = TextEditingController();
      final field = TextEditingController();
      final objective = TextEditingController();
      final methodology = TextEditingController();
      final notes = TextEditingController();
      final due = TextEditingController();
      final expectedContribution = TextEditingController();

      return StatefulBuilder(builder: (context, setState) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Center(
                      child: Text('تواصل عبر واتساب',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))),
                  RadioListTile<int>(
                      value: 0,
                      groupValue: selection,
                      onChanged: (v) => setState(() => selection = v ?? 0),
                      title: const Text('ملء النموذج')),
                  RadioListTile<int>(
                      value: 1,
                      groupValue: selection,
                      onChanged: (v) => setState(() => selection = v ?? 1),
                      title: const Text('لدي عنوان فقط')),
                  RadioListTile<int>(
                      value: 2,
                      groupValue: selection,
                      onChanged: (v) => setState(() => selection = v ?? 2),
                      title: const Text('لا أملك فكرة حالياً')),
                  const SizedBox(height: 8),
                  if (selection == 0) ...[
                    const Text('اسم الطالب'),
                    TextField(
                        controller: student,
                        decoration: InputDecoration(
                            hintText: 'مثال: أحمد علي',
                            hintStyle:
                                TextStyle(color: Theme.of(context).hintColor))),
                    const SizedBox(height: 8),
                    const Text('عنوان البحث المقترح'),
                    TextField(
                        controller: title,
                        decoration: InputDecoration(
                            hintText:
                                'مثال: الكشف المبكر عن حرائق الغابات باستخدام رؤية حاسوبية',
                            hintStyle:
                                TextStyle(color: Theme.of(context).hintColor))),
                    const SizedBox(height: 8),
                    const Text('المجال/التخصص'),
                    TextField(
                        controller: field,
                        decoration: InputDecoration(
                            hintText: 'مثال: ذكاء اصطناعي/اتصالات/طاقة',
                            hintStyle:
                                TextStyle(color: Theme.of(context).hintColor))),
                    const SizedBox(height: 8),
                    const Text('الهدف/المشكلة'),
                    TextField(
                        controller: objective,
                        maxLines: 2,
                        decoration: InputDecoration(
                            hintStyle:
                                TextStyle(color: Theme.of(context).hintColor))),
                    const SizedBox(height: 8),
                    const Text('المنهجية/الأدوات المتوقعة'),
                    TextField(
                        controller: methodology,
                        decoration: InputDecoration(
                            hintText:
                                'مثال: مراجعة أدبيات، تجارب مخبرية، خوارزميات ML',
                            hintStyle:
                                TextStyle(color: Theme.of(context).hintColor))),
                    const SizedBox(height: 8),
                    const Text('الموعد النهائي/تاريخ التسليم (اختياري)'),
                    TextField(
                        controller: due,
                        decoration: InputDecoration(
                            hintText: 'مثال: 2025-10-01',
                            hintStyle:
                                TextStyle(color: Theme.of(context).hintColor))),
                    const SizedBox(height: 8),
                    if (isPhd) ...[
                      const Text('الإسهام العلمي المتوقع'),
                      TextField(
                          controller: expectedContribution,
                          decoration: InputDecoration(
                              hintText: 'مثال: تحسين 15% على SOTA في دقة الكشف',
                              hintStyle: TextStyle(
                                  color: Theme.of(context).hintColor))),
                      const SizedBox(height: 8),
                    ],
                    const Text('ملاحظات إضافية (اختياري)'),
                    TextField(
                        controller: notes,
                        decoration: InputDecoration(
                            hintStyle:
                                TextStyle(color: Theme.of(context).hintColor))),
                  ] else if (selection == 1) ...[
                    const Text('عنوان البحث'),
                    TextField(
                        controller: title,
                        decoration: InputDecoration(
                            hintText:
                                'مثال: الكشف المبكر عن حرائق الغابات باستخدام رؤية حاسوبية',
                            hintStyle:
                                TextStyle(color: Theme.of(context).hintColor))),
                  ] else ...[
                    const Text('لن تحتاج لإدخال أي معلومات الآن.'),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('إلغاء'))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            String message = '';
                            if (selection == 2) {
                              message =
                                  'مرحبا 👋\nأنا طالب $degree لا أملك فكرة بحث حالياً، أرجو مساعدتكم باقتراحات مناسبة.\n\n— تم الإرسال من تطبيق خريج';
                            } else if (selection == 1) {
                              final t = title.text.trim();
                              message =
                                  'مرحبا 👋\nلدي عنوان بحث للدرجة $degree وأحتاج مساعدة في التفاصيل.\n\nعنوان البحث: ${t.isEmpty ? '(لم يُدخل عنوان)' : t}\n\n— تم الإرسال من تطبيق خريج';
                            } else {
                              final s = student.text.trim();
                              final t = title.text.trim();
                              final f = field.text.trim();
                              final o = objective.text.trim();
                              final m = methodology.text.trim();
                              final n = notes.text.trim();
                              final d = due.text.trim();
                              final contrib = expectedContribution.text.trim();
                              message =
                                  'مرحبا 👋\nأرغب بالتواصل حول بحث تخرج (الدرجة: $degree).\n\n';
                              message +=
                                  'اسم الطالب: ${s.isEmpty ? '(غير محدد)' : s}\n';
                              message +=
                                  'عنوان البحث المقترح: ${t.isEmpty ? '(غير محدد)' : t}\n';
                              message +=
                                  'المجال/التخصص: ${f.isEmpty ? '(غير محدد)' : f}\n';
                              message +=
                                  'الهدف/المشكلة: ${o.isEmpty ? '(غير محدد)' : o}\n';
                              message +=
                                  'المنهجية/الأدوات المتوقعة: ${m.isEmpty ? '(غير محدد)' : m}\n';
                              if (d.isNotEmpty) {
                                message += 'الموعد النهائي: $d\n';
                              }
                              if (isPhd && contrib.isNotEmpty) {
                                message += 'الإسهام العلمي المتوقع: $contrib\n';
                              }
                              message +=
                                  'ملاحظات: ${n.isEmpty ? '(لا توجد)' : n}\n\n— تم الإرسال من تطبيق خريج';
                            }

                            Navigator.of(context).pop();
                            _launchWhatsApp(context, message);
                          },
                          child: const Text('إرسال'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      });
    },
  );
}

void showSeminarContactSheet(BuildContext context, {required String degree}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) {
      int selection = 0;
      final student = TextEditingController();
      final title = TextEditingController();
      final topics = TextEditingController();
      final duration = TextEditingController();
      final media = TextEditingController();

      return StatefulBuilder(builder: (context, setState) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Center(
                    child: Text('تواصل عبر واتساب',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                RadioListTile<int>(
                    value: 0,
                    groupValue: selection,
                    onChanged: (v) => setState(() => selection = v ?? 0),
                    title: const Text('ملء النموذج')),
                RadioListTile<int>(
                    value: 1,
                    groupValue: selection,
                    onChanged: (v) => setState(() => selection = v ?? 1),
                    title: const Text('لدي عنوان فقط')),
                RadioListTile<int>(
                    value: 2,
                    groupValue: selection,
                    onChanged: (v) => setState(() => selection = v ?? 2),
                    title: const Text('لا أملك فكرة حالياً')),
                const SizedBox(height: 8),
                if (selection == 0) ...[
                  const Text('اسم الطالب'),
                  TextField(
                      controller: student,
                      decoration: InputDecoration(
                          hintText: 'مثال: أحمد علي',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor))),
                  const SizedBox(height: 8),
                  const Text('عنوان الندوة المقترح'),
                  TextField(
                      controller: title,
                      decoration: InputDecoration(
                          hintText: 'مثال: مقدمة في الرؤية الحاسوبية',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor))),
                  const SizedBox(height: 8),
                  const Text('المحاور الرئيسية'),
                  TextField(
                      controller: topics,
                      decoration: InputDecoration(
                          hintText: 'مثال: مقدمة، منهجية، نتائج',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor))),
                  const SizedBox(height: 8),
                  const Text('المدة المتوقعة'),
                  TextField(
                      controller: duration,
                      decoration: InputDecoration(
                          hintText: 'مثال: 15 دقيقة',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor))),
                  const SizedBox(height: 8),
                  const Text('الوسائط المستخدمة'),
                  TextField(
                      controller: media,
                      decoration: InputDecoration(
                          hintText: 'شرائح/فيديو/عرض مباشر',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor))),
                ] else if (selection == 1) ...[
                  const Text('عنوان الندوة'),
                  TextField(
                      controller: title,
                      decoration: const InputDecoration(
                          hintText: 'مثال: مقدمة في الرؤية الحاسوبية')),
                ] else ...[
                  const Text('لن تحتاج لإدخال أي معلومات الآن.'),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('إلغاء'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () {
                            String message = '';
                            if (selection == 2) {
                              message =
                                  'مرحبا 👋\nأنا طالب $degree لا أملك فكرة لتنظيم ندرة/سمنار حالياً، أرجو مساعدتكم باقتراحات مناسبة.\n\n— تم الإرسال من تطبيق خريج';
                            } else if (selection == 1) {
                              final t = title.text.trim();
                              message =
                                  'مرحبا 👋\nلدي عنوان لندوة للدرجة $degree وأحتاج مساعدة في التفاصيل.\n\nعنوان الندوة: ${t.isEmpty ? '(لم يُدخل عنوان)' : t}\n\n— تم الإرسال من تطبيق خريج';
                            } else {
                              final s = student.text.trim();
                              final t = title.text.trim();
                              final top = topics.text.trim();
                              final dur = duration.text.trim();
                              final med = media.text.trim();
                              message =
                                  'مرحبا 👋\nأرغب بتنظيم سمنار (الدرجة: $degree).\n\n';
                              message +=
                                  'اسم الطالب: ${s.isEmpty ? '(غير محدد)' : s}\n';
                              message +=
                                  'عنوان الندوة: ${t.isEmpty ? '(غير محدد)' : t}\n';
                              message +=
                                  'المحاور الرئيسية: ${top.isEmpty ? '(غير محدد)' : top}\n';
                              message +=
                                  'المدة المتوقعة: ${dur.isEmpty ? '(غير محدد)' : dur}\n';
                              message +=
                                  'الوسائط: ${med.isEmpty ? '(غير محدد)' : med}\n\n— تم الإرسال من تطبيق خريج';
                            }
                            Navigator.of(context).pop();
                            _launchWhatsApp(context, message);
                          },
                          child: const Text('إرسال'))),
                ]),
                const SizedBox(height: 12),
              ]),
            ),
          ),
        );
      });
    },
  );
}

void showReportContactSheet(BuildContext context, {required String degree}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) {
      int selection = 0;
      final student = TextEditingController();
      final topic = TextEditingController();
      final scope = TextEditingController();
      final pages = TextEditingController();
      final due = TextEditingController();

      return StatefulBuilder(builder: (context, setState) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Center(
                    child: Text('تواصل عبر واتساب',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                RadioListTile<int>(
                    value: 0,
                    groupValue: selection,
                    onChanged: (v) => setState(() => selection = v ?? 0),
                    title: const Text('ملء النموذج')),
                RadioListTile<int>(
                    value: 1,
                    groupValue: selection,
                    onChanged: (v) => setState(() => selection = v ?? 1),
                    title: const Text('لدي موضوع فقط')),
                RadioListTile<int>(
                    value: 2,
                    groupValue: selection,
                    onChanged: (v) => setState(() => selection = v ?? 2),
                    title: const Text('لا أملك فكرة حالياً')),
                const SizedBox(height: 8),
                if (selection == 0) ...[
                  const Text('اسم الطالب'),
                  TextField(
                      controller: student,
                      decoration:
                          const InputDecoration(hintText: 'مثال: أحمد علي')),
                  const SizedBox(height: 8),
                  const Text('موضوع التقرير'),
                  TextField(
                      controller: topic,
                      decoration: InputDecoration(
                          hintText: 'مثال: تأثير التعلم العميق على تصنيف الصور',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor))),
                  const SizedBox(height: 8),
                  const Text('نطاق التقرير/الأقسام الرئيسية'),
                  TextField(
                      controller: scope,
                      decoration: InputDecoration(
                          hintText:
                              'مثال: مقدمة، مراجعة أدبيات، تحليل، استنتاجات',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor))),
                  const SizedBox(height: 8),
                  const Text('عدد الصفحات التقريبي'),
                  TextField(
                      controller: pages,
                      decoration: InputDecoration(
                          hintText: 'مثال: 10-15',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor))),
                  const SizedBox(height: 8),
                  const Text('الموعد النهائي/التاريخ'),
                  TextField(
                      controller: due,
                      decoration: InputDecoration(
                          hintText: 'مثال: 2025-10-01',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor))),
                ] else if (selection == 1) ...[
                  const Text('موضوع التقرير'),
                  TextField(
                      controller: topic,
                      decoration: const InputDecoration(
                          hintText:
                              'مثال: تأثير التعلم العميق على تصنيف الصور')),
                ] else ...[
                  const Text('لن تحتاج لإدخال أي معلومات الآن.'),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('إلغاء'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () {
                            String message = '';
                            if (selection == 2) {
                              message =
                                  'مرحبا 👋\nأنا طالب $degree لا أملك فكرة للتقرير حالياً، أرجو مساعدتكم باقتراحات مناسبة.\n\n— تم الإرسال من تطبيق خريج';
                            } else if (selection == 1) {
                              final t = topic.text.trim();
                              message =
                                  'مرحبا 👋\nلدي موضوع تقرير للدرجة $degree وأحتاج مساعدة في التفاصيل.\n\nموضوع التقرير: ${t.isEmpty ? '(لم يُدخل موضوع)' : t}\n\n— تم الإرسال من تطبيق خريج';
                            } else {
                              final s = student.text.trim();
                              final t = topic.text.trim();
                              final sc = scope.text.trim();
                              final p = pages.text.trim();
                              final d = due.text.trim();
                              message =
                                  'مرحبا 👋\nأرغب بالمساعدة في إعداد تقرير (الدرجة: $degree).\n\n';
                              message +=
                                  'اسم الطالب: ${s.isEmpty ? '(غير محدد)' : s}\n';
                              message +=
                                  'موضوع التقرير: ${t.isEmpty ? '(غير محدد)' : t}\n';
                              message +=
                                  'نطاق التقرير/الأقسام: ${sc.isEmpty ? '(غير محدد)' : sc}\n';
                              message +=
                                  'عدد الصفحات التقريبي: ${p.isEmpty ? '(غير محدد)' : p}\n';
                              message +=
                                  'الموعد النهائي: ${d.isEmpty ? '(غير محدد)' : d}\n\n— تم الإرسال من تطبيق خريج';
                            }
                            Navigator.of(context).pop();
                            _launchWhatsApp(context, message);
                          },
                          child: const Text('إرسال'))),
                ]),
                const SizedBox(height: 12),
              ]),
            ),
          ),
        );
      });
    },
  );
}
