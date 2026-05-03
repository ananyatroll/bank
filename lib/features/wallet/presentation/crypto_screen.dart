import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../services/wallet_manager.dart';
import '../../../services/transaction_service.dart';

class CryptoScreen extends StatefulWidget {
  const CryptoScreen({super.key});
  @override State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen> {
  final _walletManager = WalletManager();
  final _txService = TransactionService();
  WalletState? _wallet;
  double _balance = 0.0;
  String _usdValue = '\$0.00';
  final double _tonPrice = 2.45;
  List<WalletTransaction> _txns = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      _wallet = await _walletManager.loadWallet();
      if (_wallet == null) {
        _wallet = await _walletManager.createWallet();
      }
      // Try to fetch balance from chain (non-blocking)
      try {
        _balance = await _txService.getBalance(_wallet!);
      } catch (_) { _balance = 0.0; }
      _usdValue = '\$${(_balance * _tonPrice).toStringAsFixed(2)}';
      try { _txns = await _txService.getTransactions(_wallet!, limit: 20); } catch (_) { _txns = []; }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    if (_wallet == null || !mounted) { _init(); return; }
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      _balance = await _txService.getBalance(_wallet!);
      _usdValue = '\$${(_balance * _tonPrice).toStringAsFixed(2)}';
      _txns = await _txService.getTransactions(_wallet!, limit: 20);
      await _txService.refreshSeqno(_wallet!);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showReceive() {
    if (_wallet == null || !mounted) return;
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Receive TON'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        QrImageView(data: _wallet!.userFriendlyAddress, size: 200, backgroundColor: Colors.white),
        const SizedBox(height: 12),
        SelectableText(_wallet!.userFriendlyAddress, style: const TextStyle(fontSize: 11)),
      ]),
      actions: [
        TextButton(onPressed: () { Clipboard.setData(ClipboardData(text: _wallet!.userFriendlyAddress)); Navigator.pop(context); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied!'))); }, child: const Text('Copy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    ));
  }

