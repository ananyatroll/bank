import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  String _pin = '';
  String _storedPin = '';
  bool _isSetup = false;
  bool _confirmMode = false;
  String _setupPin = '';
  String _error = '';
  bool _canBio = false;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    _storedPin = prefs.getString('app_pin') ?? '';
    _isSetup = _storedPin.isNotEmpty;
    _canBio = prefs.getBool('biometric_enabled') ?? false;
    setState(() {});
    if (_isSetup && _canBio) _tryBio();
  }

  Future<void> _tryBio() async {
    final available = await _auth.canCheckBiometrics;
    if (!available) return;
    try {
      final ok = await _auth.authenticate(localizedReason: 'Unlock TeleBank');
      if (ok && mounted) _goDashboard();
    } catch (_) {}
  }

  void _tap(String d) {
    if (_pin.length >= 4) return;
    setState(() => _pin += d);
    if (_pin.length == 3) {
      _pin += d;
      _checkPin();
    }
  }

  void _backspace() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _checkPin() async {
    if (!_isSetup) {
      if (!_confirmMode) {
        setState(() { _setupPin = _pin; _confirmMode = true; _pin = ''; _error = 'Confirm PIN'; });
      } else if (_pin == _setupPin) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_pin', _pin);
        _goDashboard();
      } else {
        setState(() { _error = 'PINs dont match'; _confirmMode = false; _setupPin = ''; _pin = ''; });
      }
    } else {
      if (_pin == _storedPin) { _goDashboard(); }
      else { setState(() { _error = 'Wrong PIN'; _pin = ''; }); HapticFeedback.vibrate(); }
    }
  }

  void _goDashboard() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50), boxShadow: AppColors.getShadow(8)),
                  child: const Icon(Icons.account_balance_wallet, size: 50, color: AppColors.navyBlue)),
                const SizedBox(height: 24),
                const Text('TeleBank', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_isSetup ? 'Enter your PIN' : (_confirmMode ? 'Confirm PIN' : 'Create a PIN'),
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
                if (_error.isNotEmpty) ...[const SizedBox(height: 8), Text(_error, style: const TextStyle(color: Colors.redAccent))],
                const SizedBox(height: 32),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 8), width: 16, height: 16,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: i < _pin.length ? AppColors.warmGold : Colors.transparent,
                      border: Border.all(color: AppColors.warmGold, width: 2))))),
                const SizedBox(height: 40),
                GridView.count(shrinkWrap: true, crossAxisCount: 3, childAspectRatio: 1.5, mainAxisSpacing: 12, crossAxisSpacing: 12, padding: EdgeInsets.zero,
                  children: [
                    for (var i = 1; i <= 9; i++) _btn('$i', () => _tap('$i')),
                    const SizedBox.shrink(),
                    _btn('0', () => _tap('0')),
                    _btnIcon(Icons.backspace_outlined, _backspace),
                  ]),
                const Spacer(),
                if (_isSetup && _canBio) TextButton.icon(onPressed: _tryBio, icon: const Icon(Icons.fingerprint, color: Colors.white), label: const Text('Use Biometric', style: TextStyle(color: Colors.white))),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _btn(String t, VoidCallback onTap) => Material(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(50),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(50), child: Center(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w500)))));
  Widget _btnIcon(IconData i, VoidCallback onTap) => Material(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(50),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(50), child: Center(child: Icon(i, color: Colors.white, size: 28))));
}
