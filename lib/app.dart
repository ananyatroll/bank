import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/bank/presentation/bank_select_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

class TeleBankApp extends StatefulWidget {
  const TeleBankApp({super.key});
  @override
  State<TeleBankApp> createState() => _TeleBankAppState();
}

class _TeleBankAppState extends State<TeleBankApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() { super.initState(); _loadTheme(); }

  Future<void> _loadTheme() async {
    final p = await SharedPreferences.getInstance();
    final dark = p.getBool('dark_mode') ?? false;
    if (mounted) setState(() => _themeMode = dark ? ThemeMode.dark : ThemeMode.light);
  }

  void _onThemeChanged() {
    _loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeleBank',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: _themeMode,
      home: LoginScreen(onThemeChanged: _onThemeChanged),
      routes: {
        '/bank-select': (_) => const BankSelectScreen(),
        '/dashboard': (_) => DashboardScreen(onThemeChanged: _onThemeChanged),
      },
    );
  }
}
