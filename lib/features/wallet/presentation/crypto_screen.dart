import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';

class CryptoScreen extends StatefulWidget {
  const CryptoScreen({super.key});
  @override State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen> {
  String _mnemonic = '';
  String _address = '';
  double _balance = 0.0;
  String _usdValue = '\$0.00';
  double _tonPrice = 2.45;
  List<Map<String, dynamic>> _txns = [];

  @override
  void initState() {
    super.initState();
    // Load immediately without network call
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Get or generate mnemonic
      var m = prefs.getString('ton_mnemonic');
      if (m == null || m.isEmpty) {
        m = bip39.generateMnemonic();
        await prefs.setString('ton_mnemonic', m);
      }
      _mnemonic = m;

      // Derive address from mnemonic
      final seed = bip39.mnemonicToSeed(m);
      final hash = sha256.convert(seed).bytes;
      final addr = base64.encode(hash.sublist(0, 32)).replaceAll(RegExp(r'[+/=]'), '');
      _address = 'EQ${addr.substring(0, 44)}';

      // Load cached balance
      final key = 'ton_bal_${_address.substring(0, 8)}';
      _balance = prefs.getDouble(key) ?? 0.0;
      _usdValue = '\$${(_balance * _tonPrice).toStringAsFixed(2)}';

      // Load cached transactions
      final txnKey = 'ton_txns_${_address.substring(0, 8)}';
      final ts = prefs.getStringList(txnKey) ?? [];
      _txns = [];
      for (final t in ts) {
        final p = t.split('|');
        if (p.length >= 4) {
          _txns.add({'type': p[0], 'amount': p[1], 'to': p[2], 'date': p[3]});
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      // Fallback
      _balance = 0.0;
      if (mounted) setState(() {});
    }
  }

  Future<void> _refreshBalance() async {
    setState(() {});
    await _loadWallet();
  }

  Future<void> _saveBal(double b) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'ton_bal_${_address.substring(0, 8)}';
    await prefs.setDouble(key, b);
    _balance = b;
    _usdValue = '\$${(b * _tonPrice).toStringAsFixed(2)}';
    if (mounted) setState(() {});
  }

  Future<void> _saveTxn(String type, String amt, String to) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'ton_txns_${_address.substring(0, 8)}';
    final date = DateTime.now().toString().substring(0, 16);
    _txns.insert(0, {'type': type, 'amount': amt, 'to': to, 'date': date});
    final list = _txns.map((t) => '${t['type']}|${t['amount']}|${t['to']}|${t['date']}').toList();
    await prefs.setStringList(key, list);
    if (mounted) setState(() {});
  }

  void _showReceive() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Receive TON'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        QrImageView(data: _address, size: 200, backgroundColor: Colors.white),
        const SizedBox(height: 12),
        SelectableText(_address, style: const TextStyle(fontSize: 11)),
      ]),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _address));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied!')));
          },
          child: const Text('Copy'),
        ),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    ));
  }

  void _showSend() {
    final addrCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send TON'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: addrCtrl,
            decoration: const InputDecoration(labelText: 'Recipient Address', hintText: 'EQ...'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount (TON)',
              helperText: 'Available: ${_balance.toStringAsFixed(6)} TON',
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text);
              if (amt == null || amt <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid amount')));
                return;
              }
              if (amt > _balance) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
                return;
              }
              final addr = addrCtrl.text.trim();
              if (!addr.startsWith('EQ') && !addr.startsWith('UQ')) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid TON address (must start with EQ or UQ)')));
                return;
              }
              Navigator.pop(context);
              _processSend(addr, amt);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _processSend(String to, double amount) async {
    setState(() {});
    // Simulate network delay for demo
    await Future.delayed(const Duration(seconds: 1));
    await _saveBal(_balance - amount);
    await _saveTxn('sent', amount.toStringAsFixed(6), to);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Sent $amount TON to ${to.substring(0, 12)}...')),
      );
    }
  }

  void _showMnemonic() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Backup Mnemonic'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Write down these 12 words in order. This is the ONLY way to recover your wallet.', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.bgDark, borderRadius: BorderRadius.circular(8)),
            child: Text(
              _mnemonic,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14, letterSpacing: 1),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Keep this safe! Anyone with these words can access your wallet.', style: TextStyle(fontSize: 11, color: Colors.red)),
        ]),
        actions: [
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _mnemonic));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!'), backgroundColor: Colors.orange));
            },
            child: const Text('Copy'),
          ),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Transaction History', style: Theme.of(context).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Expanded(
              child: _txns.isEmpty
                  ? const Center(child: Text('No transactions yet'))
                  : ListView.builder(
                      controller: controller,
                      itemCount: _txns.length,
                      itemBuilder: (_, i) {
                        final t = _txns[i];
                        final isSend = t['type'] == 'sent';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (isSend ? Colors.red : Colors.green).withOpacity(0.1),
                            child: Icon(isSend ? Icons.arrow_upward : Icons.arrow_downward, color: isSend ? Colors.red : Colors.green),
                          ),
                          title: Text('${isSend ? 'Sent' : 'Received'} ${t['amount']} TON',
                              style: TextStyle(color: isSend ? Colors.red : Colors.green)),
                          subtitle: Text('${t['to'].toString().substring(0, 12)}...\n${t['date']}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Balance Card
      Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0098EA), Color(0xFF0077BE)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.getShadow(4),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TON Testnet Wallet', style: TextStyle(color: Colors.white70, fontSize: 16)),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _refreshBalance),
          ]),
          const SizedBox(height: 8),
          Text('${_balance.toStringAsFixed(6)} TON',
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          Text(_usdValue, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _actBtn(Icons.arrow_upward, 'Send', _showSend),
            _actBtn(Icons.arrow_downward, 'Receive', _showReceive),
            _actBtn(Icons.history, 'History', _showHistory),
            _actBtn(Icons.qr_code, 'QR', _showReceive),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      // Address Card
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Wallet Address', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SelectableText(_address, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _address));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied!')));
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Address'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _showReceive,
                  icon: const Icon(Icons.qr_code, size: 18),
                  label: const Text('Show QR'),
                ),
              ),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      // Mnemonic Backup
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.security, color: AppColors.warning),
              const SizedBox(width: 8),
              const Text('Backup Mnemonic', style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            const Text('Store your 12-word phrase safely. Only way to recover wallet.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _showMnemonic,
              icon: const Icon(Icons.visibility),
              label: const Text('Show Mnemonic'),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      // Faucet Card
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Get Free Testnet TON', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('1. Copy your address\n2. Open Telegram → @testgiver_ton_bot\n3. Send your address to receive free TON'),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _address));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied! Open Telegram now')));
              },
              icon: const Icon(Icons.copy_all, size: 18),
              label: const Text('Copy & Open Faucet'),
            ),
          ]),
        ),
      ),
      // Transactions
      if (_txns.isNotEmpty) ...[
        const SizedBox(height: 16),
        const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._txns.map((t) {
          final isSend = t['type'] == 'sent';
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (isSend ? Colors.red : Colors.green).withOpacity(0.1),
                child: Icon(isSend ? Icons.arrow_upward : Icons.arrow_downward, color: isSend ? Colors.red : Colors.green),
              ),
              title: Text('${isSend ? 'Sent' : 'Received'} ${t['amount']} TON',
                  style: TextStyle(color: isSend ? Colors.red : Colors.green)),
              subtitle: Text('${t['to'].toString().substring(0, 12)}...\n${t['date']}'),
            ),
          );
        }),
      ],
    ]);
  }

  Widget _actBtn(IconData i, String l, VoidCallback tap) => InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(i, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(l, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      );
}
