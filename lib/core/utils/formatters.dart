import 'package:intl/intl.dart';

String formatMoney(double amount, {String currency = 'ETB'}) {
  final fmt = NumberFormat.currency(symbol: '$currency ', decimalDigits: 2);
  return fmt.format(amount);
}

String formatDateTime(DateTime dt) {
  return DateFormat('MMM d, HH:mm').format(dt);
}
