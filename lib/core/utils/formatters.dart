import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static String formatMoney(double amount, {String currency = 'ETB'}) {
    final formatter = NumberFormat('#,##0.00');
    return '$currency ${formatter.format(amount)}';
  }

  static String formatMoneyShort(double amount, {String currency = 'ETB'}) {
    if (amount >= 1000000) {
      return '$currency ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$currency ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatMoney(amount, currency: currency);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  static String formatDateShort(DateTime dateTime) {
    return DateFormat('MMM dd').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String formatPhone(String phone) {
    if (phone.length == 10 && phone.startsWith('0')) {
      return '+251${phone.substring(1)}';
    }
    return phone;
  }

  static String maskAccountNumber(String accountNumber, {int visibleDigits = 4}) {
    if (accountNumber.length <= visibleDigits) {
      return accountNumber;
    }
    final visible = accountNumber.substring(accountNumber.length - visibleDigits);
    final masked = '*' * (accountNumber.length - visibleDigits);
    return '$masked$visible';
  }

  static String truncateHash(String hash, {int prefixLength = 6, int suffixLength = 4}) {
    if (hash.length <= prefixLength + suffixLength) {
      return hash;
    }
    return '${hash.substring(0, prefixLength)}...${hash.substring(hash.length - suffixLength)}';
  }
}
