import 'package:equatable/equatable.dart';
import 'package:voicemock/features/interview/domain/difficulty_level.dart';
import 'package:voicemock/features/interview/domain/interview_role.dart';
import 'package:voicemock/features/interview/domain/interview_type.dart';

/// Configuration for an interview practice session.
///
/// Holds all user selections made before starting an interview,
/// including role, type, difficulty, and question count.
class InterviewConfig extends Equatable {
  const InterviewConfig({
    required this.role,
    required this.type,
    required this.difficulty,
    required this.questionCount,
  }) : assert(
         questionCount >= minQuestionCount && questionCount <= maxQuestionCount,
         'Question count must be between '
         '$minQuestionCount and $maxQuestionCount',
       );

  /// Creates an interview config with default values.
  factory InterviewConfig.defaults() {
    return const InterviewConfig(
      role: InterviewRole.softwareEngineer,
      type: InterviewType.behavioral,
      difficulty: DifficultyLevel.medium,
      questionCount: defaultQuestionCount,
    );
  }

  /// Minimum allowed question count
  static const int minQuestionCount = 5;

  /// Maximum allowed question count
  static const int maxQuestionCount = 10;

  /// Default question count
  static const int defaultQuestionCount = 5;

  /// The target job role for the interview
  final InterviewRole role;

  /// The type of interview (behavioral or technical)
  final InterviewType type;

  /// The difficulty level of questions
  final DifficultyLevel difficulty;

  /// Number of questions in the session (5-10)
  final int questionCount;

  /// Creates a copy with the specified changes.
  InterviewConfig copyWith({
    InterviewRole? role,
    InterviewType? type,
    DifficultyLevel? difficulty,
    int? questionCount,
  }) {
    return InterviewConfig(
      role: role ?? this.role,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      questionCount: questionCount ?? this.questionCount,
    );
  }

  @override
  List<Object?> get props => [role, type, difficulty, questionCount];
}
