/// Base Application Exception
/// 
/// Custom exception hierarchy for better error handling and user feedback.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError});
}

/// Authentication-related exceptions
class AuthException extends AppException {
  AuthException(super.message, {super.code, super.originalError});
}

/// Validation-related exceptions
class ValidationException extends AppException {
  final Map<String, List<String>>? fieldErrors;

  ValidationException(
    super.message, {
    super.code,
    this.fieldErrors,
    super.originalError,
  });
}

/// Server error exceptions (5xx)
class ServerException extends AppException {
  ServerException(super.message, {super.code, super.originalError});
}

/// Client error exceptions (4xx)
class ClientException extends AppException {
  ClientException(super.message, {super.code, super.originalError});
}

/// Token expired exception
class TokenExpiredException extends AuthException {
  TokenExpiredException(super.message, {super.code, super.originalError});
}

/// Unauthorized exception
class UnauthorizedException extends AuthException {
  UnauthorizedException(super.message, {super.code, super.originalError});
}

/// Not found exception
class NotFoundException extends ClientException {
  NotFoundException(super.message, {super.code, super.originalError});
}

/// Timeout exception
class TimeoutException extends NetworkException {
  TimeoutException(super.message, {super.code, super.originalError});
}

/// Cache exception
class CacheException extends AppException {
  CacheException(super.message, {super.code, super.originalError});
}
