import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bank/presentation/bank_home_screen.dart';
import '../../wallet/presentation/crypto_screen.dart';
import '../../payment/screens/services_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback? onThemeChanged;
  const DashboardScreen({super.key, this.onThemeChanged});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  late List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const BankHomeScreen(),
      const CryptoScreen(),
      const ServicesScreen(),
      SettingsScreen(onThemeChanged: widget.onThemeChanged),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TeleBank'),
        actions: [
          IconButton(icon: const Icon(Icons.sms_outlined), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing SMS...')));
          }),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: AppColors.getShadow(2)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.ethiopianGreen,
          unselectedItemColor: AppColors.mediumGray,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.currency_bitcoin), label: 'Crypto'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Services'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
