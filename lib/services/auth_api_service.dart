import 'package:dio/dio.dart';
import 'package:kuri_app/models/auth_response.dart';
import 'package:kuri_app/models/login_request.dart';
import 'package:kuri_app/models/password_reset_request.dart';
import 'package:kuri_app/models/register_request.dart';
import 'package:kuri_app/models/token_request.dart';
import 'package:kuri_app/services/api_client.dart';
import 'package:kuri_app/utilities/api_config.dart';
import 'storage_service.dart';

/// Authentication API Service
///
/// Handles all authentication-related API calls including:
/// - Login
/// - Token generation and refresh
/// - Password reset
/// - Registration and OTP Verification
class AuthApiService {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthApiService({
    required ApiClient apiClient,
    required StorageService storageService,
  }) : _apiClient = apiClient,
       _storageService = storageService;

  /// Login with identifier (email/username) and password
  ///
  /// Returns [TokenResponse] with access and refresh tokens
  Future<TokenResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(
      ApiConfig.loginEndpoint,
      data: request.toJson(),
    );

    return TokenResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Generate JWT tokens with username and password
  ///
  /// Returns [TokenResponse] with access and refresh tokens
  Future<TokenResponse> generateToken(TokenRequest request) async {
    final response = await _apiClient.post(
      ApiConfig.tokenEndpoint,
      data: request.toJson(),
    );

    return TokenResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Refresh access token using refresh token
  ///
  /// Returns [TokenRefreshResponse] with new access token
  Future<TokenRefreshResponse> refreshToken(TokenRefreshRequest request) async {
    final response = await _apiClient.post(
      ApiConfig.tokenRefreshEndpoint,
      data: request.toJson(),
    );

    return TokenRefreshResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Request password reset (sends OTP to email)
  ///
  /// Returns [AuthResponse] with success message
  Future<AuthResponse> requestPasswordReset(
    PasswordResetRequest request,
  ) async {
    final response = await _apiClient.post(
      ApiConfig.passwordResetRequestEndpoint,
      data: request.toJson(),
    );

    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Confirm password reset with OTP and new password
  ///
  /// Returns [AuthResponse] with success message
  Future<AuthResponse> confirmPasswordReset(
    PasswordResetConfirmRequest request,
  ) async {
    final response = await _apiClient.post(
      ApiConfig.passwordResetConfirmEndpoint,
      data: request.toJson(),
    );

    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Register a new group
  ///
  /// Returns [AuthResponse] with success message
  /// Saves "Set-Cookie" headers for OTP verification
  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _apiClient.post(
      ApiConfig.registerEndpoint,
      data: request.toJson(),
    );

    // Extract cookies from response headers
    final cookies = response.headers['set-cookie'];
    if (cookies != null && cookies.isNotEmpty) {
      // Save joined cookies string
      final cookieString = cookies.join('; ');
      await _storageService.saveSessionCookies(cookieString);
    }

    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Verify OTP for registration
  ///
  /// Uses saved session cookies for identification
  Future<AuthResponse> verifyOtp(String otp) async {
    // Get saved cookies
    final cookies = await _storageService.getSessionCookies();

    final options = Options(headers: {if (cookies != null) 'Cookie': cookies});

    final response = await _apiClient.post(
      ApiConfig.verifyOtpEndpoint,
      data: {'otp': int.tryParse(otp) ?? otp},
      options: options,
    );

    // If verification successful, clear cookies
    await _storageService.deleteSessionCookies();

    // The response might contain tokens or just success message
    // Based on Postman, it returns data. Let's assume standard auth response.
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
