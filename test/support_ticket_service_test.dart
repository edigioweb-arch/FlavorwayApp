import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flavorapps/services/api_client.dart';
import 'package:flavorapps/services/support_ticket_service.dart';

void main() {
  test('Client credentials, pagination and ticket payload use Laravel',
      () async {
    final calls = <http.Request>[];
    final service = SupportTicketService(
        tokenProvider: () async => 'client-token',
        api: ApiClient(client: MockClient((r) async {
          calls.add(r);
          return http.Response(
              jsonEncode({'data': [], 'next_page': null}), 200);
        })));
    await service.request('', page: 2);
    expect(calls.single.headers['Authorization'], 'Bearer client-token');
    expect(calls.single.url.path, '/api/v1/support/tickets');
    expect(calls.single.url.queryParameters['page'], '2');
    final key = SupportTicketService.requestKey();
    await service.request('', body: {
      'subject': 'Localisation',
      'body': 'Repère',
      'order_reference': 'FW-TEST',
      'request_key': key
    });
    expect(jsonDecode(calls.last.body)['order_reference'], 'FW-TEST');
    expect(
        key,
        matches(RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
  });
  test('No client credentials refuses before any network request', () async {
    final service = SupportTicketService(
        tokenProvider: () async => null,
        api: ApiClient(client: MockClient((r) async {
          fail('No network request expected');
        })));
    await expectLater(service.request(''), throwsA(isA<ApiException>()));
  });
}
