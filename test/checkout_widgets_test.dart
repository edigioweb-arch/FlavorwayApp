import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flavorapps/models/cart_item.dart';
import 'package:flavorapps/models/cart_quote.dart';
import 'package:flavorapps/models/payment_model.dart';
import 'package:flavorapps/models/restaurant_model.dart';
import 'package:flavorapps/screens/cart_screen.dart';
import 'package:flavorapps/screens/checkout_screen.dart';
import 'package:flavorapps/screens/product_detail_screen.dart';
import 'package:flavorapps/screens/order_success_screen.dart';
import 'package:flavorapps/services/api_client.dart';
import 'package:flavorapps/services/cart_service.dart';
import 'package:flavorapps/services/checkout_quote_service.dart';
import 'package:flavorapps/services/order_service.dart';
import 'package:flavorapps/services/payment_service.dart';
import 'cart_checkout_flow_test.dart' show item, quote, address;

class NoAuth extends Fake implements FirebaseAuth {}

class ImmediateQuotes extends CheckoutQuoteService {
  int calls = 0;
  @override
  Future<CartQuote> fetchQuote(CheckoutQuotePayload payload) async {
    calls++;
    return quote(1100);
  }
}

class FakeOrders extends OrderService {
  FakeOrders({this.fail = false, this.total = 1100}) : super(auth: NoAuth());
  final bool fail;
  final double total;
  final keys = <String>[];
  @override
  Future<OrderModel> createOrder(
      {required int restaurantId,
      required List<CartItem> items,
      required Map<String, dynamic> deliveryAddress,
      required String paymentMethod,
      required String idempotencyKey,
      String note = '',
      String? promoCode}) async {
    keys.add(idempotencyKey);
    if (fail)
      throw const ApiException(
          statusCode: 422, message: 'Produit indisponible');
    return OrderModel.fromJson({
      'id': 1,
      'order_number': 'SERVER-ORDER-42',
      'total': total,
      'currency': 'XAF',
      'status': 'pending_payment',
      'payment_status': 'unpaid'
    });
  }
}

