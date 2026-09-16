import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../services/api_client.dart';

class RestaurantWorkspaceService {
  RestaurantWorkspaceService({
    ApiClient? apiClient,
    FirebaseAuth? auth,
  })  : _apiClient = apiClient ?? ApiClient(),
        _auth = auth ?? FirebaseAuth.instance;

  static final RestaurantWorkspaceService instance =
      RestaurantWorkspaceService();

  final ApiClient _apiClient;
  final FirebaseAuth _auth;

  Future<Map<String, String>> _headers() async {
    final token = await _auth.currentUser?.getIdToken();
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, dynamic>?> fetchSubscription() async {
    final result = await _apiClient.getJson('/api/v1/restaurant/subscription',
        headers: await _headers());
    return result['data'] is Map
        ? Map<String, dynamic>.from(result['data'])
        : null;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final result = await _apiClient.postJson('/api/v1/restaurant/profile',
        body: data, headers: await _headers());
    return Map<String, dynamic>.from(result['data']);
  }

  Future<Map<String, dynamic>> fetchCatalog() async {
    final result = await _apiClient.getJson('/api/v1/restaurant/catalog',
        headers: await _headers());
    return Map<String, dynamic>.from(result['data']);
  }

  Future<Map<String, dynamic>> saveProduct(Map<String, dynamic> data,
      {int? id, http.MultipartFile? image}) async {
    final path = id == null
        ? '/api/v1/restaurant/products'
        : '/api/v1/restaurant/products/$id';
    final result = image == null
        ? await _apiClient.postJson(path, body: data, headers: await _headers())
        : await _apiClient.postMultipart(path,
            fields: _formFields(data),
            files: [image],
            headers: await _headers());
    return Map<String, dynamic>.from(result['data']);
  }

  Map<String, String> _formFields(Map<String, dynamic> data) {
    final fields = <String, String>{};
    void add(String key, dynamic value) {
      if (value is Map) {
        value.forEach((k, v) => add('$key[$k]', v));
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          add('$key[$i]', value[i]);
        }
      } else {
        fields[key] =
            value is bool ? (value ? '1' : '0') : value?.toString() ?? '';
      }
    }

    data.forEach(add);
    return fields;
  }

  Future<Map<String, dynamic>> fetchReservations({int page = 1}) async =>
      _apiClient.getJson('/api/v1/restaurant/reservations',
          queryParameters: {'page': '$page'}, headers: await _headers());

  Future<Map<String, dynamic>> reservationAction(
      String reference, String action,
      {String? reason}) async {
    final result = await _apiClient.postJson(
        '/api/v1/restaurant/reservations/$reference/$action',
        body: {if (reason != null) 'reason': reason},
        headers: await _headers());
    return Map<String, dynamic>.from(result['data']);
  }

  Future<Map<String, dynamic>> fetchDashboard() async {
    final payload = await _apiClient.getJson(
      '/api/v1/restaurant/dashboard',
      headers: await _headers(),
    );

    return Map<String, dynamic>.from((payload['data'] as Map?) ?? const {});
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final payload = await _apiClient.getJson(
      '/api/v1/restaurant/profile',
      headers: await _headers(),
    );

    return Map<String, dynamic>.from((payload['data'] as Map?) ?? const {});
  }

  Future<Map<String, dynamic>> fetchGallery() async {
    final payload = await _apiClient.getJson(
      '/api/v1/restaurant/gallery',
      headers: await _headers(),
    );

    return Map<String, dynamic>.from((payload['data'] as Map?) ?? const {});
  }

  Future<Map<String, dynamic>> uploadGallery({
    List<http.MultipartFile> galleryFiles = const [],
    http.MultipartFile? logoFile,
    http.MultipartFile? coverFile,
  }) async {
    final files = <http.MultipartFile>[
      if (logoFile != null) logoFile,
      if (coverFile != null) coverFile,
      ...galleryFiles,
    ];

    final payload = await _apiClient.postMultipart(
      '/api/v1/restaurant/gallery',
      headers: await _headers(),
      files: files,
    );

    return Map<String, dynamic>.from((payload['data'] as Map?) ?? const {});
  }

  Future<Map<String, dynamic>> deleteGalleryImage(String path) async {
    final payload = await _apiClient.postJson(
      '/api/v1/restaurant/gallery/delete',
      headers: await _headers(),
      body: {'path': path},
    );

    return Map<String, dynamic>.from((payload['data'] as Map?) ?? const {});
  }
}
