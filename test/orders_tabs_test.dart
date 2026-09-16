import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flavorapps/screens/orders_screen.dart';
import 'package:flavorapps/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class NoAuth extends Fake implements FirebaseAuth {}

class TabOrders extends OrderService {
  TabOrders() : super(auth: NoAuth());
  final controllers = <StreamController<List<OrderModel>>>[];
  int cancelled = 0;
  Stream<List<OrderModel>> source() {
    final c = StreamController<List<OrderModel>>(onCancel: () {
      cancelled++;
    });
    controllers.add(c);
    c.add([]);
    return c.stream;
  }

  @override
  Stream<List<OrderModel>> get activeOrdersStream => source();
  @override
  Stream<List<OrderModel>> get completedOrdersStream => source();
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets(
      'tabs can repeatedly detach and reattach single subscription streams',
      (tester) async {
    final service = TabOrders();
    await tester
        .pumpWidget(MaterialApp(home: OrdersScreen(orderService: service)));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Historique'));
      await tester.pumpAndSettle();
      expect(find.text("Aucune commande dans l'historique"), findsOneWidget);
      await tester.tap(find.text('En cours'));
      await tester.pumpAndSettle();
      expect(find.text('Aucune commande en cours'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(service.cancelled, service.controllers.length);
    for (final controller in service.controllers) {
      unawaited(controller.close());
    }
  });
  testWidgets(
      'reopening orders creates a new subscription and displays server updates',
      (tester) async {
    final service = TabOrders();
    for (var i = 0; i < 2; i++) {
      await tester
          .pumpWidget(MaterialApp(home: OrdersScreen(orderService: service)));
      await tester.pumpAndSettle();
      service.controllers.last.add([
        OrderModel.fromJson({
          'id': 1,
          'order_number': 'SERVER-ORDER-1',
          'status': 'confirmed',
          'total': 6000,
          'currency': 'XAF',
          'items': [],
        })
      ]);
      await tester.pumpAndSettle();
      expect(find.text('SERVER-ORDER-1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
    expect(service.cancelled, service.controllers.length);
    for (final controller in service.controllers) {
      unawaited(controller.close());
    }
  });
}
