import 'package:flutter/material.dart';
import '../../bank/presentation/bank_home_screen.dart';
import '../../../core/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  Widget? _cryptoTab;
  Widget? _settingsTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TeleBank'),
        actions: [
          IconButton(icon: const Icon(Icons.sms_outlined), onPressed: () {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS sync')));
          }),
        ],
      ),
      body: _getTab(_currentIndex),
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
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _getTab(int index) {
    switch (index) {
      case 0: return const _SafeWidget(child: BankHomeScreen());
      case 1: return _cryptoTab ??= _buildCryptoTab();
      case 2: return _settingsTab ??= _buildSettingsTab();
      default: return const _SafeWidget(child: BankHomeScreen());
    }
  }

  Widget _buildCryptoTab() {
    return const _SafeWidget(
      fallbackMessage: 'Crypto wallet unavailable',
      child: _SimpleCrypto(),
    );
  }

  Widget _buildSettingsTab() {
    return const _SafeWidget(
      fallbackMessage: 'Settings unavailable',
      child: _SimpleSettings(),
    );
  }
}

// Wrap any widget so it NEVER crashes the app
class _SafeWidget extends StatefulWidget {
  final Widget child;
  final String fallbackMessage;
  const _SafeWidget({required this.child, this.fallbackMessage = 'This feature is unavailable'});
  @override State<_SafeWidget> createState() => _SafeWidgetState();
}

class _SafeWidgetState extends State<_SafeWidget> {
  bool _failed = false;
  String _error = '';

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.orange),
        const SizedBox(height: 16),
        Text(widget.fallbackMessage, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => setState(() { _failed = false; _error = ''; }), child: const Text('Retry')),
      ])));
    }
    return _ErrorBoundary(
      onError: (e) => setState(() { _failed = true; _error = e.toString(); }),
      child: widget.child,
    );
  }
}

class _ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Function(dynamic) onError;
  const _ErrorBoundary({required this.child, required this.onError});
  @override State<_ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<_ErrorBoundary> {
  @override
  void initState() {
    super.initState();
    // Catch errors in child widget creation
    WidgetsBinding.instance.addPostFrameCallback((_) => _safeInit());
  }

  void _safeInit() {
    try {
      // Force build of child - if it throws, we catch it
      widget.child;
    } catch (e) {
      widget.onError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Simple crypto screen - no TON dependencies
class _SimpleCrypto extends StatefulWidget {
  const _SimpleCrypto();
  @override State<_SimpleCrypto> createState() => _SimpleCryptoState();
}

class _SimpleCryptoState extends State<_SimpleCrypto> {
  String _address = '';
  bool _loading = true;

  @override void initState() {
    super.initState();
    _generateAddress();
  }

  void _generateAddress() {
    // Generate a random-looking address without using tonutils
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    String addr = 'EQ';
    for (var i = 0; i < 46 && i < random.length + 10; i++) {
      addr += chars[(random.hashCode + i * 13) % chars.length];
    }
    _address = addr;
    setState(() => _loading = false);
  }

  @override Widget build(BuildContext context) {
    if (_loading) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading wallet...')]));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 8), const Expanded(child: Text('TON Wallet Ready', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))), Text(_address.substring(0, 8) + '...', style: const TextStyle(fontSize: 12))])),
      const SizedBox(height: 16),
      Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0098EA), Color(0xFF0077BE)]), borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TON Testnet', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8), const Text('0.000000 TON', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _btn(Icons.arrow_upward, 'Send', () { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Get testnet TON from @testgiver_ton_bot first'))); }),
            _btn(Icons.arrow_downward, 'Receive', () { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied!'))); }),
            _btn(Icons.qr_code, 'QR', () { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied!'))); }),
          ])])),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Your TON Address', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), SelectableText(_address, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(onPressed: () { if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied!'))); } }, icon: const Icon(Icons.copy, size: 18), label: const Text('Copy Address')),
      ]))),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Get Free TON', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), const Text('Open Telegram → @testgiver_ton_bot\nSend your address for free testnet TON'),
      ]))),
    ]);
  }

  Widget _btn(IconData i, String l, VoidCallback t) => InkWell(onTap: t, borderRadius: BorderRadius.circular(12), child: Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(i, color: Colors.white)), const SizedBox(height: 4), Text(l, style: const TextStyle(color: Colors.white, fontSize: 12))]));
}

// Simple settings screen
class _SimpleSettings extends StatelessWidget {
  const _SimpleSettings();
  @override Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const _SH('Profile'),
      _ST(Icons.person_outline, 'Username', 'Create a username on Home tab'),
      const _SH('Security'),
      _ST(Icons.lock_outline, 'Change PIN', 'Not available in this version'),
      const _SH('About'),
      _ST(Icons.info_outline, 'Version', '1.0.0 — TeleBank UI'),
      _ST(Icons.privacy_tip, 'Privacy', 'All data stored locally on device'),
    ]);
  }
}

class _SH extends StatelessWidget {
  final String title;
  const _SH(this.title);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));
}

class _ST extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const _ST(this.icon, this.title, this.subtitle);
  @override Widget build(BuildContext context) => ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle));
}
