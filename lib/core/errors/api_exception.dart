import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Typed HTTP/API error with a safe message for UI display.
class ApiException implements Exception {
  const ApiException({this.statusCode, required this.userMessage, this.cause});

  final int? statusCode;
  final String userMessage;
  final Object? cause;

  static const String defaultUserMessage =
      'Something went wrong. Please try again.';

  factory ApiException.fromResponse(http.Response response, String fallback) {
    final message = _messageFromBody(response.body, fallback);
    return ApiException(statusCode: response.statusCode, userMessage: message);
  }

  /// Extracts a short, human-readable message from an API error body.
  /// Never returns raw JSON payloads or technical dumps.
  static String _messageFromBody(String body, String fallback) {
    if (body.isEmpty) return fallback;
    try {
      final decoded = jsonDecode(body);
      final extracted = _extractMessage(decoded);
      return sanitizeDisplayMessage(extracted, fallback: fallback);
    } catch (_) {
      // Body is not JSON — never show raw response text.
      return fallback;
    }
  }

  /// Pulls the best user-facing string from WooCommerce's error shape:
  /// `{ "code": "woocommerce_rest_...", "message": "...", "data": { "status": 400 } }`
  static String? _extractMessage(Object? json) {
    if (json == null) return null;

    if (json is String) {
      final trimmed = json.trim();
      if (trimmed.isEmpty) return null;
      if (_looksLikeJson(trimmed)) {
        try {
          return _extractMessage(jsonDecode(trimmed));
        } catch (_) {
          return null;
        }
      }
      return trimmed;
    }

    if (json is List) {
      for (final item in json) {
        final message = _extractMessage(item);
        if (message != null && message.isNotEmpty) return message;
      }
      return null;
    }

    if (json is Map) {
      final map = Map<String, dynamic>.from(json);

      // WooCommerce always sends a top-level `message`; fall back to
      // other common shapes just in case a proxy/plugin changes it.
      final nested = _extractMessage(map['message']) ??
          _extractMessage(map['error']) ??
          _extractMessage(map['detail']) ??
          _extractMessage(map['errors']);
      if (nested != null && nested.isNotEmpty) return nested;

      return null;
    }

    return null;
  }

  /// Maps any caught error to a user-safe message for BLoC/UI layers.
  static String toUserMessage(
    Object error, {
    String fallback = defaultUserMessage,
  }) {
    if (error is ApiException) {
      return sanitizeDisplayMessage(error.userMessage, fallback: fallback);
    }

    // Network / filesystem / timeout failures must never surface internals.
    if (error is SocketException ||
        error is HttpException ||
        error is HandshakeException ||
        error is TlsException ||
        error is FileSystemException ||
        error is IOException ||
        error is TimeoutException ||
        error is FormatException ||
        error is http.ClientException) {
      return fallback;
    }

    if (error is Exception || error is Error) {
      final raw = error.toString();
      const prefixes = ['Exception: ', 'Error: '];
      var message = raw;
      for (final prefix in prefixes) {
        if (message.startsWith(prefix)) {
          message = message.substring(prefix.length);
          break;
        }
      }
      return sanitizeDisplayMessage(message, fallback: fallback);
    }

    return fallback;
  }

  /// Final guard for any string about to be shown in UI (toast, screen, etc.).
  static String sanitizeDisplayMessage(
    String? message, {
    String fallback = defaultUserMessage,
  }) {
    if (message == null) return fallback;
    final trimmed = message.trim();
    if (trimmed.isEmpty) return fallback;
    if (_looksTechnical(trimmed)) return fallback;
    return trimmed;
  }

  static bool _looksLikeJson(String value) {
    final trimmed = value.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }

  static bool _looksTechnical(String message) {
    if (_looksLikeJson(message)) return true;

    final lower = message.toLowerCase();
    const technicalMarkers = [
      'filesystemexception',
      'socketexception',
      'httpexception',
      'clientexception',
      'timeoutexception',
      'formatexception',
      'handshakeexception',
      'tlsexception',
      'woocommerce_rest_',
      'path =',
      'stack trace',
      '#0 ',
      'errno =',
      '"code"',
      '"status"',
    ];

    for (final marker in technicalMarkers) {
      if (lower.contains(marker)) return true;
    }

    // Long dumps with many braces/quotes are almost never user copy.
    final braceCount = '{'.allMatches(message).length +
        '}'.allMatches(message).length +
        '['.allMatches(message).length +
        ']'.allMatches(message).length;
    if (braceCount >= 4 && message.contains('"')) return true;

    return false;
  }

  @override
  String toString() => userMessage;
}
