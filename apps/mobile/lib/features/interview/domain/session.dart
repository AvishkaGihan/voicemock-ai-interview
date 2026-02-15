import 'package:equatable/equatable.dart';

/// Domain entity representing an active interview session.
class Session extends Equatable {
  const Session({
    required this.sessionId,
    required this.sessionToken,
    required this.openingPrompt,
    required this.totalQuestions,
    required this.createdAt,
  });

  /// Unique session identifier.
  final String sessionId;

  /// Authentication token for API requests.
  final String sessionToken;

  /// Opening prompt text displayed to user.
  final String openingPrompt;

  /// Total number of questions in this interview session.
  final int totalQuestions;

  /// Timestamp when session was created.
  final DateTime createdAt;

  @override
  List<Object> get props => [
    sessionId,
    sessionToken,
    openingPrompt,
    totalQuestions,
    createdAt,
  ];
}
