import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session_models.g.dart';

/// Request payload for POST /session/start.
@JsonSerializable(createToJson: false)
class SessionStartRequest extends Equatable {
  const SessionStartRequest({
    required this.role,
    required this.interviewType,
    required this.difficulty,
    required this.questionCount,
  });

  factory SessionStartRequest.fromJson(Map<String, dynamic> json) =>
      _$SessionStartRequestFromJson(json);

  /// Job role (e.g., "Software Engineer").
  final String role;

  /// Interview type (e.g., "behavioral", "technical").
  final String interviewType;

  /// Difficulty level: "easy" | "medium" | "hard".
  final String difficulty;

  /// Number of questions in session (1-10).
  final int questionCount;

  /// Converts to JSON with snake_case keys for backend.
  Map<String, dynamic> toJson() => {
    'role': role,
    'interview_type': interviewType,
    'difficulty': difficulty,
    'question_count': questionCount,
  };

  @override
  List<Object> get props => [role, interviewType, difficulty, questionCount];
}

/// Response payload from POST /session/start.
@JsonSerializable(createFactory: false)
class SessionStartResponse extends Equatable {
  const SessionStartResponse({
    required this.sessionId,
    required this.sessionToken,
    required this.openingPrompt,
  });

  /// Parses from JSON with snake_case keys from backend.
  factory SessionStartResponse.fromJson(Map<String, dynamic> json) {
    return SessionStartResponse(
      sessionId: json['session_id'] as String,
      sessionToken: json['session_token'] as String,
      openingPrompt: json['opening_prompt'] as String,
    );
  }

  /// Unique session identifier.
  final String sessionId;

  /// Authentication token for subsequent requests.
  final String sessionToken;

  /// Opening message to display to user.
  final String openingPrompt;

  Map<String, dynamic> toJson() => _$SessionStartResponseToJson(this);

  @override
  List<Object> get props => [sessionId, sessionToken, openingPrompt];
}

/// Response payload from DELETE /session/{session_id}.
class DeleteSessionResponse extends Equatable {
  const DeleteSessionResponse({required this.deleted});

  factory DeleteSessionResponse.fromJson(Map<String, dynamic> json) {
    return DeleteSessionResponse(
      deleted: (json['deleted'] as bool?) ?? false,
    );
  }

  final bool deleted;

  @override
  List<Object> get props => [deleted];
}
