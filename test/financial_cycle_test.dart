import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flavorapps/services/api_client.dart';
import 'package:flavorapps/services/order_service.dart';
import 'package:flavorapps/services/payment_service.dart';
import 'package:flavorapps/models/payment_model.dart';
import 'package:flavorapps/widgets/order_payment_action.dart';
import 'package:flavorapps/screens/order_tracking_screen.dart';
import 'package:flavorapps/screens/restaurateur/restaurant_orders_screen.dart';
import 'order_submission_test.dart' show SubmissionAuth;

OrderModel financialOrder(
        {String method = 'mtn_momo',
        String status = 'payment_failed',
        String payment = 'failed',
        bool retry = true,
        bool collect = false}) =>
    OrderModel.fromJson({
      'id': 17,
      'order_number': 'MYSQL-17',
      'payment_method': method,
      'status': status,
      'payment_status': payment,
      'can_retry_payment': retry,
      'can_collect_cash': collect,
      'total': 7300,
      'delivery_fee': 500,
      'cash_due': method == 'cash' && payment != 'paid' ? 7300 : 0,
    });

class FinancialPayments extends PaymentService {
  FinancialPayments({this.result = 'pending', this.fail = false})
      : super(auth: SubmissionAuth());
  String result;
  bool fail;
  Completer<void>? gate;
  final keys = <String?>[], methods = <String>[], references = <String>[];
  @override
  Future<PaymentModel> initiatePayment(
      {required String orderNumber,
      required String paymentMethod,
      String? phone,
      String? idempotencyKey}) async {
    keys.add(idempotencyKey);
    methods.add(paymentMethod);
    references.add(orderNumber);
    if (gate != null) await gate!.future;
    if (fail)
      throw const ApiException(
          statusCode: 503, message: 'Opérateur indisponible');
    return PaymentModel.fromJson({
      'id': 1,
      'order_number': orderNumber,
      'internal_reference': 'PAY-SERVER-1',
      'status': result
    });
  }
}

class FinancialOrders extends OrderService {
  FinancialOrders(this.order) : super(auth: SubmissionAuth());
  OrderModel order;
  int collections = 0, reads = 0;
  @override
  Future<OrderModel?> fetchOrderDetail(String orderNumber) async {
    reads++;
    return order;
  }

