import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flavorapps/services/notification_navigation_service.dart';
import 'package:flavorapps/services/order_service.dart';
import 'package:flavorapps/screens/order_tracking_screen.dart';
import 'package:flavorapps/screens/restaurateur/restaurant_orders_screen.dart';
import 'financial_cycle_test.dart'
    show FinancialOrders, FinancialPayments, financialOrder;
import 'order_submission_test.dart' show SubmissionAuth;

class MissingOrderService extends OrderService {
  MissingOrderService() : super(auth: SubmissionAuth());
  int reads = 0;
  @override
  Future<OrderModel?> fetchOrderDetail(String orderNumber) async {
    reads++;
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  const payload = {
    'type': 'order_on_the_way',
    'order_id': '17',
    'order_number': 'MYSQL-17',
    'status': 'on_the_way',
    'destination': 'client',
  };
  Future<void> mount(WidgetTester tester, Widget widget) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  Widget app(NotificationNavigationService navigation,
          List<RouteSettings> calls) =>
      MaterialApp(
        navigatorKey: navigation.navigatorKey,
        home: const Scaffold(body: Text('Accueil')),
        onGenerateRoute: (settings) {
          calls.add(settings);
          return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Scaffold(body: Text(settings.name!)));
        },
      );

  testWidgets(
      'background notification opens exact Laravel order and preserves order_id',
      (tester) async {
    final navigation = NotificationNavigationService();
    final calls = <RouteSettings>[];
    await mount(tester, app(navigation, calls));
    navigation.handlePayload(payload);
    await tester.pumpAndSettle();
    expect(calls.single.name, '/order-tracking');
    expect((calls.single.arguments as Map)['order_reference'], 'MYSQL-17');
    expect((calls.single.arguments as Map)['order_id'], '17');
  });
  testWidgets(
      'terminated notification waits for navigator and is consumed once',
      (tester) async {
    final navigation = NotificationNavigationService();
    final calls = <RouteSettings>[];
    navigation.handlePayload(payload);
    await mount(tester, app(navigation, calls));
    navigation.flushPendingPayload();
    await tester.pumpAndSettle();
    expect(calls.length, 1);
    expect((calls.single.arguments as Map)['order_number'], 'MYSQL-17');
  });
  testWidgets('foreground notification banner has working open action',
      (tester) async {
    final navigation = NotificationNavigationService();
    final calls = <RouteSettings>[];
    await mount(tester, app(navigation, calls));
    navigation.showForegroundBanner('En route', 'Votre commande arrive',
        payload: payload);
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(calls.single.name, '/order-tracking');
  });
  for (final invalid in <Map<String, dynamic>>[
    {'type': 'order_delivered', 'order_id': '17'},
    {'type': 'order_delivered', 'order_number': ''},
    {'type': 'order_delivered', 'order_number': '../other'},
    {...payload, 'destination': 'courier'},
  ]) {
    testWidgets(
        'invalid or non-client payload cannot fabricate tracking $invalid',
        (tester) async {
      final navigation = NotificationNavigationService();
      final calls = <RouteSettings>[];
      await mount(tester, app(navigation, calls));
      navigation.handlePayload(invalid);
      await tester.pumpAndSettle();
      expect(
          calls.single.name,
          invalid['destination'] == 'courier'
              ? '/courier/order'
              : '/notifications');
    });
  }
  testWidgets(
      'tracking polling reflects real courier progress and Cash stays pending',
      (tester) async {
    final orders = FinancialOrders(financialOrder(
        method: 'cash', status: 'ready', payment: 'pending', retry: false));
    await mount(
        tester,
        MaterialApp(
            home: OrderTrackingScreen(
                orderReference: 'MYSQL-17',
                orderService: orders,
                paymentService: FinancialPayments())));
    expect(find.textContaining('À encaisser'), findsOneWidget);
    orders.order = financialOrder(
        method: 'cash', status: 'delivered', payment: 'pending', retry: false);
    await tester.pump(const Duration(seconds: 13));
    await tester.pumpAndSettle();
    expect(find.text('Livrée'), findsWidgets);
    expect(find.textContaining('À encaisser'), findsOneWidget);
    expect(find.text('Payé'), findsNothing);
    orders.order = financialOrder(
        method: 'cash', status: 'delivered', payment: 'paid', retry: false);
    await tester.pump(const Duration(seconds: 13));
    await tester.pumpAndSettle();
    expect(find.text('Payé'), findsOneWidget);
    expect(orders.reads, greaterThanOrEqualTo(3));
  });
  testWidgets(
      'unknown notification order only fetches and displays missing order',
      (tester) async {
    final orders = MissingOrderService();
    final navigation = NotificationNavigationService();
    await mount(
        tester,
        MaterialApp(
            navigatorKey: navigation.navigatorKey,
            home: const Scaffold(),
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
                builder: (_) => OrderTrackingScreen(
                    orderReference:
                        (settings.arguments as Map)['order_reference'],
                    orderService: orders,
                    paymentService: FinancialPayments()))));
    navigation.handlePayload({...payload, 'order_number': 'UNKNOWN-17'});
    await tester.pumpAndSettle();
    expect(orders.reads, 1);
    expect(find.text('Commande introuvable.'), findsOneWidget);
  });
  test('courier and timeline are parsed from the same server order', () {
    final order = OrderModel.fromJson({
      'id': 17,
      'order_number': 'MYSQL-17',
      'status': 'on_the_way',
      'assigned_courier': {'id': 42, 'name': 'Livreur réel', 'phone': '123'},
      'status_history': [
        {
          'to_status': 'picked_up',
          'source': 'courier',
          'changed_at': '2026-09-15T12:00:00Z'
        }
      ]
    });
    expect(order.courierName, 'Livreur réel');
    expect(order.courierPhone, '123');
    expect(order.timeline.single.status, 'picked_up');
    expect(order.timeline.single.updatedBy, 'courier');
  });
  testWidgets(
      'restaurant polling updates delivery status without losing order access',
      (tester) async {
    final orders =
        FinancialOrders(financialOrder(status: 'picked_up', retry: false));
    await mount(tester,
        MaterialApp(home: RestaurantOrdersScreen(orderService: orders)));
    orders.order = financialOrder(status: 'on_the_way', retry: false);
    await tester.pump(const Duration(seconds: 16));
    await tester.pumpAndSettle();
    expect(find.text('En livraison'), findsWidgets);
    expect(find.textContaining('MYSQL-17'), findsWidgets);
  });
}
