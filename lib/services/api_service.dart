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

  // ─── Admin Methods ────────────────────────────────────────────────

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
      final response = await dio.post(ApiConfig.groupCreate, data: request.toJson());
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
      final response = await dio.post(ApiConfig.createCollector, data: data.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to create collector: ${response.statusCode}');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String msg = 'Error creating collector';
      if (responseData is Map<String, dynamic>) {
        msg = responseData['detail'] ?? responseData['message'] ?? responseData.toString();
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
      final response = await dio.delete('${ApiConfig.deleteCollector}$id/delete/');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      throw Exception('Failed to delete collector: ${response.statusCode}');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String msg = 'Error deleting collector';
      if (responseData is Map<String, dynamic>) {
        msg = responseData['detail'] ?? responseData['message'] ?? responseData.toString();
      }
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> updateCollector(int id, Map<String, dynamic> data) async {
    try {
      final dio = await _authDio;
      final response = await dio.put('${ApiConfig.updateCollector}$id/update/', data: data);
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
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
        msg = responseData['detail'] ?? responseData['message'] ?? responseData.toString();
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


  Future<Map<String, dynamic>> createCollection(CollectionCreateRequest request) async {
    try {
      final dio = await _authDio;
      final response = await dio.post(ApiConfig.createCollection, data: request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to create collection: ${response.statusCode}');
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Error creating collection';
      if (data is Map<String, dynamic>) {
        // Handle common DRF error fields
        msg = data['detail'] ?? 
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
}
