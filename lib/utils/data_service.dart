import '../models/app_models.dart';
import '../utils/app_colors.dart';

class DataService {
  // بيانات وهمية للدورات
  static List<Course> getDummyCourses() {
    final now = DateTime.now();
    return [
      Course(
        id: '1',
        title: 'دورة Flutter للمبتدئين',
        description: 'تعلم أساسيات تطوير التطبيقات باستخدام Flutter',
        instructor: 'أحمد محمد',
        imageUrl: 'images/Flutter.png',
        price: 'مجاني',
        isFree: true,
        duration: 1200, // 20 ساعة
        rating: 4.8,
        studentsCount: 1250,
        category: 'البرمجة',
        tags: ['Flutter', 'Dart', 'تطوير التطبيقات'],
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      Course(
        id: '2',
        title: 'تطوير تطبيقات الويب',
        description: 'دورة شاملة في تطوير مواقع الويب الحديثة',
        instructor: 'سارة أحمد',
        imageUrl: 'images/logo.png',
        price: '299 ريال',
        isFree: false,
        duration: 1800, // 30 ساعة
        rating: 4.6,
        studentsCount: 890,
        category: 'تطوير الويب',
        tags: ['HTML', 'CSS', 'JavaScript', 'React'],
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      Course(
        id: '3',
        title: 'أساسيات البرمجة',
        description: 'مقدمة شاملة في عالم البرمجة للمبتدئين',
        instructor: 'محمد علي',
        imageUrl: 'images/Flutter.png',
        price: 'مجاني',
        isFree: true,
        duration: 900, // 15 ساعة
        rating: 4.9,
        studentsCount: 2100,
        category: 'البرمجة',
        tags: ['Python', 'أساسيات', 'منطق البرمجة'],
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      Course(
        id: '4',
        title: 'تصميم واجهات المستخدم',
        description: 'تعلم تصميم واجهات جذابة وسهلة الاستخدام',
        instructor: 'فاطمة حسن',
        imageUrl: 'images/logo.png',
        price: '199 ريال',
        isFree: false,
        duration: 1080, // 18 ساعة
        rating: 4.7,
        studentsCount: 680,
        category: 'التصميم',
        tags: ['UI/UX', 'Figma', 'Adobe XD'],
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
      Course(
        id: '5',
        title: 'أمن المعلومات',
        description: 'دورة متقدمة في حماية الأنظمة والشبكات',
        instructor: 'خالد السعيد',
        imageUrl: 'images/Flutter.png',
        price: '399 ريال',
        isFree: false,
        duration: 2400, // 40 ساعة
        rating: 4.5,
        studentsCount: 420,
        category: 'الأمن السيبراني',
        tags: ['Cybersecurity', 'Network Security', 'Ethical Hacking'],
        createdAt: now.subtract(const Duration(days: 50)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),
      Course(
        id: '6',
        title: 'الذكاء الاصطناعي',
        description: 'مقدمة في تعلم الآلة والذكاء الاصطناعي',
        instructor: 'نورا الزهراني',
        imageUrl: 'images/logo.png',
        price: '499 ريال',
        isFree: false,
        duration: 3000, // 50 ساعة
        rating: 4.8,
        studentsCount: 315,
        category: 'الذكاء الاصطناعي',
        tags: ['AI', 'Machine Learning', 'Python', 'TensorFlow'],
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now.subtract(const Duration(days: 12)),
      ),
    ];
  }

  // بيانات وهمية للأقسام
  static List<Department> getDummyDepartments() {
    return [
      Department(
        id: '1',
        name: 'هندسة البرمجيات',
        description: 'تطوير التطبيقات والأنظمة الذكية',
        imageUrl: 'images/Flutter.png', // استخدام صورة Flutter للبرمجيات
        color: AppColors.departmentColor1,
        courses:
            getDummyCourses().where((c) => c.category == 'البرمجة').toList(),
      ),
      Department(
        id: '2',
        name: 'أمن المعلومات',
        description: 'حماية البيانات والشبكات الآمنة',
        imageUrl: 'images/logo.png', // استخدام اللوجو لأمن المعلومات
        color: AppColors.departmentColor2,
        courses: getDummyCourses()
            .where((c) => c.category == 'الأمن السيبراني')
            .toList(),
      ),
      Department(
        id: '3',
        name: 'الذكاء الاصطناعي',
        description: 'تعلم الآلة وتقنيات المستقبل',
        imageUrl: 'images/Flutter.png', // استخدام Flutter للذكاء الاصطناعي
        color: AppColors.departmentColor3,
        courses: getDummyCourses()
            .where((c) => c.category == 'الذكاء الاصطناعي')
            .toList(),
      ),
      Department(
        id: '4',
        name: 'تصميم الجرافيك',
        description: 'الإبداع البصري والتصميم الحديث',
        imageUrl: 'images/logo.png', // استخدام اللوجو للتصميم
        color: AppColors.courseColor1,
        courses:
            getDummyCourses().where((c) => c.category == 'التصميم').toList(),
      ),
      Department(
        id: '5',
        name: 'تطوير الويب',
        description: 'مواقع ويب تفاعلية ومبتكرة',
        imageUrl: 'images/Flutter.png', // استخدام Flutter لتطوير الويب
        color: AppColors.courseColor2,
        courses: getDummyCourses()
            .where((c) => c.category == 'تطوير الويب')
            .toList(),
      ),
      Department(
        id: '6',
        name: 'إدارة الأعمال',
        description: 'القيادة والريادة في العمل',
        imageUrl: 'images/logo.png', // استخدام اللوجو لإدارة الأعمال
        color: AppColors.projectColor1,
        courses: [],
      ),
    ];
  }

  // بيانات وهمية للمشاريع
  static List<Project> getDummyProjects() {
    final now = DateTime.now();
    return [
      // Featured projects (required additions)
      Project(
        id: 'featured_ecommerce',
        title: 'متجر إلكتروني',
        description:
            'تطبيق متكامل للتجارة الإلكترونية مع نظام دفع وإدارة المنتجات.',
        imageUrl: 'images/logo.png',
        demoUrl: null,
        githubUrl: null,
        technologies: ['Flutter', 'Laravel', 'MySQL'],
        difficulty: 'medium',
        examples: [
          'حساب مستخدم',
          'عربة تسوق',
          'بوابة دفع إلكتروني',
        ],
        howToWrite: [
          'حدد فئات المنتجات وخصائصها',
          'وصف طرق الدفع والشحن المطلوب',
          'حدد متطلبات لوحة الإدارة',
        ],
        whatsappMessage:
            'مرحبا 👋\nأرغب ببناء متجر إلكتروني متكامل للتجارة الإلكترونية.\n\n— تم الإرسال من تطبيق خريج',
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      Project(
        id: 'featured_clothing',
        title: 'موقع لمتجر ملابس',
        description:
            'متجر أزياء إلكتروني مع كتالوج مقاسات وألوان، سلة ودفع، وإدارة مخزون.',
        imageUrl: 'images/logo.png',
        demoUrl: null,
        githubUrl: null,
        technologies: ['Flutter', 'Laravel', 'MySQL'],
        difficulty: 'medium',
        examples: [
          'خيارات مقاس/لون',
          'صور متعددة للمنتج',
          'كوبونات وشحن',
        ],
        howToWrite: [
          'حدد نظام المقاسات والخيارات',
          'وصف سياسات الإرجاع والشحن',
        ],
        whatsappMessage:
            'مرحبا 👋\nأرغب ببناء موقع لمتجر ملابس مع نظام دفع وإدارة منتجات.\n\n— تم الإرسال من تطبيق خريج',
        createdAt: now.subtract(const Duration(days: 80)),
      ),
      Project(
        id: 'featured_phones',
        title: 'موقع لمتجر هواتف',
        description:
            'متجر مختص بالهواتف والإكسسوارات مع مقارنة المواصفات وضمان وفواتير.',
        imageUrl: 'images/logo.png',
        demoUrl: null,
        githubUrl: null,
        technologies: ['Flutter', 'Next.js', 'Laravel', 'MySQL'],
        difficulty: 'advanced',
        examples: [
          'مقارنة المواصفات',
          'حجوزات مسبقة',
          'إدارة فواتير وضمان',
        ],
        howToWrite: [
          'حدد حقول مواصفات الأجهزة',
          'وصف نظام المقارنة والتصفية',
        ],
        whatsappMessage:
            'مرحبا 👋\nأرغب ببناء موقع لمتجر هواتف مع إمكانية مقارنة المواصفات وربط الإكسسوارات.\n\n— تم الإرسال من تطبيق خريج',
        createdAt: now.subtract(const Duration(days: 70)),
      ),
      Project(
        id: 'featured_robot',
        title: 'روبوت ذكي',
        description:
            'روبوت ذكي يتبع الخط ويتجنب العوائق مع تحكم عبر تطبيق موبايل.',
        imageUrl: 'images/logo.png',
        demoUrl: null,
        githubUrl: null,
        technologies: ['Arduino', 'ESP32', 'Flutter'],
        difficulty: 'advanced',
        examples: [
          'تتبع خط',
          'تجنب عوائق',
          'تحكم عبر تطبيق',
        ],
        howToWrite: [
          'حدد الأجهزة والمستشعرات المطلوبة',
          'وصف أوضاع التشغيل والوظائف المطلوبة',
        ],
        whatsappMessage:
            'مرحبا 👋\nأرغب بتنفيذ مشروع روبوت ذكي (تتبع خط / تجنب عوائق) مع إمكانية التحكم عبر تطبيق موبايل.\n\n— تم الإرسال من تطبيق خريج',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      Project(
        id: '2',
        title: 'نظام إدارة المدارس',
        description: 'نظام شامل لإدارة العمليات التعليمية والطلاب والمعلمين',
        imageUrl: 'images/Flutter.png',
        demoUrl: 'https://demo.schoolms.com',
        githubUrl: 'https://github.com/user/school-management',
        technologies: ['React', 'Node.js', 'MongoDB', 'Express'],
        createdAt: now.subtract(const Duration(days: 120)),
      ),
      Project(
        id: '3',
        title: 'تطبيق توصيل الطعام',
        description: 'منصة ربط المطاعم بالعملاء مع نظام تتبع الطلبات',
        imageUrl: 'images/logo.png',
        demoUrl: 'https://demo.fooddelivery.com',
        githubUrl: 'https://github.com/user/food-delivery',
        technologies: ['Flutter', 'Laravel', 'MySQL', 'Google Maps API'],
        createdAt: now.subtract(const Duration(days: 75)),
      ),
      Project(
        id: '4',
        title: 'منصة التعلم الإلكتروني',
        description: 'نظام إدارة التعلم مع مقاطع فيديو واختبارات تفاعلية',
        imageUrl: 'images/Flutter.png',
        demoUrl: 'https://demo.lms.com',
        githubUrl: 'https://github.com/user/lms-platform',
        technologies: ['Vue.js', 'Django', 'PostgreSQL', 'Redis'],
        createdAt: now.subtract(const Duration(days: 105)),
      ),
      Project(
        id: '5',
        title: 'تطبيق إدارة المهام',
        description: 'أداة إنتاجية لتنظيم المهام والمشاريع الشخصية والجماعية',
        imageUrl: 'images/logo.png',
        demoUrl: 'https://demo.taskmanager.com',
        githubUrl: 'https://github.com/user/task-manager',
        technologies: ['React Native', 'Supabase', 'TypeScript'],
        createdAt: now.subtract(const Duration(days: 60)),
      ),
    ];
  }

  // بيانات وهمية لتقدم الدورات
  static List<CourseProgress> getDummyCourseProgress(String userId) {
    return [
      CourseProgress(
        courseId: '1',
        userId: userId,
        progress: 0.65,
        lastAccessed: DateTime.now().subtract(const Duration(hours: 2)),
        watchedVideos: 13,
        totalVideos: 20,
      ),
      CourseProgress(
        courseId: '2',
        userId: userId,
        progress: 0.30,
        lastAccessed: DateTime.now().subtract(const Duration(days: 1)),
        watchedVideos: 9,
        totalVideos: 30,
      ),
      CourseProgress(
        courseId: '4',
        userId: userId,
        progress: 0.85,
        lastAccessed: DateTime.now().subtract(const Duration(hours: 5)),
        watchedVideos: 15,
        totalVideos: 18,
      ),
    ];
  }

  // ملاحظة: تم حذف getDummyUserProfile() - معلومات المستخدم تأتي الآن من API فقط

  // الحصول على الدورات المجانية
  static List<Course> getFreeCourses() {
    return getDummyCourses().where((course) => course.isFree).toList();
  }

  // الحصول على الدورات الأكثر شهرة
  static List<Course> getPopularCourses({int limit = 6}) {
    final courses = getDummyCourses();
    courses.sort((a, b) => b.studentsCount.compareTo(a.studentsCount));
    return courses.take(limit).toList();
  }

  // البحث في الدورات
  static List<Course> searchCourses(String query) {
    final courses = getDummyCourses();
    if (query.isEmpty) return courses;

    return courses.where((course) {
      return course.title.toLowerCase().contains(query.toLowerCase()) ||
          course.description.toLowerCase().contains(query.toLowerCase()) ||
          course.instructor.toLowerCase().contains(query.toLowerCase()) ||
          course.tags
              .any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }

  // الحصول على دورات قسم معين
  static List<Course> getCoursesByDepartment(String departmentId) {
    final department = getDummyDepartments().firstWhere(
      (dept) => dept.id == departmentId,
      orElse: () => getDummyDepartments().first,
    );
    return department.courses;
  }

  // معلومات إضافية للتطبيق
  static Map<String, dynamic> getAppInfo() {
    return {
      'version': '1.0.0',
      'buildNumber': '1',
      'lastUpdate': DateTime.now().subtract(const Duration(days: 7)),
      'totalCourses': getDummyCourses().length,
      'totalDepartments': getDummyDepartments().length,
      'totalProjects': getDummyProjects().length,
      'supportEmail': 'support@newgraduate.com',
      'supportPhone': '+966 50 123 4567',
      'socialLinks': {
        'instagram': 'https://instagram.com/newgraduate_app',
        'telegram': 'https://t.me/newgraduate_support',
        'whatsapp': 'https://wa.me/966501234567',
      },
    };
  }
}
