import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:alnisa_store/config/env_config.dart';
import 'package:alnisa_store/constants/app_constants.dart';
import 'package:alnisa_store/core/errors/api_exception.dart';
import 'package:alnisa_store/service/cart_session_service.dart';
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
/// - `useWpApi` targets the public core WordPress REST API
///   (`wp-json/wp/v2`, e.g. custom post types like banners) instead of
///   REST v3, and never sends consumer keys. Mutually exclusive with
///   `useStoreApi`.
class ApiClient {
  ApiClient._();

  static Uri _buildUrl(
    String endpoint, {
    required bool useStoreApi,
    required bool useConsumerAuth,
    required bool requiresAuth,
    bool useWpApi = false,
    Map<String, String>? queryParams,
  }) {
    final apiSegment = useWpApi
        ? AppConstants.wpApiVersion
        : useStoreApi
        ? AppConstants.storeApiVersion
        : AppConstants.apiVersion;
    final fullPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('${AppConstants.baseUrl}/$apiSegment$fullPath');

    final params = <String, String>{...uri.queryParameters, ...?queryParams};
    if (useConsumerAuth && !requiresAuth && !useStoreApi && !useWpApi) {
      params['consumer_key'] = EnvConfig.wooConsumerKey;
      params['consumer_secret'] = EnvConfig.wooConsumerSecret;
    }

    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  /// Converts arbitrary query param values (int, bool, etc.) to the string
  /// form expected by WooCommerce filters (page, per_page, category,
  /// orderby, order, featured, on_sale, search, ...), dropping null values.
  static Map<String, String>? _stringifyQueryParams(
    Map<String, dynamic>? queryParams,
  ) {
    if (queryParams == null) return null;
    final result = <String, String>{};
    for (final entry in queryParams.entries) {
      if (entry.value == null) continue;
      result[entry.key] = entry.value.toString();
    }
    return result;
  }

  static Future<Map<String, String>> _buildHeaders({
    required bool requiresAuth,
    bool includeContentType = false,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = <String, String>{...?additionalHeaders};

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

  static String? _readHeaderIgnoreCase(
    Map<String, String> headers,
    String headerName,
  ) {
    final expected = headerName.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == expected && entry.value.trim().isNotEmpty) {
        return entry.value;
      }
    }
    return null;
  }

  static Future<void> _captureStoreSessionHeaders(http.Response response) async {
    final cartToken = _readHeaderIgnoreCase(response.headers, 'cart-token');
    final nonce =
        _readHeaderIgnoreCase(response.headers, 'x-wc-store-api-nonce') ??
        _readHeaderIgnoreCase(response.headers, 'nonce');

    if (cartToken != null && cartToken.isNotEmpty) {
      await CartSessionService.instance.setCartToken(cartToken);
    }
    if (nonce != null && nonce.isNotEmpty) {
      await CartSessionService.instance.setNonce(nonce);
    }
  }

  static Future<Map<String, String>> _buildStoreSessionHeaders({
    required bool includeNonce,
  }) async {
    final headers = <String, String>{};
    final cartToken = await CartSessionService.instance.getCartToken();
    if (cartToken != null && cartToken.isNotEmpty) {
      headers['Cart-Token'] = cartToken;
    }

    if (includeNonce) {
      final nonce = await CartSessionService.instance.getNonce();
      if (nonce != null && nonce.isNotEmpty) {
        headers['X-WC-Store-API-Nonce'] = nonce;
        headers['Nonce'] = nonce;
      }
    }

    return headers;
  }

  // GET a single resource, returning a decoded JSON object.
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool useConsumerAuth = true,
    bool requiresAuth = false,
    bool useStoreApi = false,
    bool useWpApi = false,
    Map<String, dynamic>? queryParams,
    List<int> successCodes = const [200, 201],
    String? defaultErrorMessage,
    Duration? timeout,
    FutureOr<void> Function(http.Response response)? onResponse,
    Map<String, String>? additionalHeaders,
  }) async {
    final uri = _buildUrl(
      endpoint,
      useStoreApi: useStoreApi,
      useWpApi: useWpApi,
      useConsumerAuth: useConsumerAuth,
      requiresAuth: requiresAuth,
      queryParams: _stringifyQueryParams(queryParams),
    );
    final headers = await _buildHeaders(
      requiresAuth: requiresAuth,
      additionalHeaders: additionalHeaders,
    );

    late final http.Response response;
    try {
      response = await http
          .get(uri, headers: headers)
          .timeout(
            timeout ?? Duration(milliseconds: AppConstants.timeoutDuration),
            onTimeout: () =>
                throw const ApiException(userMessage: 'Request timed out'),
          );
    } on SocketException catch (e, st) {
      developer.log(
        'Network unreachable calling $uri',
        name: 'ApiClient',
        error: e,
        stackTrace: st,
      );
      throw ApiException(
        userMessage:
            'No internet connection. Please check your network and try again.',
        cause: e,
      );
    } on HandshakeException catch (e, st) {
      developer.log(
        'TLS handshake failed calling $uri',
        name: 'ApiClient',
        error: e,
        stackTrace: st,
      );
      throw ApiException(
        userMessage: 'Secure connection failed. Please try again.',
        cause: e,
      );
    }

    if (onResponse != null) {
      await onResponse(response);
    }

    developer.log(
      'Response ${response.statusCode} for $uri: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
      name: 'ApiClient',
    );

    final decoded = _handleResponse(
      response,
      successCodes: successCodes,
      defaultErrorMessage: defaultErrorMessage ?? 'Request failed',
      requiresAuth: requiresAuth,
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
    bool useWpApi = false,
    Map<String, dynamic>? queryParams,
    List<int> successCodes = const [200, 201],
    String? defaultErrorMessage,
    Duration? timeout,
    FutureOr<void> Function(http.Response response)? onResponse,
    Map<String, String>? additionalHeaders,
  }) async {
    final uri = _buildUrl(
      endpoint,
      useStoreApi: useStoreApi,
      useWpApi: useWpApi,
      useConsumerAuth: useConsumerAuth,
      requiresAuth: requiresAuth,
      queryParams: _stringifyQueryParams(queryParams),
    );
    final headers = await _buildHeaders(
      requiresAuth: requiresAuth,
      additionalHeaders: additionalHeaders,
    );

    late final http.Response response;
    try {
      response = await http
          .get(uri, headers: headers)
          .timeout(
            timeout ?? Duration(milliseconds: AppConstants.timeoutDuration),
            onTimeout: () =>
                throw const ApiException(userMessage: 'Request timed out'),
          );
    } on SocketException catch (e, st) {
      developer.log(
        'Network unreachable calling $uri',
        name: 'ApiClient',
        error: e,
        stackTrace: st,
      );
      throw ApiException(
        userMessage:
            'No internet connection. Please check your network and try again.',
        cause: e,
      );
    } on HandshakeException catch (e, st) {
      developer.log(
        'TLS handshake failed calling $uri',
        name: 'ApiClient',
        error: e,
        stackTrace: st,
      );
      throw ApiException(
        userMessage: 'Secure connection failed. Please try again.',
        cause: e,
      );
    }

    if (onResponse != null) {
      await onResponse(response);
    }

    developer.log(
      'Response ${response.statusCode} for $uri: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
      name: 'ApiClient',
    );

    final effectiveErrorMessage = defaultErrorMessage ?? 'Request failed';
    final decoded = _handleResponse(
      response,
      successCodes: successCodes,
      defaultErrorMessage: effectiveErrorMessage,
      requiresAuth: requiresAuth,
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
    FutureOr<void> Function(http.Response response)? onResponse,
    Map<String, String>? additionalHeaders,
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
      additionalHeaders: additionalHeaders,
    );

    late final http.Response response;
    try {
      response = await http
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
    } on SocketException catch (e, st) {
      developer.log(
        'Network unreachable calling $uri',
        name: 'ApiClient',
        error: e,
        stackTrace: st,
      );
      throw ApiException(
        userMessage:
            'No internet connection. Please check your network and try again.',
        cause: e,
      );
    } on HandshakeException catch (e, st) {
      developer.log(
        'TLS handshake failed calling $uri',
        name: 'ApiClient',
        error: e,
        stackTrace: st,
      );
      throw ApiException(
        userMessage: 'Secure connection failed. Please try again.',
        cause: e,
      );
    }

    if (onResponse != null) {
      await onResponse(response);
    }

    developer.log(
      'Response ${response.statusCode} for $uri: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
      name: 'ApiClient',
    );

    final decoded = _handleResponse(
      response,
      successCodes: successCodes,
      defaultErrorMessage: defaultErrorMessage ?? 'Request failed',
      requiresAuth: requiresAuth,
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
    FutureOr<void> Function(http.Response response)? onResponse,
    Map<String, String>? additionalHeaders,
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
      additionalHeaders: additionalHeaders,
    );

    late final http.Response response;
    try {
      response = await http
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
    } on SocketException catch (e, st) {
      developer.log(
        'Network unreachable calling $uri',
        name: 'ApiClient',
        error: e,
        stackTrace: st,
      );
      throw ApiException(
        userMessage:
            'No internet connection. Please check your network and try again.',
        cause: e,
      );
    } on HandshakeException catch (e, st) {
      developer.log(
        'TLS handshake failed calling $uri',
        name: 'ApiClient',
        error: e,
        stackTrace: st,
      );
      throw ApiException(
        userMessage: 'Secure connection failed. Please try again.',
        cause: e,
      );
    }

    if (onResponse != null) {
      await onResponse(response);
    }

    developer.log(
      'Response ${response.statusCode} for $uri: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
      name: 'ApiClient',
    );

    final decoded = _handleResponse(
      response,
      successCodes: successCodes,
      defaultErrorMessage: defaultErrorMessage ?? 'Request failed',
      requiresAuth: requiresAuth,
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
    FutureOr<void> Function(http.Response response)? onResponse,
    Map<String, String>? additionalHeaders,
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
      additionalHeaders: additionalHeaders,
    );

    late final http.Response response;
    try {
      response = await http
          .delete(uri, headers: headers)
          .timeout(
            timeout ?? Duration(milliseconds: AppConstants.timeoutDuration),
            onTimeout: () =>
                throw const ApiException(userMessage: 'Request timed out'),
          );
    } on SocketException catch (e, st) {
      developer.log(
        'Network unreachable calling $uri',
        name: 'ApiClient',
        error: e,
        stackTrace: st,
      );
      throw ApiException(
        userMessage:
            'No internet connection. Please check your network and try again.',
        cause: e,
      );
    } on HandshakeException catch (e, st) {
      developer.log(
        'TLS handshake failed calling $uri',
        name: 'ApiClient',
        error: e,
        stackTrace: st,
      );
      throw ApiException(
        userMessage: 'Secure connection failed. Please try again.',
        cause: e,
      );
    }

    if (onResponse != null) {
      await onResponse(response);
    }

    developer.log(
      'Response ${response.statusCode} for $uri: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
      name: 'ApiClient',
    );

    _handleResponse(
      response,
      successCodes: successCodes,
      defaultErrorMessage: defaultErrorMessage ?? 'Delete request failed',
      allowEmptyBody: true,
      requiresAuth: requiresAuth,
    );
  }

  static Future<void> _ensureStoreSession() async {
    final nonce = await CartSessionService.instance.getNonce();
    if (nonce != null && nonce.isNotEmpty) return;

    final storeHeaders = await _buildStoreSessionHeaders(includeNonce: false);
    await get(
      '/cart',
      useStoreApi: true,
      useConsumerAuth: false,
      additionalHeaders: storeHeaders,
      onResponse: _captureStoreSessionHeaders,
      defaultErrorMessage: 'Unable to start cart session',
    );
  }

  /// Retries a Store API call once after clearing the persisted cart
  /// session if the first attempt is rejected with 401/403. A stale or
  /// invalid Cart-Token/Nonce (left over from an old install, or simply
  /// past its lifetime) should self-heal into a fresh guest cart session,
  /// not surface a "please sign in" error for a request that never
  /// required auth in the first place.
  static Future<T> _withStoreSessionRetry<T>(
    Future<T> Function() attempt,
  ) async {
    try {
      return await attempt();
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await CartSessionService.instance.clear();
        return attempt();
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getStoreApi(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    List<int> successCodes = const [200, 201],
    String? defaultErrorMessage,
    Duration? timeout,
  }) {
    return _withStoreSessionRetry(() async {
      final storeHeaders = await _buildStoreSessionHeaders(includeNonce: false);
      return get(
        endpoint,
        useStoreApi: true,
        useConsumerAuth: false,
        queryParams: queryParams,
        successCodes: successCodes,
        defaultErrorMessage: defaultErrorMessage,
        timeout: timeout,
        additionalHeaders: storeHeaders,
        onResponse: _captureStoreSessionHeaders,
      );
    });
  }

  static Future<Map<String, dynamic>> postStoreApi(
    String endpoint, {
    Map<String, dynamic>? body,
    List<int> successCodes = const [200, 201],
    String? defaultErrorMessage,
    Duration? timeout,
  }) {
    return _withStoreSessionRetry(() async {
      await _ensureStoreSession();
      final storeHeaders = await _buildStoreSessionHeaders(includeNonce: true);
      return post(
        endpoint,
        body: body,
        useStoreApi: true,
        useConsumerAuth: false,
        successCodes: successCodes,
        defaultErrorMessage: defaultErrorMessage,
        timeout: timeout,
        additionalHeaders: storeHeaders,
        onResponse: _captureStoreSessionHeaders,
      );
    });
  }

  static Future<Map<String, dynamic>> putStoreApi(
    String endpoint, {
    Map<String, dynamic>? body,
    List<int> successCodes = const [200, 201],
    String? defaultErrorMessage,
    Duration? timeout,
  }) {
    return _withStoreSessionRetry(() async {
      await _ensureStoreSession();
      final storeHeaders = await _buildStoreSessionHeaders(includeNonce: true);
      return put(
        endpoint,
        body: body,
        useStoreApi: true,
        useConsumerAuth: false,
        successCodes: successCodes,
        defaultErrorMessage: defaultErrorMessage,
        timeout: timeout,
        additionalHeaders: storeHeaders,
        onResponse: _captureStoreSessionHeaders,
      );
    });
  }

  static Future<void> deleteStoreApi(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    List<int> successCodes = const [200, 204],
    String? defaultErrorMessage,
    Duration? timeout,
  }) {
    return _withStoreSessionRetry(() async {
      await _ensureStoreSession();
      final storeHeaders = await _buildStoreSessionHeaders(includeNonce: true);
      await delete(
        endpoint,
        useStoreApi: true,
        useConsumerAuth: false,
        queryParams: _stringifyQueryParams(queryParams),
        successCodes: successCodes,
        defaultErrorMessage: defaultErrorMessage,
        timeout: timeout,
        additionalHeaders: storeHeaders,
        onResponse: _captureStoreSessionHeaders,
      );
    });
  }

  // Checks status code, decodes JSON, and throws ApiException on failure.
  static dynamic _handleResponse(
    http.Response response, {
    required List<int> successCodes,
    required String defaultErrorMessage,
    bool allowEmptyBody = false,
    bool requiresAuth = false,
  }) {
    if (response.statusCode == 401) {
      // Only a request that actually required a signed-in user (Firebase
      // Bearer token) being rejected means the session expired. A 401 on a
      // guest/public request (e.g. a Store API cart call with a stale
      // Cart-Token/Nonce, retried by _withStoreSessionRetry above) is a
      // different problem and must never tell the user to sign in when
      // they were never required to in the first place.
      throw ApiException(
        statusCode: 401,
        userMessage: requiresAuth
            ? 'Your session expired. Please sign in again.'
            : defaultErrorMessage,
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
