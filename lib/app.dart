import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/dashboard/dashboard_screen.dart';

class TeleBankApp extends StatelessWidget {
  const TeleBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeleBank',
      theme: buildTeleBankTheme(),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
