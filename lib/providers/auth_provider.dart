import 'package:flutter/foundation.dart';
import '../utilities/app_exception.dart';
import '../models/password_reset_request.dart';

import '../models/login_request.dart';
import '../models/register_request.dart';
import '../services/auth_repository.dart';

/// Authentication State
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Authentication Provider
/// 
/// Manages authentication state and provides methods for auth operations.
/// Uses ChangeNotifier for reactive UI updates.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  AuthState _state = AuthState.initial;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated => _state == AuthState.authenticated;

  /// Initialize authentication state
  Future<void> initialize() async {
    try {
      final isAuth = await _authRepository.isAuthenticated();
      _state = isAuth ? AuthState.authenticated : AuthState.unauthenticated;
      notifyListeners();
    } catch (e) {
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  /// Login
  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    _setLoading();

    try {
      // use login endpoint directly as it returns tokens
      await _authRepository.login(
        LoginRequest(
          identifier: identifier,
          password: password,
        ),
      );

      _state = AuthState.authenticated;
      _errorMessage = null;
      _successMessage = 'Login successful!';
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.message);
    } catch (e, stackTrace) {
      debugPrint('Login Error: $e');
      debugPrint('Stack Trace: $stackTrace');
      _setError('An unexpected error occurred during login: ${e.toString()}');
    }
  }

  /// Register
  Future<void> register({
    required String groupName,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
    required int planId,
  }) async {
    _setLoading();

    try {
      await _authRepository.register(
        RegisterRequest(
          groupName: groupName,
          phone: phone,
          email: email,
          password: password,
          confirmPassword: confirmPassword,
          planId: planId,
        ),
      );

      // After successful registration, we might want to login automatically or show a success message
      // For now, let's assume we need to login manually or the backend returns tokens (if so, we should handle it like login)
      // The user request implies "implement this in register section also while logging in and signing up there should come CPI indicator"
      // I will assume registration returns a success message and user needs to login, OR if it returns tokens, we can set authenticated.
      // AuthApiService.register returns AuthResponse.
      // If AuthResponse contains tokens, we could use them. But AuthResponse usually has message.
      // Let's check AuthResponse model.

      _state = AuthState.initial; // Or authenticated if we auto-login
      _errorMessage = null;
      _successMessage = 'Registration successful! Please verify OTP.';
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.message);
    } catch (e, stackTrace) {
      debugPrint('Registration Error: $e');
      debugPrint('Stack Trace: $stackTrace');
      _setError('An unexpected error occurred during registration: ${e.toString()}');
    }
  }

  /// Verify OTP
  Future<void> verifyOtp(String otp) async {
    _setLoading();

    try {
      await _authRepository.verifyOtp(otp);

      _state = AuthState.authenticated;
      _errorMessage = null;
      _successMessage = 'OTP Verified! Login successful.';
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('An unexpected error occurred during OTP verification');
    }
  }

  /// Logout
  Future<void> logout() async {
    _setLoading();

    try {
      await _authRepository.logout();

      _state = AuthState.unauthenticated;
      _errorMessage = null;
      _successMessage = 'Logged out successfully!';
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('An unexpected error occurred during logout');
    }
  }

  /// Request password reset
  Future<void> requestPasswordReset({required String identifier}) async {
    _setLoading();

    try {
      final response = await _authRepository.requestPasswordReset(
        PasswordResetRequest(identifier: identifier),
      );

      _state = AuthState.initial;
      _errorMessage = null;
      _successMessage = response.message ?? 'Password reset OTP sent to your email';
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('An unexpected error occurred');
    }
  }

  /// Confirm password reset
  Future<void> confirmPasswordReset({
    required String identifier,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading();

    try {
      final response = await _authRepository.confirmPasswordReset(
        PasswordResetConfirmRequest(
          identifier: identifier,
          otp: otp,
          password1: newPassword,
          password2: confirmPassword,
        ),
      );

      _state = AuthState.initial;
      _errorMessage = null;
      _successMessage = response.message ?? 'Password reset successful!';
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('An unexpected error occurred');
    }
  }

  /// Refresh token
  Future<void> refreshToken() async {
    try {
      await _authRepository.refreshAccessToken();
      _state = AuthState.authenticated;
      notifyListeners();
    } on AppException catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = 'Session expired. Please login again.';
      notifyListeners();
    }
  }

  /// Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading() {
    _state = AuthState.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Set error state
  void _setError(String message) {
    _state = AuthState.error;
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }
}
