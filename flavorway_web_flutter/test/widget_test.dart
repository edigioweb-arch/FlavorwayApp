import 'package:flutter_test/flutter_test.dart';
import 'package:flavorway_web_flutter/main.dart';

void main() {
  testWidgets('FlavorWay landing page loads', (tester) async {
    await tester.pumpWidget(const FlavorWayApp());
    expect(find.byType(FlavorWayLandingPage), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
