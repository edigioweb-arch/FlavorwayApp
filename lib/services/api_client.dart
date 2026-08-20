import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _configuredBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _sanitizeBaseUrl(_configuredBaseUrl);
    }

    if (kDebugMode) {
      return 'http://127.0.0.1:8002';
    }

    throw StateError('API_BASE_URL is required for non-debug builds.');
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );

    final response = await _send(
      () => _client.get(
        uri,
        headers: _mergeHeaders(headers),
      ),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    final response = await _send(
      () => _client.post(
        uri,
        headers: _mergeHeaders(headers),
        body: jsonEncode(body ?? const {}),
      ),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_multipartHeaders(headers))
      ..fields.addAll(fields ?? const {})
      ..files.addAll(files ?? const []);

    final streamedResponse = await _sendStreamed(() => request.send());
    final response = await http.Response.fromStream(streamedResponse);

    return _decodeResponse(response);
  }

  static const Map<String, String> _defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Map<String, String> _mergeHeaders(Map<String, String>? headers) {
    if (headers == null || headers.isEmpty) {
      return _defaultHeaders;
    }

    return <String, String>{
      ..._defaultHeaders,
      ...headers,
    };
  }

  Map<String, String> _multipartHeaders(Map<String, String>? headers) {
    final merged = <String, String>{
      'Accept': 'application/json',
      ...?headers,
    };

    merged.remove('Content-Type');

    return merged;
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message: 'Le serveur met trop de temps à répondre. Réessayez.',
      );
    } on SocketException {
      throw const ApiException(
        statusCode: 503,
        message: 'Connexion réseau indisponible. Vérifiez votre internet.',
      );
    } on http.ClientException {
      throw const ApiException(
        statusCode: 503,
        message: 'Impossible de contacter le serveur FlavorWay.',
      );
    }
  }

  Future<http.StreamedResponse> _sendStreamed(
    Future<http.StreamedResponse> Function() request,
  ) async {
    try {
      return await request().timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message: 'Le serveur met trop de temps à répondre. Réessayez.',
      );
    } on SocketException {
      throw const ApiException(
        statusCode: 503,
        message: 'Connexion réseau indisponible. Vérifiez votre internet.',
      );
    } on http.ClientException {
      throw const ApiException(
        statusCode: 503,
        message: 'Impossible de contacter le serveur FlavorWay.',
      );
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final dynamic decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        statusCode: response.statusCode >= 400 ? response.statusCode : 500,
        message: 'Réponse serveur invalide. Réessayez plus tard.',
      );
    }

    if (response.statusCode >= 400) {
      String message = 'API request failed with status ${response.statusCode}.';

      if (decoded is Map<String, dynamic>) {
        final directMessage = decoded['message']?.toString().trim();
        if (directMessage != null && directMessage.isNotEmpty) {
          message = directMessage;
        } else if (decoded['errors'] is Map) {
          final errors = Map<String, dynamic>.from(decoded['errors'] as Map);
          final firstEntry = errors.entries.firstWhere(
            (entry) => entry.value is List && (entry.value as List).isNotEmpty,
            orElse: () => const MapEntry('', []),
          );

          if (firstEntry.value is List && (firstEntry.value as List).isNotEmpty) {
            message = ((firstEntry.value as List).first ?? message).toString();
          }
        }
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: message,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected API payload.');
    }

    return decoded;
  }

  String _sanitizeBaseUrl(String rawUrl) {
    final sanitized = rawUrl.trim().replaceFirst(RegExp(r'/$'), '');

    if (!kDebugMode) {
      final host = Uri.tryParse(sanitized)?.host.toLowerCase();
      if (host == '127.0.0.1' || host == 'localhost') {
        throw StateError(
          'API_BASE_URL ne peut pas pointer vers localhost en build non debug.',
        );
      }
    }

    return sanitized;
  }
}

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
