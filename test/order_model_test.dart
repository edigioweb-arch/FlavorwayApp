import 'package:flavorapps/services/order_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OrderModel parses Laravel payload correctly', () {
    final order = OrderModel.fromJson({
      'id': 12,
      'order_number': 'FW-20260817-000012',
      'restaurant': {
        'id': 1,
        'name': 'Joli Coin',
      },
      'status': 'confirmed',
      'payment_status': 'unpaid',
      'payment_method': 'cash',
      'currency': 'XAF',
      'subtotal': 9500,
      'delivery_fee': 2000,
      'discount_total': 0,
      'total': 11500,
      'placed_at': '2026-08-17T12:00:00Z',
      'delivery_address': {
        'label': 'Maison',
        'address_line': 'Avenue de la Paix',
        'city': 'Brazzaville',
      },
      'items': [
        {
          'name': 'Poulet braisé',
          'quantity': 1,
          'unit_price': 8500,
          'options_total': 1000,
          'line_total': 9500,
          'options': [
            {
              'option_name': 'Accompagnement',
              'option_value': 'Plantains',
              'price_delta': 1000,
            }
          ],
        }
      ],
      'status_history': [
        {
          'to_status': 'confirmed',
          'source': 'client',
          'changed_at': '2026-08-17T12:00:00Z',
        }
      ],
    });

    expect(order.orderNumber, 'FW-20260817-000012');
    expect(order.restaurantName, 'Joli Coin');
    expect(order.total, 11500);
    expect(order.displayStatus, 'Commande reçue');
    expect(order.items.first.options.first['option_value'], 'Plantains');
  });
}
