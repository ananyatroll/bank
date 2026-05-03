import 'package:flutter/material.dart';
import '../features/auth/presentation/screens/pin_setup_screen.dart';
import '../features/auth/presentation/screens/biometric_setup_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/dashboard/splash_screen.dart';
import '../features/ussd/ussd_screen.dart';
import '../features/crypto/crypto_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String dashboard = '/dashboard';
  static const String pinSetup = '/pin-setup';
  static const String biometricSetup = '/biometric-setup';
  static const String ussd = '/ussd';
  static const String crypto = '/crypto';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (_) => const SplashScreen(),
      dashboard: (_) => const DashboardScreen(),
      pinSetup: (_) => const PinSetupScreen(),
      biometricSetup: (_) => const BiometricSetupScreen(),
      ussd: (_) => const UssdScreen(),
      crypto: (_) => const CryptoScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routes = getRoutes();
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: const Center(child: Text('404 - Page Not Found')),
      ),
      settings: settings,
    );
  }
}
