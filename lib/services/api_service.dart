import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/auth/auth_response.dart';
import '../models/groupadmin/dashboard_model.dart';
import '../models/groupadmin/group_model.dart';
import '../models/groupadmin/profile_model.dart';
import '../models/groupadmin/member_list.dart';
import '../models/groupadmin/cashcollector/cashcollector.dart';
import '../models/groupadmin/cashcollector/cashcollector_list.dart';
import '../models/auth/login_request.dart';
import '../models/auth/password_reset_request.dart';
import '../models/auth/register_request.dart';
import '../models/auth/token_request.dart';
import '../utilities/api_config.dart';
import '../models/groupadmin/group_create_model.dart';
import '../models/groupadmin/collection_list_model.dart';
import '../models/groupadmin/collection_create_model.dart';
import '../models/groupadmin/group_details_model.dart';
import '../models/groupadmin/auction/auction_group_details_model.dart';
import '../models/groupadmin/auction/auction_details_model.dart';
import '../models/groupadmin/auction/spin_auction_model.dart';
import '../models/groupadmin/collector_dashboard_model.dart';
import '../models/groupadmin/assigned_member_model.dart';
import '../models/groupadmin/member_history_model.dart';
import '../models/groupadmin/collector_profile_model.dart';
import '../models/collector/pending_member_model.dart';
import '../models/collector/today_collections_model.dart';
import '../models/collector/reports_model.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storageService;

  ApiService({required StorageService storageService})
    : _storageService = storageService;

  Dio get _dio {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    return dio;
  }

  /// Helper to get Dio with auth token
  Future<Dio> get _authDio async {
    final dio = _dio;
    final token = await _storageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
    return dio;
  }

  // ─── Auth Methods ─────────────────────────────────────────────────

  Future<TokenResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(ApiConfig.login, data: request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TokenResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Login failed: ${response.statusCode}');
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Login failed';
      if (data is Map<String, dynamic>) {
        msg = data['detail'] ?? data['message'] ?? data.toString();
      }
      throw Exception(msg);
    }
  }

  Future<TokenResponse> generateToken(TokenRequest request) async {
    try {
      final response = await _dio.post(ApiConfig.token, data: request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TokenResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Token generation failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error generating token: $e');
    }
  }

  Future<TokenRefreshResponse> refreshToken(TokenRefreshRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.tokenRefresh,
        data: request.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TokenRefreshResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw Exception('Token refresh failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error refreshing token: $e');
    }
  }

  Future<AuthResponse> requestPasswordReset(
    PasswordResetRequest request,
  ) async {
    try {
      final response = await _dio.post(
        ApiConfig.passwordResetRequest,
        data: request.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Password reset request failed: ${response.statusCode}');
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Password reset request failed';
      if (data is Map<String, dynamic>) {
        msg = data['detail'] ?? data['message'] ?? data.toString();
      }
      throw Exception(msg);
    }
  }

  Future<AuthResponse> confirmPasswordReset(
    PasswordResetConfirmRequest request,
  ) async {
    try {
      final response = await _dio.post(
        ApiConfig.passwordResetConfirm,
        data: request.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Password reset confirm failed: ${response.statusCode}');
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Password reset confirm failed';
      if (data is Map<String, dynamic>) {
        msg = data['detail'] ?? data['message'] ?? data.toString();
      }
      throw Exception(msg);
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: request.toJson(),
      );

      final cookies = response.headers['set-cookie'];
      if (cookies != null && cookies.isNotEmpty) {
        final cookieString = cookies.join('; ');
        await _storageService.saveSessionCookies(cookieString);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Registration failed: ${response.statusCode}');
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Registration failed';
      if (data is Map<String, dynamic>) {
        msg = data['detail'] ?? data['message'] ?? data.toString();
      }
      throw Exception(msg);
    }
  }

  Future<AuthResponse> verifyOtp(String otp) async {
    try {
      final cookies = await _storageService.getSessionCookies();
      final dio = _dio;
      final response = await dio.post(
        ApiConfig.verifyOtp,
        data: {'otp': int.tryParse(otp) ?? otp},
        options: Options(headers: {'Cookie': cookies}),
      );

      await _storageService.deleteSessionCookies();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('OTP verification failed: ${response.statusCode}');
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'OTP verification failed';
      if (data is Map<String, dynamic>) {
        msg = data['detail'] ?? data['message'] ?? data.toString();
      }
      throw Exception(msg);
    }
  }

  //  Admin Methods

  Future<DashboardResponse> getDashboardData() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.dashboard);
      if (response.statusCode == 200) {
        return DashboardResponse.fromJson(response.data);
      }
      throw Exception('Failed to load dashboard: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error fetching dashboard: ${e.message}');
    }
  }

  Future<CollectorDashboardModel> getCollectorDashboardData() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.collectorDashboard);
      if (response.statusCode == 200) {
        return CollectorDashboardModel.fromJson(response.data);
      }
      throw Exception(
        'Failed to load collector dashboard: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception('Error fetching collector dashboard: ${e.message}');
    }
  }

  Future<PendingMembersResponse> getPendingMembers() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.collectorPendingMembers);
      if (response.statusCode == 200) {
        return PendingMembersResponse.fromJson(response.data);
      }
      throw Exception('Failed to load pending members: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error fetching pending members: ${e.message}');
    }
  }

  Future<AssignedMemberResponse> getAssignedMembers({
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final dio = await _authDio;
      final response = await dio.get(
        ApiConfig.collectorMembers,
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      if (response.statusCode == 200) {
        return AssignedMemberResponse.fromJson(response.data);
      }
      throw Exception(
        'Failed to load assigned members: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception('Error fetching assigned members: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> addCollectorCollection(
    Map<String, dynamic> data,
  ) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(
        ApiConfig.collectorAddCollection,
        data: data,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to add collection: ${response.statusCode}');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String msg = 'Error adding collection';
      if (responseData is Map<String, dynamic>) {
        msg =
            responseData['detail'] ??
            responseData['message'] ??
            responseData.toString();
      }
      throw Exception(msg);
    }
  }

  Future<TodayCollectionsResponse> getTodayCollections() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.collectorTodayCollections);
      if (response.statusCode == 200) {
        return TodayCollectionsResponse.fromJson(response.data);
      }
      throw Exception(
        'Failed to load today collections: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception('Error fetching today collections: ${e.message}');
    }
  }

  Future<ReportsResponse> getReports({String? fromDate, String? toDate}) async {
    try {
      final dio = await _authDio;
      final Map<String, dynamic> queryParams = {};
      if (fromDate != null && fromDate.isNotEmpty)
        queryParams['from_date'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;

      final response = await dio.get(
        ApiConfig.collectorReports,
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        return ReportsResponse.fromJson(response.data);
      }
      throw Exception('Failed to load reports: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error fetching reports: ${e.message}');
    }
  }

  Future<void> deletePayment(int id) async {
    try {
      final dio = await _authDio;
      final response = await dio.delete(ApiConfig.deletePayment(id));
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      throw Exception('Failed to delete payment: ${response.statusCode}');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String msg = 'Error deleting payment';
      if (responseData is Map<String, dynamic>) {
        msg =
            responseData['detail'] ??
            responseData['message'] ??
            responseData.toString();
      }
      throw Exception(msg);
    }
  }

  Future<MemberHistoryResponse> getMemberHistory(int memberId) async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.memberHistory(memberId));
      if (response.statusCode == 200) {
        return MemberHistoryResponse.fromJson(response.data);
      }
      throw Exception('Failed to load member history: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error fetching member history: ${e.message}');
    }
  }

  Future<CollectorProfileResponse> getCollectorProfile() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.collectorProfile);
      if (response.statusCode == 200) {
        return CollectorProfileResponse.fromJson(response.data);
      }
      throw Exception(
        'Failed to load collector profile: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception('Error fetching collector profile: ${e.message}');
    }
  }

  Future<GroupListResponse> getGroups() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.groups);
      if (response.statusCode == 200) {
        return GroupListResponse.fromJson(response.data);
      }
      throw Exception('Failed to load groups: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error fetching groups: ${e.message}');
    }
  }

  Future<GroupCreateResponse> createGroup(GroupCreateRequest request) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(
        ApiConfig.groupCreate,
        data: request.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return GroupCreateResponse.fromJson(response.data);
      }
      throw Exception('Failed to create group: ${response.statusCode}');
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Error creating group';
      if (data is Map<String, dynamic>) {
        msg = data['detail'] ?? data['message'] ?? data.toString();
      }
      throw Exception(msg);
    }
  }

  Future<ProfileResponse> getProfile() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.profile);
      if (response.statusCode == 200) {
        return ProfileResponse.fromJson(response.data);
      }
      throw Exception('Failed to load profile: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error fetching profile: ${e.message}');
    }
  }

  Future<MemberListResponse> getMembers() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.members);
      if (response.statusCode == 200) {
        return MemberListResponse.fromJson(response.data);
      }
      throw Exception('Failed to load members: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error fetching members: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> createMember(Map<String, dynamic> data) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(ApiConfig.membersCreate, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to create member: ${response.statusCode}');
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Error creating member';
      if (data is Map<String, dynamic>) {
        msg = data['detail'] ?? data['message'] ?? data.toString();
      }
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> createCollector(CashCollectorModel data) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(
        ApiConfig.createCollector,
        data: data.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to create collector: ${response.statusCode}');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String msg = 'Error creating collector';
      if (responseData is Map<String, dynamic>) {
        msg =
            responseData['detail'] ??
            responseData['message'] ??
            responseData.toString();
      }
      throw Exception(msg);
    }
  }

  Future<CashCollectorListResponse> getCollectors() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.collectors);
      if (response.statusCode == 200) {
        return CashCollectorListResponse.fromJson(response.data);
      }
      throw Exception('Failed to load collectors: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error fetching collectors: ${e.message}');
    }
  }

  Future<void> deleteCollector(int id) async {
    try {
      final dio = await _authDio;
      final response = await dio.delete(
        '${ApiConfig.deleteCollector}$id/delete/',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      throw Exception('Failed to delete collector: ${response.statusCode}');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String msg = 'Error deleting collector';
      if (responseData is Map<String, dynamic>) {
        msg =
            responseData['detail'] ??
            responseData['message'] ??
            responseData.toString();
      }
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> updateCollector(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final dio = await _authDio;
      final response = await dio.put(
        '${ApiConfig.updateCollector}$id/update/',
        data: data,
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        debugPrint('Collector update response: ${response.data}');
        final rData = response.data;
        if (rData is Map<String, dynamic>) {
          return rData;
        }
        return {};
      }
      throw Exception('Failed to update collector: ${response.statusCode}');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String msg = 'Error updating collector';
      if (responseData is Map<String, dynamic>) {
        msg =
            responseData['detail'] ??
            responseData['message'] ??
            responseData.toString();
      }
      throw Exception(msg);
    }
  }

  Future<CollectionListResponse> getCollections() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.collectionList);
      if (response.statusCode == 200) {
        return CollectionListResponse.fromJson(response.data);
      }
      throw Exception('Failed to load collections: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error fetching collections: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> createCollection(
    CollectionCreateRequest request,
  ) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(
        ApiConfig.createCollection,
        data: request.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to create collection: ${response.statusCode}');
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Error creating collection';
      if (data is Map<String, dynamic>) {
        // Handle common DRF error fields
        msg =
            data['detail'] ??
            data['message'] ??
            data['non_field_errors']?.toString() ??
            data.toString();
      } else if (data is List) {
        // Handle direct list errors
        msg = data.join('\n');
      }
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> updateGroup(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final dio = await _authDio;
      // PUT request to api/v1/admin/groups/{id}/edit/
      final response = await dio.put(
        '${ApiConfig.groupUpdate}$id/edit/',
        data: data,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to update group: ${response.statusCode}');
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Error updating group';
      if (data is Map<String, dynamic>) {
        msg =
            data['detail'] ??
            data['message'] ??
            data['non_field_errors']?.toString() ??
            data.toString();
      } else if (data is List) {
        msg = data.join('\n');
      }
      throw Exception(msg);
    }
  }

  Future<GroupDetailsResponse> getGroupDetails(int id) async {
    try {
      final dio = await _authDio;
      final response = await dio.get('${ApiConfig.groupDetails}$id/');
      if (response.statusCode == 200) {
        return GroupDetailsResponse.fromJson(response.data);
      }
      throw Exception('Failed to load group details: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error fetching group details: ${e.message}');
    }
  }

  Future<GroupListResponse> getAuctions() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.auctions);
      if (response.statusCode == 200) {
        return GroupListResponse.fromJson(response.data);
      }
      throw Exception('Failed to load auctions: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error fetching auctions: ${e.message}');
    }
  }

  Future<AuctionGroupDetailsResponse> getAuctionGroupDetails(
    String groupId,
  ) async {
    try {
      final dio = await _authDio;
      final response = await dio.get(
        '${ApiConfig.auctionGroupDetails}$groupId/',
      );
      if (response.statusCode == 200) {
        return AuctionGroupDetailsResponse.fromJson(response.data);
      }
      throw Exception(
        'Failed to load auction group details: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception('Error fetching auction group details: ${e.message}');
    }
  }

  Future<AuctionDetailsResponse> getAuctionDetails(int id) async {
    try {
      final dio = await _authDio;
      final response = await dio.get('${ApiConfig.auctions}$id/');
      if (response.statusCode == 200) {
        return AuctionDetailsResponse.fromJson(response.data);
      }
      throw Exception('Failed to load auction details: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error fetching auction details: ${e.message}');
    }
  }

  Future<SpinAuctionResponse> getSpinAuctionData(int auctionId) async {
    try {
      final dio = await _authDio;
      final response = await dio.get('${ApiConfig.auctions}$auctionId/spin/');
      if (response.statusCode == 200) {
        return SpinAuctionResponse.fromJson(response.data);
      }
      throw Exception('Failed to load spin data: ${response.statusCode}');
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Error fetching spin data';
      if (data is Map<String, dynamic>) {
        msg =
            data['error'] ??
            data['detail'] ??
            data['message'] ??
            data.toString();
      }
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> assignAuctionWinner(
    int auctionId,
    int memberId,
  ) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(
        '${ApiConfig.auctions}$auctionId/assign-winner/',
        data: {'member_id': memberId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to assign winner: ${response.statusCode}');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String msg = 'Error assigning winner';
      if (responseData is Map<String, dynamic>) {
        msg =
            responseData['detail'] ??
            responseData['message'] ??
            responseData.toString();
      }
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> createAuction(Map<String, dynamic> data) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(ApiConfig.createAuction, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to create auction: ${response.statusCode}');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String msg = 'Error creating auction';
      if (responseData is Map<String, dynamic>) {
        msg =
            responseData['detail'] ??
            responseData['message'] ??
            responseData.toString();
      }
      throw Exception(msg);
    }
  }
}
