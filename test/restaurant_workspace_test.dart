import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flavorapps/services/api_client.dart';
import 'package:flavorapps/services/restaurant_workspace_service.dart';
import 'package:flavorapps/services/order_service.dart';
import 'package:flavorapps/services/city_api_service.dart';
import 'package:flavorapps/models/city_model.dart';
import 'package:flavorapps/screens/restaurant_owner/restaurant_dashboard_screen.dart';
import 'package:flavorapps/screens/restaurant_owner/edit_restaurant_screen.dart';
import 'package:flavorapps/screens/restaurant_owner/edit_gallery_screen.dart';
import 'package:flavorapps/screens/restaurateur/restaurant_orders_screen.dart';
import 'package:flavorapps/screens/restaurateur/restaurant_reservations_screen.dart';
import 'order_submission_test.dart' show SubmissionAuth;

class Workspace extends RestaurantWorkspaceService {
  Workspace({this.status = 'active', this.subscription = true})
      : super(auth: SubmissionAuth());
  final String status;
  final bool subscription;
  int dashboards = 0, subscriptions = 0;
  Map<String, dynamic>? saved;
  String reservationStatus = 'pending';
  final actions = <String>[];
  @override
  Future<Map<String, dynamic>> fetchProfile() async => {
        'id': 73,
        'name': 'Cuisine propriétaire',
        'status': status,
        'city_id': 1,
        'delivery_mode': 'restaurant',
        'restaurant_delivery_fee': 700
      };
  @override
  Future<Map<String, dynamic>> fetchDashboard() async {
    dashboards++;
    return {
      'restaurant': await fetchProfile(),
      'stats': {
        'orders_today': 7,
        'orders_pending': 2,
        'reservations_total': 9,
        'revenue_today': 15400,
        'average_rating': null,
        'reviews_count': null
      },
      'recent_orders': []
    };
  }

  @override
  Future<Map<String, dynamic>?> fetchSubscription() async {
    subscriptions++;
    return subscription
        ? {
            'status': 'active',
            'plan': {'name': 'Premium serveur'}
          }
        : null;
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    saved = data;
    return {...await fetchProfile(), ...data};
  }

  @override
  Future<Map<String, dynamic>> fetchGallery() async => {'gallery': []};
  @override
  Future<Map<String, dynamic>> fetchReservations({int page = 1}) async => {
        'data': [
          {
            'id': 1,
            'reservation_number': 'RES-MYSQL',
            'status': reservationStatus,
            'party_size': 3,
            'customer': {'name': 'Cliente réelle'},
            'reservation_date': '2026-09-20',
            'reservation_time': '12:00'
          }
        ],
        'meta': {'last_page': 1}
      };
  @override
  Future<Map<String, dynamic>> reservationAction(
      String reference, String action,
      {String? reason}) async {
    expect(reference, 'RES-MYSQL');
    actions.add(action);
    reservationStatus = action == 'confirm' ? 'confirmed' : 'honored';
    return {};
  }
}

class Cities extends CityApiService {
  @override
  Future<List<CityModel>> fetchCities() async => [
        CityModel.fromJson({'id': 1, 'name': 'Brazzaville', 'is_active': true})
      ];
}

