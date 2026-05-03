import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onThemeChanged;
  const SettingsScreen({super.key, this.onThemeChanged});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _biometric = false;
  String _language = 'English';
  String _username = '';
  int _autoLock = 30;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() {
      _darkMode = p.getBool('dark_mode') ?? false;
      _biometric = p.getBool('biometric_enabled') ?? false;
      _language = p.getString('language') ?? 'English';
      _username = p.getString('username') ?? '';
      _autoLock = p.getInt('auto_lock') ?? 30;
    });
  }

  Future<void> _set(String key, dynamic val) async {
    final p = await SharedPreferences.getInstance();
    if (val is bool) await p.setBool(key, val);
    else if (val is String) await p.setString(key, val);
    else if (val is int) await p.setInt(key, val);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      const _SectionHeader('Profile'),
      _Tile(Icons.person_outline, 'Username', _username.isEmpty ? 'Tap to set' : '@$_username', onTap: () => _editField(context, 'Username', _username, (v) async {
        if (v.length >= 3 && v.length <= 20 && RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
          await _set('username', v);
          if (mounted) setState(() => _username = v);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username updated!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('3-20 chars, letters/numbers/underscore only')));
        }
      })),
      _Tile(Icons.account_balance, 'Linked Banks', '4 banks connected', onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Linked Banks'),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [
          _BankRow('CBE', '****1234', Colors.green),
          _BankRow('Dashen', '****5678', Colors.blue),
          _BankRow('Awash', '****9012', Colors.amber),
          _BankRow('COOP', '****3456', Colors.teal),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ))),

      const Divider(height: 32),
      const _SectionHeader('Security'),
      SwitchListTile(title: const Text('Biometric Authentication'), subtitle: const Text('Use fingerprint to unlock'),
        value: _biometric, onChanged: (v) async { await _set('biometric_enabled', v); setState(() => _biometric = v); }, activeColor: Colors.green),
      _Tile(Icons.lock_outline, 'Change PIN', 'Update your security PIN', onTap: () {
        final ctrl = TextEditingController();
        showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Change PIN'),
          content: TextField(controller: ctrl, keyboardType: TextInputType.number, obscureText: true, decoration: const InputDecoration(labelText: 'New PIN (4 digits)')),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () async {
              if (ctrl.text.length == 4) { await _set('app_pin', ctrl.text); if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN changed!')));
              } else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Must be 4 digits')));
            }, child: const Text('Save'))]));
      }),
      _Tile(Icons.timer, 'Auto-Lock', '${_autoLock}s of inactivity', onTap: () => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Auto-Lock'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [15, 30, 60, 120].map((s) => RadioListTile(title: Text('$s seconds'), value: s, groupValue: _autoLock,
          onChanged: (v) async { await _set('auto_lock', v); if (mounted) { setState(() => _autoLock = v as int); Navigator.pop(context); } },
        )).toList()),
      ))),

      const Divider(height: 32),
      const _SectionHeader('Appearance'),
      SwitchListTile(title: const Text('Dark Mode'), subtitle: const Text('Use dark theme'),
        value: _darkMode, onChanged: (v) async {
          await _set('dark_mode', v);
          widget.onThemeChanged?.call();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dark mode ${v ? 'enabled' : 'disabled'}')));
        }, activeColor: Colors.green),
      _Tile(Icons.language, 'Language', _language, onTap: () => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Language'),
        content: Column(mainAxisSize: MainAxisSize.min, children: ['English', 'አማርኛ (Amharic)', 'Afan Oromo'].map((l) => RadioListTile(title: Text(l), value: l, groupValue: _language,
          onChanged: (v) async { await _set('language', v); if (mounted) { setState(() => _language = v as String); Navigator.pop(context); } },
        )).toList()),
      ))),

      const Divider(height: 32),
      const _SectionHeader('About'),
      _Tile(Icons.info_outline, 'Version', '1.0.0'),
      _Tile(Icons.privacy_tip, 'Privacy', 'All data stored locally on device'),
      _Tile(Icons.description, 'Disclaimer', 'For demonstration purposes only'),
      const SizedBox(height: 24),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: OutlinedButton.icon(
        onPressed: () async {
          final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Reset App'),
            content: const Text('This clears ALL data including PIN, wallet, and settings.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset'))]));
          if (ok == true) { final p = await SharedPreferences.getInstance(); await p.clear();
            if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false); }
        }, icon: const Icon(Icons.delete_outline, color: Colors.red), label: const Text('Reset All Data', style: TextStyle(color: Colors.red)),
      )),
      const SizedBox(height: 32),
    ]);
  }

  void _editField(BuildContext ctx, String label, String initial, Future<void> Function(String) onSave) {
    final ctrl = TextEditingController(text: initial);
    showDialog(context: ctx, builder: (_) => AlertDialog(title: Text('Edit $label'),
      content: TextField(controller: ctrl, decoration: InputDecoration(labelText: label)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async { await onSave(ctrl.text.trim()); Navigator.pop(ctx); }, child: const Text('Save'))]));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)));
}

class _Tile extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback? onTap;
  const _Tile(this.icon, this.title, this.subtitle, {this.onTap});
  @override Widget build(BuildContext context) => ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle),
    trailing: onTap != null ? const Icon(Icons.chevron_right) : null, onTap: onTap);
}

class _BankRow extends StatelessWidget {
  final String name, acct; final Color color;
  const _BankRow(this.name, this.acct, this.color);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 12), Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), Text(acct)]));
}
