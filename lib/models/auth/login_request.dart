import 'package:equatable/equatable.dart';

/// Login Request Model
/// 
/// Represents the request payload for user login.
class LoginRequest extends Equatable {
  final String identifier; // Email or username
  final String password;

  const LoginRequest({
    required this.identifier,
    required this.password,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'password': password,
    };
  }

  @override
  List<Object?> get props => [identifier, password];

  @override
  String toString() => 'LoginRequest(identifier: $identifier)';
}
