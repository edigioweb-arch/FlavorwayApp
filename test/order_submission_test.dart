import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flavorapps/services/api_client.dart';
import 'package:flavorapps/services/order_service.dart';
import 'cart_checkout_flow_test.dart' show item;

class SubmissionUser extends Fake implements User {
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'test-token';
}

class SubmissionAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => SubmissionUser();
}

void main() {
  test(
      'order submission sends configuration only and returns server reference and total',
      () async {
    final service = OrderService(
        auth: SubmissionAuth(),
        apiClient: ApiClient(client: MockClient((request) async {
          final payload = jsonDecode(request.body) as Map;
          expect(payload['restaurant_id'], 1);
          expect(payload['idempotency_key'], 'key');
          expect(payload['items'][0]['quantity'], 2);
          expect(payload['items'][0]['option_value_ids'], [3]);
          expect(payload.containsKey('total'), isFalse);
          expect(payload.containsKey('delivery_fee'), isFalse);
          expect(payload['items'][0].containsKey('price'), isFalse);
          expect(payload['delivery_address']['city_id'], 1);
          expect(payload['payment_method'], 'cash');
          return http.Response(
              jsonEncode({
                'data': {'id': 1, 'order_number': 'MYSQL-42', 'total': 4200}
              }),
              201);
        })));
    final order = await service.createOrder(
        restaurantId: 1,
        items: [
          item(quantity: 2, options: [3])
        ],
        deliveryAddress: {'city_id': 1, 'address_line': 'Rue'},
        paymentMethod: 'Paiement à la livraison',
        idempotencyKey: 'key');
    expect(order.orderNumber, 'MYSQL-42');
    expect(order.total, 4200);
  });
  test(
      'missing server order reference is an explicit failure, never a local reference',
      () async {
    final service = OrderService(
        auth: SubmissionAuth(),
        apiClient: ApiClient(
            client: MockClient(
                (_) async => http.Response('{"data":{"id":1}}', 201))));
    await expectLater(
        service.createOrder(
            restaurantId: 1,
            items: [item()],
            deliveryAddress: {'address_line': 'Rue'},
            paymentMethod: 'cash',
            idempotencyKey: 'key'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('Référence'))));
  });
}
