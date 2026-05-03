import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      (Icons.send, 'Send Money', AppColors.ethiopianGreen),
      (Icons.request_page, 'Request Money', AppColors.info),
      (Icons.payments, 'Cash Out', AppColors.warning),
      (Icons.phone_android, 'Airtime', AppColors.navyBlue),
      (Icons.receipt_long, 'Bill Pay', AppColors.tealGreen),
      (Icons.calendar_today, 'Scheduled', AppColors.deepGreen),
      (Icons.store, 'Pay Merchant', AppColors.goldenYellow),
      (Icons.swap_horiz, 'Other Banks', AppColors.lightBlue),
      (Icons.qr_code_scanner, 'Scan QR', AppColors.navyBlue),
      (Icons.account_balance_wallet, 'My Accounts', AppColors.ethiopianGreen),
      (Icons.history, 'History', AppColors.info),
      (Icons.help_outline, 'Support', AppColors.mediumGray),
    ];

    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: services.map((s) {
        return Card(
          child: InkWell(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${s.$2} coming soon')),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: s.$3.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(s.$1, color: s.$3, size: 28),
                ),
                const SizedBox(height: 8),
                Text(s.$2, style: AppTextStyles.caption, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
