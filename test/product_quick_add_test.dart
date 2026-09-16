import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flavorapps/models/cart_item.dart';
import 'package:flavorapps/models/restaurant_model.dart';
import 'package:flavorapps/services/cart_service.dart';
import 'package:flavorapps/widgets/cart_button.dart';
import 'package:flavorapps/widgets/product_quick_add.dart';

void main() {
  late CartService cart;
  late RestaurantDishModel dish;
  late int opened;
  setUp(() {
    cart = CartService();
    opened = 0;
    dish = RestaurantDishModel(
        id: '1',
        restaurantId: '4',
        name: 'Poulet',
        description: '',
        priceText: '5000 FCFA',
        price: 5000,
        currencyCode: 'XAF');
  });
  Future<void> mount(WidgetTester tester, {double width = 320}) async {
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: cart,
        child: MaterialApp(
            home: Scaffold(
                body: Column(children: [
          const CartButton(),
          SizedBox(
              width: width,
              child: GestureDetector(
                onTap: () => opened++,
                child: Column(children: [
                  const Text('Fiche produit'),
                  ProductQuickAdd(dish: dish, onOpenDetail: () => opened++)
                ]),
              )),
        ])))));
  }

  Future<void> add(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Ajouter Poulet'));
    await tester.pump();
  }

  CartItem variant(int option) => CartItem(
      id: '1-$option',
      productId: 1,
      restaurantId: 4,
      name: 'Poulet',
      image: '',
      restaurantName: 'R',
      price: 5000,
      currencyCode: 'XAF',
      optionValueIds: [option]);

  testWidgets('sans options ajout direct', (t) async {
    await mount(t);
    await add(t);
    expect(cart.itemCount, 1);
    expect(opened, 0);
  });
  testWidgets('quantité un et retrait visibles', (t) async {
    await mount(t);
    await add(t);
    expect(find.byTooltip('Retirer Poulet'), findsOneWidget);
    expect(t.widget<Text>(find.byKey(const ValueKey('quantity-1'))).data, '1');
  });
  testWidgets('plus incrémente', (t) async {
    await mount(t);
    await add(t);
    await add(t);
    expect(cart.items.single.quantity, 2);
  });
  testWidgets('moins décrémente', (t) async {
    await mount(t);
    await add(t);
    await add(t);
    await t.tap(find.byTooltip('Retirer Poulet'));
    await t.pump();
    expect(cart.itemCount, 1);
  });
  testWidgets('zéro revient au seul plus', (t) async {
    await mount(t);
    await add(t);
    await t.tap(find.byTooltip('Retirer Poulet'));
    await t.pump();
    expect(cart.items, isEmpty);
    expect(find.byTooltip('Retirer Poulet'), findsNothing);
    expect(find.byTooltip('Ajouter Poulet'), findsOneWidget);
  });
  testWidgets('indisponible désactivé', (t) async {
    dish.isAvailable = false;
    await mount(t);
    await add(t);
    expect(cart.items, isEmpty);
    expect(
        t
            .widget<IconButton>(find.byWidgetPredicate((widget) =>
                widget is IconButton && widget.tooltip == 'Ajouter Poulet'))
            .onPressed,
        isNull);
  });
  testWidgets('option obligatoire ouvre fiche', (t) async {
    dish.options = [
      ProductOptionModel(
          id: '9', name: 'Format', selectionType: 'single', isRequired: true)
    ];
    await mount(t);
    await add(t);
    expect(opened, 1);
    expect(cart.items, isEmpty);
  });
  testWidgets('badge synchronisé ajout et retrait', (t) async {
    await mount(t);
    await add(t);
    await add(t);
    expect(t.widget<Text>(find.byKey(const Key('cart-quantity'))).data, '2');
    await t.tap(find.byTooltip('Retirer Poulet'));
    await t.pump();
    expect(t.widget<Text>(find.byKey(const Key('cart-quantity'))).data, '1');
  });
  testWidgets('variantes restent distinctes et ouvrent fiche', (t) async {
    cart.addItem(variant(10));
    cart.addItem(variant(11));
    await mount(t);
    await add(t);
    expect(opened, 1);
    expect(cart.items.length, 2);
    expect(cart.items.map((e) => e.quantity), [1, 1]);
    expect(find.byTooltip('Retirer Poulet'), findsNothing);
  });
  testWidgets('petit espace sans overflow et cibles tactiles', (t) async {
    await mount(t, width: 130);
    await add(t);
    expect(t.takeException(), isNull);
    expect(t.getSize(find.byTooltip('Ajouter Poulet')).height,
        greaterThanOrEqualTo(48));
    expect(t.getSize(find.byTooltip('Retirer Poulet')).width,
        greaterThanOrEqualTo(48));
  });
  testWidgets('carte ouvre encore fiche', (t) async {
    await mount(t);
    await t.tap(find.text('Fiche produit'));
    expect(opened, 1);
    expect(cart.items, isEmpty);
  });
  testWidgets('options facultatives permettent ajout sans sélection',
      (t) async {
    dish.options = [
      ProductOptionModel(id: '9', name: 'Sauce', selectionType: 'single')
    ];
    await mount(t);
    await add(t);
    expect(cart.items.single.optionValueIds, isEmpty);
    expect(opened, 0);
  });
}
