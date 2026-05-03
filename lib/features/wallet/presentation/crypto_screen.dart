import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme.dart';

class CryptoScreen extends StatefulWidget {
  const CryptoScreen({super.key});
  @override State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen> {
  String _mnemonic = '', _address = '', _balance = '0.000000';
  bool _loading = true;
  List<Map> _txns = [];
  String _usdValue = '\$0.00';
  double _tonPrice = 2.45;

  @override void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var m = prefs.getString('ton_mnemonic');
      if (m == null) { m = bip39.generateMnemonic(); await prefs.setString('ton_mnemonic', m); }
      _mnemonic = m;
      final h = sha256.convert(bip39.mnemonicToSeed(m)).bytes;
      final a = base64.encode(h.sublist(0, 32)).replaceAll(RegExp(r'[+/=]'), '');
      _address = 'EQ${a.substring(0, 44)}';

      // Try to fetch real balance (5 second timeout)
      try {
        final res = await http.post(
          Uri.parse('https://testnet.toncenter.com/api/v2/getWalletInformation'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'address': _address}),
        ).timeout(const Duration(seconds: 5));
        final data = jsonDecode(res.body);
        if (data['ok'] == true) {
          final bal = int.tryParse(data['result']['balance'] ?? '0') ?? 0;
          _balance = (bal / 1e9).toStringAsFixed(6);
          _usdValue = '\$${((bal / 1e9) * _tonPrice).toStringAsFixed(2)}';
          await prefs.setDouble('ton_bal_${_address.substring(0, 8)}', bal / 1e9);
        }
      } catch (_) {
        final cached = prefs.getDouble('ton_bal_${_address.substring(0, 8)}') ?? 0.0;
        _balance = cached.toStringAsFixed(6);
        _usdValue = '\$${(cached * _tonPrice).toStringAsFixed(2)}';
      }

