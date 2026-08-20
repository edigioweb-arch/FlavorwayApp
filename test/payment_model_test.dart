import 'package:flavorapps/models/payment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PaymentModel parses payment payload correctly', () {
    final payment = PaymentModel.fromJson({
      'id': 4,
      'order_number': 'FW-20260817-000004',
      'provider': 'cash',
      'payment_method': 'cash',
      'internal_reference': 'PAY-20260817120000-000001',
      'amount': 11500,
      'currency': 'XAF',
      'status': 'pending',
      'metadata': {
        'mode': 'cash_on_delivery',
      },
    });

    expect(payment.orderNumber, 'FW-20260817-000004');
    expect(payment.amount, 11500);
    expect(payment.isPending, isTrue);
    expect(payment.metadata['mode'], 'cash_on_delivery');
  });
}
