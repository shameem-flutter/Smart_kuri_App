import 'app_constants.dart';

/// Input Validators
/// 
/// Provides validation functions for form inputs with user-friendly error messages.
class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  /// Validates email or username
  /// Returns null if valid, error message if invalid
  static String? validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.emailRequiredMessage;
    }
    return null;
  }

  /// Validates email format
  /// Returns null if valid, error message if invalid
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.emailRequiredMessage;
    }

    if (!AppConstants.emailPattern.hasMatch(value.trim())) {
      return AppConstants.emailInvalidMessage;
    }

    return null;
  }

  /// Validates password
  /// Returns null if valid, error message if invalid
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.passwordRequiredMessage;
    }

    if (value.length < 8) {
      return AppConstants.passwordMinLengthMessage;
    }

    return null;
  }

  /// Validates password confirmation
  /// Returns null if valid, error message if invalid
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return AppConstants.passwordRequiredMessage;
    }

    if (value != password) {
      return AppConstants.passwordMismatchMessage;
    }

    return null;
  }

  /// Validates OTP
  /// Returns null if valid, error message if invalid
  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.otpRequiredMessage;
    }

    if (!AppConstants.otpPattern.hasMatch(value.trim())) {
      return AppConstants.otpInvalidMessage;
    }

    return null;
  }

  /// Generic required field validator
  /// Returns null if valid, error message if invalid
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
