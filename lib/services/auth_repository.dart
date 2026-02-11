import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/password_reset_request.dart';
import '../models/token_request.dart';
import '../models/auth_response.dart';
import 'auth_api_service.dart';
import 'storage_service.dart';

/// Authentication Repository
/// 
/// Implements authentication operations by coordinating between
/// API service and storage service.
class AuthRepository {
  final AuthApiService _authApiService;
  final StorageService _storageService;

  AuthRepository({
    required AuthApiService authApiService,
    required StorageService storageService,
  })  : _authApiService = authApiService,
        _storageService = storageService;

  Future<TokenResponse> login(LoginRequest request) async {
    // Call login API
    final tokenResponse = await _authApiService.login(request);

    // Save tokens to secure storage
    await _storageService.saveTokens(
      accessToken: tokenResponse.access,
      refreshToken: tokenResponse.refresh,
    );

    // Mark as logged in
    await _storageService.setLoggedIn(true);

    return tokenResponse;
  }

  Future<TokenResponse> generateToken(TokenRequest request) async {
    // Generate tokens
    final tokenResponse = await _authApiService.generateToken(request);

    // Save tokens to secure storage
    await _storageService.saveTokens(
      accessToken: tokenResponse.access,
      refreshToken: tokenResponse.refresh,
    );

    // Mark as logged in
    await _storageService.setLoggedIn(true);

    return tokenResponse;
  }

  Future<TokenResponse> refreshAccessToken() async {
    // Get refresh token from storage
    final refreshToken = await _storageService.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('No refresh token available');
    }

    // Request new access token
    final request = TokenRefreshRequest(refresh: refreshToken);
    final response = await _authApiService.refreshToken(request);

    // Save new access token
    await _storageService.saveAccessToken(response.access);

    // Return as TokenResponse (keeping the same refresh token)
    return TokenResponse(
      access: response.access,
      refresh: refreshToken,
    );
  }

  Future<AuthResponse> requestPasswordReset(
    PasswordResetRequest request,
  ) async {
    return await _authApiService.requestPasswordReset(request);
  }

  Future<AuthResponse> confirmPasswordReset(
    PasswordResetConfirmRequest request,
  ) async {
    return await _authApiService.confirmPasswordReset(request);
  }

  Future<void> logout() async {
    // Clear all stored data
    await _storageService.clearAll();
  }

  Future<bool> isAuthenticated() async {
    // Check if user is logged in and has valid tokens
    final isLoggedIn = await _storageService.isLoggedIn();
    final accessToken = await _storageService.getAccessToken();

    return isLoggedIn && accessToken != null && accessToken.isNotEmpty;
  }

  Future<String?> getAccessToken() async {
    return await _storageService.getAccessToken();
  }

  Future<String?> getRefreshToken() async {
    return await _storageService.getRefreshToken();
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    return await _authApiService.register(request);
  }

  Future<AuthResponse> verifyOtp(String otp) async {
    final response = await _authApiService.verifyOtp(otp);
    
    // If verification is successful, we should mark the user as logged in
    // However, the verify-otp endpoint might just return success message without tokens
    // If it returns tokens in data, we should save them.
    // Based on the Postman response, it returns "status" and maybe "data".
    // Assuming for now it just verifies. 
    // If it returns tokens:
    if (response.data != null && response.data!.containsKey('access')) {
         final tokenResponse = TokenResponse.fromJson(response.data!);
         await _storageService.saveTokens(
            accessToken: tokenResponse.access,
            refreshToken: tokenResponse.refresh,
         );
         await _storageService.setLoggedIn(true);
    }
    
    return response;
  }
}
