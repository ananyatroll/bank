import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  String _storedPin = '';
  bool _isSetup = false;
  bool _confirmMode = false;
  String _setupPin = '';
  String _error = '';
  bool _busy = false;

  @override void initState() { super.initState(); _loadPin(); }

  Future<void> _loadPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _storedPin = prefs.getString('app_pin') ?? '';
      _isSetup = _storedPin.isNotEmpty;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _tap(String d) {
    if (_pin.length >= 4 || _busy) return;
    final newPin = _pin + d;
    if (newPin.length == 4) {
      setState(() => _pin = newPin);
      // Process after frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) => _processPin(newPin));
    } else {
      setState(() => _pin = newPin);
    }
  }

  Future<void> _processPin(String pin) async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    try {
      if (!_isSetup) {
        if (!_confirmMode) {
          setState(() { _setupPin = pin; _confirmMode = true; _pin = ''; _error = 'Confirm PIN'; _busy = false; });
        } else {
          if (pin == _setupPin) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('app_pin', pin);
            if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
          } else {
            setState(() { _error = 'PINs do not match'; _confirmMode = false; _setupPin = ''; _pin = ''; _busy = false; });
          }
        }
      } else {
        if (pin == _storedPin) {
          if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          setState(() { _error = 'Wrong PIN'; _pin = ''; _busy = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _busy = false; });
    }
  }

  void _backspace() { if (_pin.isNotEmpty && !_busy) setState(() => _pin = _pin.substring(0, _pin.length - 1)); }

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
                  child: _busy ? const CircularProgressIndicator(color: AppColors.navyBlue)
                    : const Icon(Icons.account_balance_wallet, size: 50, color: AppColors.navyBlue)),
                const SizedBox(height: 24),
                const Text('TeleBank', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_isSetup ? 'Enter your PIN' : (_confirmMode ? 'Confirm PIN' : 'Create a PIN'),
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
                const Text('Enter 4-digit PIN', style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _btn(String t, VoidCallback o) => Material(color: _busy ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(50),
    child: _busy ? const SizedBox() : InkWell(onTap: o, borderRadius: BorderRadius.circular(50), child: Center(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w500)))));
  Widget _btnIcon(IconData i, VoidCallback o) => Material(color: _busy ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(50),
    child: _busy ? const SizedBox() : InkWell(onTap: o, borderRadius: BorderRadius.circular(50), child: Center(child: Icon(i, color: Colors.white, size: 28))));
}
