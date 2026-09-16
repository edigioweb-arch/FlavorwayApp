import 'api_client.dart';

/// Le serveur ne révèle l'email d'un pseudo qu'après contrôle du mot de passe.
class LoginIdentifierService {
  LoginIdentifierService({ApiClient? api}) : _api = api ?? ApiClient();
  final ApiClient _api;

  Future<String> resolve(String identifier, String password) async {
    final normalized = identifier.trim().toLowerCase();
    if (normalized.contains('@')) return normalized;
    final response = await _api.postJson('/api/v1/auth/username-login', body: {
      'username': normalized,
      'password': password,
    });
    final email = response['email'];
    if (email is! String || !email.contains('@')) {
      throw const FormatException('Réponse de connexion invalide.');
    }
    return email;
  }
}
