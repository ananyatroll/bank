import '../models/bank_models.dart';
import '../models/sms_event.dart';

class SmsBalanceParser {
  BankBalance? parse(SmsEvent event) {
    final body = event.body;
    final bankId = _detectBank(event);
    final amount = _extractAmount(body);
    if (amount == null) return null;
    final last4 = _extractLast4(body);

    return BankBalance(
      bankId: bankId,
      amount: amount,
      currency: 'ETB',
      last4: last4,
      updatedAt: event.timestamp,
    );
  }

  BankId _detectBank(SmsEvent event) {
    final text = '${event.sender} ${event.body}'.toLowerCase();
    if (text.contains('cbe') || text.contains('commercial bank of ethiopia')) {
      return BankId.cbe;
    }
    if (text.contains('dashen')) {
      return BankId.dashen;
    }
    if (text.contains('awash')) {
      return BankId.awash;
    }
    return BankId.other;
  }

  double? _extractAmount(String body) {
    final patterns = <RegExp>[
      RegExp(r'(ETB|Birr)\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'balance\s*is\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final raw = match.group(2) ?? match.group(1) ?? '';
        return double.tryParse(raw.replaceAll(',', ''));
      }
    }
    return null;
  }

  String _extractLast4(String body) {
    final match = RegExp(r'(?:account|a/c|acct)\s*[:#-]*\s*([0-9Xx*]{4,})',
            caseSensitive: false)
        .firstMatch(body);
    if (match == null) return '----';
    final raw = match.group(1) ?? '';
    if (raw.length <= 4) return raw;
    return raw.substring(raw.length - 4);
  }
}
