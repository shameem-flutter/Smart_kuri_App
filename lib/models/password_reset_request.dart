import 'package:equatable/equatable.dart';

/// Password Reset Request Model
/// 
/// Represents the request payload for initiating password reset.
class PasswordResetRequest extends Equatable {
  final String identifier; // Email or username

  const PasswordResetRequest({
    required this.identifier,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
    };
  }

  @override
  List<Object?> get props => [identifier];

  @override
  String toString() => 'PasswordResetRequest(identifier: $identifier)';
}

/// Password Reset Confirm Model
/// 
/// Represents the request payload for confirming password reset with OTP.
class PasswordResetConfirmRequest extends Equatable {
  final String identifier;
  final String otp;
  final String password1;
  final String password2;

  const PasswordResetConfirmRequest({
    required this.identifier,
    required this.otp,
    required this.password1,
    required this.password2,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'otp': otp,
      'password1': password1,
      'password2': password2,
    };
  }

  @override
  List<Object?> get props => [identifier, otp, password1, password2];

  @override
  String toString() => 'PasswordResetConfirmRequest(identifier: $identifier, otp: $otp)';
}
