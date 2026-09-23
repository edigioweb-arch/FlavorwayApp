import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flavorapps/services/api_client.dart';
import 'package:flavorapps/services/courier_session_service.dart';
import 'package:flavorapps/services/notification_navigation_service.dart';
import 'package:flavorapps/screens/courier/courier_screens.dart';

class MemoryCourierTokens implements CourierTokenStore {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}

class CourierServer {
  final store = MemoryCourierTokens();
  final calls = <http.Request>[];
  bool mustChange = false;
  bool failLogin = false;
  bool failAction = false;
  bool expired = false;
  bool restaurant = false;
  String phone = '123';
  final readNotifications = <int>{};
  String status = 'ready';
  String payment = 'pending';
  Map<String, dynamic> get profile => {
        'id': 12,
        'first_name': 'Lina',
        'last_name': 'Livreuse',
        'name': 'Lina Livreuse',
        'email': 'courier@test.local',
        'phone': phone,
        'role': 'courier',
        'courier_type': restaurant ? 'restaurant' : 'flavorway',
        'status': 'active',
        'restaurant':
            restaurant ? {'id': 1, 'name': 'Restaurant associé'} : null,
        'city': {'id': 1, 'name': 'Brazzaville'},
        'must_change_password': mustChange,
      };
  Map<String, dynamic> get order => {
        'id': 51,
        'order_number': 'SERVER-51',
        'restaurant': {'name': 'Restaurant réel', 'address': 'Rue restaurant'},
        'delivery_address': {
          'address_line': 'Rue client',
          'city': 'Brazzaville',
          'instructions': 'Portail bleu',
          'landmark': 'École',
        },
        'notes': 'Appeler en arrivant',
        'client_phone': '+242060000001',
        'status': status,
        'payment_method': 'cash',
        'payment_status': payment,
        'subtotal': 10000,
        'delivery_fee': 1000,
        'discount_total': 0,
        'total': 11000,
        'cash_due': payment == 'paid' ? 0 : 11000,
        'courier_actions': status == 'ready'
            ? ['pickup']
            : status == 'picked_up'
                ? ['on-the-way']
                : status == 'on_the_way'
                    ? ['deliver']
                    : [],
        'can_collect_cash': status == 'delivered' && payment != 'paid',
        'items': [
          {
            'name': 'Plat serveur',
            'quantity': 2,
            'line_total': 10000,
            'options': [
              {'option_name': 'Sauce', 'option_value': 'Piment'}
            ]
          }
        ],
        'status_history': [
          {
            'to_status': 'ready',
            'source': 'restaurant',
            'changed_at': '2026-09-21T10:00:00Z'
          }
        ],
      };
  late final session = CourierSessionService(
      store: store,
      api: ApiClient(client: MockClient((request) async {
        calls.add(request);
        final path = request.url.path.replaceFirst('/api/v1/courier/', '');
        http.Response json(Map<String, dynamic> body, [int code = 200]) =>
            http.Response(jsonEncode(body), code,
                headers: {'content-type': 'application/json; charset=utf-8'});
        if (path == 'password/forgot') {
          return json(
              {'message': 'Demande transmise à l’administration.'}, 202);
        }
        if (path == 'login') {
          if (failLogin)
            return json({'message': 'Identifiants invalides'}, 401);
          return json({
            'data': {'token': 'laravel-token', 'profile': profile}
          });
        }
        if (expired) return json({'message': 'Session expirée'}, 401);
        if (path == 'me' || path == 'profile') return json({'data': profile});
        if (path == 'password') {
          mustChange = false;
          return json({
            'data': {'token': 'rotated-token', 'profile': profile}
          });
        }
        if (path == 'logout') return json({'success': true});
        if (path == 'dashboard')
          return json({
            'data': {
              'active_orders': 7,
              'today_orders': 9,
              'completed_deliveries': 321,
              'cash_due': payment == 'paid' ? 0 : 11000,
              'collections_count':
                  status == 'delivered' && payment != 'paid' ? 1 : 0,
              'collections_due':
                  status == 'delivered' && payment != 'paid' ? 11000 : 0,
              'collections':
                  status == 'delivered' && payment != 'paid' ? [order] : [],
            }
          });
        if (path.startsWith('notifications/') && request.method == 'POST') {
          readNotifications.add(int.parse(path.split('/')[1]));
          return json({'success': true});
        }
        if (path == 'notifications') {
          final page = request.url.queryParameters['page'] ?? '1';
          final id = page == '1' ? 1 : 2;
          return json({
            'data': [
              {
                'id': id,
                'title':
                    page == '1' ? 'Commande prête' : 'Assignation précédente',
                'body': 'SERVER-51',
                'is_read': readNotifications.contains(id),
                'created_at': '2026-09-22T10:00:00Z',
                'data': {'destination': 'courier', 'order_number': 'SERVER-51'}
              }
            ],
            'meta': {
              'last_page': 2,
              'current_page': int.parse(page),
              'unread_count': 2 - readNotifications.length
            },
          });
        }
        if (path == 'orders' || path == 'history')
          return json({
            'data': [order],
            'meta': {'last_page': 2, 'total': 21}
          });
        if (path == 'orders/SERVER-51') return json({'data': order});
        if (request.method == 'POST' && path.startsWith('orders/')) {
          if (failAction)
            return json({'message': 'Commande non autorisée'}, 403);
          switch (path.split('/').last) {
            case 'pickup':
              status = 'picked_up';
              break;
            case 'on-the-way':
              status = 'on_the_way';
              break;
            case 'deliver':
              status = 'delivered';
              break;
            case 'cash-collected':
              payment = 'paid';
              break;
          }
          return json({'data': order});
        }
        return json({'success': true});
      })));
}

