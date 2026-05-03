import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/supabase_service.dart';
import '../../../core/theme.dart';
import '../../../config/constants.dart';
import '../../ussd/presentation/ussd_screen.dart';

class BankHomeScreen extends StatefulWidget {
  const BankHomeScreen({super.key});
  @override State<BankHomeScreen> createState() => _BankHomeScreenState();
}

class _BankHomeScreenState extends State<BankHomeScreen> {
  String _username = '';
  String? _userId;
  double _balance = 100.00; // Sign-up bonus
  bool _showBalance = true;
  List<Map<String, dynamic>> _txns = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await SharedPreferences.getInstance();
    _username = p.getString('username') ?? '';

    // Try Supabase first
    final userId = p.getString('supabase_user_id');
    if (userId != null) {
      _userId = userId;
      final bal = await SupabaseService.getBalance(userId);
      if (bal != null) _balance = bal;
      final txns = await SupabaseService.getTransactions(userId);
      _txns = txns.map((t) => {
        'title': t['description'] ?? t['type'] ?? 'Transaction',
        'date': (t['created_at'] ?? '').toString().substring(0, 16).replaceFirst('T', ' '),
        'amount': "${t['sender_id'] == userId ? '-' : '+'}ETB ${double.parse(t['amount'].toString()).toStringAsFixed(2)}",
        'in': t['receiver_id'] == userId,
      }).toList();
    }
    setState(() => _loading = false);
  }

  Future<void> _saveTxn(String title, String amount, bool isIn) async {
    final now = DateTime.now();
    final dateStr = '${now.month}/${now.day}, ${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    _txns.insert(0, {'title': title, 'date': dateStr, 'amount': amount, 'in': isIn});
    final p = await SharedPreferences.getInstance();
    final ts = p.getStringList('telebank_txns') ?? [];
    ts.insert(0, '$title|$dateStr|$amount|${isIn ? 1 : 0}');
    await p.setStringList('telebank_txns', ts);
    setState(() {});
  }

  Future<void> _saveBal(double b) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('wallet_balance', b);
    _balance = b;
    setState(() {});
  }

  void _checkUsername() { if (_username.isEmpty) _showUsernameDialog(); }

  void _showUsernameDialog() {
    final ctrl = TextEditingController();
    String err = '';
    bool checking = false;
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(builder: (ctx2, s) => AlertDialog(
      title: const Text('👤 Create Username'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Choose a username to send and receive birr. Must be unique!'),
        const SizedBox(height: 12),
        TextField(controller: ctrl, decoration: InputDecoration(labelText: 'Username', prefixText: '@', errorText: err.isEmpty ? null : err, suffixIcon: checking ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null), autofocus: true),
        const SizedBox(height: 8), const Text('3-20 chars, letters, numbers, underscores only', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
      actions: [FilledButton(onPressed: checking ? null : () async {
        final u = ctrl.text.trim().toLowerCase();
        if (u.length < 3 || u.length > 20 || !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(u)) { s(() => err = u.isEmpty ? 'Required' : 'Invalid format'); return; }
        // Check if username exists on Supabase
        s(() { checking = true; err = ''; });
        try {
          final existing = await SupabaseService.supabase.from('users').select().eq('username', u).maybeSingle();
          if (existing != null) { s(() { err = 'Username already taken! Try another.'; checking = false; }); return; }
        } catch (_) {}
        // Register on Supabase
        final result = await SupabaseService.register(u, '1234'); // temp pin for now
        if (result.containsKey('error')) { s(() { err = result['error'].toString(); checking = false; }); return; }
        final p = await SharedPreferences.getInstance();
        await p.setString('username', u);
        await p.setString('supabase_user_id', result['id']);
        setState(() => _username = u);
        Navigator.pop(ctx);
      }, child: checking ? const Text('Checking...') : const Text('Continue'))],
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
    // Verify recipient exists
    try {
      final recipient = await SupabaseService.supabase.from('users').select().eq('username', val.toLowerCase()).maybeSingle();
      if (recipient == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User @$val not found'))); return; }
    } catch (_) {}
    if (_userId != null) {
      final result = await SupabaseService.sendMoney(_userId!, val, amt, 'send');
      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'])));
        _load();
        return;
      }
      _load();
    } else {
      _saveBal(_balance - amt);
      _saveTxn('Sent to @$val', '-ETB ${amt.toStringAsFixed(2)}', false);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent ETB ${amt.toStringAsFixed(2)} to @$val')));
  });}

  void _showRequest() { _showDialog(title: '📥 Request Money', icon: Icons.arrow_downward, color: AppColors.info, fieldLabel: 'Request from @Username', onConfirm: (val, amt) async {
    if (_userId != null) {
      final result = await SupabaseService.sendMoney(_userId!, val, amt, 'request');
      if (result.containsKey('error')) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']))); _load(); return; }
      _load();
    } else {
      _saveTxn('Request to @$val', '+ETB ${amt.toStringAsFixed(2)}', true);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent!')));
  });}

  void _showAirtime() { _showDialog(title: '📱 Buy Airtime', icon: Icons.phone_android, color: AppColors.navyBlue, fieldLabel: 'Phone Number', fieldHint: '09XXXXXXXX', keyType: TextInputType.phone, onConfirm: (val, amt) async {
    if (_userId != null) { final result = await SupabaseService.sendMoney(_userId!, 'SYSTEM', amt, 'airtime'); if (result.containsKey('error')) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']))); return; } _load(); }
    else { _saveBal(_balance - amt); _saveTxn('Airtime - $val', '-ETB ${amt.toStringAsFixed(2)}', false); }
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

  void _showReceipt(Map<String, dynamic> txn) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Row(children: [const Icon(Icons.receipt_long, color: AppColors.ethiopianGreen), const SizedBox(width: 8), const Text('Transaction Receipt')]),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: AppColors.ethiopianGreen, width: 2), borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Column(children: [
              Text('TeleBank', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
              const Text('Transaction Receipt', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(),
            ])),
            const SizedBox(height: 12),
            _receiptRow('Type', txn['title']),
            _receiptRow('Amount', txn['amount']),
            _receiptRow('Status', txn['in'] ? '✅ Credited' : '✅ Debited'),
            _receiptRow('Date', txn['date']),
            _receiptRow('Account', '****1234'),
            const Divider(),
            Center(child: Text(_username.isEmpty ? 'User' : '@$_username', style: const TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: txn['in'] ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text(txn['in'] ? 'SUCCESS' : 'SENT', style: TextStyle(color: txn['in'] ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold)))),
          ])),
      ])),
      actions: [
        TextButton(onPressed: () { Clipboard.setData(ClipboardData(text: 'TeleBank Receipt\\n${txn['title']}\\n${txn['amount']}\\n${txn['date']}')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt copied!'))); }, child: const Text('Copy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    ));
  }

  Widget _receiptRow(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]));

}