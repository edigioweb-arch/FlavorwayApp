import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flavorapps/models/city_model.dart';
import 'package:flavorapps/services/city_api_service.dart';
import 'package:flavorapps/screens/signup_screen.dart';

class SignupCities extends CityApiService {
  @override
  Future<List<CityModel>> fetchCities() async => [];
}

class RecoveringSignupCities extends CityApiService {
  RecoveringSignupCities({this.failFirst = false});
  final bool failFirst;
  int calls = 0;
  @override
  Future<List<CityModel>> fetchCities() async {
    calls++;
    if (failFirst && calls == 1) throw Exception('Network unavailable');
    return [
      CityModel.fromJson({
        'id': 2,
        'name': 'Brazzaville',
        'country': {'id': 2, 'name': 'Congo', 'iso_code': 'CG'},
        'is_active': true,
        'is_visible_in_app': true,
        'launch_status': 'launched',
      })
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  Future<void> mount(WidgetTester tester,
      {Size size = const Size(360, 640),
      double keyboard = 0,
      CityApiService? cities}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(MaterialApp(
        home: SignUpScreen(cityApiService: cities ?? SignupCities())));
    await tester.pumpAndSettle();
  }

  Finder field(String hint) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == hint);
  Finder next() => find.widgetWithText(ElevatedButton, 'Suivant').first;
  Future<void> enter(WidgetTester tester, String hint, String value) async {
    await tester.ensureVisible(field(hint));
    await tester.pumpAndSettle();
    await tester.enterText(field(hint), value);
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester,
      {String email = 'recette@example.com',
      String phone = '242061234567',
      String password = 'Test1234',
      String confirm = 'Test1234'}) async {
    await enter(tester, 'Nom complet', 'Client Recette');
    await enter(tester, 'Utilisateur', 'client_recette');
    await enter(tester, 'Email', email);
    await enter(tester, 'Téléphone', phone);
    await enter(tester, 'Mot de passe', password);
    await enter(tester, 'Confirmer le mot de passe', confirm);
  }

  bool enabled(WidgetTester tester) =>
      tester.widget<ElevatedButton>(next()).onPressed != null;

  testWidgets('valid client form enables Next', (tester) async {
    await mount(tester);
    await fill(tester);
    expect(enabled(tester), isTrue);
  });
  testWidgets('invalid email shows rule and disables Next', (tester) async {
    await mount(tester);
    await fill(tester, email: 'client@');
    expect(enabled(tester), isFalse);
    expect(find.text('Saisissez un email valide, par exemple nom@exemple.com.'),
        findsOneWidget);
  });
  testWidgets('formatted Congo international phone is accepted',
      (tester) async {
    await mount(tester);
    await fill(tester, phone: '+242 06 123 45 67');
    expect(enabled(tester), isTrue);
  });
  testWidgets('invalid phone refuses letters and missing national digits',
      (tester) async {
    await mount(tester);
    await fill(tester, phone: '242abc');
    expect(enabled(tester), isFalse);
    await enter(tester, 'Téléphone', '24206123');
    expect(enabled(tester), isFalse);
    expect(
        find.textContaining('Congo : 242 suivi de 9 chiffres'), findsOneWidget);
  });
  testWidgets('short password has visible rule and disables Next',
      (tester) async {
    await mount(tester);
    await fill(tester, password: 'abc', confirm: 'abc');
    expect(enabled(tester), isFalse);
    expect(find.text('Le mot de passe doit contenir au moins 6 caractères.'),
        findsOneWidget);
  });
  testWidgets(
      'missing confirmation disables Next without permanent instructions',
      (tester) async {
    await mount(tester);
    await fill(tester, confirm: '');
    expect(enabled(tester), isFalse);
    expect(find.text('Confirmation obligatoire, identique au mot de passe.'),
        findsNothing);
  });
  testWidgets('mismatched confirmation shows error then clears when corrected',
      (tester) async {
    await mount(tester);
    await fill(tester, confirm: 'Different123');
    expect(enabled(tester), isFalse);
    expect(
        find.text('Les mots de passe ne correspondent pas.'), findsOneWidget);
    await enter(tester, 'Confirmer le mot de passe', 'Test1234');
    expect(enabled(tester), isTrue);
  });
  testWidgets(
      'small Android screen has no overflow and last field is accessible',
      (tester) async {
    await mount(tester, size: const Size(320, 480));
    await fill(tester);
    await tester.ensureVisible(next());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(next().hitTestable(), findsOneWidget);
  });
  testWidgets('open keyboard keeps password confirmation and Next scrollable',
      (tester) async {
    await mount(tester, size: const Size(360, 640), keyboard: 300);
    await fill(tester);
    await tester.ensureVisible(field('Confirmer le mot de passe'));
    await tester.pumpAndSettle();
    expect(field('Confirmer le mot de passe').hitTestable(), findsOneWidget);
    await tester.ensureVisible(next());
    await tester.pumpAndSettle();
    expect(next().hitTestable(), findsOneWidget);
    expect(tester.getRect(next()).bottom, lessThanOrEqualTo(340));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Next navigates PageView to address step', (tester) async {
    await mount(tester);
    await fill(tester);
    await tester.ensureVisible(next());
    await tester.pumpAndSettle();
    await tester.tap(next());
    await tester.pumpAndSettle();
    expect(find.text('Pays indisponibles — Réessayer'), findsOneWidget);
    expect(field('Adresse'), findsOneWidget);
    await tester
        .ensureVisible(find.widgetWithText(ElevatedButton, 'Créer un compte'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ElevatedButton, 'Créer un compte').hitTestable(),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reserved username explicitly disables Next', (tester) async {
    await mount(tester);
    await fill(tester);
    await enter(tester, 'Utilisateur', 'admin');
    expect(enabled(tester), isFalse);
    expect(find.text('Déjà pris'), findsOneWidget);
  });
  for (final failFirst in [false, true]) {
    testWidgets(
        'country city and address usable after network failure: $failFirst',
        (tester) async {
      final cities = RecoveringSignupCities(failFirst: failFirst);
      await mount(tester, cities: cities);
      await fill(tester);
      await tester.ensureVisible(next());
      await tester.pumpAndSettle();
      await tester.tap(next());
      await tester.pumpAndSettle();
      final country = find.text(
          failFirst ? 'Pays indisponibles — Réessayer' : 'Choisir un pays');
      await tester.ensureVisible(country);
      await tester.tap(country);
      await tester.pumpAndSettle();
      await tester.tap(find.text('République du Congo (Brazzaville)').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Choisir une ville'));
      await tester.tap(find.text('Choisir une ville'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brazzaville').last);
      await tester.pumpAndSettle();
      await enter(tester, 'Adresse', 'Adresse de recette');
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(cities.calls, failFirst ? 2 : 1);
      expect(
          tester
              .widget<ElevatedButton>(
                  find.widgetWithText(ElevatedButton, 'Créer un compte'))
              .onPressed,
          isNotNull);
      expect(tester.takeException(), isNull);
    });
  }
}
