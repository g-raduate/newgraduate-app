import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/simple_theme_provider.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/auth/data/auth_repository.dart';
import 'services/api_client.dart';
import 'services/location_service.dart';
import 'config/runtime_config.dart';
import 'features/onboarding/screens/splash_screen.dart';
import 'utils/debug_helper.dart';
import 'utils/global_long_press_blocker.dart';
import 'features/auth/screens/login_screen.dart';
import 'services/screen_recording_service.dart';
import 'widgets/recording_shield.dart';
import 'services/privacy_guard.dart';
import 'utils/emulator_guard.dart';
import 'widgets/emulator_block_screen.dart';
import 'config/app_constants.dart';
import 'managers/security_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // اجعل التطبيق دائمًا في الوضع العمودي افتراضيًا
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // تنظيف أي URLs مخزنة قديماً لضمان استخدام المتغير العالمي
  await DebugHelper.forceUseGlobalUrl();
  print('🚀 تم تنظيف البيانات وإجبار استخدام المتغير العالمي');

  // تحقق من المحاكي قبل تشغيل التطبيق (إلا إذا كان في وضع التطوير)
  bool shouldBlockEmulator = true;
  
  print('🔍 فحص إعدادات التطوير...');
  print('📊 underDevelopmentOverride = ${AppConstants.underDevelopmentOverride}');
  
  // إذا كان في وضع التطوير، اسمح بالمحاكي
  if (AppConstants.underDevelopmentOverride == true) {
    shouldBlockEmulator = false;
    print('🔧 وضع التطوير مفعل - السماح بالمحاكي');
  } else {
    print('⚠️ وضع التطوير غير مفعل - سيتم فحص المحاكي');
  }
  
  print('🎯 shouldBlockEmulator = $shouldBlockEmulator');
  
  final isEmu = shouldBlockEmulator ? await EmulatorGuard.isEmulator() : false;
  
  print('📱 هل هو محاكي؟ $isEmu');

  runApp(MyApp(isEmulator: isEmu));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.isEmulator});

  final bool isEmulator;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SimpleThemeProvider()),
        ChangeNotifierProvider(create: (_) => RuntimeConfig()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        Provider<ApiClient>(create: (_) => ApiClient()),
        Provider<AuthRepository>(
            create: (ctx) => AuthRepository(ctx.read<ApiClient>())),
        ChangeNotifierProvider<AuthController>(
          create: (ctx) => AuthController(ctx.read<AuthRepository>()),
        ),
      ],
      child: Consumer<SimpleThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'تطبيق خريج',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            locale: const Locale('ar', 'SA'),
            builder: (context, child) {
              // تأكيد إبقاء التطبيق عمودياً دائماً
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
              ]);

              final media = MediaQueryData.fromView(View.of(context));
              final isTablet = media.size.shortestSide >= 600;
              Widget content = Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              );
              // امنع الضغط المطوّل على الأجهزة اللوحية/التابلت فقط
              if (isTablet) {
                content = GlobalLongPressBlocker(child: content);
              }

              // dev flag: تحت التطوير
              // إذا تم تحديد override في AppConstants نستخدمه، غير ذلك نستخدم RuntimeConfig
              final storedUnderDev =
                  context.read<RuntimeConfig>().underDevelopment;
              final bool underDevelopment =
                  AppConstants.underDevelopmentOverride ?? storedUnderDev;

              // تطبيق علم الأمان على أندرويد (لاقط شاشة) إذا الحماية مفعلة
              PrivacyGuard.setSecureFlag(!underDevelopment);

              // تهيئة مدير الأمان الجديد بعد انتهاء السبلاش سكرين
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // تأخير 4 ثواني للتأكد من انتهاء السبلاش سكرين (3.5 ثانية + 0.5 هامش أمان)
                Future.delayed(const Duration(seconds: 4), () {
                  if (!SecurityManager.isInitialized && context.mounted) {
                    SecurityManager.initialize(context);
                  }
                });
              });

              // درع التسجيل يغطي التطبيق بالكامل عندما تكون الحماية مفعلة
              final screenShield = ScreenRecordingService();
              screenShield.init();

              return Stack(
                children: [
                  content,
                  if (!underDevelopment)
                    RecordingShield(listenable: screenShield.isCaptured),
                ],
              );
            },
            home: isEmulator 
                ? const EmulatorBlockScreen() 
                : const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
            },
          );
        },
      ),
    );
  }
}
