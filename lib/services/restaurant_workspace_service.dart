import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../services/api_client.dart';

class RestaurantWorkspaceService {
  RestaurantWorkspaceService({
    ApiClient? apiClient,
    FirebaseAuth? auth,
  })  : _apiClient = apiClient ?? ApiClient(),
        _auth = auth ?? FirebaseAuth.instance;

  static final RestaurantWorkspaceService instance = RestaurantWorkspaceService();

  final ApiClient _apiClient;
  final FirebaseAuth _auth;

  Future<Map<String, String>> _headers() async {
    final token = await _auth.currentUser?.getIdToken();
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
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
