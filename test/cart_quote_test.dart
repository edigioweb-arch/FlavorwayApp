import 'package:flavorapps/models/cart_quote.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CartQuote parses quote payload correctly', () {
    final quote = CartQuote.fromJson({
      'restaurant_id': 1,
      'currency': 'XAF',
      'items': [
        {
          'product_id': 10,
          'name': 'Poulet braisé',
          'quantity': 2,
          'unit_price': 8500,
          'options_total': 1000,
          'line_total': 19000,
          'selected_option_value_ids': [3, 8],
        },
      ],
      'subtotal': 19000,
      'delivery_fee': 2000,
      'discount_total': 0,
      'total': 21000,
      'pricing_version': '2026-08-17T18:00:00Z',
    });

    expect(quote.restaurantId, 1);
    expect(quote.currency, 'XAF');
    expect(quote.items.first.productId, 10);
    expect(quote.items.first.selectedOptionValueIds, [3, 8]);
    expect(quote.total, 21000);
  });
}
