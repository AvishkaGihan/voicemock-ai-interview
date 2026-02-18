import 'package:json_annotation/json_annotation.dart';

part 'turn_models.g.dart';

/// Coaching rubric dimension score and tip.
@JsonSerializable()
class CoachingDimension {
  /// Creates a [CoachingDimension].
  const CoachingDimension({
    required this.label,
    required this.score,
    required this.tip,
  });

  /// Creates a [CoachingDimension] from JSON.
  factory CoachingDimension.fromJson(Map<String, dynamic> json) =>
      _$CoachingDimensionFromJson(json);

  /// Rubric dimension label (e.g., Clarity).
  final String label;

  /// Score from 1 to 5.
  final int score;

  /// Actionable short tip for this dimension.
  final String tip;

  /// Converts this [CoachingDimension] to JSON.
  Map<String, dynamic> toJson() => _$CoachingDimensionToJson(this);
}

/// Structured coaching feedback returned per turn.
@JsonSerializable()
class CoachingFeedback {
  /// Creates a [CoachingFeedback].
  const CoachingFeedback({
    required this.dimensions,
    required this.summaryTip,
  });

  /// Creates a [CoachingFeedback] from JSON.
  factory CoachingFeedback.fromJson(Map<String, dynamic> json) =>
      _$CoachingFeedbackFromJson(json);

  /// Rubric dimensions with score and tip.
  final List<CoachingDimension> dimensions;

  /// Most impactful one-line improvement tip.
  @JsonKey(name: 'summary_tip')
  final String summaryTip;

  /// Converts this [CoachingFeedback] to JSON.
  Map<String, dynamic> toJson() => _$CoachingFeedbackToJson(this);
}

/// Structured end-of-session summary returned on final turn.
@JsonSerializable()
class SessionSummary {
  /// Creates a [SessionSummary].
  const SessionSummary({
    required this.overallAssessment,
    required this.strengths,
    required this.improvements,
    required this.averageScores,
    this.recommendedActions = const <String>[],
  });

  /// Creates a [SessionSummary] from JSON.
  factory SessionSummary.fromJson(Map<String, dynamic> json) =>
      _$SessionSummaryFromJson(json);

  /// 2-3 sentence overall review.
  @JsonKey(name: 'overall_assessment')
  final String overallAssessment;

  /// Concrete strengths (1-3 items).
  final List<String> strengths;

  /// Growth-oriented improvements (1-3 items).
  final List<String> improvements;

  /// Per-dimension average scores.
  @JsonKey(name: 'average_scores')
  final Map<String, double> averageScores;

  /// Concrete next steps tied to rubric weaknesses (2-4 items when present).
  @JsonKey(name: 'recommended_actions', defaultValue: <String>[])
  final List<String> recommendedActions;

  /// Converts this [SessionSummary] to JSON.
  Map<String, dynamic> toJson() => _$SessionSummaryToJson(this);
}

/// Response data from POST /turn containing transcript and metadata.
@JsonSerializable()
class TurnResponseData {
  /// Creates a [TurnResponseData].
  const TurnResponseData({
    required this.transcript,
    required this.timings,
    required this.questionNumber,
    required this.totalQuestions,
    this.assistantText,
    this.ttsAudioUrl,
    this.coachingFeedback,
    this.sessionSummary,
    this.isComplete = false,
  });

  /// Creates a [TurnResponseData] from JSON.
  factory TurnResponseData.fromJson(Map<String, dynamic> json) =>
      _$TurnResponseDataFromJson(json);

  /// The transcribed text from the user's audio.
  final String transcript;

  /// The assistant's text response (LLM-generated follow-up question).
  @JsonKey(name: 'assistant_text')
  final String? assistantText;

  /// URL to the TTS audio file (null until TTS is integrated).
  @JsonKey(name: 'tts_audio_url')
  final String? ttsAudioUrl;

  /// Structured coaching feedback for this turn.
  @JsonKey(name: 'coaching_feedback')
  final CoachingFeedback? coachingFeedback;

  /// End-of-session summary (final turn only).
  @JsonKey(name: 'session_summary')
  final SessionSummary? sessionSummary;

  /// Timing information for each processing stage in milliseconds.
  final Map<String, double> timings;

  /// Whether this was the final turn (session complete).
  @JsonKey(name: 'is_complete')
  final bool isComplete;

  /// Current question number (1-indexed).
  @JsonKey(name: 'question_number')
  final int questionNumber;

  /// Total configured questions for the session.
  @JsonKey(name: 'total_questions')
  final int totalQuestions;

  /// Converts this [TurnResponseData] to JSON.
  Map<String, dynamic> toJson() => _$TurnResponseDataToJson(this);
}
