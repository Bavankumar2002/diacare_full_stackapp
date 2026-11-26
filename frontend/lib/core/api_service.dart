// =============================================================================
// DiaCare - Centralized REST API Service with Auto-Discovery & Fallback
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _baseUrl = AppConstants.defaultBaseUrl;
  String? _authToken;

  String get baseUrl => _baseUrl;
  String? get token => _authToken;

  // Known backend endpoints to test automatically
  static const List<String> _candidateUrls = [
    'https://shreetechhub.com/demosite/diacare',
  ];

  /// Initialize service with stored token and base URL
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(AppConstants.keyJwtToken);
    final customUrl = prefs.getString(AppConstants.keyBaseUrl);
    if (customUrl != null &&
        customUrl.trim().isNotEmpty &&
        !customUrl.contains('diacare_api') &&
        !customUrl.contains('192.168.') &&
        !customUrl.contains('localhost') &&
        !customUrl.contains('10.0.2.2')) {
      _baseUrl = customUrl.trim();
    } else {
      _baseUrl = AppConstants.defaultBaseUrl;
      await prefs.setString(AppConstants.keyBaseUrl, _baseUrl);
    }

    // Run quick background auto-discovery to pick the best working IP
    unawaited(_autoDetectWorkingBaseUrl());
  }

  void setToken(String? token) {
    _authToken = token;
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyBaseUrl, _baseUrl);
  }

  /// Automatically ping known candidates and pick the one that responds
  Future<String?> _autoDetectWorkingBaseUrl() async {
    for (final candidate in _candidateUrls) {
      try {
        final uri = Uri.parse('$candidate/index.php');
        final response = await http
            .get(uri)
            .timeout(const Duration(milliseconds: 2500));
        if (response.statusCode == 200) {
          _baseUrl = candidate;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.keyBaseUrl, _baseUrl);
          debugPrint('Auto-detected responsive API base URL: $_baseUrl');
          return candidate;
        }
      } catch (_) {}
    }
    return null;
  }

  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Uri _buildUri(
    String baseUrl,
    String endpoint, [
    Map<String, dynamic>? queryParams,
  ]) {
    var cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    var cleanEndpoint = endpoint.replaceAll(RegExp(r'^/+'), '');
    var fullUrl = '$cleanBase/$cleanEndpoint';

    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map((k, v) => MapEntry(k, v.toString()));
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  /// Send GET request with automatic fallback
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = _buildUri(_baseUrl, endpoint, queryParams);
      final response = await http
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 8));

      return _handleResponse(response);
    } on SocketException catch (_) {
      return _retryWithFallback('GET', endpoint, queryParams: queryParams);
    } on TimeoutException catch (_) {
      return _retryWithFallback('GET', endpoint, queryParams: queryParams);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  /// Send POST request with automatic fallback
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = _buildUri(_baseUrl, endpoint);
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 8));

      return _handleResponse(response);
    } on SocketException catch (_) {
      return _retryWithFallback('POST', endpoint, body: body);
    } on TimeoutException catch (_) {
      return _retryWithFallback('POST', endpoint, body: body);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  /// Send DELETE request with automatic fallback
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = _buildUri(_baseUrl, endpoint);
      final response = await http
          .delete(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 8));

      return _handleResponse(response);
    } on SocketException catch (_) {
      return _retryWithFallback('DELETE', endpoint, body: body);
    } on TimeoutException catch (_) {
      return _retryWithFallback('DELETE', endpoint, body: body);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  /// Attempt fallback across candidates if the primary URL fails
  Future<ApiResponse> _retryWithFallback(
    String method,
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    final workingUrl = await _autoDetectWorkingBaseUrl();
    if (workingUrl != null && workingUrl != _baseUrl) {
      _baseUrl = workingUrl;
      try {
        final uri = _buildUri(workingUrl, endpoint, queryParams);
        http.Response response;
        if (method == 'POST') {
          response = await http
              .post(
                uri,
                headers: _buildHeaders(),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 8));
        } else if (method == 'DELETE') {
          response = await http
              .delete(
                uri,
                headers: _buildHeaders(),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 8));
        } else {
          response = await http
              .get(uri, headers: _buildHeaders())
              .timeout(const Duration(seconds: 8));
        }
        return _handleResponse(response);
      } catch (_) {}
    }

    return ApiResponse(
      success: false,
      message:
          'Cannot connect to backend server at $_baseUrl. Ensure XAMPP Apache is running and your phone and PC are on the same Wi-Fi network.',
      statusCode: 0,
    );
  }

  ApiResponse _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      final bool isSuccess =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded['status'] == 'success';
      final String message = decoded['message'] ?? 'Response received';
      final data = decoded['data'];

      return ApiResponse(
        success: isSuccess,
        message: message,
        data: data,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message:
            'Server response parsing failed (${response.statusCode}): ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }
}
