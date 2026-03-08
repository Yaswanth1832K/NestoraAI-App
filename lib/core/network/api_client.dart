import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:house_rental/config/api_config.dart';
import 'package:house_rental/core/errors/exceptions.dart';

/// Centralized API client for all HTTP requests to the FastAPI backend.
class ApiClient {
  final http.Client _client;

  ApiClient(this._client);

  /// GET request helper
  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    return _performRequest(
      () => _client.get(
        _buildUri(endpoint),
        headers: _buildHeaders(headers),
      ),
      'GET',
      endpoint,
    );
  }

  /// POST request helper
  Future<dynamic> post(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    return _performRequest(
      () => _client.post(
        _buildUri(endpoint),
        headers: _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      ),
      'POST',
      endpoint,
      body: body,
    );
  }

  /// PATCH request helper
  Future<dynamic> patch(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    return _performRequest(
      () => _client.patch(
        _buildUri(endpoint),
        headers: _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      ),
      'PATCH',
      endpoint,
      body: body,
    );
  }

  /// PUT request helper
  Future<dynamic> put(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    return _performRequest(
      () => _client.put(
        _buildUri(endpoint),
        headers: _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      ),
      'PUT',
      endpoint,
      body: body,
    );
  }

  /// DELETE request helper
  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    return _performRequest(
      () => _client.delete(
        _buildUri(endpoint),
        headers: _buildHeaders(headers),
      ),
      'DELETE',
      endpoint,
    );
  }

  /// Health check helper
  Future<bool> checkHealth() async {
    try {
      final response = await _client.get(
        _buildUri(ApiConfig.healthEndpoint),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🚨 Health check failed: $e');
      return false;
    }
  }

  /// Build URI from endpoint
  Uri _buildUri(String endpoint) {
    final base = ApiConfig.baseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$base$path');
  }

  /// Build default headers
  Map<String, String> _buildHeaders(Map<String, String>? extraHeaders) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  /// Common request logic including logging, timeout, and exception handling
  Future<dynamic> _performRequest(
    Future<http.Response> Function() requestFn,
    String method,
    String endpoint, {
    dynamic body,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🌐 [API Request] $method ${ApiConfig.baseUrl}$endpoint');
        if (body != null) debugPrint('📦 Body: ${jsonEncode(body)}');
      }

      final response = await requestFn().timeout(
        const Duration(milliseconds: ApiConfig.connectTimeout),
      );

      if (kDebugMode) {
        debugPrint('✅ [API Response] ${response.statusCode} for $endpoint');
        debugPrint('📄 Body: ${response.body}');
      }

      return _handleResponse(response);
    } on TimeoutException {
      debugPrint('⏰ [API Timeout] $method $endpoint');
      throw const NetworkException(message: 'Connection timed out. Please check your internet or server.');
    } on http.ClientException catch (e) {
      debugPrint('📡 [API Network Error] $e');
      throw const NetworkException(message: 'Unable to connect to server. Please check your internet connection.');
    } catch (e) {
      debugPrint('🚨 [API Unexpected Error] $e');
      if (e is AppException) rethrow;
      throw ServerException(message: 'An unexpected error occurred: $e');
    }
  }

  /// Map HTTP status codes to AppExceptions
  dynamic _handleResponse(http.Response response) {
    final body = response.body;
    final dynamic decoded = body.isNotEmpty ? jsonDecode(body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw AuthException(message: 'Unauthorized: ${decoded?['detail'] ?? body}', code: response.statusCode.toString());
    } else {
      throw ServerException(
        message: 'Server Error (${response.statusCode}): ${decoded?['detail'] ?? body}',
        code: response.statusCode.toString(),
      );
    }
  }
}
