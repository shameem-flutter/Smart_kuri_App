import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kuri_app/models/member/member_dashboard_model.dart';
import 'package:kuri_app/models/member/member_payments_model.dart';
import 'package:kuri_app/models/member/member_profile_model.dart';
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
import '../models/auth/plan_model.dart';
import '../utilities/api_config.dart';
import '../utilities/app_exception.dart';
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
import '../models/groupadmin/member_details_model.dart';
import '../models/groupadmin/collector_profile_model.dart';
import '../models/collector/pending_member_model.dart';
import '../models/collector/today_collections_model.dart';
import '../models/collector/reports_model.dart';
import '../models/groupadmin/pending_payments_model.dart';
import '../models/groupadmin/group_payments_history_model.dart';
import '../models/groupadmin/notification_model.dart';
import '../models/collector/collections_model.dart';
import '../models/collector/handover_pending_model.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storageService;

  ApiService({required StorageService storageService})
    : _storageService = storageService;

  /// Centralized Dio error message extractor.
  /// Handles plain-text (ngrok offline), JSON map, list, and timeout errors.
  String _extractDioErrorMsg(DioException e, String defaultMsg) {
    // Connection-level errors
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your network.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Could not connect to the server. Please check your network.';
    }

    // Response-level errors
    final data = e.response?.data;
    if (data != null) {
      if (data is String && data.isNotEmpty) {
        if (data.contains('ERR_NGROK')) {
          return 'Server endpoint is currently offline. Please try again later.';
        }
        if (data.contains('<html') || data.contains('<!DOCTYPE')) {
          return '$defaultMsg (Server error ${e.response?.statusCode ?? ''})';
        }
        return data.trim();
      } else if (data is Map<String, dynamic>) {
        return data['detail'] as String? ??
            data['message'] as String? ??
            data['error'] as String? ??
            data['non_field_errors']?.toString() ??
            data.toString();
      } else if (data is List) {
        return data.join('\n');
      }
    }

    return e.message ?? defaultMsg;
  }

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
        followRedirects: true,
        maxRedirects: 5,
      ),
    );
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    return dio;
  }

  /// Helper to get Dio with auth token and automatic token refresh
  Future<Dio> get _authDio async {
    final dio = _dio;
    final token = await _storageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          // Only handle 401 Unauthorized errors
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          try {
            String? newAccessToken;

            // Step 1: Try tokenRefresh for a new access token
            final currentRefreshToken = await _storageService.getRefreshToken();
            if (currentRefreshToken != null && currentRefreshToken.isNotEmpty) {
              try {
                final refreshResponse = await _dio.post(
                  ApiConfig.tokenRefresh,
                  data: {'refresh': currentRefreshToken},
                );
                if (refreshResponse.statusCode == 200 ||
                    refreshResponse.statusCode == 201) {
                  newAccessToken = refreshResponse.data['access'] as String;
                  await _storageService.saveAccessToken(newAccessToken);
                }
              } catch (_) {
                // Refresh token expired, fall through to Step 2
              }
            }

            // Step 2: If tokenRefresh failed, we don't fallback to credentials. We trigger logout.
            if (newAccessToken == null) {
              await _storageService.clearAll();
              throw UnauthorizedException(
                'Session expired. Please login again.',
              );
            }

            // Step 3: Retry the original request with the new token
            final options = error.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await _dio.fetch(options);
            return handler.resolve(retryResponse);
          } catch (e) {
            debugPrint('Token refresh failed: $e');
            await _storageService.clearAll();
            return handler.next(error);
          }
        },
      ),
    );

    return dio;
  }

  // ─── Auth Methods ─────────────────────────────────────────────────

  Future<TokenResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(ApiConfig.login, data: request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TokenResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Login failed: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Login failed'));
    }
  }

  Future<void> logout(String identifier, String password) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(
        ApiConfig.logout,
        data: {'identifier': identifier, 'password': password},
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Logout failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Don't throw if logout fails on server side to still clear local storage
      debugPrint('Error logging out from backend: ${e.message}');
    } catch (e) {
      debugPrint('Error logging out from backend: $e');
    }
  }

  Future<TokenResponse> generateToken(TokenRequest request) async {
    try {
      final response = await _dio.post(ApiConfig.token, data: request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TokenResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Token generation failed: ${response.statusCode}');
    } catch (e) {
      throw ServerException('Error generating token: $e');
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
      throw ServerException('Token refresh failed: ${response.statusCode}');
    } catch (e) {
      throw ServerException('Error refreshing token: $e');
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
      throw ServerException(
        'Password reset request failed: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Password reset request failed'),
      );
    }
  }

  Future<AuthResponse> firstLoginChangePassword(
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(
        ApiConfig.firstLoginChangePassword,
        data: {
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException(
        'First login password change failed: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Password change failed'));
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
      throw ServerException(
        'Password reset confirm failed: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Password reset confirm failed'),
      );
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
      throw ServerException('Registration failed: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Registration failed'));
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
      throw ServerException('OTP verification failed: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'OTP verification failed'));
    }
  }

  Future<PlanListResponse> getPlans() async {
    try {
      final dio = await _authDio; // Plans API requires Bearer token auth
      final response = await dio.get(ApiConfig.plans);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return PlanListResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Failed to fetch plans: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Failed to fetch plans'));
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
      throw ServerException('Failed to load dashboard: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error fetching dashboard'));
    }
  }

  Future<CollectorDashboardModel> getCollectorDashboardData() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.collectorDashboard);
      if (response.statusCode == 200) {
        return CollectorDashboardModel.fromJson(response.data);
      }
      throw ServerException(
        'Failed to load collector dashboard: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching collector dashboard'),
      );
    }
  }

  Future<PendingMembersResponse> getPendingMembers({String status = 'pending'}) async {
    try {
      final dio = await _authDio;
      final response = await dio.get(
        ApiConfig.collectorPendingMembers,
        queryParameters: {'status': status},
      );
      if (response.statusCode == 200) {
        return PendingMembersResponse.fromJson(response.data);
      }
      throw ServerException(
        'Failed to load pending members: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching pending members'),
      );
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
      throw ServerException(
        'Failed to load assigned members: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching assigned members'),
      );
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
      throw ServerException('Failed to add collection: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error adding collection'));
    }
  }

  Future<TodayCollectionsResponse> getTodayCollections() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.collectorTodayCollections);
      if (response.statusCode == 200) {
        return TodayCollectionsResponse.fromJson(response.data);
      }
      throw ServerException(
        'Failed to load today collections: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching today collections'),
      );
    }
  }

  Future<ReportsResponse> getReports({String? fromDate, String? toDate}) async {
    try {
      final dio = await _authDio;
      final Map<String, dynamic> queryParams = {};
      if (fromDate != null && fromDate.isNotEmpty) {
        queryParams['from_date'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;

      final response = await dio.get(
        ApiConfig.collectorReports,
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        return ReportsResponse.fromJson(response.data);
      }
      throw ServerException('Failed to load reports: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error fetching reports'));
    }
  }

  Future<void> deletePayment(int id) async {
    try {
      final dio = await _authDio;
      final response = await dio.delete(ApiConfig.deletePayment(id));
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      throw ServerException('Failed to delete payment: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error deleting payment'));
    }
  }

  Future<void> resendPayment(int id) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(ApiConfig.resendPayment(id));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      throw ServerException('Failed to resend payment: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error resending payment'));
    }
  }

  Future<void> sendToAdmin() async {
    try {
      final dio = await _authDio;
      final response = await dio.post(ApiConfig.sendToAdmin);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      throw ServerException('Failed to send to admin: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error sending to admin'));
    }
  }

  Future<void> resendGroupPayments(int groupId) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(
        ApiConfig.resendGroupPayments,
        data: {'group_id': groupId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      throw ServerException('Failed to resend group payments: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error resending group payments'));
    }
  }

  Future<MemberHistoryResponse> getMemberHistory(int memberId) async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.memberHistory(memberId));
      if (response.statusCode == 200) {
        return MemberHistoryResponse.fromJson(response.data);
      }
      throw ServerException(
        'Failed to load member history: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching member history'),
      );
    }
  }

  Future<CollectorProfileResponse> getCollectorProfile() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.collectorProfile);
      if (response.statusCode == 200) {
        return CollectorProfileResponse.fromJson(response.data);
      }
      throw ServerException(
        'Failed to load collector profile: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching collector profile'),
      );
    }
  }

  Future<GroupListResponse> getGroups() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.groups);
      if (response.statusCode == 200) {
        return GroupListResponse.fromJson(response.data);
      }
      throw ServerException('Failed to load groups: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error fetching groups'));
    }
  }

  Future<GroupCreateResponse> createGroup(GroupCreateRequest request) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(
        ApiConfig.groupCreateAdmin,
        data: request.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return GroupCreateResponse.fromJson(response.data);
        } else {
          return const GroupCreateResponse(message: 'Success', group: {});
        }
      }
      throw ServerException('Failed to create group: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error creating group'));
    }
  }

  Future<ProfileResponse> getProfile() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.profile);
      if (response.statusCode == 200) {
        return ProfileResponse.fromJson(response.data);
      }
      throw ServerException('Failed to load profile: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error fetching profile'));
    }
  }

  Future<MemberListResponse> getMembers() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.members);
      if (response.statusCode == 200) {
        return MemberListResponse.fromJson(response.data);
      }
      throw ServerException('Failed to load members: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error fetching members'));
    }
  }

  Future<Map<String, dynamic>> createMember(Map<String, dynamic> data) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(ApiConfig.membersCreate, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException('Failed to create member: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error creating member'));
    }
  }

  Future<Map<String, dynamic>> updateMember(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final dio = await _authDio;
      final response = await dio.put(
        '${ApiConfig.memberUpdate}$id/update/',
        data: data,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException('Failed to update member: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error updating member'));
    }
  }

  Future<void> deleteMember(int id) async {
    try {
      final dio = await _authDio;
      final response = await dio.delete(ApiConfig.deleteMember(id));
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      throw ServerException('Failed to delete member: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error deleting member'));
    }
  }

  Future<MemberDetailsResponse> getMemberAdminDetails(int id) async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.memberAdminDetails(id));
      if (response.statusCode == 200) {
        return MemberDetailsResponse.fromJson(response.data);
      }
      throw ServerException(
        'Failed to load member details: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching member details'),
      );
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
      throw ServerException(
        'Failed to create collector: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error creating collector'));
    }
  }

  Future<CashCollectorListResponse> getCollectors() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.collectors);
      if (response.statusCode == 200) {
        return CashCollectorListResponse.fromJson(response.data);
      }
      throw ServerException(
        'Failed to load collectors: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching collectors'),
      );
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
      throw ServerException(
        'Failed to delete collector: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error deleting collector'));
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
      throw ServerException(
        'Failed to update collector: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error updating collector'));
    }
  }

  Future<CollectionListResponse> getCollections() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.collectionList);
      if (response.statusCode == 200) {
        return CollectionListResponse.fromJson(response.data);
      }
      throw ServerException(
        'Failed to load collections: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching collections'),
      );
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
      throw ServerException(
        'Failed to create collection: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error creating collection'),
      );
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
      throw ServerException('Failed to update group: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error updating group'));
    }
  }

  Future<GroupDetailsResponse> getGroupDetails(int id) async {
    try {
      final dio = await _authDio;
      final response = await dio.get('${ApiConfig.groupDetails}$id/');
      if (response.statusCode == 200) {
        return GroupDetailsResponse.fromJson(response.data);
      }
      throw ServerException(
        'Failed to load group details: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching group details'),
      );
    }
  }

  Future<GroupListResponse> getAuctions() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.auctions);
      if (response.statusCode == 200) {
        return GroupListResponse.fromJson(response.data);
      }
      throw ServerException('Failed to load auctions: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error fetching auctions'));
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
      throw ServerException(
        'Failed to load auction group details: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching auction group details'),
      );
    }
  }

  Future<AuctionDetailsResponse> getAuctionDetails(int id) async {
    try {
      final dio = await _authDio;
      final response = await dio.get('${ApiConfig.auctions}$id/');
      if (response.statusCode == 200) {
        return AuctionDetailsResponse.fromJson(response.data);
      }
      throw ServerException(
        'Failed to load auction details: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching auction details'),
      );
    }
  }

  Future<SpinAuctionResponse> getSpinAuctionData(int auctionId) async {
    try {
      final dio = await _authDio;
      final response = await dio.get('${ApiConfig.auctions}$auctionId/spin/');
      if (response.statusCode == 200) {
        return SpinAuctionResponse.fromJson(response.data);
      }
      throw ServerException('Failed to load spin data: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error fetching spin data'));
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
      throw ServerException('Failed to assign winner: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error assigning winner'));
    }
  }

  Future<Map<String, dynamic>> createAuction(Map<String, dynamic> data) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(ApiConfig.createAuction, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException('Failed to create auction: ${response.statusCode}');
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMsg(e, 'Error creating auction'));
    }
  }
  // ==========================================
  // Member Specific Methods
  // ==========================================

  /// Get Member Dashboard
  Future<MemberDashboardResponse> getMemberDashboard() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.memberDashboard);
      return MemberDashboardResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Failed to load member dashboard'),
      );
    }
  }

  /// Get Member Payments
  Future<MemberPaymentsResponse> getMemberPayments() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.memberPayments);
      return MemberPaymentsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Failed to load payment history'),
      );
    }
  }

  /// Get Member Profile
  Future<MemberProfileResponse> getMemberProfile() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.memberProfile);
      return MemberProfileResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Failed to load member profile'),
      );
    }
  }

  /// Get Member Auctions
  Future<List<AuctionItem>> getMemberAuctions() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.memberAuctions);
      final List<dynamic> data = response.data;
      return data.map((e) => AuctionItem.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Failed to load member auctions'),
      );
    }
  }

  Future<PendingPaymentsResponse> getPendingPayments() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.pendingPayments);
      if (response.statusCode == 200) {
        return PendingPaymentsResponse.fromJson(response.data);
      }
      throw ServerException(
        'Failed to load pending payments: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching pending payments'),
      );
    }
  }

  Future<GroupPaymentsHistoryResponse> getGroupPayments(int groupId) async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.groupPayments(groupId));
      if (response.statusCode == 200) {
        return GroupPaymentsHistoryResponse.fromJson(response.data);
      }
      throw ServerException(
        'Failed to load group payments: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching group payments'),
      );
    }
  }

  /// Approve a single payment by its ID
  Future<String> approvePayment(int paymentId) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(ApiConfig.approvePayment(paymentId));
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? 'Payment approved';
      }
      return 'Payment approved';
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Failed to approve payment'),
      );
    }
  }

  /// Reject a single payment by its ID
  Future<String> rejectPayment(int paymentId) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(ApiConfig.rejectPayment(paymentId));
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? 'Payment rejected';
      }
      return 'Payment rejected';
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Failed to reject payment'),
      );
    }
  }

  Future<void> editAuctionDate({
    required int groupId,
    required int auctionId,
    required String newDate,
  }) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(
        ApiConfig.editAuctionDates(groupId),
        data: {'auction_id': auctionId, 'new_date': newDate},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          'Failed to edit auction date: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error editing auction date'),
      );
    }
  }

  Future<NotificationListResponse> getNotifications() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.notifications);
      if (response.statusCode == 200) {
        return NotificationListResponse.fromJson(response.data);
      }
      throw ServerException(
        'Failed to load notifications: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching notifications'),
      );
    }
  }

  /// Assign winners for all months at once (bulk assign-all).
  /// [winners] is a list of maps like [{'month': 1, 'id': 5}, ...].
  Future<Map<String, dynamic>> assignAllWinners(
    int auctionId,
    List<Map<String, int>> winners,
  ) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(
        ApiConfig.assignAllWinners(auctionId),
        data: {'winners': winners},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {'message': 'Winners assigned'};
      }
      throw ServerException(
        'Failed to assign all winners: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error assigning all winners'),
      );
    }
  }
  
  /// Approve all payments for a group
  Future<Map<String, dynamic>> approveGroupPayments(int groupId) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(ApiConfig.approveGroupPayments(groupId));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {'message': 'All payments approved'};
      }
      throw ServerException(
        'Failed to approve all payments: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error approving all payments'),
      );
    }
  }

  /// Reject all payments for a group
  Future<Map<String, dynamic>> rejectGroupPayments(int groupId) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(ApiConfig.rejectGroupPayments(groupId));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {'message': 'All payments rejected'};
      }
      throw ServerException(
        'Failed to reject all payments: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error rejecting all payments'),
      );
    }
  }

  /// Get Collector Collections
  Future<CollectorCollectionsResponse> getCollectorCollections() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.collectorCollections);
      if (response.statusCode == 200) {
        return CollectorCollectionsResponse.fromJson(response.data);
      }
      throw ServerException(
        'Failed to load collector collections: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching collector collections'),
      );
    }
  }

  /// Get Handover Pending info
  Future<HandoverPendingModel> getHandoverPending() async {
    try {
      final dio = await _authDio;
      final response = await dio.get(ApiConfig.collectorHandoverPending);
      if (response.statusCode == 200) {
        return HandoverPendingModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw ServerException(
        'Failed to load handover pending: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error fetching handover pending'),
      );
    }
  }

  /// Send handover amount to admin
  Future<Map<String, dynamic>> sendHandoverToAdmin() async {
    try {
      final dio = await _authDio;
      final response = await dio.post(ApiConfig.collectorHandoverPending);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {'message': 'Handover sent successfully'};
      }
      throw ServerException(
        'Failed to send handover: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMsg(e, 'Error sending handover to admin'),
      );
    }
  }
}

