import 'package:alnisa_store/core/errors/api_exception.dart';

/// Shared helpers for unwrapping and parsing WooCommerce JSON responses.
///
/// WooCommerce REST v3 collection endpoints (`/products`,
/// `/products/categories`, `/orders`, ...) return a bare JSON array, while
/// single-resource endpoints return a bare JSON object. [ApiClient] also
/// falls back to an older `{ "data": ... }` wrapper style for any endpoint
/// that isn't a plain WooCommerce response, so these helpers handle both.
class ApiResponseParser {
  ApiResponseParser._();

  /// Unwraps a decoded JSON body, handling:
  /// - a bare `List` (WooCommerce collection endpoints)
  /// - a `Map` with a top-level `data` key (legacy/custom wrapper style)
  /// - a bare `Map` representing a single resource
  static dynamic unwrapData(dynamic decodedBody) {
    if (decodedBody is List) return decodedBody;
    if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
      return decodedBody['data'];
    }
    return decodedBody;
  }

  /// Parses a decoded body expected to be a list of resources.
  static List<T> parseList<T>(
    dynamic decodedBody,
    T Function(Map<String, dynamic>) fromJson, {
    String unexpectedFormatMessage = 'Unexpected response format',
  }) {
    final decoded = unwrapData(decodedBody);

    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().map(fromJson).toList();
    }

    throw ApiException(userMessage: unexpectedFormatMessage);
  }

  /// Parses a decoded body expected to be a list, but also accepts a single
  /// bare object (some WooCommerce endpoints return one resource directly).
  static List<T> parseListOrSingle<T>(
    dynamic decodedBody,
    T Function(Map<String, dynamic>) fromJson, {
    String unexpectedFormatMessage = 'Unexpected response format',
  }) {
    final decoded = unwrapData(decodedBody);

    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().map(fromJson).toList();
    }

    if (decoded is Map<String, dynamic>) {
      return [fromJson(decoded)];
    }

    throw ApiException(userMessage: unexpectedFormatMessage);
  }

  /// Parses a decoded body expected to be a single resource object.
  static T parseObject<T>(
    dynamic decodedBody,
    T Function(Map<String, dynamic>) fromJson, {
    String unexpectedFormatMessage = 'Unexpected response format',
  }) {
    final decoded = unwrapData(decodedBody);

    if (decoded is Map<String, dynamic>) {
      return fromJson(decoded);
    }

    throw ApiException(userMessage: unexpectedFormatMessage);
  }
}