void main() {
  testWidgets('connected courier changes password from profile and returns',
      (tester) async {
    final server = CourierServer();
    await server.session.login('courier@test.local', 'old');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CourierProfileScreen(session: server.session))));
    await tester.scrollUntilVisible(find.text('Changer mon mot de passe'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Changer mon mot de passe'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ce changement est obligatoire'), findsNothing);
    await tester.enterText(find.byType(TextField).at(0), 'old');
    await tester.enterText(find.byType(TextField).at(1), 'PersonalSecret123');
    await tester.enterText(find.byType(TextField).at(2), 'PersonalSecret123');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(server.store.token, 'rotated-token');
    expect(find.text('Mot de passe modifié.'), findsOneWidget);
    final body = jsonDecode(server.calls.last.body);
    expect(body['current_password'], 'old');
    expect(body['password_confirmation'], 'PersonalSecret123');
  });

  test('recovery uses public Laravel endpoint without a session', () async {
    final server = CourierServer();
    expect(await server.session.requestPasswordReset(' courier@test.local '),
        'Demande transmise à l’administration.');
    expect(server.calls.single.url.path, '/api/v1/courier/password/forgot');
    expect(server.calls.single.headers['authorization'], isNull);
    expect(
        jsonDecode(server.calls.single.body), {'email': 'courier@test.local'});
    expect(server.session.hasSession, isFalse);
  });
  testWidgets('recovery sends request and displays server acknowledgement',
      (tester) async {
    final server = CourierServer();
    await tester.pumpWidget(MaterialApp(
        home: CourierForgotPasswordScreen(
            session: server.session, email: 'courier@test.local')));
    await tester.tap(find.text('Envoyer ma demande'));
    await tester.pumpAndSettle();
    expect(find.text('Demande transmise à l’administration.'), findsOneWidget);
    expect(find.text('Retour à la connexion'), findsOneWidget);
    expect(server.session.hasSession, isFalse);
  });
  testWidgets('recovery refuses malformed email without sending',
      (tester) async {
    final server = CourierServer();
    await tester.pumpWidget(MaterialApp(
        home: CourierForgotPasswordScreen(session: server.session)));
    await tester.tap(find.text('Envoyer ma demande'));
    await tester.pumpAndSettle();
    expect(find.text('Indiquez un email valide.'), findsOneWidget);
    expect(server.calls, isEmpty);
  });

  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> mount(WidgetTester tester, Widget widget) async {
    await tester.binding.setSurfaceSize(const Size(440, 1500));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(MaterialApp(home: widget));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'detail menu reaches profile and home without losing courier session',
      (tester) async {
    final server = CourierServer();
    await server.session.login('a@b.c', 'old');
    await mount(tester,
        CourierGate(session: server.session, orderReference: 'SERVER-51'));
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Profil livreur'), findsOneWidget);
    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();
    expect(find.text('Bonjour Lina Livreuse'), findsOneWidget);
    expect(server.session.isReady, isTrue);
  });
  testWidgets(
      'pickup is red until server confirms and then shows green confirmation',
      (tester) async {
    final server = CourierServer();
    await server.session.login('a@b.c', 'old');
    await mount(tester,
        CourierGate(session: server.session, orderReference: 'SERVER-51'));
    final button =
        find.widgetWithText(FilledButton, 'Confirmer la récupération');
    await tester.ensureVisible(button);
    expect(
        tester.widget<FilledButton>(button).style!.backgroundColor!.resolve({}),
        const Color(0xFFB3261E));
    expect(find.text('Récupération confirmée'), findsNothing);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(server.status, 'picked_up');
    expect(find.text('Récupération confirmée'), findsOneWidget);
    expect(button, findsNothing);
  });

  testWidgets(
      'assigned confirmed order explains waiting and shows pickup after refresh',
      (tester) async {
    final server = CourierServer()..status = 'confirmed';
    await server.session.login('a@b.c', 'old');
    await mount(tester,
        CourierGate(session: server.session, orderReference: 'SERVER-51'));
    expect(find.text('En attente du restaurant'), findsOneWidget);
    expect(find.text('Suivi de la commande'), findsOneWidget);
    expect(find.text('Confirmer la récupération'), findsNothing);
    server.status = 'ready';
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();
    expect(find.text('Confirmer la récupération'), findsOneWidget);
    expect(find.text('En attente du restaurant'), findsNothing);
  });
  test('courier login uses Laravel and persists only its token', () async {
    final server = CourierServer();
    await server.session.login('courier@test.local', 'secret');
    expect(server.store.token, 'laravel-token');
    expect(server.session.isReady, isTrue);
    expect(server.calls.single.url.path, '/api/v1/courier/login');
    expect(jsonDecode(server.calls.single.body),
        {'email': 'courier@test.local', 'password': 'secret'});
  });
  test('mandatory password rotates stored credential', () async {
    final server = CourierServer()..mustChange = true;
    await server.session.login('a@b.c', 'old');
    expect(server.session.isReady, isFalse);
    await server.session
        .changePassword('old', 'NewSecret1234', 'NewSecret1234');
    expect(server.store.token, 'rotated-token');
    expect(server.session.mustChangePassword, isFalse);
  });
  test('restore validates Laravel session and expiry clears credentials',
      () async {
    final server = CourierServer();
    server.store.token = 'stored-token';
    await server.session.restore();
    expect(server.session.isReady, isTrue);
    expect(server.calls.single.headers['Authorization'], 'Bearer stored-token');
    server.expired = true;
    await expectLater(
        server.session.request('orders'), throwsA(isA<ApiException>()));
    expect(server.store.token, isNull);
    expect(server.session.profile, isNull);
  });
  test('logout revokes server session before clearing secure token', () async {
    final server = CourierServer();
    await server.session.login('a@b.c', 'old');
    await server.session.logout();
    expect(server.calls.last.url.path, '/api/v1/courier/logout');
    expect(server.calls.last.method, 'POST');
    expect(server.store.token, isNull);
  });
  testWidgets('courier login is distinct and offers an admin recovery request',
      (tester) async {
    final server = CourierServer();
    await mount(tester, CourierGate(session: server.session));
    expect(find.text('Connexion livreur'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'courier@test.local');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Bonjour Lina Livreuse'), findsOneWidget);
  });
  testWidgets('invalid login displays error without opening dashboard',
      (tester) async {
    final server = CourierServer()..failLogin = true;
    await mount(tester, CourierGate(session: server.session));
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Identifiants invalides'), findsOneWidget);
    expect(find.text('Bonjour Lina Livreuse'), findsNothing);
  });
  testWidgets('mandatory password gates dashboard and notification deep link',
      (tester) async {
    final server = CourierServer()..mustChange = true;
    await server.session.login('a@b.c', 'old');
    await mount(tester,
        CourierGate(session: server.session, orderReference: 'SERVER-51'));
    expect(find.text('Changer mon mot de passe'), findsOneWidget);
    expect(server.calls.any((c) => c.url.path.endsWith('/SERVER-51')), isFalse);
    await tester.enterText(find.byType(TextField).at(0), 'old');
    await tester.enterText(find.byType(TextField).at(1), 'NewSecret1234');
    await tester.enterText(find.byType(TextField).at(2), 'NewSecret1234');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('SERVER-51'), findsOneWidget);
  });
  for (final isRestaurant in [false, true]) {
    testWidgets(
        'dashboard displays server stats and courier type restaurant=$isRestaurant',
        (tester) async {
      final server = CourierServer()..restaurant = isRestaurant;
      await server.session.login('a@b.c', 'old');
      await mount(tester, CourierGate(session: server.session));
      expect(find.text('321'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Livreur ${isRestaurant ? 'Restaurant' : 'FlavorWay'}'),
          findsOneWidget);
      expect(find.text('Joli Coin'), findsNothing);
    });
  }
  testWidgets(
      'assigned orders list fetches API and opens exact server reference',
      (tester) async {
    final server = CourierServer();
    await server.session.login('a@b.c', 'old');
    await mount(tester, CourierGate(session: server.session));
    await tester.tap(find.text('Voir mes commandes assignées'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SERVER-51'));
    await tester.pumpAndSettle();
    expect(find.text('Rue restaurant'), findsOneWidget);
    expect(find.text('Rue client, Brazzaville'), findsOneWidget);
    expect(find.text('Sauce : Piment'), findsOneWidget);
  });
  testWidgets(
      'delivery buttons call existing API transitions and preserve timeline',
      (tester) async {
    final server = CourierServer();
    await server.session.login('a@b.c', 'old');
    await mount(tester,
        CourierGate(session: server.session, orderReference: 'SERVER-51'));
    for (final label in [
      'Confirmer la récupération',
      'Démarrer la livraison',
      'Confirmer la livraison'
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(server.status, 'delivered');
    expect(server.payment, 'pending');
    expect(find.text('Suivi de la commande'), findsOneWidget);
    final actions = server.calls
        .where((c) => c.method == 'POST')
        .map((c) => c.url.path)
        .toList();
    expect(
        actions,
        containsAllInOrder([
          '/api/v1/courier/orders/SERVER-51/pickup',
          '/api/v1/courier/orders/SERVER-51/on-the-way',
          '/api/v1/courier/orders/SERVER-51/deliver'
        ]));
  });
  testWidgets('Cash needs explicit confirmation then shows server paid state',
      (tester) async {
    final server = CourierServer()..status = 'delivered';
    await server.session.login('a@b.c', 'old');
    await mount(tester,
        CourierGate(session: server.session, orderReference: 'SERVER-51'));
    await tester.tap(find.text('Confirmer l’encaissement'));
    await tester.pumpAndSettle();
    expect(server.payment, 'pending');
    await tester.tap(find.text('Cash reçu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Paiement : Payé'), 300);
    expect(find.text('Paiement : Payé'), findsOneWidget);
    expect(find.text('Confirmer l’encaissement'), findsNothing);
  });
  testWidgets('failed delivery request does not fabricate success',
      (tester) async {
    final server = CourierServer()..failAction = true;
    await server.session.login('a@b.c', 'old');
    await mount(tester,
        CourierGate(session: server.session, orderReference: 'SERVER-51'));
    await tester.tap(find.text('Confirmer la récupération'));
    await tester.pumpAndSettle();
    expect(find.text('Commande non autorisée'), findsOneWidget);
    expect(server.status, 'ready');
    expect(find.text('Démarrer la livraison'), findsNothing);
  });
  testWidgets('history requests server pagination', (tester) async {
    final server = CourierServer();
    await server.session.login('a@b.c', 'old');
    await mount(
        tester,
        Scaffold(
            body: CourierOrdersScreen(session: server.session, history: true)));
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(server.calls.last.url.path, '/api/v1/courier/history');
    expect(server.calls.last.url.queryParameters['page'], '2');
  });
  testWidgets('profile exposes only phone editing', (tester) async {
    final server = CourierServer()..restaurant = true;
    await server.session.login('a@b.c', 'old');
    await mount(
        tester, Scaffold(body: CourierProfileScreen(session: server.session)));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Restaurant associé'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '456');
    await tester.tap(find.text('Enregistrer le téléphone'));
    await tester.pumpAndSettle();
    expect(jsonDecode(server.calls.last.body), {'phone': '456'});
  });
  testWidgets('courier notification routes to protected courier detail',
      (tester) async {
    final navigation = NotificationNavigationService();
    final routes = <RouteSettings>[];
    await tester.pumpWidget(MaterialApp(
        navigatorKey: navigation.navigatorKey,
        home: const Scaffold(),
        onGenerateRoute: (settings) {
          routes.add(settings);
          return MaterialPageRoute(builder: (_) => const Scaffold());
        }));
    navigation
        .handlePayload({'destination': 'courier', 'order_number': 'SERVER-51'});
    await tester.pumpAndSettle();
    expect(routes.single.name, '/courier/order');
    expect((routes.single.arguments as Map)['order_number'], 'SERVER-51');
  });
  testWidgets('courier notifications are loaded from Laravel', (tester) async {
    final server = CourierServer();
    await server.session.login('a@b.c', 'old');
    await mount(tester, CourierNotificationsScreen(session: server.session));
    expect(find.text('Commande prête'), findsOneWidget);
    expect(server.calls.last.url.path, '/api/v1/courier/notifications');
  });

  testWidgets(
      'delivered unpaid cash remains visible in active list and history',
      (tester) async {
    final server = CourierServer()..status = 'delivered';
    await server.session.login('a@b.c', 'old');
    for (final history in [false, true]) {
      await mount(
          tester,
          Scaffold(
              body: CourierOrdersScreen(
                  key: ValueKey(history),
                  session: server.session,
                  history: history)));
      expect(find.text('Cash à encaisser : 11000 FCFA'), findsOneWidget);
    }
    server.payment = 'paid';
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();
    expect(find.text('Cash à encaisser : 11000 FCFA'), findsNothing);
  });

  testWidgets('dashboard shows pending collections and opens server order',
      (tester) async {
    final server = CourierServer()..status = 'delivered';
    await server.session.login('a@b.c', 'old');
    await mount(tester, CourierGate(session: server.session));
    expect(find.text('Encaissements à confirmer'), findsOneWidget);
    await tester.ensureVisible(find.text('SERVER-51'));
    expect(find.text('Cash à encaisser : 11000 FCFA'), findsOneWidget);
    await tester.tap(find.text('SERVER-51'));
    await tester.pumpAndSettle();
    expect(server.calls.any((r) => r.url.path.endsWith('/orders/SERVER-51')),
        isTrue);
    expect(find.text('Confirmer l’encaissement'), findsOneWidget);
  });

  testWidgets('active list polls every 30 seconds and pauses in background',
      (tester) async {
    final server = CourierServer();
    await server.session.login('a@b.c', 'old');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await mount(
        tester, Scaffold(body: CourierOrdersScreen(session: server.session)));
    int calls() =>
        server.calls.where((r) => r.url.path.endsWith('/orders')).length;
    expect(calls(), 1);
    await tester.pump(const Duration(seconds: 29));
    expect(calls(), 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(calls(), 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 60));
    expect(calls(), 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('dashboard polling updates cash and stops under another route',
      (tester) async {
    final server = CourierServer()..status = 'delivered';
    await server.session.login('a@b.c', 'old');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await mount(tester, CourierGate(session: server.session));
    server.payment = 'paid';
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Aucun encaissement en attente.'), findsOneWidget);
    int calls() =>
        server.calls.where((r) => r.url.path.endsWith('/dashboard')).length;
    final count = calls();
    await tester.tap(find.byTooltip('Notifications : 2 non lues'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 60));
    await tester.pumpAndSettle();
    expect(calls(), count);
  });

  testWidgets('bell count updates after notification is marked read',
      (tester) async {
    final server = CourierServer();
    await server.session.login('a@b.c', 'old');
    await mount(tester, CourierGate(session: server.session));
    await tester.tap(find.byTooltip('Notifications : 2 non lues'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Non lue'), findsOneWidget);
    await tester.tap(find.byTooltip('Marquer comme lue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lue ·'), findsOneWidget);
    expect(find.byTooltip('Marquer comme lue'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Notifications : 1 non lues'), findsOneWidget);
  });

  testWidgets('notification pagination and refresh use Laravel page parameter',
      (tester) async {
    final server = CourierServer();
    await server.session.login('a@b.c', 'old');
    await mount(tester, CourierNotificationsScreen(session: server.session));
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Assignation précédente'), findsOneWidget);
    expect(server.calls.last.url.queryParameters['page'], '2');
    server.readNotifications.add(2);
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();
    expect(find.textContaining('Lue ·'), findsOneWidget);
    await tester.tap(find.text('Précédent'));
    await tester.pumpAndSettle();
    expect(find.text('Commande prête'), findsOneWidget);
  });

  testWidgets(
      'notification tap marks read and opens exact server order reference',
      (tester) async {
    final server = CourierServer();
    await server.session.login('a@b.c', 'old');
    final routes = <RouteSettings>[];
    await tester.pumpWidget(MaterialApp(
      navigatorKey: NotificationNavigationService.instance.navigatorKey,
      home: CourierNotificationsScreen(session: server.session),
      onGenerateRoute: (settings) {
        routes.add(settings);
        return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Order target')));
      },
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commande prête'));
    await tester.pumpAndSettle();
    expect(server.readNotifications, contains(1));
    expect(routes.single.name, '/courier/order');
    expect((routes.single.arguments as Map)['order_number'], 'SERVER-51');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'detail shows delivery instructions landmark note and authorized phone',
      (tester) async {
    final server = CourierServer();
    await server.session.login('a@b.c', 'old');
    await mount(tester,
        CourierGate(session: server.session, orderReference: 'SERVER-51'));
    await tester.scrollUntilVisible(find.text('Portail bleu'), 300);
    expect(find.text('Portail bleu'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('+242060000001'), 200);
    expect(find.text('École'), findsOneWidget);
    expect(find.text('Appeler en arrivant'), findsOneWidget);
    expect(find.text('+242060000001'), findsOneWidget);
  });

  testWidgets('profile fetches admin updates on opening and on pull refresh',
      (tester) async {
    final server = CourierServer();
    await server.session.login('a@b.c', 'old');
    server.phone = '987';
    server.restaurant = true;
    final revision = server.session.credentialRevision;
    await mount(
        tester, Scaffold(body: CourierProfileScreen(session: server.session)));
    expect(find.text('Restaurant associé'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '987');
    expect(server.calls.last.url.path, '/api/v1/courier/profile');
    expect(server.session.credentialRevision, revision);
    server.phone = '456';
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '456');
  });
}
