import 'package:flutter/material.dart';
import '../features/auth/presentation/screens/pin_setup_screen.dart';
import '../features/auth/presentation/screens/biometric_setup_screen.dart';
import '../features/bank/presentation/bank_select_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/dashboard/splash_screen.dart';
import '../features/ussd/presentation/ussd_screen.dart';
import '../features/wallet/presentation/crypto_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const String splash = '/splash';
  static const String bankSelect = '/bank-select';
  static const String dashboard = '/dashboard';
  static const String pinSetup = '/pin-setup';
  static const String biometricSetup = '/biometric-setup';
  static const String ussd = '/ussd';
  static const String crypto = '/crypto';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (_) => const SplashScreen(),
      bankSelect: (_) => const BankSelectScreen(),
      dashboard: (_) => const DashboardScreen(),
      pinSetup: (_) => const PinSetupScreen(),
      biometricSetup: (_) => const BiometricSetupScreen(),
      ussd: (_) => const UssdScreen(),
      crypto: (_) => const CryptoScreen(),
    };
  }
}
