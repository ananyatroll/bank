import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onDial,
    required this.onSyncSms,
    required this.onSavePin,
    required this.onUnlockPin,
  });

  final VoidCallback onDial;
  final VoidCallback onSyncSms;
  final VoidCallback onSavePin;
  final VoidCallback onUnlockPin;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onDial,
              icon: const Icon(Icons.phone_forwarded_outlined),
              label: const Text('Dial *888#'),
            ),
            OutlinedButton.icon(
              onPressed: onSyncSms,
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Sync SMS'),
            ),
            OutlinedButton.icon(
              onPressed: onSavePin,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Save PIN'),
            ),
            OutlinedButton.icon(
              onPressed: onUnlockPin,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Unlock PIN'),
            ),
          ],
        ),
      ),
    );
  }
}
