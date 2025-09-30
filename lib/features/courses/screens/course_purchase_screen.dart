import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:newgraduate/providers/simple_theme_provider.dart';
import 'package:newgraduate/services/institute_info_service.dart';

class CoursePurchaseScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const CoursePurchaseScreen({
    super.key,
    required this.course,
  });

  @override
  State<CoursePurchaseScreen> createState() => _CoursePurchaseScreenState();
}

class _CoursePurchaseScreenState extends State<CoursePurchaseScreen> {
  String? institutePhone;
  bool isLoadingInstituteData = false;
  String? cachedInstitutePhone; // 🎯 متغير لحفظ الرقم

  @override
  void initState() {
    super.initState();
    _loadInstitutePhone();
  }

  Future<void> _loadInstitutePhone() async {
    print('🔍 بدء عملية البحث عن رقم هاتف المعهد...');
    print(
        '🔍 بيانات الدورة المتاحة: institute_phone=${widget.course['institute_phone']}, phone=${widget.course['phone']}');

    // 🎯 أولاً: التحقق من الرقم المحفوظ في المتغير
    if (cachedInstitutePhone != null && cachedInstitutePhone!.isNotEmpty) {
      print('✅ استخدام الرقم المحفوظ: $cachedInstitutePhone');
      setState(() {
        institutePhone = cachedInstitutePhone;
      });
      return;
    }

    // 🎯 ثانياً: التحقق من البيانات المحفوظة محلياً
    try {
      final savedInstitutePhone =
          await InstituteInfoService.getInstitutePhone();
      if (savedInstitutePhone != null &&
          savedInstitutePhone.isNotEmpty &&
          savedInstitutePhone != 'null') {
        print('✅ تم العثور على رقم هاتف المعهد المحفوظ: $savedInstitutePhone');
        cachedInstitutePhone = savedInstitutePhone; // 🎯 حفظ في المتغير
        setState(() {
          institutePhone = savedInstitutePhone;
        });
        return;
      } else {
        print('⚠️ لا توجد بيانات محفوظة للمعهد، سيتم التحقق من بيانات الدورة');
      }
    } catch (e) {
      print('❌ خطأ في استرجاع البيانات المحفوظة: $e');
    }

    // 🎯 ثالثاً: التحقق من وجود رقم الهاتف في بيانات الدورة
    final existingInstitutePhone = widget.course['institute_phone']?.toString();
    final existingPhone = widget.course['phone']?.toString();

    if (existingInstitutePhone != null &&
        existingInstitutePhone.isNotEmpty &&
        existingInstitutePhone != 'null') {
      print(
          '✅ تم العثور على رقم المعهد في بيانات الدورة: $existingInstitutePhone');
      cachedInstitutePhone = existingInstitutePhone; // 🎯 حفظ في المتغير
      setState(() {
        institutePhone = existingInstitutePhone;
      });
      return;
    }

    if (existingPhone != null &&
        existingPhone.isNotEmpty &&
        existingPhone != 'null') {
      print('✅ تم العثور على رقم هاتف في بيانات الدورة: $existingPhone');
      cachedInstitutePhone = existingPhone; // 🎯 حفظ في المتغير
      setState(() {
        institutePhone = existingPhone;
      });
      return;
    }

    // 🎯 أخيراً: إذا لم تتوفر البيانات، حدد رقم ثابت للمعهد (07748687725)
    print('⚠️ لم يتم العثور على رقم هاتف، استخدام الرقم الافتراضي');
    final defaultPhone = '07748687725';
    final formattedPhone = _formatPhoneToInternational(defaultPhone);

    cachedInstitutePhone = formattedPhone; // 🎯 حفظ في المتغير
    setState(() {
      institutePhone = formattedPhone;
    });

    print('✅ تم تعيين الرقم الافتراضي: $formattedPhone');
  }

