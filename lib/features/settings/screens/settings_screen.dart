import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _language = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _toggleDarkMode(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', val);
    setState(() => _darkMode = val);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Profile'),
        _settingsTile(Icons.person_outline, 'Profile', 'Manage your account'),
        _settingsTile(Icons.account_balance, 'Linked Banks', '4 banks connected'),
        const Divider(height: 32),
        _sectionTitle('Security'),
        _settingsTile(Icons.fingerprint, 'Biometric Authentication', 'Use fingerprint to unlock'),
        _settingsTile(Icons.lock_outline, 'Change PIN', 'Update your security PIN'),
        _settingsTile(Icons.security, 'Auto-Lock', 'After 30 seconds'),
        const Divider(height: 32),
        _sectionTitle('Preferences'),
        SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Toggle app theme'),
          value: _darkMode,
          onChanged: _toggleDarkMode,
          activeColor: AppColors.ethiopianGreen,
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Language'),
          subtitle: Text(_language),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showLanguageDialog(context),
        ),
        const Divider(height: 32),
        _sectionTitle('About'),
        _settingsTile(Icons.info_outline, 'About TeleBank', 'Version 1.0.0'),
        _settingsTile(Icons.privacy_tip, 'Privacy Policy', 'Your data stays on device'),
        _settingsTile(Icons.description, 'Terms of Service', 'For demonstration purposes only'),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.mediumGray)),
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppColors.ethiopianGreen),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title coming soon')),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'አማርኛ (Amharic)', 'Afan Oromo'].map((lang) {
            return RadioListTile(
              title: Text(lang),
              value: lang,
              groupValue: _language,
              onChanged: (val) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('language', val.toString());
                setState(() => _language = val.toString());
                if (mounted) Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
