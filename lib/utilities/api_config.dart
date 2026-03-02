import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static String baseUrl = '';
  static const String _baseUrlKey = 'api_base_url';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);
    if (savedUrl != null) {
      baseUrl = savedUrl;
    } else {
      baseUrl = 'https://dormered-unforgeable-phyliss.ngrok-free.dev/';
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
    baseUrl = 'https://dormered-unforgeable-phyliss.ngrok-free.dev/';
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
  static const String collectorDashboard = 'api/v1/collector/dashboard/';
  static const String collectorMembers = 'api/v1/collector/list-members/';
  static const String collectorPendingMembers =
      'api/v1/collector/pending-members/';
  static const String collectorTodayCollections =
      'api/v1/collector/today-collections/';
  static const String collectorReports = 'api/v1/collector/reports/';
  static const String collectorAddCollection =
      'api/v1/collector/add-collection/';
  static String deletePayment(int id) =>
      'api/v1/collector/payments/$id/delete/';
  static String memberHistory(int id) =>
      'api/v1/collector/members/$id/history/';
  static const String collectorProfile = 'api/v1/collector/profile/';
  static const String groups = 'api/v1/admin/groups/';
  static const String groupCreate = 'api/v1/admin/groups/create/';
  static const String profile = 'api/v1/admin/profile/';
  static const String members = 'api/v1/members/';
  static const String memberDashboard = 'api/v1/members/dashboard/';
  static const String membersCreate = 'api/v1/members/create/';
  static const String createCollector = 'api/v1/admin/collectors/create/';
  static const String collectors = 'api/v1/admin/collectors/';
  static const String deleteCollector = 'api/v1/admin/collectors/';
  static const String updateCollector = 'api/v1/admin/collectors/';
  static const String collectionList = 'api/v1/group/payments/';
  static const String createCollection = 'api/v1/group/payments/create/';
  static const String groupUpdate = 'api/v1/admin/groups/';
  static const String groupDetails = 'api/v1/admin/groups/';
  static const String auctions = 'api/v1/admin/auctions/';
  static const String auctionGroupDetails = 'api/v1/admin/auctions/group/';
  static const String createAuction = 'api/v1/admin/auctions/create/';
}
