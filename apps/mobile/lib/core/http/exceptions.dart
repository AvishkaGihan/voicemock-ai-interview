/// HTTP client exceptions for network layer.
library;

/// Exception thrown when network connectivity issues occur.
class NetworkException implements Exception {
  NetworkException({required this.message, this.requestId});
  final String message;
  final String? requestId;

  @override
  String toString() => 'NetworkException: $message (requestId: $requestId)';
}

/// Exception thrown when server returns error response.
class ServerException implements Exception {
  ServerException({
    required this.message,
    required this.code,
    this.stage,
    this.retryable,
    this.requestId,
  });
  final String message;
  final String code;
  final String? stage;
  final bool? retryable;
  final String? requestId;

  @override
  String toString() =>
      'ServerException: $code - $message '
      '(stage: $stage, requestId: $requestId)';
}
