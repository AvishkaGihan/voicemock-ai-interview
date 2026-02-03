import 'package:equatable/equatable.dart';

import 'package:voicemock/features/interview/domain/domain.dart';

/// Base state for session management.
sealed class SessionState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initial state before any session operation.
class SessionInitial extends SessionState {}

/// Loading state while starting session.
class SessionLoading extends SessionState {}

/// Success state with active session.
class SessionSuccess extends SessionState {
  SessionSuccess({required this.session});
  final Session session;

  @override
  List<Object> get props => [session];
}

/// Failure state with error details.
class SessionFailure extends SessionState {
  SessionFailure({required this.failure});
  final InterviewFailure failure;

  @override
  List<Object> get props => [failure];
}
