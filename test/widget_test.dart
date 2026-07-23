import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('Test chargement app FlavorWay', (WidgetTester tester) async {
    await tester.pumpWidget(const FlavorWayApp());

    expect(find.byType(Scaffold), findsOneWidget);
  });
}
