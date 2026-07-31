import 'package:flutter/material.dart';
import 'package:seniors_27/core/auth/session_manager.dart';
import 'package:seniors_27/core/theme/app_theme.dart';
import 'package:seniors_27/features/auth/login_email_screen.dart';
import 'package:seniors_27/features/splash/splash_screen.dart';

void main() {
  runApp(const SeniorsApp());
}

class SeniorsApp extends StatelessWidget {
  const SeniorsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seniors 2027',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.retro,
      navigatorKey: SessionManager.instance.navigatorKey,
      routes: {SessionManager.loginRouteName: (_) => const LoginEmailScreen()},
      home: const SplashScreen(),
    );
  }
}
