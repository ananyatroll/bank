import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'config/routes.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/bank/presentation/bank_select_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

class TeleBankApp extends StatefulWidget {
  const TeleBankApp({super.key});
  @override State<TeleBankApp> createState() => _TeleBankAppState();
}

class _TeleBankAppState extends State<TeleBankApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override void initState() { super.initState(); _loadTheme(); }

  Future<void> _loadTheme() async {
    final p = await SharedPreferences.getInstance();
    final dark = p.getBool('dark_mode') ?? false;
    if (mounted) setState(() => _themeMode = dark ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeleBank',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: _themeMode,
      home: const LoginScreen(),
      routes: {
        '/bank-select': (_) => const BankSelectScreen(),
        '/dashboard': (_) => DashboardScreen(onThemeChanged: () { _loadTheme(); }),
      },
    );
  }
}
