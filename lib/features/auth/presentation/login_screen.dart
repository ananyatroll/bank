import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onThemeChanged;
  const LoginScreen({super.key, this.onThemeChanged});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final LocalAuthentication _auth = LocalAuthentication();
  String _pin = '';
  String _storedPin = '';
  bool _isSetup = false;
  bool _confirmMode = false;
  String _setupPin = '';
  String _error = '';
  bool _canBio = false;
  bool _bioAvailable = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    _storedPin = prefs.getString('app_pin') ?? '';
    _isSetup = _storedPin.isNotEmpty;

    try {
      _bioAvailable = await _auth.canCheckBiometrics;
      final bios = await _auth.getAvailableBiometrics();
      _canBio = _bioAvailable && bios.isNotEmpty;
    } catch (_) {
      _bioAvailable = false;
      _canBio = false;
    }
    setState(() {
      _loading = false;
    });

    // Auto-prompt biometric if available
    if (_isSetup && _canBio) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _tryBio();
    }
  }

  Future<void> _tryBio() async {
    if (!_canBio) return;
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock TeleBank to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (ok && mounted) {
        HapticFeedback.lightImpact();
        _goDashboard();
      }
    } on PlatformException catch (e) {
      if (mounted) {
        // User cancelled or failed - fall back to PIN
        if (e.code == 'NotRecognized' || e.code == 'NoBiometricAvailable') {
          setState(() => _error = 'Fingerprint not recognized');
          HapticFeedback.vibrate();
        }
      }
    } catch (_) {}
  }

  void _tap(String d) {
    if (_pin.length >= 4) return;
    final newPin = _pin + d;
    if (newPin.length == 4) {
      setState(() => _pin = newPin);
      _checkPin();
    } else {
      setState(() => _pin = newPin);
    }
  }

  void _backspace() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _checkPin() {
    if (!_isSetup) {
      if (!_confirmMode) {
        setState(() { _setupPin = _pin; _confirmMode = true; _pin = ''; _error = 'Confirm your PIN'; });
      } else {
        if (_pin == _setupPin) {
          _savePinAndGo(_pin);
        } else {
          setState(() { _error = 'PINs do not match'; _confirmMode = false; _setupPin = ''; _pin = ''; });
          HapticFeedback.vibrate();
        }
      }
    } else {
      if (_pin == _storedPin) {
        _goDashboard();
      } else {
        setState(() { _error = 'Wrong PIN'; _pin = ''; });
        HapticFeedback.vibrate();
      }
    }
  }

  Future<void> _savePinAndGo(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_pin', pin);
    if (mounted) _goDashboard();
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
                Container(width: 100, height: 100,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50), boxShadow: AppColors.getShadow(8)),
                  child: const Icon(Icons.account_balance_wallet, size: 50, color: AppColors.navyBlue)),
                const SizedBox(height: 24),
                const Text('TeleBank', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_isSetup ? 'Enter your PIN' : (_confirmMode ? 'Confirm PIN' : 'Create a PIN'),
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
                if (_error.isNotEmpty) ...[const SizedBox(height: 8), Text(_error, style: const TextStyle(color: Colors.redAccent))],
                const SizedBox(height: 32),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) => AnimatedContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16, height: 16,
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: i < _pin.length ? AppColors.warmGold : Colors.transparent,
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
                if (_isSetup && _canBio)
                  Padding(padding: const EdgeInsets.only(bottom: 20),
                    child: OutlinedButton.icon(
                      onPressed: _tryBio,
                      icon: const Icon(Icons.fingerprint, size: 32),
                      label: const Text('Use Fingerprint', style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        foregroundColor: Colors.white,
                      ))),
                if (_isSetup && _bioAvailable && !_canBio)
                  const Padding(padding: EdgeInsets.only(bottom: 20),
                    child: Text('Biometric enrollment failed. Use PIN.', style: TextStyle(color: Colors.white54))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _btn(String t, VoidCallback onTap) => Material(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(50),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(50),
      child: Center(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w500)))));
  Widget _btnIcon(IconData i, VoidCallback onTap) => Material(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(50),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(50),
      child: Center(child: Icon(i, color: Colors.white, size: 28))));
}
