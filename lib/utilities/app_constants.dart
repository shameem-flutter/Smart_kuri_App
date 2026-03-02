/// Application Constants
/// 
/// Contains all application-wide constants including storage keys,
/// validation patterns, and error messages.
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';
  static const String emailKey = 'email';
  static const String roleKey = 'role';
  static const String isLoggedInKey = 'is_logged_in';
  static const String credentialIdentifierKey = 'credential_identifier';
  static const String credentialPasswordKey = 'credential_password';

  // Validation Patterns
  static final RegExp emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp passwordPattern = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$',
  );

  static final RegExp otpPattern = RegExp(r'^\d{6}$');

  // Validation Messages
  static const String emailRequiredMessage = 'Email or username is required';
  static const String emailInvalidMessage = 'Please enter a valid email';
  static const String passwordRequiredMessage = 'Password is required';
  static const String passwordMinLengthMessage = 'Password must be at least 8 characters';
  static const String passwordWeakMessage = 'Password must contain letters and numbers';
  static const String passwordMismatchMessage = 'Passwords do not match';
  static const String otpRequiredMessage = 'OTP is required';
  static const String otpInvalidMessage = 'OTP must be 6 digits';

  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unknownErrorMessage = 'An unexpected error occurred.';
  static const String sessionExpiredMessage = 'Session expired. Please login again.';
  static const String invalidCredentialsMessage = 'Invalid credentials. Please try again.';

  // Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String logoutSuccessMessage = 'Logged out successfully!';
  static const String passwordResetRequestSuccessMessage = 'Password reset OTP sent to your email.';
  static const String passwordResetSuccessMessage = 'Password reset successful!';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double buttonHeight = 56.0;
}
