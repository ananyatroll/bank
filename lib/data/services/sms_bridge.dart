import 'package:flutter/services.dart';

import '../models/sms_event.dart';

class SmsBridge {
  static const EventChannel _channel = EventChannel('telebank/sms_events');

  Stream<SmsEvent> get smsStream {
    return _channel
        .receiveBroadcastStream()
        .map((event) => SmsEvent.fromMap(event as Map<dynamic, dynamic>));
  }
}
