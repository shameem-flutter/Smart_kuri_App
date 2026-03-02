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
    // Save credentials for automatic token refresh
    await _storageService.saveCredentials(
      identifier: request.identifier,
      password: request.password,
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
    // Step 1: Try refreshing the access token using the refresh token
    final currentRefreshToken = await _storageService.getRefreshToken();
    if (currentRefreshToken != null && currentRefreshToken.isNotEmpty) {
      try {
        final refreshRequest = TokenRefreshRequest(refresh: currentRefreshToken);
        final refreshResponse = await _apiService.refreshToken(refreshRequest);
        await _storageService.saveAccessToken(refreshResponse.access);
        return TokenResponse(access: refreshResponse.access, refresh: currentRefreshToken);
      } catch (_) {
        // Refresh token might be expired, fall through to Step 2
      }
    }

    // Step 2: Fall back to token endpoint with stored credentials
    final identifier = await _storageService.getCredentialIdentifier();
    final password = await _storageService.getCredentialPassword();
    if (identifier == null || password == null) {
      throw Exception('No stored credentials for token refresh');
    }

    final tokenRequest = TokenRequest(username: identifier, password: password);
    final tokenResponse = await _apiService.generateToken(tokenRequest);
    await _storageService.saveTokens(
      accessToken: tokenResponse.access,
      refreshToken: tokenResponse.refresh,
    );
    return tokenResponse;
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
