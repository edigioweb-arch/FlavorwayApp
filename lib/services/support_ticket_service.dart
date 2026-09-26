import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_client.dart';
import 'courier_session_service.dart';

class SupportTicketService {
  SupportTicketService({this.courier, ApiClient? api, this.tokenProvider})
      : _api = api ?? ApiClient();
  final CourierSessionService? courier;
  final ApiClient _api;
  final Future<String?> Function()? tokenProvider;
  Future<Map<String, dynamic>> request(String suffix,
      {Map<String, dynamic>? body, int page = 1}) async {
    if (courier != null) {
      return courier!.request('support/tickets$suffix',
          body: body, query: {'page': '$page'});
    }
    final token = await (tokenProvider?.call() ??
        FirebaseAuth.instance.currentUser?.getIdToken() ??
        Future.value(null));
    if (token == null) {
      throw const ApiException(
          statusCode: 401,
          message: 'Connectez-vous pour contacter le Support.');
    }
    final headers = {'Authorization': 'Bearer $token'};
    return body == null
        ? _api.getJson('/api/v1/support/tickets$suffix',
            headers: headers, queryParameters: {'page': '$page'})
        : _api.postJson('/api/v1/support/tickets$suffix',
            headers: headers, body: body);
  }

  static String requestKey() {
    final r = Random.secure();
    final b = List.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
