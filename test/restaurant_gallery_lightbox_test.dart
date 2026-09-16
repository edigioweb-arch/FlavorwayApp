import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flavorapps/widgets/restaurant_gallery_lightbox.dart';

void main() {
  Future<void> mount(WidgetTester tester,
      {List<String> images = const ['missing-a.png', 'missing-b.png'],
      int index = 0}) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: RestaurantGalleryThumbnail(
      images: images,
      index: index,
      child: const SizedBox(width: 128, height: 108, child: Text('Photo')),
    ))));
    if (images.isNotEmpty) {
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('thumbnail opens selected image contained at full screen',
      (tester) async {
    await mount(tester, index: 1);
    expect(find.byType(RestaurantGalleryLightbox), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(
        tester.widget<Image>(find.byKey(const ValueKey('missing-b.png'))).fit,
        BoxFit.contain);
  });
  testWidgets('next and previous navigate all images and wrap', (tester) async {
    await mount(tester);
    await tester.tap(find.byTooltip('Photo suivante'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('missing-b.png')), findsOneWidget);
    await tester.tap(find.byTooltip('Photo suivante'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Photo précédente'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
  });
  testWidgets('close button dismisses lightbox', (tester) async {
    await mount(tester);
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    expect(find.byType(RestaurantGalleryLightbox), findsNothing);
  });
  testWidgets('keyboard arrows and Escape work', (tester) async {
    await mount(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(RestaurantGalleryLightbox), findsNothing);
  });
  testWidgets('dark background closes the viewer', (tester) async {
    await mount(tester);
    await tester.tapAt(const Offset(4, 150));
    await tester.pumpAndSettle();
    expect(find.byType(RestaurantGalleryLightbox), findsNothing);
  });
  testWidgets('single photo disables navigation', (tester) async {
    await mount(tester, images: ['missing-a.png']);
    expect(find.text('1 / 1'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Photo suivante'))
            .onPressed,
        isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('empty gallery has no clickable thumbnail', (tester) async {
    await mount(tester, images: []);
    expect(find.text('Photo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('small mobile viewport has no overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mount(tester);
    expect(find.byTooltip('Fermer').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Photo suivante').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