  String _formatPhoneToInternational(String phone) {
    print('🔄 تحويل الرقم للصيغة الدولية: $phone');

    // إزالة المسافات والرموز غير المرغوبة
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // إذا كان الرقم يبدأ بـ + فهو بالفعل بالصيغة الدولية
    if (cleanPhone.startsWith('+')) {
      print('✅ الرقم بالفعل بالصيغة الدولية: $cleanPhone');
      return cleanPhone;
    }

    // إذا كان الرقم عراقي يبدأ بـ 07
    if (cleanPhone.startsWith('07') && cleanPhone.length == 11) {
      // تحويل من 07XXXXXXXXX إلى +9647XXXXXXXXX
      String converted = '+964' + cleanPhone.substring(1);
      print('✅ تم تحويل الرقم العراقي: $phone → $converted');
      return converted;
    }

    // إذا كان الرقم يبدأ بـ 964 (رمز العراق بدون +)
    if (cleanPhone.startsWith('964') && cleanPhone.length == 13) {
      String converted = '+$cleanPhone';
      print('✅ تم إضافة + للرقم العراقي: $phone → $converted');
      return converted;
    }

    // إذا كان الرقم سعودي يبدأ بـ 05
    if (cleanPhone.startsWith('05') && cleanPhone.length == 10) {
      String converted = '+966' + cleanPhone.substring(1);
      print('✅ تم تحويل الرقم السعودي: $phone → $converted');
      return converted;
    }

    // إذا كان الرقم يبدأ بـ 966 (رمز السعودية بدون +)
    if (cleanPhone.startsWith('966') && cleanPhone.length == 12) {
      String converted = '+$cleanPhone';
      print('✅ تم إضافة + للرقم السعودي: $phone → $converted');
      return converted;
    }

    // إذا لم نتمكن من تحديد البلد، نرجع الرقم كما هو مع إضافة +
    if (!cleanPhone.startsWith('+')) {
      cleanPhone = '+$cleanPhone';
    }

    print('⚠️ لم يتم التعرف على نوع الرقم، إرجاع: $cleanPhone');
    return cleanPhone;
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'غير محدد';

    double? priceValue;
    if (price is String) {
      priceValue = double.tryParse(price);
    } else if (price is num) {
      priceValue = price.toDouble();
    }

    if (priceValue == null || priceValue <= 0) return 'غير محدد';

    // تنسيق السعر مع فاصلة كل 3 أرقام
    String formattedNumber;
    if (priceValue == priceValue.toInt()) {
      int intValue = priceValue.toInt();
      formattedNumber = _addCommasToNumber(intValue.toString());
      return '$formattedNumber دينار';
    } else {
      formattedNumber = _addCommasToNumber(priceValue.toStringAsFixed(2));
      return '$formattedNumber دينار';
    }
  }

  // دالة مساعدة لإضافة الفواصل كل 3 أرقام
  String _addCommasToNumber(String number) {
    // فصل الجزء الصحيح عن الجزء العشري إن وجد
    List<String> parts = number.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    // إضافة الفواصل للجزء الصحيح
    String result = '';
    int counter = 0;

    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (counter > 0 && counter % 3 == 0) {
        result = ',$result';
      }
      result = integerPart[i] + result;
      counter++;
    }