  void _showSend() {
    if (_wallet == null || !mounted) return;
    final addrCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, s) => AlertDialog(
      title: const Text('Send TON'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_sending) const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
        if (!_sending) ...[
          TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Recipient Address', hintText: 'EQ...')),
          const SizedBox(height: 12),
          TextField(controller: amtCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Amount (TON)', helperText: 'Available: ${_balance.toStringAsFixed(6)} TON')),
        ],
      ]),
      actions: [
        TextButton(onPressed: _sending ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        if (!_sending) FilledButton(onPressed: () async {
          final amt = double.tryParse(amtCtrl.text);
          if (amt == null || amt <= 0) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid amount'))); return; }
          if (amt > _balance) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance'))); return; }
          final addr = addrCtrl.text.trim();
          if (!addr.startsWith('EQ') && !addr.startsWith('UQ')) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Must start with EQ or UQ'))); return; }
          s(() => _sending = true);
          try {
            await _txService.sendTon(wallet: _wallet!, destination: addr, amount: amt);
            if (mounted) Navigator.pop(context);
            _refresh();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent $amt TON')));
          } catch (e) {
            s(() => _sending = false);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
          }
        }, child: const Text('Send')),
      ],
    )));
  }

  void _showMnemonic() {
    if (_wallet == null || !mounted) return;
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('⚠️ Your 24-Word Mnemonic'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Write these down in order!', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Wrap(spacing: 4, runSpacing: 4, children: _wallet!.mnemonic.asMap().entries.map((e) => Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.bgDark, borderRadius: BorderRadius.circular(4)), child: Text('${e.key + 1}. ${e.value}', style: const TextStyle(color: Colors.white, fontFamily: 'monospace')))).toList()),
        const SizedBox(height: 8),
        const Text('Anyone with these words can access your wallet!', style: TextStyle(fontSize: 11, color: Colors.red)),
      ]),
      actions: [
        FilledButton(onPressed: () { Clipboard.setData(ClipboardData(text: _wallet!.mnemonic.join(' '))); Navigator.pop(context); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'))); }, child: const Text('Copy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
      ],
    ));
  }

  void _showHistory() {
    if (!mounted) return;
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => DraggableScrollableSheet(initialChildSize: 0.5, maxChildSize: 0.8, expand: false, builder: (_, c) => Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Text('Transaction History', style: Theme.of(context).textTheme.titleLarge)),
      const Divider(height: 1),
      Expanded(child: _txns.isEmpty ? const Center(child: Text('No transactions yet')) : ListView.builder(controller: c, itemCount: _txns.length, itemBuilder: (_, i) {
        final t = _txns[i];
        return ListTile(leading: CircleAvatar(backgroundColor: (t.isIncoming ? Colors.green : Colors.red).withOpacity(0.1), child: Icon(t.isIncoming ? Icons.arrow_downward : Icons.arrow_upward, color: t.isIncoming ? Colors.green : Colors.red)),
          title: Text('${t.isIncoming ? 'Received' : 'Sent'} ${t.amount.toStringAsFixed(6)} TON', style: TextStyle(color: t.isIncoming ? Colors.green : Colors.red)),
          subtitle: Text(t.timestamp.toString().substring(0, 16)));
      })),
    ])));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _wallet == null) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(), SizedBox(height: 16), Text('Initializing wallet...', style: TextStyle(color: Colors.grey)),
      ]));
    }
    if (_error != null && _wallet == null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16), Text('Failed to initialize:\n$_error', textAlign: TextAlign.center),
        const SizedBox(height: 16), FilledButton(onPressed: _init, child: const Text('Retry')),
      ])));
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (_loading) const LinearProgressIndicator(),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.check_circle, color: AppColors.success), const SizedBox(width: 8),
          Expanded(child: Text(_wallet != null ? 'TON Wallet Active' : 'Loading...', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success))),
          if (_wallet != null) Text(_wallet!.shortAddress, style: const TextStyle(fontSize: 12)),
        ])),
      const SizedBox(height: 16),
      // Balance Card
      Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0098EA), Color(0xFF0077BE)]), borderRadius: BorderRadius.circular(20), boxShadow: AppColors.getShadow(4)),
        padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TON Testnet', style: TextStyle(color: Colors.white70, fontSize: 16)),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _refresh),
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
        const SizedBox(height: 8), SelectableText(_wallet?.userFriendlyAddress ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton.tonalIcon(onPressed: () { if (_wallet != null && mounted) { Clipboard.setData(ClipboardData(text: _wallet!.userFriendlyAddress)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'))); } }, icon: const Icon(Icons.copy, size: 18), label: const Text('Copy'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.tonalIcon(onPressed: _showReceive, icon: const Icon(Icons.qr_code, size: 18), label: const Text('QR Code'))),
        ])]))),
      const SizedBox(height: 12),
      // Mnemonic
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.security, color: AppColors.warning), const SizedBox(width: 8), const Text('Backup Mnemonic', style: TextStyle(fontWeight: FontWeight.bold))]),
        const SizedBox(height: 8), const Text('Your 24-word recovery phrase'),
        const SizedBox(height: 12), FilledButton.icon(onPressed: _showMnemonic, icon: const Icon(Icons.visibility), label: const Text('Show Words')),
      ]))),
      const SizedBox(height: 12),
      // Faucet
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Get Free TON', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), const Text('Telegram: @testgiver_ton_bot\nSend your address for free testnet TON'),
        const SizedBox(height: 12), FilledButton.tonalIcon(onPressed: () { if (_wallet != null && mounted) { Clipboard.setData(ClipboardData(text: _wallet!.userFriendlyAddress)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied!'))); } }, icon: const Icon(Icons.copy_all, size: 18), label: const Text('Copy Address')),
      ]))),
      // Transactions
      if (_txns.isNotEmpty) ...[const SizedBox(height: 16), const Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
        ..._txns.map((t) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: (t.isIncoming ? Colors.green : Colors.red).withOpacity(0.1), child: Icon(t.isIncoming ? Icons.arrow_downward : Icons.arrow_upward, color: t.isIncoming ? Colors.green : Colors.red)),
          title: Text('${t.isIncoming ? 'Received' : 'Sent'} ${t.amount.toStringAsFixed(6)} TON', style: TextStyle(color: t.isIncoming ? Colors.green : Colors.red)),
          subtitle: Text(t.timestamp.toString().substring(0, 16))))),
      ],
    ]);
  }

  Widget _actBtn(IconData i, String l, VoidCallback t) => InkWell(onTap: t, borderRadius: BorderRadius.circular(12), child: Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(i, color: Colors.white)), const SizedBox(height: 4), Text(l, style: const TextStyle(color: Colors.white, fontSize: 12))]));
}
