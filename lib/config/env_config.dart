/// Compile-time configuration injected via `--dart-define-from-file`.
///
/// Example:
/// `flutter run --dart-define-from-file=env/dev.json`
class EnvConfig {
  EnvConfig._();

  /// WordPress/WooCommerce site root, e.g. `https://alnisastore.com`.
  static const String baseUrl = String.fromEnvironment('BASE_URL');

  /// WooCommerce REST API v3 path segment, appended after [baseUrl].
  static const String apiVersion = String.fromEnvironment(
    'API_VERSION',
    defaultValue: 'wp-json/wc/v3',
  );

  /// WooCommerce Store API path segment (session-based cart endpoints).
  static const String storeApiVersion = String.fromEnvironment(
    'STORE_API_VERSION',
    defaultValue: 'wp-json/wc/store/v1',
  );

  /// Public core WordPress REST API path segment (custom post types like
  /// banners) — no consumer key required.
  static const String wpApiVersion = String.fromEnvironment(
    'WP_API_VERSION',
    defaultValue: 'wp-json/wp/v2',
  );

  /// Read-only WooCommerce REST API consumer key. Must never be a
  /// write-scoped key — this is bundled into the client app.
  static const String wooConsumerKey = String.fromEnvironment(
    'WOO_CONSUMER_KEY',
  );

  /// Read-only WooCommerce REST API consumer secret.
  static const String wooConsumerSecret = String.fromEnvironment(
    'WOO_CONSUMER_SECRET',
  );

  static void validate() {
    final missing = <String>[
      if (baseUrl.isEmpty) 'BASE_URL',
      if (wooConsumerKey.isEmpty) 'WOO_CONSUMER_KEY',
      if (wooConsumerSecret.isEmpty) 'WOO_CONSUMER_SECRET',
    ];

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required environment values: ${missing.join(', ')}. '
        'Run with --dart-define-from-file=env/dev.json '
        '(copy env/dev.json.example to env/dev.json first).',
      );
    }
  }
}
