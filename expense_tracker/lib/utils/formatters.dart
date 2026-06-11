import 'package:intl/intl.dart';

final NumberFormat _currency =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

final NumberFormat _compactCurrency =
    NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

String formatCurrency(double value) => _currency.format(value);

String formatCurrencyCompact(double value) => _compactCurrency.format(value);

String formatDay(DateTime date) {
  final today = DateTime.now();
  final day = DateTime(date.year, date.month, date.day);
  final todayDay = DateTime(today.year, today.month, today.day);
  final difference = todayDay.difference(day).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  return DateFormat('EEE, d MMM yyyy').format(date);
}

String formatShortDate(DateTime date) => DateFormat('d MMM yyyy').format(date);
