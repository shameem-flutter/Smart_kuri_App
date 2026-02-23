import 'package:equatable/equatable.dart';

/// Authentication Response Model
/// 
/// Represents a generic authentication response from the API.
class AuthResponse extends Equatable {
  final String? message;
  final Map<String, dynamic>? data;
  final bool success;

  const AuthResponse({
    this.message,
    this.data,
    this.success = true,
  });

  /// Create from JSON response
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      success: json['success'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [message, data, success];

  @override
  String toString() => 'AuthResponse(success: $success, message: $message)';
}

/// Token Response Model
/// 
/// Represents the JWT token response from the API.
class TokenResponse extends Equatable {
  final String access;
  final String refresh;
  final String username;
  final String role;

  const TokenResponse({
    required this.access,
    required this.refresh,
    this.username = '',
    this.role = '',
  });

  /// Create from JSON response
  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'access': access,
      'refresh': refresh,
      'username': username,
      'role': role,
    };
  }

  @override
  List<Object?> get props => [access, refresh, username, role];

  @override
  String toString() => 'TokenResponse(access: ${access.substring(0, 20)}..., refresh: ${refresh.substring(0, 20)}..., username: $username, role: $role)';
}

/// Token Refresh Response Model
/// 
/// Represents the response when refreshing access token.
class TokenRefreshResponse extends Equatable {
  final String access;

  const TokenRefreshResponse({
    required this.access,
  });

  /// Create from JSON response
  factory TokenRefreshResponse.fromJson(Map<String, dynamic> json) {
    return TokenRefreshResponse(
      access: json['access'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'access': access,
    };
  }

  @override
  List<Object?> get props => [access];

  @override
  String toString() => 'TokenRefreshResponse(access: ${access.substring(0, 20)}...)';
}
