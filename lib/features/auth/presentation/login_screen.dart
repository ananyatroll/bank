import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
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
  String _bioStatus = '';

  @override void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _storedPin = prefs.getString('app_pin') ?? '';
    _isSetup = _storedPin.isNotEmpty;

    // Simple biometric check
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final bios = await _auth.getAvailableBiometrics();
      _canBio = canCheck && bios.isNotEmpty;
      _bioStatus = _canBio ? '🔓 Fingerprint ready' : '🔒 No fingerprint';
    } catch (e) {
      _canBio = false;
      _bioStatus = '🔒 ${e.toString().substring(0, 30)}';
    }
    if (mounted) setState(() {});
  }

  Future<void> _bioAuth() async {
    if (!_canBio) return;
    setState(() => _error = 'Scanning...');
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Unlock TeleBank',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      if (authenticated && mounted) {
        _goDashboard();
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'NotRecognized':
          setState(() => _error = 'Fingerprint not recognized');
          break;
        case 'LockedOut':
          setState(() => _error = 'Locked out. Use PIN.');
          break;
        case 'NotEnrolled':
          setState(() => _error = 'No fingerprint set on device');
          break;
        case 'AuthInProgress':
          setState(() => _error = 'Already trying...');
          break;
        default:
          setState(() => _error = 'Use PIN instead');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Use PIN');
    }
  }

  void _tap(String d) {
    if (_pin.length >= 4) return;
    final newPin = _pin + d;
    if (newPin.length == 4) { setState(() => _pin = newPin); _checkPin(); }
    else { setState(() => _pin = newPin); }
  }

  void _backspace() { if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1)); }

  void _checkPin() {
    if (!_isSetup) {
      if (!_confirmMode) {
        setState(() { _setupPin = _pin; _confirmMode = true; _pin = ''; _error = 'Confirm PIN'; });
      } else {
        if (_pin == _setupPin) { _saveAndGo(_pin); }
        else { setState(() { _error = 'PINs do not match'; _confirmMode = false; _setupPin = ''; _pin = ''; }); HapticFeedback.vibrate(); }
      }
    } else {
      if (_pin == _storedPin) { _goDashboard(); }
      else { setState(() { _error = 'Wrong PIN'; _pin = ''; }); HapticFeedback.vibrate(); }
    }
  }

  Future<void> _saveAndGo(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_pin', pin);
    if (mounted) _goDashboard();
  }

  void _goDashboard() { Navigator.pushReplacementNamed(context, '/dashboard'); }

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
                if (_bioStatus.isNotEmpty) ...[const SizedBox(height: 4), Text(_bioStatus, style: const TextStyle(color: Colors.white54, fontSize: 12))],
                if (_error.isNotEmpty) ...[const SizedBox(height: 8), Text(_error, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))],
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) => AnimatedContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16, height: 16,
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: i < _pin.length ? AppColors.warmGold : Colors.transparent,
                      border: Border.all(color: AppColors.warmGold, width: 2))))),
                const SizedBox(height: 32),
                GridView.count(shrinkWrap: true, crossAxisCount: 3, childAspectRatio: 1.5, mainAxisSpacing: 12, crossAxisSpacing: 12, padding: EdgeInsets.zero,
                  children: [
                    for (var i = 1; i <= 9; i++) _btn('$i', () => _tap('$i')),
                    const SizedBox.shrink(),
                    _btn('0', () => _tap('0')),
                    _btnIcon(Icons.backspace_outlined, _backspace),
                  ]),
                const Spacer(),
                if (_isSetup) ...[
                  if (_canBio)
                    OutlinedButton.icon(
                      onPressed: _bioAuth,
                      icon: const Icon(Icons.fingerprint, size: 36),
                      label: const Text('Use Fingerprint', style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white30, width: 2), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), foregroundColor: Colors.white),
                    ),
                  const SizedBox(height: 12),
                  const Text('Or enter 4-digit PIN above', style: TextStyle(color: Colors.white54)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _btn(String t, VoidCallback o) => Material(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(50),
    child: InkWell(onTap: o, borderRadius: BorderRadius.circular(50), child: Center(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w500)))));
  Widget _btnIcon(IconData i, VoidCallback o) => Material(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(50),
    child: InkWell(onTap: o, borderRadius: BorderRadius.circular(50), child: Center(child: Icon(i, color: Colors.white, size: 28))));
}
