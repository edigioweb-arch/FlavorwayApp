import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flavorapps/services/cart_service.dart';
import 'package:flavorapps/widgets/cart_button.dart';
import 'cart_checkout_flow_test.dart' show item;

void main() {
  testWidgets('home cart entry uses cart route and live total quantity badge',
      (tester) async {
    final cart = CartService();
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: cart,
        child: MaterialApp(
          home: const Scaffold(body: CartButton()),
          routes: {'/cart': (_) => const Scaffold(body: Text('Panier ouvert'))},
        )));
    cart.addItem(item(quantity: 2));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    cart.updateQuantity('10', 4);
    await tester.pump();
    expect(find.text('4'), findsOneWidget);
    cart.addItem(item(id: 'variant', quantity: 3, options: [1]));
    await tester.pump();
    expect(find.text('7'), findsOneWidget);
    cart.removeItem('variant');
    await tester.pump();
    expect(find.text('4'), findsOneWidget);
    cart.clear();
    await tester.pump();
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    await tester.tap(find.byKey(const Key('home-cart')));
    await tester.pumpAndSettle();
    expect(find.text('Panier ouvert'), findsOneWidget);
  });
}
