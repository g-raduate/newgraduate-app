import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:newgraduate/utils/prefs_keys.dart';
import 'package:newgraduate/features/onboarding/screens/policy_screen.dart';
import 'package:newgraduate/features/auth/screens/login_screen.dart';
import 'package:newgraduate/features/shell/screens/main_shell.dart';
import 'package:provider/provider.dart';
import 'package:newgraduate/features/auth/data/auth_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.bounceOut,
    ));

    _animationController.forward();

    // Hydrate bearer from saved token for subsequent API calls if available
    Future.microtask(() async {
      final repo = context.read<AuthRepository>();
      await repo.hydrateBearerFromPrefs();
    });

    Timer(const Duration(milliseconds: 3500), () async {
      final prefs = await SharedPreferences.getInstance();
      final accepted = prefs.getBool(kPolicyAccepted) ?? false;
      final loggedIn = prefs.getBool(kIsLoggedIn) ?? false;

      if (!mounted) return;

      if (!accepted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PolicyScreen()),
        );
      } else if (!loggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC2F2ED),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFC2F2ED),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // مساحة فارغة في الأعلى
            const Spacer(flex: 2),

            // Splash Animation مع التحريك
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'images/splash.gif',
                        width: 420,
                        height: 420,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 420,
                            height: 420,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: const Color(0xFF2196F3).withOpacity(0.1),
                            ),
                            child: const Icon(
                              Icons.school,
                              size: 168,
                              color: Color(0xFF2196F3),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            // مساحة فارغة في الأسفل
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
