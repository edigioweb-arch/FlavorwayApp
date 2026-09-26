import 'package:flutter_test/flutter_test.dart';
import 'package:flavorapps/utils/courier_money.dart';

void main() {
  test('Server currencies stay distinct without conversion', () {
    final result = courierCurrencyTotals([
      {'currency_code': 'XAF', 'amount': 11000},
      {'currency_code': 'XOF', 'amount': 25000},
    ]);
    expect(result, '11 000 XAF\n25 000 XOF');
    expect(result, isNot(contains('36 000')));
    expect(courierMoney(12.5, 'EUR'), '12,5 EUR');
  });
  test('Missing currency never invents FCFA', () {
    expect(courierMoney(11000, null), '11 000 (devise non renseignée)');
    expect(courierMoney(null, 'USD'), '—');
    expect(courierCurrencyTotals([]), 'Aucun montant en attente');
  });
}
