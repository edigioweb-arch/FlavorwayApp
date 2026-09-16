import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flavorapps/screens/signup_success_screen.dart';
import 'package:flavorapps/screens/login_screen.dart';
import 'package:flavorapps/services/api_client.dart';
import 'package:flavorapps/services/login_identifier_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('success stays until explicit login action', (tester) async {
    var signedOut = false;
    await tester.pumpWidget(MaterialApp(
        home: SignupSuccessScreen(
      title: 'Compte créé',
      message: 'Bienvenue',
      resendEmail: () async {},
      signOut: () async {
        signedOut = true;
      },
    )));
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Compte créé'), findsOneWidget);
    expect(signedOut, false);
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(signedOut, true);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
  testWidgets('failed verification can be resent without recreating account',
      (tester) async {
    var sends = 0;
    await tester.pumpWidget(MaterialApp(
        home: SignupSuccessScreen(
      title: 'Compte créé',
      message: 'Bienvenue',
      verificationError: 'Réseau indisponible',
      resendEmail: () async {
        sends++;
      },
      signOut: () async {},
    )));
    expect(find.textContaining('Réseau indisponible'), findsOneWidget);
    await tester.tap(find.text('Renvoyer l’email de vérification'));
    await tester.pump();
    expect(sends, 1);
    expect(find.textContaining('L’envoi du lien'), findsOneWidget);
    await tester.tap(find.text('Renvoyer l’email de vérification'));
    await tester.pump();
    expect(sends, 1);
  });
  testWidgets('resend failure is visible', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: SignupSuccessScreen(
      title: 'Compte créé',
      message: 'Bienvenue',
      resendEmail: () async {
        throw Exception('Envoi indisponible');
      },
      signOut: () async {},
    )));
    await tester.tap(find.text('Renvoyer l’email de vérification'));
    await tester.pump();
    expect(find.textContaining('Envoi indisponible'), findsOneWidget);
  });
  test('email does not require username endpoint', () async {
    final service = LoginIdentifierService(
        api: ApiClient(
            client: MockClient((_) async => throw StateError('unexpected'))));
    expect(await service.resolve(' CLIENT@Example.com ', 'secret'),
        'client@example.com');
  });
  test('username normalized and password preserved', () async {
    final service = LoginIdentifierService(
        api: ApiClient(client: MockClient((request) async {
      expect(request.url.path, '/api/v1/auth/username-login');
      expect(jsonDecode(request.body),
          {'username': 'cynthia', 'password': ' secret '});
      return http.Response('{"email":"client@example.com"}', 200);
    })));
    expect(
        await service.resolve(' CYNTHIA ', ' secret '), 'client@example.com');
  });
  test('incorrect username password cannot resolve email', () async {
    final service = LoginIdentifierService(
        api: ApiClient(
            client: MockClient((_) async => http.Response(
                '{"message":"Identifiant ou mot de passe incorrect."}', 401))));
    await expectLater(
        service.resolve('cynthia', 'wrong'), throwsA(isA<ApiException>()));
  });
}