    return result + decimalPart;
  }

  String _getCourseType() {
    final isFree = widget.course['is_free_course'] == true;
    if (isFree) return 'دورة مجانية';

    final type = widget.course['course_type'] ?? widget.course['type'];
    if (type != null) return type.toString();

    return 'دورة مدفوعة';
  }

  void _openWhatsApp(String? phoneNumber) async {
    // طباعة رقم الهاتف الأصلي للتأكد
    print('📞 ================== معلومات الاتصال ==================');
    print('📞 رقم الهاتف الأصلي المرسل: $phoneNumber');
    print(
        '📞 مصدر الرقم: ${widget.course['institute_phone'] != null ? 'institute_phone' : 'phone'}');
    print('📞 course[institute_phone]: ${widget.course['institute_phone']}');
    print('📞 course[phone]: ${widget.course['phone']}');

    if (phoneNumber == null || phoneNumber.isEmpty) {
      print('❌ لا يوجد رقم هاتف متاح للاتصال');
      // عرض رسالة خطأ للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد رقم هاتف متاح للتواصل مع المعهد'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // استخدام دالة التحويل للصيغة الدولية
    String cleanPhone = _formatPhoneToInternational(phoneNumber);
    print('📞 الرقم النهائي المُستخدم: $cleanPhone');
    print('📞 ================================================');

    final courseName =
        widget.course['name'] ?? widget.course['title'] ?? 'الدورة';
    final message = 'مرحباً، أرغب في الاستفسار عن دورة: $courseName';

    final whatsappUrl =
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}';

    print('💬 اسم الدورة: $courseName');
    print('💬 الرسالة: $message');
    print('💬 رابط الواتساب النهائي: $whatsappUrl');
    print('📞 ================================================');

    try {
      final Uri url = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        print('✅ تم فتح الواتساب بنجاح');
      } else {
        throw 'Could not launch $whatsappUrl';
      }
    } catch (e) {
      print('❌ خطأ في فتح الواتساب: $e');
      // عرض رسالة خطأ للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في فتح الواتساب: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug info to check available course data
    print('📊 ================ بيانات الدورة الكاملة ================');
    print('📊 Course data keys: ${widget.course.keys.toList()}');
    print('📊 Course data values:');
    widget.course.forEach((key, value) {
      print('📊   $key: $value');
    });

    // طباعة معلومات الهاتف المتاحة بشكل مفصل
    print('📞 ================ معلومات الهاتف المتاحة ================');
    print(
        '📞 institute_phone: ${widget.course['institute_phone']} (نوع: ${widget.course['institute_phone'].runtimeType})');
    print(
        '📞 phone: ${widget.course['phone']} (نوع: ${widget.course['phone'].runtimeType})');
    print('📞 institute_name: ${widget.course['institute_name']}');
    print('📞 institute_id: ${widget.course['institute_id']}');
    print('📞 حالة التحميل: isLoadingInstituteData = $isLoadingInstituteData');
    print('📞 رقم الهاتف المحفوظ محليا: $institutePhone');
    print('📞 =========================================================');

    return Consumer<SimpleThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor:
              themeProvider.isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            title: const Text(
              'شراء الدورة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoKufiArabic',
              ),
            ),
            backgroundColor: themeProvider.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header section with course image
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        themeProvider.primaryColor,
                        themeProvider.primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Course image placeholder or icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: (widget.course['image_url'] != null &&
                                          widget.course['image_url']
                                              .toString()
                                              .isNotEmpty) ||
                                      (widget.course['image'] != null &&
                                          widget.course['image']
                                              .toString()
                                              .isNotEmpty)
                                  ? Image.network(
                                      (widget.course['image_url'] ??
                                              widget.course['image'])
                                          .toString(),
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, progress) {
                                        if (progress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white.withOpacity(0.9),
                                            ),
                                            strokeWidth: 2.0,
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(
                                          Icons.school_outlined,
                                          size: 40,
                                          color: Colors.white.withOpacity(0.9),
                                        );
                                      },
                                    )
                                  : Icon(
                                      Icons.school_outlined,
                                      size: 40,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Course name
                          Text(
                            widget.course['name']?.toString() ??
                                widget.course['title']?.toString() ??
                                'اسم الدورة',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'NotoKufiArabic',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Course type
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getCourseType(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontFamily: 'NotoKufiArabic',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Course details section
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Course title card
                      _buildInfoCard(
                        icon: Icons.book_outlined,
                        title: 'عنوان الدورة',
                        value: widget.course['name']?.toString() ??
                            widget.course['title']?.toString() ??
                            'غير محدد',
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 12),

                      // Course type card
                      _buildInfoCard(
                        icon: Icons.category_outlined,
                        title: 'نوع الدورة',
                        value: _getCourseType(),
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 12),

                      // Price card
                      _buildInfoCard(
                        icon: Icons.attach_money,
                        title: 'سعر الدورة',
                        value: _formatPrice(widget.course['price']),
                        themeProvider: themeProvider,
                        isPrice: true,
                      ),
                      const SizedBox(height: 12),

                      // Instructor card (if available)
                      if (widget.course['instructor_name'] != null) ...[
                        _buildInfoCard(
                          icon: Icons.person_outline,
                          title: 'الأستاذ',
                          value: widget.course['instructor_name'].toString(),
                          themeProvider: themeProvider,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Description card (if available)
                      if (widget.course['description'] != null &&
                          widget.course['description']
                              .toString()
                              .isNotEmpty) ...[
                        _buildInfoCard(
                          icon: Icons.description_outlined,
                          title: 'الوصف',
                          value: widget.course['description'].toString(),
                          themeProvider: themeProvider,
                          isDescription: true,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Institute card (if available)
                      if (widget.course['institute_name'] != null) ...[
                        _buildInfoCard(
                          icon: Icons.business_outlined,
                          title: 'المعهد',
                          value: widget.course['institute_name'].toString(),
                          themeProvider: themeProvider,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Lectures count card (if available)
                      if (widget.course['lectures_count'] != null) ...[
                        _buildInfoCard(
                          icon: Icons.play_circle_outline,
                          title: 'عدد المحاضرات',
                          value: widget.course['lectures_count'].toString() +
                              ' محاضرة',
                          themeProvider: themeProvider,
                        ),
                        const SizedBox(height: 12),
                      ],

                      const SizedBox(height: 20),

                      // Contact button
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: SizedBox(
                          height: 40, // ارتفاع أصغر
                          child: ElevatedButton.icon(
                            onPressed: isLoadingInstituteData
                                ? null
                                : () async {
                                    print(
                                        '🎯 ================ النقر على تواصل معنا ================');

                                    // 🎯 استخدام الرقم المحفوظ أولاً
                                    String? phoneToUse = cachedInstitutePhone;

                                    if (phoneToUse == null ||
                                        phoneToUse.isEmpty) {
                                      // إذا لم يكن هناك رقم محفوظ، جرب من بيانات الدورة
                                      phoneToUse =
                                          widget.course['institute_phone'] ??
                                              widget.course['phone'];
                                    }

                                    print(
                                        '🎯 الرقم المُختار للإرسال: $phoneToUse');
                                    print(
                                        '🎯 مصدر الرقم: ${cachedInstitutePhone != null ? 'الرقم المحفوظ' : 'بيانات الدورة'}');
                                    print(
                                        '🎯 ====================================================');

                                    // إذا لم يكن هناك رقم، محاولة جلب البيانات مرة أخرى
                                    if (phoneToUse == null ||
                                        phoneToUse.toString().isEmpty) {
                                      print(
                                          '⚠️ لا يوجد رقم هاتف، محاولة جلب البيانات مرة أخرى...');
                                      await _loadInstitutePhone();

                                      // استخدام الرقم المحفوظ بعد التحديث
                                      phoneToUse = cachedInstitutePhone;
                                    }

                                    if (phoneToUse != null &&
                                        phoneToUse.isNotEmpty) {
                                      _openWhatsApp(phoneToUse);
                                    } else {
                                      _openWhatsApp(null);
                                    }
                                  },
                            icon: isLoadingInstituteData
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.chat_outlined,
                                    size: 18, // أيقونة أصغر
                                  ),
                            label: Text(
                              isLoadingInstituteData
                                  ? 'جاري التحميل...'
                                  : 'تواصل معنا',
                              style: TextStyle(
                                fontSize: 14, // خط أصغر
                                fontWeight: FontWeight.w600,
                                fontFamily: 'NotoKufiArabic',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider
                                  .primaryColor, // نفس لون زر شراء الدورة
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(20), // أكثر بيضاوية
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              elevation: 3,
                              shadowColor:
                                  themeProvider.primaryColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'للتواصل مع المعهد عبر الواتساب',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeProvider.isDarkMode
                              ? Colors.white60
                              : Colors.black54,
                          fontFamily: 'NotoKufiArabic',
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required SimpleThemeProvider themeProvider,
    bool isDescription = false,
    bool isPrice = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: isDescription
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                icon,
                color: themeProvider.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.isDarkMode
                          ? Colors.white60
                          : Colors.black54,
                      fontFamily: 'NotoKufiArabic',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isPrice ? 20 : 16,
                      fontWeight: isPrice ? FontWeight.bold : FontWeight.w500,
                      color: isPrice
                          ? themeProvider.primaryColor
                          : (themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87),
                      fontFamily: 'NotoKufiArabic',
                    ),
                    maxLines: isDescription ? null : 2,
                    overflow: isDescription ? null : TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
