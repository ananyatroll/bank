import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';

import '../models/bank_models.dart';
import 'device_security_service.dart';

class PinVaultService {
  PinVaultService(this._box, this._auth, this._deviceSecurity);

  final Box<dynamic> _box;
  final LocalAuthentication _auth;
  final DeviceSecurityService _deviceSecurity;

  Future<bool> ensureDeviceSecure() async {
    final secure = await _deviceSecurity.isDeviceSecure();
    if (!secure) {
      await _deviceSecurity.openSecuritySettings();
    }
    return secure;
  }

  Future<void> savePin(BankId bankId, String pin) async {
    await _box.put(_key(bankId), pin);
  }

  Future<String?> getPin(BankId bankId) async {
    final canCheck = await _auth.canCheckBiometrics;
    if (!canCheck) return null;

    final ok = await _auth.authenticate(
      localizedReason: 'Unlock your saved PIN',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
    if (!ok) return null;
    return _box.get(_key(bankId)) as String?;
  }

  Future<void> deletePin(BankId bankId) async {
    await _box.delete(_key(bankId));
  }

  String _key(BankId bankId) => 'pin_${bankId.name}';
}