class FakePayments extends PaymentService {
  FakePayments({this.fail = true}) : super(auth: NoAuth());
  final bool fail;
  int calls = 0;
  @override
  Future<PaymentModel> initiatePayment(
      {required String orderNumber,
      required String paymentMethod,
      String? phone,
      String? idempotencyKey}) async {
    calls++;
    if (fail)
      throw const ApiException(
          statusCode: 503, message: 'Paiement indisponible');
    return PaymentModel.fromJson(
        {'id': 1, 'order_number': orderNumber, 'status': 'failed'});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> mount(
      WidgetTester tester, Widget screen, CartService cart) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: cart,
        child: MaterialApp(
          home: screen,
          routes: {
            '/cart': (_) => const Scaffold(body: Text('Panier ouvert')),
            '/checkout': (_) => const Scaffold(body: Text('Adresse requise')),
            '/orders': (_) => const Scaffold(body: Text('Mes commandes')),
            '/order-tracking': (context) => Scaffold(
                body: Text(
                    'Suivi ${ModalRoute.of(context)!.settings.arguments}')),
            '/order-success': (_) => const Scaffold(body: Text('Succès')),
          },
        )));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    final button = find.textContaining('Passer la commande');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  RestaurantDishModel dish(
          {bool available = true,
          String selection = 'multiple',
          bool required = true}) =>
      RestaurantDishModel(
        id: '10',
        restaurantId: '1',
        name: 'Plat test',
        description: 'Description',
        priceText: '1000 XAF',
        price: 1000,
        currencyCode: 'XAF',
        isAvailable: available,
        options: [
          ProductOptionModel(
              id: '1',
              name: 'Sauces',
              selectionType: selection,
              isRequired: required,
              values: [
                ProductOptionValueModel(id: '1', name: 'Option A'),
                ProductOptionValueModel(id: '2', name: 'Option B')
              ])
        ],
      );

  testWidgets('cart opens address step without requesting a quote',
      (tester) async {
    final api = ImmediateQuotes();
    final cart = CartService(quoteService: api)..addItem(item());
    await mount(tester, const CartScreen(), cart);
    expect(api.calls, 0);
    await tester.tap(find.text('Choisir l’adresse de livraison'));
    await tester.pumpAndSettle();
    expect(find.text('Adresse requise'), findsOneWidget);
  });
  testWidgets('unavailable product cannot be added', (tester) async {
    final cart = CartService();
    await mount(
        tester, ProductDetailScreen(dish: dish(available: false)), cart);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    expect(cart.itemCount, 0);
  });
  testWidgets('required multiple options and post-add cart entry work',
      (tester) async {
    final cart = CartService();
    await mount(tester, ProductDetailScreen(dish: dish()), cart);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    await tester.ensureVisible(find.text('Option A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Option A'));
    await tester.pump();
    await tester.tap(find.text('Option B'));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(cart.items.single.optionValueIds, [1, 2]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir le panier'));
    await tester.pumpAndSettle();
    expect(find.text('Panier ouvert'), findsOneWidget);
  });
  testWidgets('optional single option can be switched and deselected',
      (tester) async {
    final cart = CartService();
    await mount(
        tester,
        ProductDetailScreen(dish: dish(selection: 'single', required: false)),
        cart);
    await tester.ensureVisible(find.text('Option A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Option A'));
    await tester.pump();
    await tester.tap(find.text('Option B'));
    await tester.pump();
    expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Option A'))
            .selected,
        isFalse);
    expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Option B'))
            .selected,
        isTrue);
    await tester.tap(find.text('Option B'));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(cart.items.single.optionValueIds, isEmpty);
  });
  testWidgets('failed creation keeps cart address and retry key',
      (tester) async {
    final cart = CartService(quoteService: ImmediateQuotes())
      ..addItem(item())
      ..selectDeliveryAddress(address);
    final orders = FakeOrders(fail: true);
    await mount(
        tester,
        CheckoutScreen(
            orderService: orders,
            initialPaymentMethod: 'Paiement à la livraison'),
        cart);
    await submit(tester);
    expect(cart.itemCount, 1);
    expect(cart.deliveryAddress, address);
    expect(find.textContaining('Produit indisponible'), findsOneWidget);
    await submit(tester);
    expect(orders.keys.length, 2);
    expect(orders.keys[0], orders.keys[1]);
  });
  testWidgets(
      'payment exception routes to actual server order without false success',
      (tester) async {
    final cart = CartService(quoteService: ImmediateQuotes())
      ..addItem(item())
      ..selectDeliveryAddress(address);
    await mount(
        tester,
        CheckoutScreen(
            orderService: FakeOrders(),
            paymentService: FakePayments(),
            initialPaymentMethod: 'Paiement à la livraison',
            onOrderCreated: (_) {}),
        cart);
    await submit(tester);
    expect(find.text('Suivi SERVER-ORDER-42'), findsOneWidget);
    expect(find.text('Succès'), findsNothing);
    expect(cart.itemCount, 0);
  });
  testWidgets('failed payment response also routes to tracking',
      (tester) async {
    final cart = CartService(quoteService: ImmediateQuotes())
      ..addItem(item())
      ..selectDeliveryAddress(address);
    await mount(
        tester,
        CheckoutScreen(
            orderService: FakeOrders(),
            paymentService: FakePayments(fail: false),
            initialPaymentMethod: 'Paiement à la livraison',
            onOrderCreated: (_) {}),
        cart);
    await submit(tester);
    expect(find.text('Suivi SERVER-ORDER-42'), findsOneWidget);
    expect(find.text('Succès'), findsNothing);
  });
  testWidgets('changed server total is shown before initiating payment',
      (tester) async {
    final cart = CartService(quoteService: ImmediateQuotes())
      ..addItem(item())
      ..selectDeliveryAddress(address);
    final payments = FakePayments();
    await mount(
        tester,
        CheckoutScreen(
            orderService: FakeOrders(total: 1500),
            paymentService: payments,
            initialPaymentMethod: 'Paiement à la livraison',
            onOrderCreated: (_) {}),
        cart);
    await tester.ensureVisible(find.textContaining('Passer la commande'));
    await tester.tap(find.textContaining('Passer la commande'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('de 1100 à 1500'), findsOneWidget);
    expect(payments.calls, 0);
    await tester.tap(find.text('Voir ma commande'));
    await tester.pumpAndSettle();
    expect(find.text('Suivi SERVER-ORDER-42'), findsOneWidget);
  });
  testWidgets('success screen never fabricates a missing reference',
      (tester) async {
    await mount(tester, const OrderSuccessScreen(), CartService());
    expect(find.textContaining('FLW-'), findsNothing);
    expect(find.textContaining('Référence indisponible'), findsOneWidget);
  });
}
