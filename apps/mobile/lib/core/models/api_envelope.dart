import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_envelope.g.dart';

/// Generic API response envelope wrapping all JSON endpoints.
///
/// Enforces mutual exclusion: exactly one of [data] or [error]
/// must be non-null.
@JsonSerializable(genericArgumentFactories: true)
class ApiEnvelope<T> extends Equatable {
  const ApiEnvelope({
    required this.data,
    required this.error,
    required this.requestId,
  });

  /// Factory constructor for JSON deserialization.
  ///
  /// Requires a [fromJsonT] function to deserialize the generic data type.
  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiEnvelopeFromJson(json, fromJsonT);

  /// Response payload on success (null if error occurred).
  final T? data;

  /// Error details on failure (null if success).
  final ApiError? error;

  /// Unique request identifier for tracing.
  @JsonKey(name: 'request_id')
  final String requestId;

  /// Returns true if response contains data (success case).
  bool get isSuccess => data != null && error == null;

  /// Returns true if response contains error (failure case).
  bool get isError => error != null && data == null;

  /// Converts envelope to JSON map.
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiEnvelopeToJson(this, toJsonT);

  @override
  List<Object?> get props => [data, error, requestId];
}

/// Structured error details from API.
@JsonSerializable()
class ApiError extends Equatable {
  const ApiError({
    required this.code,
    required this.stage,
    required this.messageSafe,
    this.retryable,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);

  /// Machine-readable error code (e.g., "validation_error", "internal_error").
  final String code;

  /// Stage where error occurred: upload | stt | llm | tts | unknown.
  final String stage;

  /// User-safe error message for display.
  @JsonKey(name: 'message_safe')
  final String messageSafe;

  /// Indicates if operation can be retried.
  final bool? retryable;

  /// Optional structured error details.
  final Map<String, dynamic>? details;

  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);

  @override
  List<Object?> get props => [code, stage, messageSafe, retryable, details];
}
