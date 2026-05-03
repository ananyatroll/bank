import '../models/bank_models.dart';
import '../models/sms_event.dart';

class SmsBalanceParser {
  BankBalance? parse(SmsEvent event) {
    final body = event.body;
    final bankId = _detectBank(event);
    final amount = _extractBalance(body);
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
    if (text.contains('cbe') || text.contains('commercial bank of ethiopia') || event.sender == '8888') {
      return BankId.cbe;
    }
    if (text.contains('dashen') || event.sender == '8899') {
      return BankId.dashen;
    }
    if (text.contains('awash') || event.sender == '8811') {
      return BankId.awash;
    }
    if (text.contains('coop') || text.contains('cooperative') || text.contains('oromia') || event.sender == '8822') {
      return BankId.coop;
    }
    return BankId.other;
  }

  double? _extractBalance(String body) {
    final patterns = <RegExp>[
      RegExp(r'(?:balance|available balance|current balance)[:\s]*(?:ETB|Birr)?\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'(?:ETB|Birr)\s*([0-9,]+(?:\.[0-9]{2})?)\s*(?:balance|available)', caseSensitive: false),
      RegExp(r'(?:new balance|updated balance)[:\s]*(?:ETB|Birr)?\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'(?:credited with|received|debited from)[\s\S]*?(?:ETB|Birr)?\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final raw = match.group(1) ?? '';
        return double.tryParse(raw.replaceAll(',', ''));
      }
    }
    return null;
  }

  String _extractLast4(String body) {
    final match = RegExp(r'(?:account|a/c|acct)\s*[:#\s]*\**(\d{4})\b', caseSensitive: false)
        .firstMatch(body);
    if (match == null) return '----';
    return match.group(1) ?? '----';
  }
}
