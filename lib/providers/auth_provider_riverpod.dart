import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
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
  final bool needsOnetimeSetup;
  final String? registrationEmail;
  final String? registrationPassword;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
    this.successMessage,
    this.role,
    this.isFirstLogin = false,
    this.isInitialized = false,
    this.isLoggingOut = false,
    this.needsOnetimeSetup = false,
    this.registrationEmail,
    this.registrationPassword,
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
    bool? needsOnetimeSetup,
    String? registrationEmail,
    String? registrationPassword,
    bool clearRegistrationCredentials = false,
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
      needsOnetimeSetup: needsOnetimeSetup ?? this.needsOnetimeSetup,
      registrationEmail: clearRegistrationCredentials
          ? null
          : (registrationEmail ?? this.registrationEmail),
      registrationPassword: clearRegistrationCredentials
          ? null
          : (registrationPassword ?? this.registrationPassword),
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
    needsOnetimeSetup,
    registrationEmail,
    registrationPassword,
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
      // Restore the persistent onetime-setup flag so the user is redirected
      // to the group-creation screen even after closing and reopening the app.
      bool needsSetup = isAuth
          ? await ref.read(storageServiceProvider).getNeedsOnetimeSetup()
          : false;

      // Self-healing: if the user is flagged for setup, verify if they still need it.
      if (isAuth && needsSetup) {
        if (role == 'member' || role == 'collector') {
          debugPrint(
            'Auth Init: Non-admin role detected, clearing setup flag.',
          );
          await completeOnetimeSetup();
          needsSetup = false;
        } else {
          try {
            final groupsResponse = await ref
                .read(apiServiceProvider)
                .getGroups();
            if (groupsResponse.count > 0) {
              debugPrint('Auth Init: Groups found, clearing stuck setup flag.');
              await completeOnetimeSetup();
              needsSetup = false;
            }
          } catch (e) {
            debugPrint('Auth Init: Group check failed (likely offline): $e');
          }
        }
      }

      if (minimumDuration != null) {
        final elapsed = DateTime.now().difference(start);
        if (elapsed < minimumDuration) {
          await Future.delayed(minimumDuration - elapsed);
        }
      }

      state = state.copyWith(
        isAuthenticated: isAuth,
        role: role,
        needsOnetimeSetup: needsSetup,
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
      final role = tokenResponse.role;
      bool needsSetup = await ref
          .read(storageServiceProvider)
          .getNeedsOnetimeSetup();

      // Self-healing: if the user is flagged for setup, verify if they still need it.
      if (needsSetup) {
        if (role == 'member' || role == 'collector') {
          await completeOnetimeSetup();
          needsSetup = false;
        } else {
          try {
            final groupsResponse = await ref
                .read(apiServiceProvider)
                .getGroups();
            if (groupsResponse.count > 0) {
              debugPrint(
                'Auth Login: Groups found, clearing stuck setup flag.',
              );
              await completeOnetimeSetup();
              needsSetup = false;
            }
          } catch (_) {}
        }
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        successMessage: 'Login successful!',
        role: role,
        isFirstLogin: tokenResponse.isFirstLogin,
        needsOnetimeSetup: needsSetup,
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
    required String name,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final response = await _authRepository.register(
        RegisterRequest(
          name: name,
          phone: phone,
          email: email,
          password: password,
          confirmPassword: confirmPassword,
        ),
      );
      state = state.copyWith(
        isLoading: false,
        successMessage:
            response.message ?? 'Registration successful! Please verify OTP.',
        registrationEmail: email,
        registrationPassword: password,
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

      if (state.registrationEmail != null &&
          state.registrationPassword != null) {
        final tokenResponse = await _authRepository.login(
          LoginRequest(
            identifier: state.registrationEmail!,
            password: state.registrationPassword!,
          ),
        );
        // Persist the flag so it survives app kill/reopen.
        await ref.read(storageServiceProvider).setNeedsOnetimeSetup(true);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          successMessage: 'OTP Verified! Login successful.',
          role: tokenResponse.role,
          isFirstLogin: tokenResponse.isFirstLogin,
          needsOnetimeSetup: true,
          clearRegistrationCredentials: true,
        );
      } else {
        // Fallback
        final role = await _authRepository.getRole();
        final isAuth = await _authRepository.isAuthenticated();

        // Persist the flag so it survives app kill/reopen.
        await ref.read(storageServiceProvider).setNeedsOnetimeSetup(true);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: isAuth,
          role: role,
          successMessage: isAuth
              ? 'OTP Verified! Login successful.'
              : 'OTP Verified! Please log in.',
          needsOnetimeSetup: isAuth,
        );
      }
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

  Future<void> completeOnetimeSetup() async {
    state = state.copyWith(needsOnetimeSetup: false);
    // Clear persisted flag so re-opening the app goes straight to the dashboard.
    try {
      await ref.read(storageServiceProvider).clearNeedsOnetimeSetup();
    } catch (e) {
      debugPrint(
        'Warning: Failed to clear onetime setup storage flag, handled: $e',
      );
    }
  }

  Future<void> setNeedsOnetimeSetup(bool needsSetup) async {
    await ref.read(storageServiceProvider).setNeedsOnetimeSetup(needsSetup);
    state = state.copyWith(needsOnetimeSetup: needsSetup);
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
