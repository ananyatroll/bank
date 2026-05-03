import 'package:flutter/services.dart';

class UssdBridge {
  static const EventChannel _events = EventChannel('telebank/ussd_events');
  static const MethodChannel _call = MethodChannel('telebank/ussd_call');

  Stream<String> get textStream {
    return _events.receiveBroadcastStream().map((event) {
      final data = event as Map<dynamic, dynamic>;
      return data['text']?.toString() ?? '';
    });
  }

  Future<void> dialUssd(String code, {bool useCall = true}) async {
    await _call.invokeMethod('dialUssd', {
      'code': code,
      'useCall': useCall,
    });
  }

  Future<void> sendInput(String input) async {
    await _call.invokeMethod('sendInput', {'input': input});
  }

  Future<void> dismiss() async {
    await _call.invokeMethod('dismissUssd');
  }
}
