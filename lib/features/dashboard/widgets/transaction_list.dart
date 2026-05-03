import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart' show AppFormatters;
import '../../../data/models/bank_models.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key, required this.transactions});

  final List<BankTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No activity yet.'),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length.clamp(0, 5),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final txn = transactions[index];
          final sign = txn.direction == TxnDirection.credit ? '+' : '-';
          return ListTile(
            leading: Icon(
              txn.direction == TxnDirection.credit
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
            ),
            title: Text(txn.title),
            subtitle: Text(AppFormatters.formatDateTime(txn.timestamp)),
            trailing: Text('$sign${txn.amount.toStringAsFixed(2)}'),
          );
        },
      ),
    );
  }
}
