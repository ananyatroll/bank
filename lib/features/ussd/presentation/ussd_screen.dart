import 'package:flutter/material.dart';
import '../../../config/constants.dart';
import '../../../core/theme.dart';

class UssdScreen extends StatefulWidget {
  const UssdScreen({super.key});
  @override
  State<UssdScreen> createState() => _UssdScreenState();
}

class _UssdScreenState extends State<UssdScreen> {
  int? _selected;
  @override
  Widget build(BuildContext context) {
    final banks = AppConstants.banks;
    if (_selected == null) {
      return Scaffold(appBar: AppBar(title: const Text('Select Bank for USSD')),
        body: GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(16), mainAxisSpacing: 12, crossAxisSpacing: 12,
          children: List.generate(banks.length, (i) {
            final b = banks[i];
            final colors = [AppColors.ethiopianGreen, AppColors.navyBlue, AppColors.goldenYellow, AppColors.tealGreen];
            return Card(child: InkWell(onTap: () => setState(() => _selected = i), borderRadius: BorderRadius.circular(16),
              child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.account_balance, size: 48, color: colors[i]),
                const SizedBox(height: 8),
                Text(b['short'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors[i])),
                const SizedBox(height: 4), Text(b['name'], style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: colors[i].withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(b['ussd'], style: TextStyle(fontWeight: FontWeight.bold, color: colors[i]))),
              ]))));
          })));
    }
    final bank = banks[_selected!];
    final colors = [AppColors.ethiopianGreen, AppColors.navyBlue, AppColors.goldenYellow, AppColors.tealGreen];
    return Scaffold(appBar: AppBar(title: Text('USSD - ${bank['short']}'), actions: [
      IconButton(icon: const Icon(Icons.swap_horiz), onPressed: () => setState(() => _selected = null)),
    ]),
      body: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.phone_in_talk, size: 80, color: colors[_selected!]),
        const SizedBox(height: 24),
        Text('Dial ${bank['ussd']}?', style: AppTextStyles.heading2),
        const SizedBox(height: 8),
        const Text('This will open your phone dialer with the USSD code', textAlign: TextAlign.center),
        const SizedBox(height: 32),
        FilledButton.icon(onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening dialer for ${bank['ussd']}...')));
        }, icon: const Icon(Icons.phone), label: Text('Dial ${bank['ussd']}')),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: () => setState(() => _selected = null), child: const Text('Change Bank')),
      ])));
  }
}
