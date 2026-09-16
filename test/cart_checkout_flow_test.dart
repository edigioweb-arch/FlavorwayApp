import 'dart:async';
import 'package:flavorapps/models/cart_item.dart';
import 'package:flavorapps/models/cart_quote.dart';
import 'package:flavorapps/services/api_client.dart';
import 'package:flavorapps/services/cart_service.dart';
import 'package:flavorapps/services/checkout_quote_service.dart';
import 'package:flutter_test/flutter_test.dart';

class ControlledQuotes extends CheckoutQuoteService {
  final requests = <CheckoutQuotePayload>[];
  final responses = <Completer<CartQuote>>[];
  @override
  Future<CartQuote> fetchQuote(CheckoutQuotePayload payload) {
    requests.add(payload);
    final response = Completer<CartQuote>();
    responses.add(response);
    return response.future;
  }
}

CartItem item(
        {String id = '10', int quantity = 1, List<int> options = const []}) =>
    CartItem(
      id: id,
      productId: 10,
      restaurantId: 1,
      name: 'Plat',
      image: '',
      restaurantName: 'Restaurant',
      price: 1000,
      currencyCode: 'XAF',
      quantity: quantity,
      optionValueIds: options,
    );
CartQuote quote(double total, {bool manual = false}) => CartQuote(
      restaurantId: 1,
      currency: 'XAF',
      items: const [],
      subtotal: total - 100,
      deliveryFee: 100,
      discountTotal: 0,
      total: total,
      pricingVersion: 'test',
      requiresManualQuote: manual,
    );
const address = {
  'full': 'Rue test',
  'city_id': '1',
  'delivery_zone_area_id': '2'
};

void main() {
  late ControlledQuotes api;
  late CartService cart;
  setUp(() {
    api = ControlledQuotes();
    cart = CartService(quoteService: api);
    cart.addItem(item());
  });

  test('no network quote before address, invalid city is explained', () async {
    expect(await cart.refreshQuote(), isFalse);
    cart.selectDeliveryAddress({'full': 'Rue', 'city_id': 'invalid'});
    expect(await cart.refreshQuote(), isFalse);
    expect(api.requests, isEmpty);
    expect(cart.quoteErrorMessage, contains('ville'));
  });
  test('address and coordinates precede quote, mobile amounts are excluded',
      () async {
    cart.selectDeliveryAddress({...address, 'latitude': -4, 'longitude': 15.2});
    final pending = cart.refreshQuote(paymentMethod: 'cash');
    final payload = api.requests.single.toJson();
    expect(payload['delivery_address']['city_id'], 1);
    expect(payload['delivery_address']['delivery_zone_area_id'], 2);
    expect(payload['delivery_address']['latitude'], -4);
    expect(payload.containsKey('total'), isFalse);
    expect(payload['items'][0].containsKey('price'), isFalse);
    api.responses.single.complete(quote(1100));
    expect(await pending, isTrue);
  });
  test(
      'quantity change recalculates and stale success cannot overwrite newest quote',
      () async {
    cart.selectDeliveryAddress(address);
    final a = cart.refreshQuote();
    cart.updateQuantity('10', 3);
    expect(api.requests.length, 2);
    expect(api.requests[0].items.single.quantity, 1);
    expect(api.requests[1].items.single.quantity, 3);
    api.responses[1].complete(quote(3100));
    await Future<void>.delayed(Duration.zero);
    api.responses[0].complete(quote(1100));
    expect(await a, isFalse);
    expect(cart.quote!.total, 3100);
    expect(cart.hasValidQuote, isTrue);
  });
  test('stale failure cannot clear newest quote', () async {
    cart.selectDeliveryAddress(address);
    final a = cart.refreshQuote();
    final b = cart.refreshQuote();
    api.responses[1].complete(quote(2100));
    await b;
    api.responses[0].completeError(
        const ApiException(statusCode: 422, message: 'Ancien échec'));
    expect(await a, isFalse);
    expect(cart.quote!.total, 2100);
    expect(cart.quoteErrorMessage, isNull);
  });
  test('address and zone change invalidate an in-flight quote', () async {
    cart.selectDeliveryAddress(address);
    final a = cart.refreshQuote();
    cart.selectDeliveryAddress({...address, 'delivery_zone_area_id': '3'});
    expect(cart.hasValidQuote, isFalse);
    final b = cart.refreshQuote();
    expect(api.requests[1].deliveryZoneAreaId, '3');
    api.responses[1].complete(quote(2500));
    await b;
    api.responses[0].complete(quote(1100));
    await a;
    expect(cart.quote!.total, 2500);
  });
  test('removing a variant recalculates the remaining lines', () async {
    cart.addItem(item(id: '10-2', options: [2]));
    cart.selectDeliveryAddress(address);
    final a = cart.refreshQuote();
    api.responses[0].complete(quote(2100));
    await a;
    cart.removeItem('10-2');
    expect(api.requests[1].items.length, 1);
    api.responses[1].complete(quote(1100));
    await Future<void>.delayed(Duration.zero);
    expect(cart.quote!.total, 1100);
  });
  test('clear invalidates pending requests and resets badge', () async {
    cart.selectDeliveryAddress(address);
    final a = cart.refreshQuote();
    cart.clear();
    api.responses[0].complete(quote(1100));
    expect(await a, isFalse);
    expect(cart.itemCount, 0);
    expect(cart.quote, isNull);
    expect(cart.deliveryAddress, isNull);
  });
  test('manual quote flag cannot become a valid zero-fee quote', () async {
    cart.selectDeliveryAddress(address);
    final a = cart.refreshQuote();
    api.responses[0].complete(quote(1000, manual: true));
    expect(await a, isFalse);
    expect(cart.hasValidQuote, isFalse);
    expect(cart.quoteErrorMessage, contains('confirmés avant la commande'));
    expect(cart.itemCount, 1);
    expect(cart.deliveryAddress, address);
  });
  test('delivery validation failure preserves address and cart', () async {
    cart.selectDeliveryAddress(address);
    final a = cart.refreshQuote();
    api.responses[0].completeError(
        const ApiException(statusCode: 422, message: 'Ville inactive'));
    expect(await a, isFalse);
    expect(cart.quoteErrorMessage, 'Ville inactive');
    expect(cart.itemCount, 1);
    expect(cart.deliveryAddress, address);
  });
  test('same product with different options remains two lines', () {
    cart.addItem(item(id: '10-2', quantity: 2, options: [2]));
    expect(cart.items.length, 2);
    expect(cart.itemCount, 3);
  });
}
