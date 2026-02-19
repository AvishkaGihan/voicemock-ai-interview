import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:voicemock/core/http/exceptions.dart';
import 'package:voicemock/core/models/models.dart';

/// HTTP client wrapper for VoiceMock API communication.
///
/// Handles request ID injection, logging, envelope parsing, and error mapping.
class ApiClient {
  ApiClient({required String baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    _dio.interceptors.addAll([
      _RequestIdInterceptor(_uuid),
      _LoggingInterceptor(),
    ]);
  }

  /// Factory constructor for testing with custom Dio instance.
  ApiClient.withDio(this._dio);

  final Dio _dio;
  final Uuid _uuid = const Uuid();

  String get baseUrl => _dio.options.baseUrl;

  /// Makes POST request and returns envelope-wrapped response.
  ///
  /// Throws [NetworkException] on connectivity issues.
  /// Throws [ServerException] on API error responses.
  Future<ApiEnvelope<T>> post<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        throw ServerException(
          message: 'Invalid response format',
          code: 'invalid_format',
          requestId: response.headers.value('x-request-id'),
        );
      }

      final envelope = ApiEnvelope<T>.fromJson(
        responseData,
        (json) => fromJson(json! as Map<String, dynamic>),
      );

      // Check for API-level errors in envelope
      if (envelope.isError) {
        throw ServerException(
          message: envelope.error!.messageSafe,
          code: envelope.error!.code,
          stage: envelope.error!.stage,
          retryable: envelope.error!.retryable,
          requestId: envelope.requestId,
        );
      }

      return envelope;
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw NetworkException(message: 'Unexpected error: $e');
    }
  }

  /// Makes multipart POST request with file upload.
  ///
  /// Used for uploading audio files or data to `/turn` endpoint.
  /// [filePath] and [fileFieldName] are optional if only sending fields.
  /// Throws [NetworkException] on connectivity issues.
  /// Throws [ServerException] on API error responses.
  Future<ApiEnvelope<T>> postMultipart<T>(
    String path, {
    required Map<String, String> fields,
    required T Function(Map<String, dynamic>) fromJson,
    String? filePath,
    String? fileFieldName,
    String? bearerToken,
  }) async {
    try {
      final map = Map<String, dynamic>.from(fields);
      if (filePath != null && fileFieldName != null) {
        map[fileFieldName] = await MultipartFile.fromFile(filePath);
      }

      final formData = FormData.fromMap(map);

      final options = Options(
        headers: {
          if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
        },
        receiveTimeout: const Duration(seconds: 60),
        // Longer timeout for uploads
      );

      final response = await _dio.post<dynamic>(
        path,
        data: formData,
        options: options,
      );

      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        throw ServerException(
          message: 'Invalid response format',
          code: 'invalid_format',
          requestId: response.headers.value('x-request-id'),
        );
      }

      final envelope = ApiEnvelope<T>.fromJson(
        responseData,
        (json) => fromJson(json! as Map<String, dynamic>),
      );

      // Check for API-level errors in envelope
      if (envelope.isError) {
        throw ServerException(
          message: envelope.error!.messageSafe,
          code: envelope.error!.code,
          stage: envelope.error!.stage,
          retryable: envelope.error!.retryable,
          requestId: envelope.requestId,
        );
      }

      return envelope;
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw NetworkException(message: 'Unexpected error: $e');
    }
  }

  /// Makes DELETE request and returns envelope-wrapped response.
  ///
  /// Throws [NetworkException] on connectivity issues.
  /// Throws [ServerException] on API error responses.
  Future<ApiEnvelope<T>> delete<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
    String? bearerToken,
    Duration? timeout,
  }) async {
    try {
      final options = Options(
        headers: {
          if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
        },
        receiveTimeout: timeout,
        sendTimeout: timeout,
      );

      final response = await _dio.delete<dynamic>(
        path,
        options: options,
      );

      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        throw ServerException(
          message: 'Invalid response format',
          code: 'invalid_format',
          requestId: response.headers.value('x-request-id'),
        );
      }

      final envelope = ApiEnvelope<T>.fromJson(
        responseData,
        (json) => fromJson(json! as Map<String, dynamic>),
      );

      if (envelope.isError) {
        throw ServerException(
          message: envelope.error!.messageSafe,
          code: envelope.error!.code,
          stage: envelope.error!.stage,
          retryable: envelope.error!.retryable,
          requestId: envelope.requestId,
        );
      }

      return envelope;
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw NetworkException(message: 'Unexpected error: $e');
    }
  }

  /// Maps Dio exceptions to domain exceptions.
  Exception _mapDioException(DioException e) {
    final requestId = e.response?.headers.value('x-request-id');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Request timed out. Please check your connection.',
          requestId: requestId,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Cannot connect to server. Please check your internet.',
          requestId: requestId,
        );

      case DioExceptionType.badResponse:
        // Try to parse error envelope from response
        if (e.response?.data is Map<String, dynamic>) {
          try {
            final envelope = ApiEnvelope<void>.fromJson(
              e.response!.data as Map<String, dynamic>,
              (json) {},
            );
            if (envelope.isError) {
              return ServerException(
                message: envelope.error!.messageSafe,
                code: envelope.error!.code,
                stage: envelope.error!.stage,
                retryable: envelope.error!.retryable,
                requestId: envelope.requestId,
              );
            }
          } on Exception catch (_) {
            // Fall through to generic error
          }
        }

        return ServerException(
          message: 'Server error: ${e.response?.statusMessage ?? "Unknown"}',
          code: 'http_${e.response?.statusCode}',
          requestId: requestId,
        );

      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Request was cancelled',
          requestId: requestId,
        );

      case DioExceptionType.unknown:
        return NetworkException(
          message: 'Network error: ${e.message}',
          requestId: requestId,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'SSL certificate error',
          requestId: requestId,
        );
    }
  }
}

/// Interceptor that adds X-Request-ID header to all requests.
class _RequestIdInterceptor extends Interceptor {
  _RequestIdInterceptor(this._uuid);
  final Uuid _uuid;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add X-Request-ID if not already present
    if (!options.headers.containsKey('X-Request-ID')) {
      options.headers['X-Request-ID'] = _uuid.v4();
    }
    super.onRequest(options, handler);
  }
}

/// Interceptor that logs HTTP requests and responses (redacts sensitive data).
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // HTTP request logging for debugging
    final method = options.method;
    final uri = options.uri;
    // Using print for HTTP request logging in development/debugging
    final logMessage = '[HTTP] → $method $uri';
    // HTTP logging intentionally uses print for development visibility
    log(logMessage, name: 'voicemock.http');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // HTTP response logging for debugging
    final req = response.requestOptions;
    final status = response.statusCode;
    // Using print for HTTP response logging in development/debugging
    final logMessage = '[HTTP] ← $status ${req.uri}';
    // HTTP logging intentionally uses print for development visibility
    log(logMessage, name: 'voicemock.http');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // HTTP error logging for debugging
    final req = err.requestOptions;
    // Using print for HTTP error logging in development/debugging
    final logMessage = '[HTTP] ✗ ${err.type} ${req.uri}';
    // HTTP logging intentionally uses print for development visibility
    log(logMessage, name: 'voicemock.http', error: err);
    super.onError(err, handler);
  }
}
