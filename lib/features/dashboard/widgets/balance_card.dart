import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart' show AppFormatters;
import '../../../data/models/bank_models.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.balance});

  final BankBalance balance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              balance.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: balance.amount),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, _) {
                return Text(
                  AppFormatters.formatMoney(value, currency: balance.currency),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                );
              },
            ),
            const SizedBox(height: 8),
            Text('Acct ****${balance.last4}'),
            Text(
              'Updated ${AppFormatters.formatDateTime(balance.updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
