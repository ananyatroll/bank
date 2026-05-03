import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/bank/presentation/bank_select_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

class TeleBankApp extends StatelessWidget {
  const TeleBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeleBank',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: const LoginScreen(),
      routes: {
        '/bank-select': (_) => const BankSelectScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
    );
  }
}
