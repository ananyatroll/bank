import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/models/bank_models.dart';
import '../../providers.dart';
import '../crypto/crypto_screen.dart';
import '../ussd/ussd_screen.dart';
import 'widgets/balance_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/transaction_list.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(bankControllerProvider.notifier).start();
      await _requestSmsPermission();
    });
  }

  Future<void> _requestSmsPermission() async {
    await Permission.sms.request();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TeleBank'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bank'),
              Tab(text: 'Crypto'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _requestSmsPermission(),
              icon: const Icon(Icons.sms_outlined),
              tooltip: 'Sync SMS',
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            BankDashboard(),
            CryptoScreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UssdScreen()),
            );
          },
          label: const Text('USSD'),
          icon: const Icon(Icons.phone_in_talk_outlined),
        ),
      ),
    );
  }
}

class BankDashboard extends ConsumerWidget {
  const BankDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bankControllerProvider);
    final balances = state.balances.values.toList();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7F5EF), Color(0xFFE8F1F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          QuickActions(
            onDial: () async {
              final status = await Permission.phone.request();
              if (status.isGranted) {
                await ref.read(ussdBridgeProvider).dialUssd('*888#');
              }
            },
            onSyncSms: () => Permission.sms.request(),
            onSavePin: () => _savePin(context, ref),
            onUnlockPin: () => _unlockPin(context, ref),
          ),
          const SizedBox(height: 20),
          Text(
            'Balances',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: balances.isEmpty
                ? const _EmptyBalances()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount =
                          constraints.maxWidth > 500 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: balances.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 2.4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          return BalanceCard(balance: balances[index]);
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recent activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TransactionList(transactions: state.transactions),
        ],
      ),
    );
  }

  Future<BankId?> _pickBank(BuildContext context) async {
    return showDialog<BankId>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select bank'),
        children: BankId.values
            .map(
              (bank) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, bank),
                child: Text(bank.name.toUpperCase()),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _savePin(BuildContext context, WidgetRef ref) async {
    final bankId = await _pickBank(context);
    if (bankId == null) return;

    final controller = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (pin == null || pin.isEmpty) return;
    await ref.read(pinVaultProvider).savePin(bankId, pin);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN saved')),
    );
  }

  Future<void> _unlockPin(BuildContext context, WidgetRef ref) async {
    final bankId = await _pickBank(context);
    if (bankId == null) return;

    final pin = await ref.read(pinVaultProvider).getPin(bankId);
    if (pin == null || pin.isEmpty) return;

    await ref.read(ussdBridgeProvider).sendInput(pin);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN sent to USSD session')),
    );
  }
}

class _EmptyBalances extends StatelessWidget {
  const _EmptyBalances();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Waiting for SMS balance updates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Trigger a balance check via USSD and keep the SMS app open.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
