class SmsEvent {
  final String sender;
  final String body;
  final DateTime timestamp;

  const SmsEvent({
    required this.sender,
    required this.body,
    required this.timestamp,
  });

  factory SmsEvent.fromMap(Map<dynamic, dynamic> map) {
    return SmsEvent(
      sender: map['sender']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
