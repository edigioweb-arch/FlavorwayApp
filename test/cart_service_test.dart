import 'package:flavorapps/models/cart_item.dart';
import 'package:flavorapps/models/cart_quote.dart';
import 'package:flavorapps/services/cart_service.dart';
import 'package:flavorapps/services/checkout_quote_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCheckoutQuoteService extends CheckoutQuoteService {
  _FakeCheckoutQuoteService({this.quote, this.error});

  final CartQuote? quote;
  final Object? error;

  @override
  Future<CartQuote> fetchQuote(CheckoutQuotePayload payload) async {
    if (error != null) {
      throw error!;
    }

    return quote!;
  }
}

void main() {
  CartItem buildItem() {
    return CartItem(
      id: '10-3',
      productId: 10,
      restaurantId: 1,
      name: 'Poulet braisé',
      image: '',
      restaurantName: 'Joli Coin',
      price: 8500,
      currencyCode: 'XAF',
      quantity: 2,
      optionValueIds: const [3],
      options: const {'Taille': 'Grand format'},
    );
  }

  test('CartService updates total after successful quote', () async {
    final service = CartService(
      quoteService: _FakeCheckoutQuoteService(
        quote: CartQuote.fromJson({
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
              'selected_option_value_ids': [3],
            },
          ],
          'subtotal': 19000,
          'delivery_fee': 2000,
          'discount_total': 0,
          'total': 21000,
          'pricing_version': '2026-08-17T18:00:00Z',
        }),
      ),
    );

    service.addItem(buildItem());
    final success = await service.refreshQuote(paymentMethod: 'cash');

    expect(success, isTrue);
    expect(service.hasValidQuote, isTrue);
    expect(service.displayTotal, 21000);
  });

  test('CartService blocks checkout when quote fails', () async {
    final service = CartService(
      quoteService: _FakeCheckoutQuoteService(
        error: Exception('Produit indisponible'),
      ),
    );

    service.addItem(buildItem());
    final success = await service.refreshQuote(paymentMethod: 'cash');

    expect(success, isFalse);
    expect(service.hasValidQuote, isFalse);
    expect(service.quoteStatus, CartQuoteStatus.quoteError);
  });
}
