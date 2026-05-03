import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../config/constants.dart';
import '../../ussd/presentation/ussd_screen.dart';

class BankHomeScreen extends StatefulWidget {
  const BankHomeScreen({super.key});
  @override State<BankHomeScreen> createState() => _BankHomeScreenState();
}

class _BankHomeScreenState extends State<BankHomeScreen> {
  String _username = '';
  double _balance = 4250.00;
  bool _showBalance = true;
  List<Map<String, dynamic>> _txns = [];

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _username = p.getString('username') ?? '';
    _balance = p.getDouble('wallet_balance') ?? 4250.00;
    final ts = p.getStringList('telebank_txns') ?? [];
    if (ts.isEmpty) {
      _txns = [
        {'title': 'Salary Deposit', 'date': 'Today, 9:00 AM', 'amount': '+ETB 3,500.00', 'in': true},
        {'title': 'Airtime Purchase', 'date': 'Yesterday, 3:15 PM', 'amount': '-ETB 100.00', 'in': false},
        {'title': 'Bill Payment - Ethio Telecom', 'date': 'May 2, 11:30 AM', 'amount': '-ETB 450.00', 'in': false},
      ];
    } else {
      for (final t in ts) { final parts = t.split('|'); if (parts.length >= 4) _txns.add({'title': parts[0], 'date': parts[1], 'amount': parts[2], 'in': parts[3] == '1'}); }
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveTxn(String title, String amount, bool isIn) async {
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateStr = '${now.month}/${now.day}, ${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    _txns.insert(0, {'title': title, 'date': dateStr, 'amount': amount, 'in': isIn});
    await p.setStringList('telebank_txns', _txns.map((t) => '${t['title']}|${t['date']}|${t['amount']}|${t['in'] ? 1 : 0}').toList());
    setState(() {});
  }

  Future<void> _saveBal(double b) async { final p = await SharedPreferences.getInstance(); await p.setDouble('wallet_balance', b); _balance = b; setState(() {}); }

  void _checkUsername() { if (_username.isEmpty) _showUsernameDialog(); }

  void _showUsernameDialog() {
    final ctrl = TextEditingController();
    String err = '';
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(builder: (ctx2, s) => AlertDialog(
      title: const Text('👤 Create Username'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Choose a username to send and receive birr.'),
        const SizedBox(height: 12),
        TextField(controller: ctrl, decoration: InputDecoration(labelText: 'Username', prefixText: '@', errorText: err.isEmpty ? null : err), autofocus: true),
        const SizedBox(height: 8), const Text('3-20 chars, letters, numbers, underscores', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
      actions: [FilledButton(onPressed: () {
        final u = ctrl.text.trim();
        if (u.length < 3 || u.length > 20 || !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(u)) { s(() => err = u.isEmpty ? 'Required' : 'Invalid format'); return; }
        SharedPreferences.getInstance().then((p) => p.setString('username', u));
        setState(() => _username = u);
        Navigator.pop(ctx);
      }, child: const Text('Continue'))],
    )));
  }

  // Generic amount+input dialog
  void _showDialog({required String title, required IconData icon, required Color color, required String fieldLabel, String? fieldHint, TextInputType? keyType, required Future<void> Function(String val, double amt) onConfirm}) {
    final c1 = TextEditingController(), c2 = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Expanded(child: Text(title))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c1, decoration: InputDecoration(labelText: fieldLabel, hintText: fieldHint), keyboardType: keyType),
        const SizedBox(height: 12),
        TextField(controller: c2, decoration: const InputDecoration(labelText: 'Amount (ETB)'), keyboardType: TextInputType.number),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final amt = double.tryParse(c2.text);
          if (amt == null || amt <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount'))); return; }
          if (amt > _balance) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance'))); return; }
          Navigator.pop(context);
          await onConfirm(c1.text.trim(), amt);
        }, child: const Text('Confirm'))],
    ));
  }

  void _showSendBirr() { _checkUsername(); _showDialog(title: '💸 Send Birr', icon: Icons.send, color: AppColors.ethiopianGreen, fieldLabel: 'Recipient @Username', fieldHint: 'john_doe', onConfirm: (val, amt) async {
    if (val.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter username'))); return; }
    _saveBal(_balance - amt); _saveTxn('Sent to @$val', '-ETB ${amt.toStringAsFixed(2)}', false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent ETB ${amt.toStringAsFixed(2)} to @$val')));
  });}

  void _showRequest() { _showDialog(title: '📥 Request Money', icon: Icons.arrow_downward, color: AppColors.info, fieldLabel: 'Request from @Username', onConfirm: (val, amt) async {
    _saveTxn('Request to @$val', '+ETB ${amt.toStringAsFixed(2)}', true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent!')));
  });}

  void _showAirtime() { _showDialog(title: '📱 Buy Airtime', icon: Icons.phone_android, color: AppColors.navyBlue, fieldLabel: 'Phone Number', fieldHint: '09XXXXXXXX', keyType: TextInputType.phone, onConfirm: (val, amt) async {
    _saveBal(_balance - amt); _saveTxn('Airtime - $val', '-ETB ${amt.toStringAsFixed(2)}', false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Airtime purchased!')));
  });}

  void _showCashOut() { _showDialog(title: '💵 Cash Out', icon: Icons.payments, color: AppColors.warning, fieldLabel: 'Agent Phone', fieldHint: '09XXXXXXXX', keyType: TextInputType.phone, onConfirm: (val, amt) async {
    _saveBal(_balance - amt); _saveTxn('Cash Out - $val', '-ETB ${amt.toStringAsFixed(2)}', false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cash out request sent to agent')));
  });}

  void _showMerchant() { _showDialog(title: '🏪 Pay Merchant', icon: Icons.store, color: AppColors.goldenYellow, fieldLabel: 'Merchant ID', fieldHint: 'M12345', onConfirm: (val, amt) async {
    _saveBal(_balance - amt); _saveTxn('Merchant - $val', '-ETB ${amt.toStringAsFixed(2)}', false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment sent to merchant')));
  });}

  void _showBillPay() {
    final c1 = TextEditingController(), c2 = TextEditingController(), c3 = TextEditingController();
    String? _provider;
    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, s) => AlertDialog(
      title: const Text('🧾 Pay Bill'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: _provider, decoration: const InputDecoration(labelText: 'Service Provider'),
          items: const [DropdownMenuItem(value: 'Ethio Telecom', child: Text('Ethio Telecom')), DropdownMenuItem(value: 'EEU', child: Text('Ethiopian Electric')), DropdownMenuItem(value: 'AAWSA', child: Text('Water & Sewer')), DropdownMenuItem(value: 'DSTV', child: Text('DSTV'))],
          onChanged: (v) => s(() => _provider = v)),
        const SizedBox(height: 12),
        TextField(controller: c1, decoration: const InputDecoration(labelText: 'Account/Reference Number')),
        const SizedBox(height: 12),
        TextField(controller: c2, decoration: const InputDecoration(labelText: 'Amount (ETB)'), keyboardType: TextInputType.number),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final amt = double.tryParse(c2.text);
          if (_provider == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select provider'))); return; }
          if (amt == null || amt <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount'))); return; }
          if (amt > _balance) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance'))); return; }
          Navigator.pop(context);
          _saveBal(_balance - amt); _saveTxn('Bill - $_provider', '-ETB ${amt.toStringAsFixed(2)}', false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill paid successfully!')));
        }, child: const Text('Pay'))],
    )));
  }

  void _showUSSD() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UssdScreen()));

  void _showScheduled() => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('📅 Scheduled Payments'),
    content: _txns.where((t) => t['title'].toString().contains('Scheduled')).isEmpty ? const Text('No scheduled payments')
      : Column(mainAxisSize: MainAxisSize.min, children: _txns.where((t) => t['title'].toString().contains('Scheduled')).map((t) => ListTile(title: Text(t['title']), subtitle: Text(t['date']), trailing: Text(t['amount']))).toList()),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
  ));

  @override
  Widget build(BuildContext context) {
    if (_username.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.person_add, size: 80, color: AppColors.ethiopianGreen),
        const SizedBox(height: 16), const Text('Create Your Username', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), const Text('Choose a username to send and receive birr', textAlign: TextAlign.center),
        const SizedBox(height: 24), ElevatedButton.icon(onPressed: _showUsernameDialog, icon: const Icon(Icons.check), label: const Text('Get Started')),
      ])));
    }
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF7F5EF), Color(0xFFE8F1F5)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // Balance Card
        Container(decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.getShadow(4)),
          padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ሰላም, @$_username! 👋', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const Text('CBE Birr Account', style: TextStyle(color: Colors.white70, fontSize: 14))]),
              Row(children: [IconButton(icon: const Icon(Icons.sync, color: Colors.white), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Balance synced')))),
                PopupMenuButton<String>(icon: const Icon(Icons.more_vert, color: Colors.white), itemBuilder: (_) => [const PopupMenuItem(value: 'name', child: Text('Change Username'))],
                  onSelected: (v) { if (v == 'name') _showUsernameDialog(); })]),
            ]),
            const SizedBox(height: 16),
            Row(children: [Expanded(child: Text(_showBalance ? 'ETB ${_balance.toStringAsFixed(2)}' : '****', style: const TextStyle(color: AppColors.warmGold, fontSize: 32, fontWeight: FontWeight.bold))),
              IconButton(icon: Icon(_showBalance ? Icons.visibility : Icons.visibility_off, color: Colors.white), onPressed: () => setState(() => _showBalance = !_showBalance)),
            ]),
            const Text('****1234', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 4), const Text('Last synced: Just now', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ])),
        const SizedBox(height: 24),
        // Quick Actions
        Text('Quick Actions', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 4, childAspectRatio: 0.85, mainAxisSpacing: 8, crossAxisSpacing: 8, children: [
          _act(Icons.arrow_upward, 'Send', AppColors.ethiopianGreen, _showSendBirr),
          _act(Icons.arrow_downward, 'Request', AppColors.info, _showRequest),
          _act(Icons.payments, 'Cash Out', AppColors.warning, _showCashOut),
          _act(Icons.phone_android, 'Airtime', AppColors.navyBlue, _showAirtime),
          _act(Icons.receipt_long, 'Bill Pay', AppColors.tealGreen, _showBillPay),
          _act(Icons.calendar_today, 'Scheduled', AppColors.deepGreen, _showScheduled),
          _act(Icons.store, 'Merchant', AppColors.goldenYellow, _showMerchant),
          _act(Icons.phone_in_talk, 'USSD', AppColors.lightBlue, _showUSSD),
        ]),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Recent Transactions', style: AppTextStyles.heading3), TextButton(onPressed: _showAllTxns, child: const Text('View All'))]),
        const SizedBox(height: 8),
        ..._txns.take(5).map((t) => Card(child: ListTile(
          leading: CircleAvatar(backgroundColor: (t['in'] ? AppColors.success : AppColors.error).withOpacity(0.1), child: Icon(t['in'] ? Icons.arrow_downward : Icons.arrow_upward, color: t['in'] ? AppColors.success : AppColors.error)),
          title: Text(t['title']), subtitle: Text(t['date']),
          trailing: Text(t['amount'], style: TextStyle(fontWeight: FontWeight.bold, color: t['in'] ? AppColors.success : AppColors.error)),
        ))),
        if (_txns.isEmpty) const Center(child: Text('No transactions yet')),
      ]),
    );
  }

  Widget _act(IconData i, String l, Color c, VoidCallback t) => Card(child: InkWell(onTap: t, borderRadius: BorderRadius.circular(12), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(i, color: c, size: 24)),
    const SizedBox(height: 6), Text(l, style: AppTextStyles.caption, textAlign: TextAlign.center),
  ])));

  void _showAllTxns() => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Transaction History'),
    content: SizedBox(width: double.maxFinite, child: ListView(shrinkWrap: true, children: _txns.map((t) => ListTile(
      leading: Icon(t['in'] ? Icons.arrow_downward : Icons.arrow_upward, color: t['in'] ? Colors.green : Colors.red),
      title: Text(t['title']), subtitle: Text(t['date']), trailing: Text(t['amount'], style: TextStyle(color: t['in'] ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
    )).toList())), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
  ));
}
