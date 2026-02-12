import 'package:equatable/equatable.dart';

/// Base class for domain-level failures in interview feature.
sealed class InterviewFailure extends Equatable {
  const InterviewFailure({
    required this.message,
    this.requestId,
    this.retryable = false,
  });
  final String message;
  final String? requestId;
  final bool retryable;

  @override
  List<Object?> get props => [message, requestId, retryable];
}

/// Network connectivity failure.
class NetworkFailure extends InterviewFailure {
  const NetworkFailure({
    required super.message,
    super.requestId,
    super.retryable = true,
  });
}

/// Server-side error (4xx/5xx responses).
class ServerFailure extends InterviewFailure {
  const ServerFailure({
    required super.message,
    super.requestId,
    super.retryable,
    this.stage,
  });
  final String? stage;

  @override
  List<Object?> get props => [...super.props, stage];
}

/// Validation error (invalid input).
class ValidationFailure extends InterviewFailure {
  const ValidationFailure({
    required super.message,
    super.requestId,
    super.retryable = false,
    this.details,
  });
  final Map<String, dynamic>? details;

  @override
  List<Object?> get props => [...super.props, details];
}

/// Unknown or unexpected error.
class UnknownFailure extends InterviewFailure {
  const UnknownFailure({
    required super.message,
    super.requestId,
    super.retryable = false,
  });
}

/// Recording failure (microphone capture errors).
class RecordingFailure extends InterviewFailure {
  const RecordingFailure({
    required super.message,
    super.requestId,
    super.retryable = true,
  });

  String get stage => 'recording';

  @override
  List<Object?> get props => [...super.props, stage];
}