class OwnerOrders extends OrderService {
  OwnerOrders() : super(auth: SubmissionAuth());
  String status = 'confirmed';
  final actions = <String>[];
  @override
  Future<List<OrderModel>> fetchRestaurantOrders(
          {String? status, int page = 1}) async =>
      [
        OrderModel.fromJson({
          'id': 1,
          'order_number': 'ORDER-MYSQL',
          'status': this.status,
          'total': 3100,
          'payment_status': 'unpaid'
        })
      ];
  @override
  Future<OrderModel> transitionRestaurantOrder(
      {required String orderNumber,
      required String action,
      String? reason}) async {
    expect(orderNumber, 'ORDER-MYSQL');
    actions.add(action);
    status = action == 'confirm' ? 'preparing' : 'ready';
    return (await fetchRestaurantOrders()).first;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  Future<void> mount(WidgetTester tester, Widget screen) async {
    await tester.binding.setSurfaceSize(const Size(420, 1300));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'active compatibility dashboard loads authenticated restaurant and real statistics and subscription',
      (tester) async {
    final api = Workspace();
    await mount(tester, RestaurantDashboardScreen(workspace: api));
    expect(find.text('Cuisine propriétaire'), findsWidgets);
    expect(find.textContaining('Premium serveur'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('Non disponible'), findsNWidgets(2));
    expect(find.textContaining('Joli Coin'), findsNothing);
    for (final fake in ['12', '86', '48', '4,8', '124']) {
      expect(find.text(fake), findsNothing);
    }
    expect(api.dashboards, 1);
    expect(api.subscriptions, 1);
  });
  testWidgets(
      'pending owner never calls active business dashboard or subscription',
      (tester) async {
    final api = Workspace(status: 'pending');
    await mount(tester, RestaurantDashboardScreen(workspace: api));
    expect(find.textContaining('après activation'), findsOneWidget);
    expect(api.dashboards, 0);
    expect(api.subscriptions, 0);
  });
  testWidgets('missing subscription never invents a Standard plan',
      (tester) async {
    await mount(tester,
        RestaurantDashboardScreen(workspace: Workspace(subscription: false)));
    expect(find.text('Aucun abonnement associé'), findsOneWidget);
    expect(find.textContaining('Standard'), findsNothing);
  });
  testWidgets(
      'owner profile save persists through workspace API without local restaurant ID',
      (tester) async {
    final api = Workspace();
    await mount(
        tester, EditRestaurantScreen(workspace: api, cityApi: Cities()));
    expect(find.text('Cuisine propriétaire'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Nom modifié');
    final save = find.textContaining('Enregistrer').last;
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(api.saved?['name'], 'Nom modifié');
    expect(api.saved?['city_id'], 1);
    expect(api.saved?.containsKey('restaurant_id'), isFalse);
  });
  testWidgets(
      'owner order buttons call existing API transitions and refresh status',
      (tester) async {
    final api = OwnerOrders();
    await mount(tester, RestaurantOrdersScreen(orderService: api));
    await tester.tap(find.text('Démarrer'));
    await tester.pumpAndSettle();
    expect(api.actions, ['confirm']);
    expect(find.text('Prête'), findsOneWidget);
    await tester.tap(find.text('Prête'));
    await tester.pumpAndSettle();
    expect(api.actions, ['confirm', 'ready']);
    expect(find.text('Démarrer'), findsNothing);
  });
  testWidgets(
      'reservation confirmation refreshes available actions from server status',
      (tester) async {
    final api = Workspace();
    await mount(tester, RestaurantReservationsScreen(workspace: api));
    await tester.tap(find.textContaining('RES-MYSQL').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(api.actions, ['confirm']);
    expect(find.textContaining('Cliente réelle'), findsWidgets);
  });
  testWidgets('gallery uses authenticated response and honest empty state',
      (tester) async {
    await mount(tester, EditGalleryScreen(workspace: Workspace()));
    expect(find.text('Aucune photo réelle enregistrée pour le moment.'),
        findsOneWidget);
    expect(find.text('Ajouter des photos'), findsOneWidget);
  });
  for (final endpoint in [
    'profile',
    'dashboard',
    'subscription',
    'catalog',
    'gallery'
  ]) {
    test('workspace $endpoint uses authenticated Laravel endpoint', () async {
      final api = RestaurantWorkspaceService(
          auth: SubmissionAuth(),
          apiClient: ApiClient(client: MockClient((request) async {
            expect(request.url.path, '/api/v1/restaurant/$endpoint');
            expect(request.headers['Authorization'], 'Bearer test-token');
            expect(request.url.queryParameters.containsKey('restaurant_id'),
                isFalse);
            return http.Response(
                jsonEncode({
                  'data': {'id': 73}
                }),
                200);
          })));
      final result = await switch (endpoint) {
        'profile' => api.fetchProfile(),
        'dashboard' => api.fetchDashboard(),
        'subscription' => api.fetchSubscription(),
        'catalog' => api.fetchCatalog(),
        _ => api.fetchGallery()
      };
      expect(result?['id'], 73);
    });
  }
  test('product update sends normalized product ID and configured options',
      () async {
    final api = RestaurantWorkspaceService(
        auth: SubmissionAuth(),
        apiClient: ApiClient(client: MockClient((request) async {
          expect(request.url.path, '/api/v1/restaurant/products/91');
          final body = jsonDecode(request.body);
          expect(body['base_price'], 4500);
          expect(body['options'][0]['selection_type'], 'multiple');
          expect(body.containsKey('menu_categories'), isFalse);
          return http.Response('{"data":{"id":91,"base_price":4500}}', 200);
        })));
    expect(
        (await api.saveProduct({
          'base_price': 4500,
          'options': [
            {'name': 'Garnitures', 'selection_type': 'multiple'}
          ]
        }, id: 91))['base_price'],
        4500);
  });
  for (final action in ['confirm', 'reject', 'honor', 'no-show']) {
    test('reservation $action invokes existing owner endpoint', () async {
      final api = RestaurantWorkspaceService(
          auth: SubmissionAuth(),
          apiClient: ApiClient(client: MockClient((request) async {
            expect(request.url.path,
                '/api/v1/restaurant/reservations/RES-42/$action');
            if (action == 'reject')
              expect(jsonDecode(request.body)['reason'], 'Complet');
            return http.Response(
                '{"data":{"reservation_number":"RES-42"}}', 200);
          })));
      await api.reservationAction('RES-42', action,
          reason: action == 'reject' ? 'Complet' : null);
    });
  }
  test('gallery upload sends multipart and uses returned persisted resource',
      () async {
    final api = RestaurantWorkspaceService(
        auth: SubmissionAuth(),
        apiClient: ApiClient(client: MockClient((request) async {
          expect(request.url.path, '/api/v1/restaurant/gallery');
          expect(request.headers['content-type'],
              startsWith('multipart/form-data'));
          expect(request.body, contains('gallery[]'));
          return http.Response(
              '{"data":{"gallery":[{"path":"restaurants/73/gallery/hash.jpg"}]}}',
              200);
        })));
    final result = await api.uploadGallery(galleryFiles: [
      http.MultipartFile.fromBytes('gallery[]', [1, 2, 3],
          filename: 'photo.jpg')
    ]);
    expect(result['gallery'][0]['path'], 'restaurants/73/gallery/hash.jpg');
  });
  test('owner orders pagination uses server page and status parameters',
      () async {
    final service = OrderService(
        auth: SubmissionAuth(),
        apiClient: ApiClient(client: MockClient((request) async {
          expect(request.url.path, '/api/v1/restaurant/orders');
          expect(
              request.url.queryParameters, {'page': '2', 'status': 'history'});
          return http.Response('{"data":[]}', 200);
        })));
    expect(await service.fetchRestaurantOrders(status: 'history', page: 2),
        isEmpty);
  });
  test('rejection reason is read from Laravel status history', () {
    final order = OrderModel.fromJson({
      'status_history': [
        {
          'to_status': 'cancelled',
          'metadata': {'reason': 'Rupture'}
        }
      ]
    });
    expect(order.rejectionReason, 'Rupture');
  });
}
