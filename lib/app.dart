import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/vip/presentation/vip_screen.dart';
import 'features/wallet/presentation/wallet_screen.dart';
import 'features/ai/presentation/ai_assistant_screen.dart';
import 'features/ai/presentation/app_doctor_screen.dart';

class EnjoyApp extends StatelessWidget {
  const EnjoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ENJOY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      routes: {
        '/wallet': (_) => const WalletScreen(),
        '/vip': (_) => const VipScreen(),
        '/ai': (_) => const AiAssistantScreen(),
        '/doctor': (_) => const AppDoctorScreen(),
      },
    );
  }
}