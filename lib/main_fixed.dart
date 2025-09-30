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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // اجعل التطبيق دائمًا في الوضع العمودي افتراضيًا
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // تنظيف أي URLs مخزنة قديماً لضمان استخدام المتغير العالمي
  await DebugHelper.forceUseGlobalUrl();
  print('🚀 تم تنظيف البيانات وإجبار استخدام المتغير العالمي');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
              return content;
            },
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
            },
          );
        },
      ),
    );
  }
}
