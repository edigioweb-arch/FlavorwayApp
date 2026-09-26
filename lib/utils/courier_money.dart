import 'package:intl/intl.dart';

/// Displays the server currency without conversion or an assumed currency.
String courierMoney(dynamic amount, dynamic currency) {
  final value = num.tryParse('$amount');
  if (value == null) return '—';
  final code = currency?.toString().trim();
  final formatted = NumberFormat('#,##0.##', 'fr_FR')
      .format(value)
      .replaceAll('\u202f', ' ')
      .replaceAll('\u00a0', ' ');
  return '$formatted ${code == null || code.isEmpty ? '(devise non renseignée)' : code}';
}

String courierCurrencyTotals(dynamic totals) {
  if (totals is! List) return 'Montants indisponibles';
  if (totals.isEmpty) return 'Aucun montant en attente';
  return totals
      .map((row) => courierMoney(row['amount'], row['currency_code']))
      .join('\n');
}
