import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../lib/services/cart_service.dart';
import '../lib/services/restaurant_service.dart';
import '../lib/services/message_service.dart';
import '../lib/services/notification_service.dart';
import '../lib/services/locale_service.dart';
import '../lib/main.dart';

void main() {
  testWidgets('Test chargement app FlavorWay', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartService()),
          ChangeNotifierProvider(create: (_) => RestaurantService()),
          ChangeNotifierProvider(create: (_) => MessageService()),
          ChangeNotifierProvider.value(value: NotificationService.instance),
          ChangeNotifierProvider.value(value: LocaleService.instance),
        ],
        child: const FlavorWayApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
