import '../models/auth/login_request.dart';
import '../models/auth/register_request.dart';
import '../models/auth/password_reset_request.dart';
import '../models/auth/token_request.dart';
import '../models/auth/auth_response.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthRepository({
    required ApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService,
       _storageService = storageService;

  Future<TokenResponse> login(LoginRequest request) async {
    final tokenResponse = await _apiService.login(request);
    await _storageService.saveTokens(
      accessToken: tokenResponse.access,
      refreshToken: tokenResponse.refresh,
    );
    if (tokenResponse.role.isNotEmpty) {
      await _storageService.saveRole(tokenResponse.role);
    }
    await _storageService.setLoggedIn(true);
    return tokenResponse;
  }

  Future<TokenResponse> generateToken(TokenRequest request) async {
    final tokenResponse = await _apiService.generateToken(request);
    await _storageService.saveTokens(
      accessToken: tokenResponse.access,
      refreshToken: tokenResponse.refresh,
    );
    if (tokenResponse.role.isNotEmpty) {
      await _storageService.saveRole(tokenResponse.role);
    }
    await _storageService.setLoggedIn(true);
    return tokenResponse;
  }

  Future<TokenResponse> refreshAccessToken() async {
    final refreshToken = await _storageService.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('No refresh token available');
    }

    final request = TokenRefreshRequest(refresh: refreshToken);
    final response = await _apiService.refreshToken(request);

    await _storageService.saveAccessToken(response.access);
    return TokenResponse(access: response.access, refresh: refreshToken);
  }

  Future<AuthResponse> requestPasswordReset(
    PasswordResetRequest request,
  ) async {
    return await _apiService.requestPasswordReset(request);
  }

  Future<AuthResponse> confirmPasswordReset(
    PasswordResetConfirmRequest request,
  ) async {
    return await _apiService.confirmPasswordReset(request);
  }

  Future<void> logout() async {
    await _storageService.clearAll();
  }

  Future<bool> isAuthenticated() async {
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

  Future<String?> getRole() async {
    return await _storageService.getRole();
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    return await _apiService.register(request);
  }

  Future<AuthResponse> verifyOtp(String otp) async {
    final response = await _apiService.verifyOtp(otp);

    if (response.data != null && response.data!.containsKey('access')) {
      final tokenResponse = TokenResponse.fromJson(response.data!);
      await _storageService.saveTokens(
        accessToken: tokenResponse.access,
        refreshToken: tokenResponse.refresh,
      );
      if (tokenResponse.role.isNotEmpty) {
        await _storageService.saveRole(tokenResponse.role);
      }
      await _storageService.setLoggedIn(true);
    }

    return response;
  }
}