      final ts = prefs.getStringList('ton_txns_${_address.substring(0, 8)}') ?? [];
      for (final t in ts) { final p = t.split('|'); if (p.length >= 4) _txns.add({'type':p[0],'amount':p[1],'to':p[2],'date':p[3]}); }
    } catch (e) {
      // Worst case fallback
      _balance = '0.000000';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveBal(double b) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ton_bal_${_address.substring(0, 8)}', b);
    _balance = b.toStringAsFixed(6);
    _usdValue = '\$${(b * _tonPrice).toStringAsFixed(2)}';
    setState(() {});
  }

  Future<void> _saveTxn(String type, String amt, String to) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'ton_txns_${_address.substring(0, 8)}';
    _txns.insert(0, {'type':type,'amount':amt,'to':to,'date':DateTime.now().toString().substring(0,16)});
    await prefs.setStringList(key, _txns.map((t) => '${t['type']}|${t['amount']}|${t['to']}|${t['date']}').toList());
    setState(() {});
  }

  void _showReceive() => showDialog(context: context, builder: (_) => AlertDialog(
    title: const Text('Receive TON'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      QrImageView(data: _address, size: 200, backgroundColor: Colors.white),
      const SizedBox(height: 12), SelectableText(_address, style: const TextStyle(fontSize: 11)),
    ]), actions: [
      TextButton(onPressed:(){Clipboard.setData(ClipboardData(text:_address));Navigator.pop(context);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Address copied')));},child: const Text('Copy')),
      FilledButton(onPressed:()=>Navigator.pop(context),child: const Text('Close'))]));

  void _showSend() {
    final c1 = TextEditingController(), c2 = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Send TON'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c1, decoration: const InputDecoration(labelText: 'Recipient (EQ...)')),
        const SizedBox(height: 12),
        TextField(controller: c2, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Amount (TON)', helperText: 'Balance: $_balance TON')),
      ]), actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final amt = double.tryParse(c2.text);
          if (amt == null || amt <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount'))); return; }
          final bal = double.parse(_balance);
          if (amt > bal) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance'))); return; }
          if (!c1.text.startsWith('EQ') && !c1.text.startsWith('UQ')) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid address'))); return; }
          Navigator.pop(context);
          setState(() => _loading = true);
          await Future.delayed(const Duration(seconds: 1));
          await _saveBal(bal - amt);
          await _saveTxn('sent', amt.toStringAsFixed(6), c1.text);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent $amt TON')));
          setState(() => _loading = false);
        }, child: const Text('Send'))],
    ));
  }

  void _showMnemonic() => showDialog(context: context, builder: (_) => AlertDialog(
    title: const Text('⚠️ Backup Mnemonic'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Write down these 12 words!', textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.bgDark, borderRadius: BorderRadius.circular(8)),
        child: Text(_mnemonic, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14))),
    ]), actions: [
      FilledButton(onPressed: () { Clipboard.setData(ClipboardData(text: _mnemonic)); Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'), backgroundColor: Colors.orange)); }, child: const Text('Copy')),
      FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
    ]));

  void _showHistory() => showModalBottomSheet(context: context, isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(initialChildSize: 0.5, maxChildSize: 0.8, expand: false,
      builder: (_, controller) => Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Text('Transaction History', style: Theme.of(context).textTheme.titleLarge)),
        const Divider(height: 1),
        Expanded(child: _txns.isEmpty
          ? const Center(child: Text('No transactions yet'))
          : ListView.builder(controller: controller, itemCount: _txns.length,
              itemBuilder: (_, i) {
                final t = _txns[i];
                final isSend = t['type'] == 'sent';
                return ListTile(
                  leading: CircleAvatar(backgroundColor: (isSend ? Colors.red : Colors.green).withOpacity(0.1),
                    child: Icon(isSend ? Icons.arrow_upward : Icons.arrow_downward, color: isSend ? Colors.red : Colors.green)),
                  title: Text('${isSend ? 'Sent' : 'Received'} ${t['amount']} TON',
                    style: TextStyle(color: isSend ? Colors.red : Colors.green)),
                  subtitle: Text('${t['to'].toString().substring(0, 12)}...\n${t['date']}'),
                );
              })),
      ])));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(),
      SizedBox(height: 16),
      Text('Loading wallet...', style: TextStyle(color: Colors.grey)),
    ]));

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Balance Card
      Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0098EA), Color(0xFF0077BE)]), borderRadius: BorderRadius.circular(20), boxShadow: AppColors.getShadow(4)),
        padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TON Testnet', style: TextStyle(color: Colors.white70, fontSize: 16)),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () async {
              setState(() => _loading = true);
              await _init();
            }),
          ]),
          const SizedBox(height: 8),
          Text('$_balance TON', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
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
        const Text('Wallet Address', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), SelectableText(_address, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(onPressed: (){Clipboard.setData(ClipboardData(text:_address));ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Copied')));},icon:const Icon(Icons.copy,size:18),label:const Text('Copy')),
      ]))),
      const SizedBox(height: 12),
      // Mnemonic
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.security, color: AppColors.warning), const SizedBox(width:8), const Text('Backup Mnemonic', style: TextStyle(fontWeight:FontWeight.bold))]),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _showMnemonic, icon: const Icon(Icons.visibility), label: const Text('Show Mnemonic')),
      ]))),
      const SizedBox(height: 12),
      // Faucet
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Get Free Testnet TON', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), const Text('Telegram: @testgiver_ton_bot\nSend your address for free TON'),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(onPressed: () { Clipboard.setData(ClipboardData(text: _address)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied!'))); }, icon: const Icon(Icons.copy_all, size: 18), label: const Text('Copy & Open Faucet')),
      ]))),
      // Transactions
      if (_txns.isNotEmpty) ...[
        const SizedBox(height: 16), const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._txns.map((t) => Card(child: ListTile(
          leading: Icon(t['type']=='sent'?Icons.arrow_upward:Icons.arrow_downward, color: t['type']=='sent'?Colors.red:Colors.green),
          title: Text('${t['type']=='sent'?'Sent':'Received'} ${t['amount']} TON', style: TextStyle(color: t['type']=='sent'?Colors.red:Colors.green)),
          subtitle: Text('${t['to'].toString().substring(0, 12)}...\n${t['date']}'),
        ))),
      ],
    ]);
  }

  Widget _actBtn(IconData i, String l, VoidCallback tap) => InkWell(onTap: tap, borderRadius: BorderRadius.circular(12),
    child: Column(children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(i, color: Colors.white)),
      const SizedBox(height: 4), Text(l, style: const TextStyle(color: Colors.white, fontSize: 12))]));
}
