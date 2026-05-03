import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../bank/presentation/bank_home_screen.dart';
import '../../../core/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

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
            const BottomNavigationBarItem(icon: Icon(Icons.monetization_on), label: 'ETH'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _getTab(int index) {
    switch (index) {
      case 0: return const _SafeWidget(child: BankHomeScreen());
      case 1: return const _EthDemoTab();
      case 2: return const _SimpleSettings();
      default: return const _SafeWidget(child: BankHomeScreen());
    }
  }
}

// ETH Demo Tab - send/receive by username
class _EthDemoTab extends StatefulWidget {
  const _EthDemoTab();
  @override State<_EthDemoTab> createState() => _EthDemoTabState();
}

class _EthDemoTabState extends State<_EthDemoTab> {
  String _myUsername = '';
  double _ethBalance = 0.0;
  List<Map<String, dynamic>> _ethTxns = [];
  bool _loading = true;
  final TextEditingController _recipientCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _recipientCtrl.dispose(); _amountCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final p = await SharedPreferences.getInstance();
      _myUsername = p.getString('username') ?? '';
      _ethBalance = p.getDouble('eth_balance_$_myUsername') ?? 0.0;
      if (_ethBalance == 0.0 && _myUsername.isNotEmpty) {
        // Give new user 1.0 ETH demo balance
        _ethBalance = 1.0;
        await p.setDouble('eth_balance_$_myUsername', 1.0);
        _ethTxns = [{'title': 'Welcome Bonus', 'amount': '+1.0000 ETH', 'date': 'Today', 'in': true}];
        await p.setStringList('eth_txns_$_myUsername', ['Welcome Bonus|+1.0000 ETH|Today|1']);
      } else {
        final ts = p.getStringList('eth_txns_$_myUsername') ?? [];
        for (final t in ts) {
          final parts = t.split('|');
          if (parts.length >= 4) _ethTxns.add({'title': parts[0], 'amount': parts[1], 'date': parts[2], 'in': parts[3] == '1'});
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _sendEth() async {
    final recipient = _recipientCtrl.text.trim().toLowerCase();
    final amount = double.tryParse(_amountCtrl.text);
    if (_myUsername.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a username on Home tab first'))); return; }
    if (recipient.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter recipient username'))); return; }
    if (recipient == _myUsername) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Can't send to yourself"))); return; }
    if (amount == null || amount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid amount'))); return; }
    if (amount > _ethBalance) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient ETH balance'))); return; }

    try {
      final p = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dateStr = '${now.month}/${now.day} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      // Debit from sender
      _ethBalance -= amount;
      await p.setDouble('eth_balance_$_myUsername', _ethBalance);
      _ethTxns.insert(0, {'title': 'Sent to @$recipient', 'amount': '-${amount.toStringAsFixed(4)} ETH', 'date': dateStr, 'in': false});
      await _saveTxns(p);

      // Credit to recipient (even if they don't exist yet - their balance will be created when they open the app)
      double recipientBal = p.getDouble('eth_balance_$recipient') ?? 0.0;
      recipientBal += amount;
      await p.setDouble('eth_balance_$recipient', recipientBal);
      final rTxns = p.getStringList('eth_txns_$recipient') ?? [];
      rTxns.insert(0, 'Received from @$_myUsername|+${amount.toStringAsFixed(4)} ETH|$dateStr|1');
      await p.setStringList('eth_txns_$recipient', rTxns);

      _recipientCtrl.clear();
      _amountCtrl.clear();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent ${amount.toStringAsFixed(4)} ETH to @$recipient')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _saveTxns(SharedPreferences p) async {
    final list = _ethTxns.map((t) => '${t['title']}|${t['amount']}|${t['date']}|${t['in'] ? 1 : 0}').toList();
    await p.setStringList('eth_txns_$_myUsername', list);
  }

  Future<void> _resetBalance() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('eth_balance_$_myUsername', 1.0);
    _ethBalance = 1.0;
    _ethTxns = [{'title': 'Balance Reset', 'amount': '+1.0000 ETH', 'date': 'Today', 'in': true}];
    await _saveTxns(p);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ETH balance reset to 1.0')));
    }
  }

  @override Widget build(BuildContext context) {
    if (_myUsername.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.monetization_on, size: 80, color: AppColors.ethiopianGreen),
        const SizedBox(height: 16),
        const Text('Demo ETH Wallet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Create a username on the Home tab to start sending and receiving ETH', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.home), label: const Text('Go to Home')),
      ])));
    }
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Balance card
      Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF627EEA), Color(0xFF3C5BD6)]), borderRadius: BorderRadius.circular(20), boxShadow: AppColors.getShadow(4)),
        padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.monetization_on, color: Colors.white, size: 28), const SizedBox(width: 8), const Text('Ethereum Demo', style: TextStyle(color: Colors.white70, fontSize: 16))]),
          const SizedBox(height: 8),
          Text('${_ethBalance.toStringAsFixed(4)} ETH', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4), Text('Balance for @$_myUsername', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _resetBalance, icon: const Icon(Icons.refresh, size: 18), label: const Text('Reset Balance'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30)))),
          ]),
        ])),
      const SizedBox(height: 20),
      // Send section
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.send, color: AppColors.ethiopianGreen), const SizedBox(width: 8), const Text('Send ETH', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 12),
        TextField(controller: _recipientCtrl, decoration: const InputDecoration(labelText: 'Recipient @Username', hintText: 'john_doe', border: OutlineInputBorder()),
          textInputAction: TextInputAction.next),
        const SizedBox(height: 12),
        TextField(controller: _amountCtrl, decoration: const InputDecoration(labelText: 'Amount (ETH)', hintText: '0.001'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 48, child: FilledButton.icon(onPressed: _sendEth, icon: const Icon(Icons.send), label: const Text('Send ETH'))),
      ]))),
      const SizedBox(height: 16),
      // How it works
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📖 How Demo ETH Works', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('• You start with 1.0 ETH\n• Send to any username (even if they don\'t exist yet)\n• When they open this tab, they\'ll see the received ETH\n• All data stored locally on this device\n• Click "Reset Balance" to get 1.0 ETH back', style: TextStyle(fontSize: 13)),
      ]))),
      const SizedBox(height: 16),
      // Transaction history
      Row(children: [const Text('ETH Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Spacer(), TextButton(onPressed: _load, child: const Text('Refresh'))]),
      if (_ethTxns.isEmpty) const Center(child: Text('No ETH transactions yet')) else
        ..._ethTxns.map((t) => Card(child: ListTile(
          leading: CircleAvatar(backgroundColor: (t['in'] ? Colors.green : Colors.red).withOpacity(0.1), child: Icon(t['in'] ? Icons.arrow_downward : Icons.arrow_upward, color: t['in'] ? Colors.green : Colors.red)),
          title: Text(t['title']),
          subtitle: Text(t['date']),
          trailing: Text(t['amount'], style: TextStyle(fontWeight: FontWeight.bold, color: t['in'] ? Colors.green : Colors.red)),
        ))),
    ]);
  }
}

// Error boundary widget
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _safeInit());
  }

  void _safeInit() {
    try { widget.child; } catch (e) { if (mounted) setState(() { _failed = true; _error = e.toString(); }); }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.orange),
        const SizedBox(height: 16), Text(widget.fallbackMessage, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 16), FilledButton(onPressed: () => setState(() { _failed = false; _error = ''; _safeInit(); }), child: const Text('Retry')),
      ])));
    }
    return widget.child;
  }
}

// Simple settings screen
class _SimpleSettings extends StatelessWidget {
  const _SimpleSettings();
  @override Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const _SH('Profile'),
      _ST(Icons.person_outline, 'Username', 'Create a username on Home tab'),
      const _SH('Demo ETH'),
      _ST(Icons.monetization_on, 'Send/Receive ETH', 'Tap the ETH tab'),
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
