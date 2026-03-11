import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../utilities/app_exception.dart';
import '../models/auth/password_reset_request.dart';
import '../models/auth/login_request.dart';
import '../models/auth/register_request.dart';
import '../services/auth_repository.dart';

import 'group_provider.dart';

/// Authentication State
class AuthState extends Equatable {
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;
  final String? successMessage;
  final String? role;
  final bool isFirstLogin;
  final bool isInitialized;
  final bool isLoggingOut;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
    this.successMessage,
    this.role,
    this.isFirstLogin = false,
    this.isInitialized = false,
    this.isLoggingOut = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
    String? successMessage,
    String? role,
    bool clearMessages = false,
    bool? isFirstLogin,
    bool? isInitialized,
    bool? isLoggingOut,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
      role: role ?? this.role,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isAuthenticated,
    errorMessage,
    successMessage,
    role,
    isFirstLogin,
    isInitialized,
    isLoggingOut,
  ];
}

/// Authentication Notifier (Riverpod 3.x compatible)
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  Future<void> initialize({Duration? minimumDuration}) async {
    final start = DateTime.now();
    try {
      final isAuth = await _authRepository.isAuthenticated();
      final role = await _authRepository.getRole();
      
      if (minimumDuration != null) {
        final elapsed = DateTime.now().difference(start);
        if (elapsed < minimumDuration) {
          await Future.delayed(minimumDuration - elapsed);
        }
      }

      state = state.copyWith(
        isAuthenticated: isAuth,
        role: role,
        isInitialized: true,
      );
    } catch (e) {
      if (minimumDuration != null) {
        final elapsed = DateTime.now().difference(start);
        if (elapsed < minimumDuration) {
          await Future.delayed(minimumDuration - elapsed);
        }
      }
      state = state.copyWith(isAuthenticated: false, isInitialized: true);
    }
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final tokenResponse = await _authRepository.login(
        LoginRequest(identifier: identifier, password: password),
      );
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        successMessage: 'Login successful!',
        role: tokenResponse.role,
        isFirstLogin: tokenResponse.isFirstLogin,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred during login',
      );
    }
  }

  Future<void> firstLoginChangePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final response = await _authRepository.firstLoginChangePassword(
        newPassword,
        confirmPassword,
      );
      state = state.copyWith(
        isLoading: false,
        isFirstLogin: false, // Update flag after success
        successMessage: response.message ?? 'Password changed successfully!',
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred while changing password.',
      );
    }
  }

  Future<void> register({
    required String groupName,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
    required int planId,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
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
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Registration successful! Please verify OTP.',
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred during registration',
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _authRepository.verifyOtp(otp);
      
      // Fetch role after successful OTP verification
      final role = await _authRepository.getRole();
      
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        role: role,
        successMessage: 'OTP Verified! Login successful.',
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred during OTP verification',
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, isLoggingOut: true);
    try {
      await _authRepository.logout();
    } catch (_) {
      // Even if network fails, we should still clear local state
    } finally {
      state = const AuthState(isInitialized: true, isLoggingOut: false);
    }
  }

  Future<void> requestPasswordReset({required String identifier}) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final response = await _authRepository.requestPasswordReset(
        PasswordResetRequest(identifier: identifier),
      );
      state = state.copyWith(
        isLoading: false,
        successMessage:
            response.message ?? 'Password reset OTP sent to your email',
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  Future<void> confirmPasswordReset({
    required String identifier,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final response = await _authRepository.confirmPasswordReset(
        PasswordResetConfirmRequest(
          identifier: identifier,
          otp: otp,
          password1: newPassword,
          password2: confirmPassword,
        ),
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: response.message ?? 'Password reset successful!',
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  Future<void> refreshToken() async {
    try {
      await _authRepository.refreshAccessToken();
      state = state.copyWith(isAuthenticated: true);
    } on AppException catch (e) {
      state = state.copyWith(isAuthenticated: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        errorMessage: 'Session expired. Please login again.',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

// Auth-specific providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthRepository(apiService: apiService, storageService: storageService);
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Which auth view is currently displayed (login / register / forgotPassword)
enum AuthViewMode { login, register, forgotPassword }

class AuthViewNotifier extends Notifier<AuthViewMode> {
  @override
  AuthViewMode build() => AuthViewMode.login;

  void switchTo(AuthViewMode mode) => state = mode;
}

final authViewProvider = NotifierProvider<AuthViewNotifier, AuthViewMode>(
  AuthViewNotifier.new,
);
