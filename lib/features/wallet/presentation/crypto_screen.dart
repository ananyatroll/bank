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
  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen> {
  String _mnemonic = '', _address = '', _balance = '0.00';
  bool _loading = true;
  final List<Map> _txns = [];

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    var m = prefs.getString('ton_mnemonic');
    if (m == null) { m = bip39.generateMnemonic(); await prefs.setString('ton_mnemonic', m); }
    _mnemonic = m;
    final h = sha256.convert(bip39.mnemonicToSeed(m)).bytes;
    final a = base64.encode(h.sublist(0, 32)).replaceAll(RegExp(r'[+/=]'), '');
    _address = 'EQ${a.substring(0, 44)}';
    _balance = (prefs.getDouble('ton_bal') ?? 0.0).toStringAsFixed(2);
    final ts = prefs.getStringList('ton_txns') ?? [];
    for (final t in ts) { final p = t.split('|'); if (p.length >= 3) _txns.add({'type':p[0],'amount':p[1],'to':p[2]}); }
    setState(() => _loading = false);
  }

  Future<void> _saveBal(double b) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ton_bal', b);
    _balance = b.toStringAsFixed(2);
    setState(() {});
  }

  Future<void> _saveTxn(String type, String amt, String to) async {
    final prefs = await SharedPreferences.getInstance();
    _txns.insert(0, {'type':type,'amount':amt,'to':to});
    await prefs.setStringList('ton_txns', _txns.map((t) => '${t['type']}|${t['amount']}|${t['to']}').toList());
    setState(() {});
  }

  void _showReceive() => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Receive TON'), content: Column(mainAxisSize: MainAxisSize.min, children: [
    QrImageView(data: _address, size: 200, backgroundColor: Colors.white),
    const SizedBox(height: 12), SelectableText(_address, style: const TextStyle(fontSize: 11)),
  ]), actions: [TextButton(onPressed:(){Clipboard.setData(ClipboardData(text:_address));Navigator.pop(context);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Copied')));},child: const Text('Copy')),
    FilledButton(onPressed:()=>Navigator.pop(context),child: const Text('Close'))]));

  void _showSend() {
    final c1 = TextEditingController(), c2 = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send TON'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: c1, decoration: const InputDecoration(labelText: 'Recipient (EQ...)')),
          const SizedBox(height: 12),
          TextField(controller: c2, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Amount', helperText: 'Balance: $_balance TON')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            final amt = double.tryParse(c2.text);
            if (amt == null || amt <= 0) return;
            Navigator.pop(context);
            setState(() => _loading = true);
            await Future.delayed(const Duration(seconds: 1));
            final cur = double.parse(_balance);
            await _saveBal(cur - amt);
            await _saveTxn('sent', amt.toStringAsFixed(2), c1.text);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent \$amt TON')));
            setState(() => _loading = false);
          }, child: const Text('Send')),
        ],
      ),
    );
  }

  void _showMnemonic() => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('⚠️ Backup Mnemonic'), content: Column(mainAxisSize:MainAxisSize.min,children:[
    const Text('Write down these 12 words!'), const SizedBox(height:12),
    Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:AppColors.bgDark,borderRadius:BorderRadius.circular(8)),
      child: Text(_mnemonic, style:const TextStyle(color:Colors.white,fontFamily:'monospace',fontSize:14))),
  ]), actions: [FilledButton(onPressed:(){Clipboard.setData(ClipboardData(text:_mnemonic));Navigator.pop(context);},child: const Text('Copy')),
    FilledButton(onPressed:()=>Navigator.pop(context),child: const Text('Done'))]));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0098EA), Color(0xFF0077BE)]), borderRadius: BorderRadius.circular(20), boxShadow: AppColors.getShadow(4)),
        padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TON Testnet Wallet', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('$_balance TON', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _actBtn(Icons.arrow_upward, 'Send', _showSend), _actBtn(Icons.arrow_downward, 'Receive', _showReceive),
            _actBtn(Icons.history, 'History', () {}), _actBtn(Icons.qr_code, 'QR', _showReceive),
          ])])),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Wallet Address', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), SelectableText(_address, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(onPressed:(){Clipboard.setData(ClipboardData(text:_address));ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Copied')));},icon:const Icon(Icons.copy,size:18),label:const Text('Copy')),
      ]))),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.security, color: AppColors.warning), const SizedBox(width:8), const Text('Backup Mnemonic', style: TextStyle(fontWeight:FontWeight.bold))]),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _showMnemonic, icon: const Icon(Icons.visibility), label: const Text('Show Mnemonic')),
      ]))),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Get Testnet TON', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Telegram: @testgiver_ton_bot', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Send your address to the bot to receive free testnet TON'),
      ]))),
      if (_txns.isNotEmpty) ...[
        const SizedBox(height: 16), const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._txns.map((t) => Card(child: ListTile(
          leading: Icon(t['type']=='sent'?Icons.arrow_upward:Icons.arrow_downward, color: t['type']=='sent'?Colors.red:Colors.green),
          title: Text('${t['type']=='sent'?'Sent':'Received'} ${t['amount']} TON'),
          subtitle: Text(t['to'].toString().substring(0, 12)),
        ))),
      ],
    ]);
  }

  Widget _actBtn(IconData i, String l, VoidCallback tap) => InkWell(onTap: tap, borderRadius: BorderRadius.circular(12),
    child: Column(children: [Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white.withOpacity(0.2),borderRadius:BorderRadius.circular(12)),child:Icon(i,color:Colors.white)),
      const SizedBox(height:4),Text(l,style:const TextStyle(color:Colors.white,fontSize:12))]));
}
