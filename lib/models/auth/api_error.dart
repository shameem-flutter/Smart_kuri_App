import 'package:equatable/equatable.dart';

/// API Error Model
/// 
/// Represents error responses from the API with structured error information.
class ApiError extends Equatable {
  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, List<String>>? fieldErrors;
  final dynamic details;

  const ApiError({
    required this.message,
    this.code,
    this.statusCode,
    this.fieldErrors,
    this.details,
  });

  /// Create from JSON error response
  factory ApiError.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    // Handle different error response formats
    String message = json['message'] as String? ??
        json['error'] as String? ??
        json['detail'] as String? ??
        'An error occurred';

    String? code = json['code'] as String? ?? json['error_code'] as String?;

    // Parse field-specific errors (validation errors)
    Map<String, List<String>>? fieldErrors;
    if (json.containsKey('errors') && json['errors'] is Map) {
      fieldErrors = {};
      final errors = json['errors'] as Map<String, dynamic>;
      errors.forEach((key, value) {
        if (value is List) {
          fieldErrors![key] = value.map((e) => e.toString()).toList();
        } else {
          fieldErrors![key] = [value.toString()];
        }
      });
    }

    return ApiError(
      message: message,
      code: code,
      statusCode: statusCode,
      fieldErrors: fieldErrors,
      details: json['details'],
    );
  }

  /// Get user-friendly error message
  String get userMessage {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      // Return first field error
      final firstError = fieldErrors!.values.first;
      return firstError.isNotEmpty ? firstError.first : message;
    }
    return message;
  }

  /// Check if error has field-specific errors
  bool get hasFieldErrors => fieldErrors != null && fieldErrors!.isNotEmpty;

  @override
  List<Object?> get props => [message, code, statusCode, fieldErrors, details];

  @override
  String toString() => 'ApiError(statusCode: $statusCode, code: $code, message: $message)';
}
