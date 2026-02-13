import 'package:shared_preferences/shared_preferences.dart';

class ApiEndpoints {
  static String baseUrl = '';
  static const String _baseUrlKey = 'api_base_url';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);
    if (savedUrl != null) {
      baseUrl = savedUrl;
    } else {
      // Default ngrok URL
      baseUrl = 'http://dormered-unforgeable-phyliss.ngrok-free.dev/';
    }
  }

  static Future<void> updateBaseUrl(String protocol, String host) async {
    String formattedHost = host.endsWith('/')
        ? host.substring(0, host.length - 1)
        : host;

    final newUrl = '$protocol$formattedHost/';
    baseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, newUrl);
  }

  static Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlKey);
    baseUrl = 'http://dormered-unforgeable-phyliss.ngrok-free.dev/';
  }

  // Auth endpoints
  static const String login = 'api/v1/login/';
  static const String token = 'api/v1/token/';
  static const String tokenRefresh = 'api/v1/token/refresh/';
  static const String passwordResetRequest = 'api/v1/password-reset/request/';
  static const String passwordResetConfirm = 'api/v1/password-reset/confirm/';
  static const String register = 'api/v1/group/signup/';
  static const String verifyOtp = 'api/v1/group/verify-otp/';

  // Admin endpoints
  static const String dashboard = 'api/v1/admin/dashboard/';
  static const String groups = 'api/v1/admin/groups/';
}
