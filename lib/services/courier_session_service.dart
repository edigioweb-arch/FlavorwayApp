import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

abstract class CourierTokenStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SecureCourierTokenStore implements CourierTokenStore {
  static const _storage = FlutterSecureStorage();
  static const _key = 'flavorway.courier.api_token';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Dedicated Laravel session. Never uses Firebase Auth or client credentials.
class CourierSessionService extends ChangeNotifier {
  CourierSessionService({ApiClient? api, CourierTokenStore? store})
      : _api = api ?? ApiClient(),
        _store = store ?? SecureCourierTokenStore();
  static final instance = CourierSessionService();
  final ApiClient _api;
  final CourierTokenStore _store;
  String? _token;
  int _credentialRevision = 0;
  int get credentialRevision => _credentialRevision;
  Map<String, dynamic>? profile;
  String? restoreError;
  bool get hasSession => _token != null;
  bool get mustChangePassword => profile?['must_change_password'] == true;
  bool get isReady => hasSession && profile != null && !mustChangePassword;

  Future<void> restore() async {
    restoreError = null;
    try {
      _token ??= await _store.read();
      if (_token != null) {
        final response = await request('me');
        profile = Map<String, dynamic>.from(response['data'] as Map);
      }
    } catch (error) {
      if (hasSession) restoreError = userMessage(error);
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final response = await _api.postJson('/api/v1/courier/login',
        body: {'email': email.trim(), 'password': password});
    await _accept(response);
  }

  Future<String> requestPasswordReset(String email) async {
    final response = await _api.postJson('/api/v1/courier/password/forgot',
        body: {'email': email.trim()});
    return response['message'] as String;
  }

  Future<void> changePassword(
      String current, String password, String confirmation) async {
    final response = await request('password', body: {
      'current_password': current,
      'password': password,
      'password_confirmation': confirmation,
    });
    await _accept(response);
  }

  Future<void> _accept(Map<String, dynamic> response) async {
    final data = Map<String, dynamic>.from(response['data'] as Map);
    final next = data['token'] as String;
    await _store.write(next);
    _token = next;
    _credentialRevision++;
    profile = Map<String, dynamic>.from(data['profile'] as Map);
    restoreError = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> request(String path,
      {Map<String, dynamic>? body, Map<String, String>? query}) async {
    final currentToken = _token;
    if (currentToken == null) {
      throw const ApiException(
          statusCode: 401, message: 'Connectez-vous comme livreur.');
    }
    final headers = {'Authorization': 'Bearer $currentToken'};
    try {
      final response = body == null
          ? await _api.getJson('/api/v1/courier/$path',
              headers: headers, queryParameters: query)
          : await _api.postJson('/api/v1/courier/$path',
              headers: headers, body: body);
      if (_token != currentToken) {
        throw const ApiException(
            statusCode: 409, message: 'La session a changé. Actualisez.');
      }
      return response;
    } on ApiException catch (error) {
      if (_token == currentToken && error.statusCode == 401) {
        await _forget();
      } else if (_token == currentToken && error.statusCode == 403) {
        try {
          final me = await _api.getJson('/api/v1/courier/me', headers: headers);
          if (_token == currentToken) {
            profile = Map<String, dynamic>.from(me['data'] as Map);
            notifyListeners();
          }
        } on ApiException catch (check) {
          if (_token == currentToken &&
              (check.statusCode == 401 || check.statusCode == 403)) {
            await _forget();
          }
        }
      }
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    final response = await request('profile');
    profile = Map<String, dynamic>.from(response['data'] as Map);
    notifyListeners();
  }

  Future<void> updatePhone(String phone) async {
    final response = await request('profile', body: {'phone': phone.trim()});
    profile = Map<String, dynamic>.from(response['data'] as Map);
    notifyListeners();
  }

  /// Keep the session when the network fails: logout is not reported as successful
  /// until the server has revoked the token and disabled its push registration.
  Future<void> logout() async {
    if (_token != null) {
      try {
        await request('logout', body: {});
      } on ApiException catch (error) {
        if (error.statusCode != 401) rethrow;
      }
    }
    await _forget();
  }

  Future<void> _forget() async {
    _token = null;
    _credentialRevision++;
    profile = null;
    restoreError = null;
    await _store.clear();
    notifyListeners();
  }

  static String userMessage(Object error) => error is ApiException
      ? error.message
      : 'Impossible de terminer cette opération. Réessayez.';
}
