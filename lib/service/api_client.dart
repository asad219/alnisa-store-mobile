import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:alnisa_store/config/env_config.dart';
import 'package:alnisa_store/constants/app_constants.dart';
import 'package:alnisa_store/core/errors/api_exception.dart';
import 'package:alnisa_store/service/firebase_auth_service.dart';
import 'package:http/http.dart' as http;

/// Static HTTP client for the WooCommerce REST API v3 and Store API.
///
/// - `useConsumerAuth` (default `true`) appends the read-only
///   `consumer_key`/`consumer_secret` query params sourced from
///   [EnvConfig], as required by WooCommerce REST v3 for public catalog
///   endpoints (products, categories, etc.).
/// - `requiresAuth` attaches the current Firebase ID token as an
///   `Authorization: Bearer` header for endpoints tied to a logged-in
///   customer (orders, account details, ...), and disables consumer-key
///   auth for that request.
/// - `useStoreApi` targets the session-based WooCommerce Store API
///   (cart endpoints) instead of REST v3, and never sends consumer keys.
class ApiClient {
  ApiClient._();

  static Uri _buildUrl(
    String endpoint, {
    required bool useStoreApi,
    required bool useConsumerAuth,
    required bool requiresAuth,
    Map<String, String>? queryParams,
  }) {
    final apiSegment =
        useStoreApi ? AppConstants.storeApiVersion : AppConstants.apiVersion;
    final fullPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('${AppConstants.baseUrl}/$apiSegment$fullPath');

    final params = <String, String>{...uri.queryParameters, ...?queryParams};
    if (useConsumerAuth && !requiresAuth && !useStoreApi) {
      params['consumer_key'] = EnvConfig.wooConsumerKey;
      params['consumer_secret'] = EnvConfig.wooConsumerSecret;
    }

    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  static Future<Map<String, String>> _buildHeaders({
    required bool requiresAuth,
    bool includeContentType = false,
  }) async {
    final headers = <String, String>{};

    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (requiresAuth) {
      final token = await FirebaseAuthService.instance.getIdToken();
      if (token == null || token.isEmpty) {
        throw const ApiException(
          statusCode: 401,
          userMessage: 'Authentication required. Please sign in again.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // GET a single resource, returning a decoded JSON object.
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool useConsumerAuth = true,
    bool requiresAuth = false,
    bool useStoreApi = false,
    Map<String, String>? queryParams,
    List<int> successCodes = const [200, 201],
    String? defaultErrorMessage,
    Duration? timeout,
  }) async {
    final uri = _buildUrl(
      endpoint,
      useStoreApi: useStoreApi,
      useConsumerAuth: useConsumerAuth,
      requiresAuth: requiresAuth,
      queryParams: queryParams,
    );
    final headers = await _buildHeaders(requiresAuth: requiresAuth);

    final response = await http
        .get(uri, headers: headers)
        .timeout(
          timeout ?? Duration(milliseconds: AppConstants.timeoutDuration),
          onTimeout: () =>
              throw const ApiException(userMessage: 'Request timed out'),
        );

    final decoded = _handleResponse(
      response,
      successCodes: successCodes,
      defaultErrorMessage: defaultErrorMessage ?? 'Request failed',
    );

    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  // GET a collection, returning the decoded JSON list. WooCommerce
  // collection endpoints (/products, /products/categories, /orders) return
  // a bare array rather than a { data: [...] } wrapper.
  static Future<List<dynamic>> getList(
    String endpoint, {
    bool useConsumerAuth = true,
    bool requiresAuth = false,
    bool useStoreApi = false,
    Map<String, String>? queryParams,
    List<int> successCodes = const [200, 201],
    String? defaultErrorMessage,
    Duration? timeout,
  }) async {
    final uri = _buildUrl(
      endpoint,
      useStoreApi: useStoreApi,
      useConsumerAuth: useConsumerAuth,
      requiresAuth: requiresAuth,
      queryParams: queryParams,
    );
    final headers = await _buildHeaders(requiresAuth: requiresAuth);

    final response = await http
        .get(uri, headers: headers)
        .timeout(
          timeout ?? Duration(milliseconds: AppConstants.timeoutDuration),
          onTimeout: () =>
              throw const ApiException(userMessage: 'Request timed out'),
        );

    final effectiveErrorMessage = defaultErrorMessage ?? 'Request failed';
    final decoded = _handleResponse(
      response,
      successCodes: successCodes,
      defaultErrorMessage: effectiveErrorMessage,
    );

    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      return decoded['data'] as List;
    }

    throw ApiException(
      statusCode: response.statusCode,
      userMessage: effectiveErrorMessage,
    );
  }

  // POST request with optional body.
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool useConsumerAuth = true,
    bool requiresAuth = false,
    bool useStoreApi = false,
    Map<String, String>? queryParams,
    List<int> successCodes = const [200, 201],
    String? defaultErrorMessage,
    Duration? timeout,
  }) async {
    final uri = _buildUrl(
      endpoint,
      useStoreApi: useStoreApi,
      useConsumerAuth: useConsumerAuth,
      requiresAuth: requiresAuth,
      queryParams: queryParams,
    );
    final headers = await _buildHeaders(
      requiresAuth: requiresAuth,
      includeContentType: true,
    );

    final response = await http
        .post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(
          timeout ?? Duration(milliseconds: AppConstants.timeoutDuration),
          onTimeout: () =>
              throw const ApiException(userMessage: 'Request timed out'),
        );

    final decoded = _handleResponse(
      response,
      successCodes: successCodes,
      defaultErrorMessage: defaultErrorMessage ?? 'Request failed',
    );

    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  // PUT request with optional body.
  static Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool useConsumerAuth = true,
    bool requiresAuth = false,
    bool useStoreApi = false,
    Map<String, String>? queryParams,
    List<int> successCodes = const [200, 201],
    String? defaultErrorMessage,
    Duration? timeout,
  }) async {
    final uri = _buildUrl(
      endpoint,
      useStoreApi: useStoreApi,
      useConsumerAuth: useConsumerAuth,
      requiresAuth: requiresAuth,
      queryParams: queryParams,
    );
    final headers = await _buildHeaders(
      requiresAuth: requiresAuth,
      includeContentType: true,
    );

    final response = await http
        .put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(
          timeout ?? Duration(milliseconds: AppConstants.timeoutDuration),
          onTimeout: () =>
              throw const ApiException(userMessage: 'Request timed out'),
        );

    final decoded = _handleResponse(
      response,
      successCodes: successCodes,
      defaultErrorMessage: defaultErrorMessage ?? 'Request failed',
    );

    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  // DELETE request.
  static Future<void> delete(
    String endpoint, {
    bool useConsumerAuth = true,
    bool requiresAuth = false,
    bool useStoreApi = false,
    Map<String, String>? queryParams,
    List<int> successCodes = const [200, 204],
    String? defaultErrorMessage,
    Duration? timeout,
  }) async {
    final uri = _buildUrl(
      endpoint,
      useStoreApi: useStoreApi,
      useConsumerAuth: useConsumerAuth,
      requiresAuth: requiresAuth,
      queryParams: queryParams,
    );
    final headers = await _buildHeaders(
      requiresAuth: requiresAuth,
      includeContentType: true,
    );

    final response = await http
        .delete(uri, headers: headers)
        .timeout(
          timeout ?? Duration(milliseconds: AppConstants.timeoutDuration),
          onTimeout: () =>
              throw const ApiException(userMessage: 'Request timed out'),
        );

    _handleResponse(
      response,
      successCodes: successCodes,
      defaultErrorMessage: defaultErrorMessage ?? 'Delete request failed',
      allowEmptyBody: true,
    );
  }

  // Checks status code, decodes JSON, and throws ApiException on failure.
  static dynamic _handleResponse(
    http.Response response, {
    required List<int> successCodes,
    required String defaultErrorMessage,
    bool allowEmptyBody = false,
  }) {
    if (response.statusCode == 401) {
      throw const ApiException(
        statusCode: 401,
        userMessage: 'Your session expired. Please sign in again.',
      );
    }

    if (!successCodes.contains(response.statusCode)) {
      throw ApiException.fromResponse(response, defaultErrorMessage);
    }

    if (response.body.isEmpty) {
      return allowEmptyBody ? null : <String, dynamic>{};
    }

    try {
      return jsonDecode(response.body);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to decode response body as JSON',
        name: 'ApiClient',
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException(
        statusCode: response.statusCode,
        userMessage: defaultErrorMessage,
        cause: e,
      );
    }
  }
}
