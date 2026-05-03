import 'package:flutter/services.dart';

class DeviceSecurityService {
  static const MethodChannel _channel = MethodChannel('telebank/device_security');

  Future<bool> isDeviceSecure() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDeviceSecure');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openSecuritySettings() async {
    try {
      await _channel.invokeMethod('openSecuritySettings');
    } catch (_) {
      // Ignore, the device may not support the intent.
    }
  }
}
