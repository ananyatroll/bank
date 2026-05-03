import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../config/constants.dart';

class BankHomeScreen extends StatefulWidget {
  const BankHomeScreen({super.key});
  @override
  State<BankHomeScreen> createState() => _BankHomeScreenState();
}

class _BankHomeScreenState extends State<BankHomeScreen> {
  bool _showBalance = true;
  final List<Map<String, dynamic>> _txns = [
    {'title': 'Transfer Received', 'date': 'Today, 2:30 PM', 'amount': '+ETB 500.00', 'incoming': true},
    {'title': 'Airtime Purchase', 'date': 'Yesterday, 10:15 AM', 'amount': '-ETB 50.00', 'incoming': false},
    {'title': 'Bill Payment', 'date': 'May 1, 8:00 AM', 'amount': '-ETB 200.00', 'incoming': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFF7F5EF), Color(0xFFE8F1F5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Balance Card
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.getShadow(4),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('ሰላም! 👋', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('CBE Birr Account', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ]),
                    IconButton(icon: const Icon(Icons.sync, color: Colors.white), onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing balance...')));
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _showBalance ? 'ETB 4,250.00' : '****',
                        style: const TextStyle(color: AppColors.warmGold, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_showBalance ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                      onPressed: () => setState(() => _showBalance = !_showBalance),
                    ),
                  ],
                ),
                const Text('****1234', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                const Text('Last synced: Just now', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Quick Actions
          Text('Quick Actions', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 0.85,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _actionCard(Icons.arrow_upward, 'Send', AppColors.ethiopianGreen),
              _actionCard(Icons.arrow_downward, 'Request', AppColors.info),
              _actionCard(Icons.payments, 'Cash Out', AppColors.warning),
              _actionCard(Icons.phone_android, 'Airtime', AppColors.navyBlue),
              _actionCard(Icons.receipt_long, 'Bill Pay', AppColors.tealGreen),
              _actionCard(Icons.calendar_today, 'Scheduled', AppColors.deepGreen),
              _actionCard(Icons.store, 'Merchant', AppColors.goldenYellow),
              _actionCard(Icons.swap_horiz, 'Other', AppColors.lightBlue),
            ],
          ),
          const SizedBox(height: 24),
          // Recent Transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions', style: AppTextStyles.heading3),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 8),
          ..._txns.map((t) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (t['incoming'] ? AppColors.success : AppColors.error).withOpacity(0.1),
                child: Icon(t['incoming'] ? Icons.arrow_downward : Icons.arrow_upward,
                    color: t['incoming'] ? AppColors.success : AppColors.error),
              ),
              title: Text(t['title']),
              subtitle: Text(t['date']),
              trailing: Text(t['amount'], style: TextStyle(
                fontWeight: FontWeight.bold,
                color: t['incoming'] ? AppColors.success : AppColors.error,
              )),
            ),
          )),
          if (_txns.isEmpty) const Center(child: Text('No transactions yet')),
        ],
      ),
    );
  }

  Widget _actionCard(IconData icon, String label, Color color) {
    return Card(
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label coming soon'))),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
