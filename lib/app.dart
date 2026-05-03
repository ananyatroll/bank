import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'config/routes.dart';

class TeleBankApp extends StatelessWidget {
  const TeleBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeleBank',
      debugShowCheckedModeBanner: false,
      theme: buildTeleBankLightTheme(),
      darkTheme: buildTeleBankDarkTheme(),
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
