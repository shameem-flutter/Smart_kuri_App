import 'package:equatable/equatable.dart';

/// Token Request Model
/// 
/// Represents the request payload for generating JWT tokens.
class TokenRequest extends Equatable {
  final String username;
  final String password;

  const TokenRequest({
    required this.username,
    required this.password,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }

  @override
  List<Object?> get props => [username, password];

  @override
  String toString() => 'TokenRequest(username: $username)';
}

/// Token Refresh Request Model
/// 
/// Represents the request payload for refreshing access token.
class TokenRefreshRequest extends Equatable {
  final String refresh;

  const TokenRefreshRequest({
    required this.refresh,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'refresh': refresh,
    };
  }

  @override
  List<Object?> get props => [refresh];

  @override
  String toString() => 'TokenRefreshRequest(refresh: ${refresh.substring(0, 20)}...)';
}
