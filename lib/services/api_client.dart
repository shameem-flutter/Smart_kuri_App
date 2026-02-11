import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:dio_retry_plus/dio_retry_plus.dart';
import '../utilities/api_config.dart';
import '../utilities/app_constants.dart';
import '../utilities/app_exception.dart';
import '../models/api_error.dart';
import 'storage_service.dart';

/// API Client
/// 
/// Centralized HTTP client using Dio with interceptors for:
/// - Automatic token injection
/// - Error handling and transformation
/// - Request/response logging
/// - Automatic retry with exponential backoff
class ApiClient {
  late final Dio _dio;
  final StorageService _storageService;

  ApiClient({
    required StorageService storageService,
    Dio? dio,
  }) : _storageService = storageService {
    _dio = dio ?? Dio();
    _configureDio();
  }

  /// Configure Dio with base options and interceptors
  void _configureDio() {
    // Base options
    _dio.options = BaseOptions(
      baseUrl: ApiConfig.basePath,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      validateStatus: (status) {
        return status != null && status >= 200 && status < 300;
      },
    );

    // Add interceptors in order
    _dio.interceptors.addAll([
      _baseUrlInterceptor(), // Add base URL interceptor
      _authInterceptor(),
      _retryInterceptor(),
      _errorInterceptor(),
      _loggingInterceptor(),
    ]);
  }

  /// Base URL Interceptor
  /// Ensures the correct base URL is used for every request
  Interceptor _baseUrlInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        options.baseUrl = ApiConfig.basePath;
        return handler.next(options);
      },
    );
  }

  /// Authentication Interceptor
  /// Automatically adds access token to requests
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get access token from storage
        final accessToken = await _storageService.getAccessToken();
        
        if (accessToken != null && accessToken.isNotEmpty) {
          // Add Bearer token to Authorization header
          options.headers['Authorization'] = 'Bearer $accessToken';
        }

        return handler.next(options);
      },
    );
  }

  /// Retry Interceptor
  /// Automatically retries failed requests with exponential backoff
  Interceptor _retryInterceptor() {
    return RetryInterceptor(
      dio: _dio,
      logPrint: (_) {},

      retries: ApiConfig.maxRetries,
      retryDelays: List.generate(
        ApiConfig.maxRetries,
        (index) => ApiConfig.retryDelay * (index + 1),
      ),
      toNoInternetPageNavigator: () async {
        // TODO: Handle no internet navigation if needed
        // For now, we just log it as we rely on global error handling

      },
    );
  }

  /// Error Interceptor
  /// Transforms Dio errors into application-specific exceptions
  Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        final appException = _handleError(error);
        return handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            error: appException,
            type: error.type,
          ),
        );
      },
    );
  }

  /// Logging Interceptor (Development only)
  /// Logs request and response details for debugging
  Interceptor _loggingInterceptor() {
    return PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
    );
  }

  /// Handle Dio errors and transform to app exceptions
  AppException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          AppConstants.networkErrorMessage,
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleResponseError(error);

      case DioExceptionType.cancel:
        return NetworkException('Request cancelled', originalError: error);

      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          return NetworkException(
            AppConstants.networkErrorMessage,
            originalError: error,
          );
        }
        return NetworkException(
          'Connection error occurred',
          originalError: error,
        );

      default:
        return NetworkException(
          AppConstants.unknownErrorMessage,
          originalError: error,
        );
    }
  }

  /// Handle HTTP response errors
  AppException _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // Parse error from response
    ApiError apiError;
    try {
      if (data is Map<String, dynamic>) {
        apiError = ApiError.fromJson(data, statusCode: statusCode);
      } else if (data is String) {
        apiError = ApiError(
          message: data,
          statusCode: statusCode,
        );
      } else {
        apiError = ApiError(
          message: AppConstants.serverErrorMessage,
          statusCode: statusCode,
          details: data,
        );
      }
    } catch (e) {
      apiError = ApiError(
        message: 'Failed to parse error response',
        statusCode: statusCode,
        details: e.toString(),
      );
    }

    // Map status codes to specific exceptions
    switch (statusCode) {
      case 400:
        if (apiError.hasFieldErrors) {
          return ValidationException(
            apiError.userMessage,
            code: apiError.code,
            fieldErrors: apiError.fieldErrors,
            originalError: error,
          );
        }
        return ClientException(
          apiError.userMessage,
          code: apiError.code,
          originalError: error,
        );

      case 401:
        return UnauthorizedException(
          apiError.userMessage,
          code: apiError.code,
          originalError: error,
        );

      case 403:
        return AuthException(
          apiError.userMessage,
          code: apiError.code,
          originalError: error,
        );

      case 404:
        return NotFoundException(
          apiError.userMessage,
          code: apiError.code,
          originalError: error,
        );

      case 422:
        return ValidationException(
          apiError.userMessage,
          code: apiError.code,
          fieldErrors: apiError.fieldErrors,
          originalError: error,
        );

      default:
        if (statusCode != null && statusCode >= 500) {
          return ServerException(
            AppConstants.serverErrorMessage,
            code: apiError.code,
            originalError: error,
          );
        }
        return ClientException(
          apiError.userMessage,
          code: apiError.code,
          originalError: error,
        );
    }
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }
}
