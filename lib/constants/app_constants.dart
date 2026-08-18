import 'package:alnisa_store/config/env_config.dart';

class AppConstants {
  AppConstants._();

  // Variables
  static const String appName = 'Alnisa Store';
  static String get baseUrl => EnvConfig.baseUrl;

  /// WooCommerce REST API v3 path segment (products, categories, orders).
  static String get apiVersion => EnvConfig.apiVersion;

  /// WooCommerce Store API path segment (session-based cart).
  static String get storeApiVersion => EnvConfig.storeApiVersion;

  /// Public core WordPress REST API path segment (banners, etc.).
  static String get wpApiVersion => EnvConfig.wpApiVersion;

  /// Default HTTP timeout. The WooCommerce/WP backend can take 7-10s+ per
  /// request, so this needs enough headroom for slower mobile networks
  /// and pages that fire several requests concurrently (e.g. Home screen).
  static const int timeoutDuration = 45000; // in milliseconds

  // shared_preferences keys
  static const String seenOnboardingKey = 'seenOnboarding';
  static const String isDarkThemeKey = 'isDarkTheme';
  static const String localeLanguageCodeKey = 'localeLanguageCode';

  // flutter_secure_storage keys
  static const String cartTokenKey = 'cartToken';
  static const String cartNonceKey = 'cartNonce';
}
