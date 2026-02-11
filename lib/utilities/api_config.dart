import 'package:shared_preferences/shared_preferences.dart';

/// API Configuration
/// 
/// Centralized configuration for all API endpoints and settings.
/// Supports dynamic base URL for IP configuration.
class ApiConfig {
  // Private constructor
  ApiConfig._();

  static const String _defaultBaseUrl = 'https://dormered-unforgeable-phyliss.ngrok-free.dev';
  static String? _customBaseUrl;
  static const String _baseUrlKey = 'custom_base_url';

  /// Initialize configuration
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customBaseUrl = prefs.getString(_baseUrlKey);
  }

  /// Update base URL
  static Future<void> updateBaseUrl(String protocol, String host) async {
    final newUrl = '$protocol$host';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, newUrl);
    _customBaseUrl = newUrl;
  }

  /// Reset to default URL
  static Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlKey);
    _customBaseUrl = null;
  }

  /// Base URL for the API
  static String get baseUrl => _customBaseUrl ?? _defaultBaseUrl;

  /// API version
  static const String apiVersion = 'v1';

  /// Base API path
  static String get basePath => '$baseUrl/api/$apiVersion';

  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Retry configurations
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Endpoints
  static const String loginEndpoint = '/login/';
  static const String tokenEndpoint = '/token/';
  static const String tokenRefreshEndpoint = '/token/refresh/';
  static const String passwordResetRequestEndpoint = '/password-reset/request/';
  static const String passwordResetConfirmEndpoint = '/password-reset/confirm/';
  static const String registerEndpoint = '/group/signup/';
  static const String verifyOtpEndpoint = '/group/verify-otp/';
  static const String healthCheckEndpoint = '/'; // Endpoint to check connection

  /// Get full URL for an endpoint
  static String getUrl(String endpoint) => '$basePath$endpoint';
}
