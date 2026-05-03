import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/services/ussd_parser.dart';
import '../../providers.dart';

class UssdScreen extends ConsumerStatefulWidget {
  const UssdScreen({super.key});

  @override
  ConsumerState<UssdScreen> createState() => _UssdScreenState();
}

class _UssdScreenState extends ConsumerState<UssdScreen> {
  final TextEditingController _inputController = TextEditingController();
  final UssdParser _parser = UssdParser();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bridge = ref.read(ussdBridgeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('USSD Session'),
        actions: [
          IconButton(
            onPressed: bridge.dismiss,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: StreamBuilder<String>(
        stream: bridge.textStream,
        builder: (context, snapshot) {
          final raw = snapshot.data ?? '';
          final menu = raw.isEmpty ? null : _parser.parse(raw);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    raw.isEmpty ? 'Waiting for USSD response...' : raw,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (menu != null && menu.options.isNotEmpty) ...[
                Text(
                  'Options',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: menu.options
                      .map(
                        (option) => OutlinedButton(
                          onPressed: () => bridge.sendInput(option.code),
                          child: Text('${option.code}. ${option.label}'),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (menu?.prompt != null) ...[
                Text(
                  menu!.prompt!,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _inputController,
                decoration: const InputDecoration(
                  labelText: 'Send input',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  final text = _inputController.text.trim();
                  if (text.isEmpty) return;
                  bridge.sendInput(text);
                  _inputController.clear();
                },
                icon: const Icon(Icons.send),
                label: const Text('Send'),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  final status = await Permission.phone.request();
                  if (status.isGranted) {
                    await bridge.dialUssd('*888#');
                  }
                },
                icon: const Icon(Icons.phone_forwarded_outlined),
                label: const Text('Dial *888#'),
              ),
            ],
          );
        },
      ),
    );
  }
}