  @override
  Future<List<OrderModel>> fetchRestaurantOrders(
          {String? status, int page = 1}) async =>
      [order];
  @override
  Future<void> confirmRestaurantCash(String orderNumber) async {
    expect(orderNumber, 'MYSQL-17');
    collections++;
    order = financialOrder(
        method: 'cash', status: 'delivered', payment: 'paid', retry: false);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  Future<void> mount(WidgetTester tester, Widget screen) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: screen)));
    await tester.pumpAndSettle();
  }

  test('cancelled Cash is never shown as due', () {
    expect(
        financialOrder(
                method: 'cash',
                status: 'cancelled',
                payment: 'cancelled',
                retry: false)
            .paymentLabel,
        contains('aucun encaissement'));
  });
  test('server-authorized failed order remains accessible in active orders',
      () {
    expect(financialOrder().isActive, isTrue);
    expect(financialOrder(retry: false).isActive, isFalse);
    expect(financialOrder(status: 'cancelled').isActive, isFalse);
    expect(financialOrder(status: 'delivered').isActive, isFalse);
  });
  test('cash is due until Laravel confirms paid', () {
    expect(financialOrder(method: 'cash', payment: 'unpaid').paymentLabel,
        contains('À encaisser'));
    expect(
        financialOrder(method: 'cash', payment: 'paid').paymentLabel, 'Payé');
  });
  for (final entry in {
    'reconciliation_required': 'vérification financière',
    'refund_pending': 'en attente',
    'refunded': 'Remboursé'
  }.entries) {
    test('financial ${entry.key} is distinct from ordinary paid', () {
      expect(financialOrder(payment: entry.key).paymentLabel,
          contains(entry.value));
    });
  }
  testWidgets(
      'client Cash screen never offers collection or retry even if retry flag is true',
      (tester) async {
    final api = FinancialPayments();
    await mount(
        tester,
        OrderPaymentAction(
            order: financialOrder(method: 'cash'),
            paymentService: api,
            onRefresh: () async {}));
    expect(find.byType(ElevatedButton), findsNothing);
    expect(api.keys, isEmpty);
  });
  testWidgets('server denial hides retry', (tester) async {
    await mount(
        tester,
        OrderPaymentAction(
            order: financialOrder(retry: false),
            paymentService: FinancialPayments(),
            onRefresh: () async {}));
    expect(find.text('Réessayer le paiement'), findsNothing);
  });
  testWidgets(
      'retry uses original server order and method then refreshes without false paid',
      (tester) async {
    final api = FinancialPayments();
    var refreshed = 0;
    await mount(
        tester,
        OrderPaymentAction(
            order: financialOrder(),
            paymentService: api,
            onRefresh: () async {
              refreshed++;
            }));
    await tester.tap(find.text('Réessayer le paiement'));
    await tester.pumpAndSettle();
    expect(api.references, ['MYSQL-17']);
    expect(api.methods, ['mtn_momo']);
    expect(refreshed, 1);
    expect(find.textContaining('reste en attente'), findsOneWidget);
    expect(find.textContaining('confirmé par le serveur'), findsNothing);
  });
  testWidgets('uncertain network failure preserves retry key and order access',
      (tester) async {
    final api = FinancialPayments(fail: true);
    await mount(
        tester,
        OrderPaymentAction(
            order: financialOrder(),
            paymentService: api,
            onRefresh: () async {}));
    await tester.tap(find.text('Réessayer le paiement'));
    await tester.pumpAndSettle();
    expect(find.text('Opérateur indisponible'), findsOneWidget);
    await tester.tap(find.text('Réessayer le paiement'));
    await tester.pumpAndSettle();
    expect(api.keys.length, 2);
    expect(api.keys[0], api.keys[1]);
  });
  testWidgets('explicit failed attempt uses a new key on next retry',
      (tester) async {
    final api = FinancialPayments(result: 'failed');
    await mount(
        tester,
        OrderPaymentAction(
            order: financialOrder(),
            paymentService: api,
            onRefresh: () async {}));
    await tester.tap(find.text('Réessayer le paiement'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Votre commande reste accessible'), findsOneWidget);
    await tester.tap(find.text('Réessayer le paiement'));
    await tester.pumpAndSettle();
    expect(api.keys[0], isNot(api.keys[1]));
  });
  testWidgets('server failure after pending permits a fresh retry key',
      (tester) async {
    final api = FinancialPayments();
    Widget action(OrderModel order) => OrderPaymentAction(
        order: order, paymentService: api, onRefresh: () async {});
    await mount(tester, action(financialOrder(payment: 'pending')));
    await tester.tap(find.text('Réessayer le paiement'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: action(financialOrder(payment: 'failed')))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Réessayer le paiement'));
    await tester.pumpAndSettle();
    expect(api.keys.length, 2);
    expect(api.keys[0], isNot(api.keys[1]));
  });
  testWidgets('double tap cannot initiate two payments', (tester) async {
    final api = FinancialPayments()..gate = Completer<void>();
    await mount(
        tester,
        OrderPaymentAction(
            order: financialOrder(),
            paymentService: api,
            onRefresh: () async {}));
    await tester.tap(find.text('Réessayer le paiement'));
    await tester.pump();
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    expect(api.keys.length, 1);
    api.gate!.complete();
    await tester.pumpAndSettle();
  });
  testWidgets(
      'tracking detail exposes retry for server-authorized failed order',
      (tester) async {
    final orders = FinancialOrders(financialOrder());
    final payments = FinancialPayments();
    await mount(
        tester,
        OrderTrackingScreen(
            orderReference: 'MYSQL-17',
            orderService: orders,
            paymentService: payments));
    final retry = find.text('Réessayer le paiement');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(payments.references, ['MYSQL-17']);
    expect(orders.reads, greaterThan(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'restaurant cash action requires server permission and refreshes paid',
      (tester) async {
    final orders = FinancialOrders(financialOrder(
        method: 'cash',
        status: 'delivered',
        payment: 'unpaid',
        retry: false,
        collect: true));
    await mount(tester, RestaurantOrdersScreen(orderService: orders));
    await tester.tap(find.text('Confirmer l’encaissement'));
    await tester.pumpAndSettle();
    expect(orders.collections, 1);
    expect(find.text('Confirmer l’encaissement'), findsNothing);
    await tester.tap(find.text('Détail'));
    await tester.pumpAndSettle();
    expect(find.text('Payé'), findsOneWidget);
  });
  testWidgets('restaurant without permission never sees cash confirmation',
      (tester) async {
    await mount(
        tester,
        RestaurantOrdersScreen(
            orderService: FinancialOrders(financialOrder(
                method: 'cash',
                status: 'delivered',
                payment: 'unpaid',
                retry: false))));
    expect(find.text('Confirmer l’encaissement'), findsNothing);
  });
  test('payment retry transmits no authoritative amount or status', () async {
    final api = PaymentService(
        auth: SubmissionAuth(),
        apiClient: ApiClient(client: MockClient((request) async {
          expect(request.url.path, '/api/v1/orders/MYSQL-17/payments');
          final data = jsonDecode(request.body);
          expect(data['payment_method'], 'mtn_momo');
          expect(data['idempotency_key'], 'retry-key');
          expect(data.containsKey('amount'), isFalse);
          expect(data.containsKey('status'), isFalse);
          expect(data.containsKey('user_id'), isFalse);
          return http.Response(
              '{"data":{"order_number":"MYSQL-17","internal_reference":"PAY-REAL","status":"pending"}}',
              201);
        })));
    expect(
        (await api.initiatePayment(
                orderNumber: 'MYSQL-17',
                paymentMethod: 'mtn_momo',
                idempotencyKey: 'retry-key'))
            .internalReference,
        'PAY-REAL');
  });
  test(
      'missing reference from payment API is an error instead of fabricated success',
      () async {
    final api = PaymentService(
        auth: SubmissionAuth(),
        apiClient: ApiClient(
            client: MockClient((_) async =>
                http.Response('{"data":{"status":"paid"}}', 201))));
    await expectLater(
        api.initiatePayment(orderNumber: 'MYSQL-17', paymentMethod: 'mtn_momo'),
        throwsA(isA<ApiException>()));
  });
  test('restaurant collection sends only authenticated order action', () async {
    final api = OrderService(
        auth: SubmissionAuth(),
        apiClient: ApiClient(client: MockClient((request) async {
          expect(request.url.path,
              '/api/v1/restaurant/orders/MYSQL-17/cash-collected');
          expect(jsonDecode(request.body), isEmpty);
          expect(request.headers['Authorization'], isNotEmpty);
          return http.Response('{"data":{"status":"paid"}}', 200);
        })));
    await api.confirmRestaurantCash('MYSQL-17');
  });
}
