import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/constants.dart';
import '../../../core/theme.dart';

class UssdScreen extends StatefulWidget {
  const UssdScreen({super.key});
  @override State<UssdScreen> createState() => _UssdScreenState();
}

class _UssdScreenState extends State<UssdScreen> {
  int? _selected;

  Future<void> _dial(String code) async {
    final uri = Uri.parse('tel:${Uri.encodeComponent(code)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('USSD Code'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Copy this code and dial it manually:'),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
              child: Text(code, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
            const SizedBox(height: 12),
            TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Done')),
          ]),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final banks = AppConstants.banks;
    final colors = [AppColors.ethiopianGreen, AppColors.navyBlue, AppColors.goldenYellow, AppColors.tealGreen];

    if (_selected == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Bank')),
        body: Padding(padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Text('Tap a bank to dial its USSD code', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Expanded(child: GridView.count(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
              children: List.generate(banks.length, (i) {
                final b = banks[i];
                return Card(child: InkWell(onTap: () => setState(() => _selected = i), borderRadius: BorderRadius.circular(16),
                  child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.account_balance, size: 48, color: colors[i]),
                    const SizedBox(height: 8),
                    Text(b['short'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors[i])),
                    const SizedBox(height: 4), Text(b['name'], style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: colors[i].withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(b['ussd'], style: TextStyle(fontWeight: FontWeight.bold, color: colors[i]))),
                  ]))));
              }))),
          ])));
    }

    final bank = banks[_selected!];
    final color = colors[_selected!];

    return Scaffold(
      appBar: AppBar(title: Text('USSD - ${bank['short']}'), actions: [
        IconButton(icon: const Icon(Icons.swap_horiz), onPressed: () => setState(() => _selected = null)),
      ]),
      body: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.phone_in_talk, size: 80, color: color),
        const SizedBox(height: 24),
        Text('Dial ${bank['ussd']}?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('This will open your phone dialer with ${bank['ussd']}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () => _dial(bank['ussd']),
          icon: const Icon(Icons.phone),
          label: Text('Dial ${bank['ussd']}'),
          style: FilledButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
        ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: () => setState(() => _selected = null), child: const Text('Change Bank')),
      ])),
    );
  }
}
