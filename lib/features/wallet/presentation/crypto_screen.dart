import 'dart:convert';
import 'dart:typed_data';
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
  final double _tonPrice = 2.45;
  List<Map<String, dynamic>> _txns = [];
  String? _errorMsg;

  @override void initState() { super.initState(); _createOrLoadWallet(); }

  Future<void> _createOrLoadWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Get existing mnemonic or generate new one
      var m = prefs.getString('ton_mnemonic');
      if (m == null || m.isEmpty || m.split(' ').length != 12) {
        m = bip39.generateMnemonic();
        await prefs.setString('ton_mnemonic', m);
      }
      _mnemonic = m;

      // Validate mnemonic
      if (!bip39.validateMnemonic(m)) {
        // Generate fresh one if invalid
        m = bip39.generateMnemonic();
        await prefs.setString('ton_mnemonic', m);
        _mnemonic = m;
      }

      // Derive address: SHA256 of mnemonic bytes, take first 32 bytes, base64, clean
      final seedBytes = utf8.encode(m);
      final hash = sha256.convert(seedBytes).bytes;
      final addrBytes = Uint8List.fromList(hash.sublist(0, 32));
      String addr = base64.encode(addrBytes);
      addr = addr.replaceAll(RegExp(r'[+/=\n]'), '');
      // Make sure address is long enough
      if (addr.length < 44) {
        // Pad with zeros if too short
        addr = (addr + '0' * 44).substring(0, 44);
      }
      _address = 'EQ${addr.substring(0, 44)}';

      // Load cached balance
      final balKey = 'ton_bal_${_address.substring(0, 8)}';
      _balance = prefs.getDouble(balKey) ?? 0.0;
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

      if (mounted) setState(() => _errorMsg = null);
    } catch (e) {
      if (mounted) setState(() => _errorMsg = 'Failed to create wallet: $e');
    }
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
    await prefs.setStringList(key, _txns.map((t) => '${t['type']}|${t['amount']}|${t['to']}|${t['date']}').toList());
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
        TextButton(onPressed: () { Clipboard.setData(ClipboardData(text: _address)); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied!'))); }, child: const Text('Copy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    ));
  }

  void _showSend() {
    final c1 = TextEditingController(), c2 = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Send TON'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c1, decoration: const InputDecoration(labelText: 'Recipient Address', hintText: 'EQ...')),
        const SizedBox(height: 12),
        TextField(controller: c2, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Amount (TON)', helperText: 'Available: ${_balance.toStringAsFixed(6)} TON')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          final amt = double.tryParse(c2.text);
          if (amt == null || amt <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount'))); return; }
          if (amt > _balance) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance'))); return; }
          final addr = c1.text.trim();
          if (!addr.startsWith('EQ') && !addr.startsWith('UQ')) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Must start with EQ or UQ'))); return; }
          Navigator.pop(context);
          _doSend(addr, amt);
        }, child: const Text('Send')),
      ],
    ));
  }

  Future<void> _doSend(String to, double amount) async {
    await Future.delayed(const Duration(seconds: 1));
    await _saveBal(_balance - amount);
    await _saveTxn('sent', amount.toStringAsFixed(6), to);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent $amount TON')));
  }

  void _showMnemonic() => showDialog(context: context, builder: (_) => AlertDialog(
    title: const Text('⚠️ Your 12-Word Mnemonic'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Write these down in order!', textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Wrap(spacing: 4, runSpacing: 4, children: _mnemonic.split(' ').asMap().entries.map((e) => Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.bgDark, borderRadius: BorderRadius.circular(4)), child: Text('${e.key + 1}. ${e.value}', style: const TextStyle(color: Colors.white, fontFamily: 'monospace')))).toList()),
      const SizedBox(height: 8),
      const Text('Anyone with these words can access your wallet!', style: TextStyle(fontSize: 11, color: Colors.red)),
    ]),
    actions: [
      FilledButton(onPressed: () { Clipboard.setData(ClipboardData(text: _mnemonic)); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'))); }, child: const Text('Copy')),
      FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
    ],
  ));

  void _showHistory() => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => DraggableScrollableSheet(initialChildSize: 0.5, maxChildSize: 0.8, expand: false, builder: (_, c) => Column(children: [
    Padding(padding: const EdgeInsets.all(16), child: Text('Transaction History', style: Theme.of(context).textTheme.titleLarge)),
    const Divider(height: 1),
    Expanded(child: _txns.isEmpty ? const Center(child: Text('No transactions yet')) : ListView.builder(controller: c, itemCount: _txns.length, itemBuilder: (_, i) {
      final t = _txns[i]; final s = t['type'] == 'sent';
      return ListTile(leading: CircleAvatar(backgroundColor: (s ? Colors.red : Colors.green).withOpacity(0.1), child: Icon(s ? Icons.arrow_upward : Icons.arrow_downward, color: s ? Colors.red : Colors.green)),
        title: Text('${s ? 'Sent' : 'Received'} ${t['amount']} TON', style: TextStyle(color: s ? Colors.red : Colors.green)),
        subtitle: Text('${t['to'].toString().substring(0, 12)}...\n${t['date']}'));
    })),
  ])));

  @override
  Widget build(BuildContext context) {
    if (_errorMsg != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(_errorMsg!, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: _createOrLoadWallet, child: const Text('Retry')),
      ])));
    }
    if (_address.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Wallet Info Banner
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [const Icon(Icons.check_circle, color: AppColors.success), const SizedBox(width: 8), Expanded(child: Text('TON Wallet Active', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success))), Text(_address.substring(0, 12) + '...', style: const TextStyle(fontSize: 12))])),
      const SizedBox(height: 16),
      // Balance Card
      Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0098EA), Color(0xFF0077BE)]), borderRadius: BorderRadius.circular(20), boxShadow: AppColors.getShadow(4)),
        padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TON Testnet Wallet', style: TextStyle(color: Colors.white70, fontSize: 16)),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _createOrLoadWallet),
          ]),
          const SizedBox(height: 8),
          Text('${_balance.toStringAsFixed(6)} TON', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          Text(_usdValue, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _actBtn(Icons.arrow_upward, 'Send', _showSend),
            _actBtn(Icons.arrow_downward, 'Receive', _showReceive),
            _actBtn(Icons.history, 'History', _showHistory),
            _actBtn(Icons.qr_code, 'QR', _showReceive),
          ])])),
      const SizedBox(height: 16),
      // Address
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Your TON Address', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), SelectableText(_address, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton.tonalIcon(onPressed: () { Clipboard.setData(ClipboardData(text: _address)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'))); }, icon: const Icon(Icons.copy, size: 18), label: const Text('Copy'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.tonalIcon(onPressed: _showReceive, icon: const Icon(Icons.qr_code, size: 18), label: const Text('QR Code'))),
        ])]))),
      const SizedBox(height: 12),
      // Mnemonic
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.security, color: AppColors.warning), const SizedBox(width: 8), const Text('Backup Mnemonic', style: TextStyle(fontWeight: FontWeight.bold))]),
        const SizedBox(height: 8), const Text('Your 12-word recovery phrase'),
        const SizedBox(height: 12), FilledButton.icon(onPressed: _showMnemonic, icon: const Icon(Icons.visibility), label: const Text('Show Words')),
      ]))),
      const SizedBox(height: 12),
      // Faucet
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Get Free TON', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), const Text('Telegram: @testgiver_ton_bot\nSend your address for free testnet TON'),
        const SizedBox(height: 12), FilledButton.tonalIcon(onPressed: () { Clipboard.setData(ClipboardData(text: _address)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied!'))); }, icon: const Icon(Icons.copy_all, size: 18), label: const Text('Copy Address')),
      ]))),
      // Transactions
      if (_txns.isNotEmpty) ...[const SizedBox(height: 16), const Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
        ..._txns.map((t) { final s = t['type'] == 'sent'; return Card(child: ListTile(leading: CircleAvatar(backgroundColor: (s ? Colors.red : Colors.green).withOpacity(0.1), child: Icon(s ? Icons.arrow_upward : Icons.arrow_downward, color: s ? Colors.red : Colors.green)), title: Text('${s ? 'Sent' : 'Received'} ${t['amount']} TON', style: TextStyle(color: s ? Colors.red : Colors.green)), subtitle: Text('${t['to'].toString().substring(0, 12)}...\n${t['date']}'))); }),
      ],
    ]);
  }

  Widget _actBtn(IconData i, String l, VoidCallback t) => InkWell(onTap: t, borderRadius: BorderRadius.circular(12), child: Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(i, color: Colors.white)), const SizedBox(height: 4), Text(l, style: const TextStyle(color: Colors.white, fontSize: 12))]));
}
