import 'package:equatable/equatable.dart';
import 'package:voicemock/core/models/models.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// Sealed class representing all possible states of the interview flow.
///
/// Each state corresponds to a specific stage in the voice turn loop and
/// contains the relevant data needed for that stage.
sealed class InterviewState extends Equatable {
  const InterviewState();

  /// Returns the current stage of the interview.
  InterviewStage get stage;

  @override
  List<Object?> get props => [];
}

/// Initial state - not currently in an active interview session.
class InterviewIdle extends InterviewState {
  const InterviewIdle();

  @override
  InterviewStage get stage => InterviewStage.ready;
}

/// Ready state - waiting for user to start recording their answer.
class InterviewReady extends InterviewState {
  const InterviewReady({
    required this.questionNumber,
    required this.totalQuestions,
    required this.questionText,
    this.previousTranscript,
    this.coachingFeedback,
    this.wasInterrupted = false,
    this.lastTtsAudioUrl = '',
  });

  final int questionNumber;
  final int totalQuestions;
  final String questionText;
  final String? previousTranscript;
  final CoachingFeedback? coachingFeedback;
  final bool wasInterrupted;
  final String lastTtsAudioUrl;

  @override
  InterviewStage get stage => InterviewStage.ready;

  @override
  List<Object?> get props => [
    questionNumber,
    totalQuestions,
    questionText,
    previousTranscript,
    coachingFeedback,
    wasInterrupted,
    lastTtsAudioUrl,
  ];
}

/// Recording state - user is actively recording their answer.
class InterviewRecording extends InterviewState {
  const InterviewRecording({
    required this.questionNumber,
    required this.totalQuestions,
    required this.questionText,
    required this.recordingStartTime,
  });

  final int questionNumber;
  final int totalQuestions;
  final String questionText;
  final DateTime recordingStartTime;

  @override
  InterviewStage get stage => InterviewStage.recording;

  @override
  List<Object?> get props => [
    questionNumber,
    totalQuestions,
    questionText,
    recordingStartTime,
  ];
}

/// Uploading state - audio file is being uploaded to backend.
class InterviewUploading extends InterviewState {
  const InterviewUploading({
    required this.questionNumber,
    required this.totalQuestions,
    required this.questionText,
    required this.audioPath,
    required this.startTime,
  });

  final int questionNumber;
  final int totalQuestions;
  final String questionText;
  final String audioPath;
  final DateTime startTime;

  @override
  InterviewStage get stage => InterviewStage.uploading;

  @override
  List<Object?> get props => [
    questionNumber,
    totalQuestions,
    questionText,
    audioPath,
    startTime,
  ];
}

/// Transcribing state - speech-to-text transcription in progress.
class InterviewTranscribing extends InterviewState {
  const InterviewTranscribing({
    required this.questionNumber,
    required this.totalQuestions,
    required this.questionText,
    required this.startTime,
  });

  final int questionNumber;
  final int totalQuestions;
  final String questionText;
  final DateTime startTime;

  @override
  InterviewStage get stage => InterviewStage.transcribing;

  @override
  List<Object?> get props => [
    questionNumber,
    totalQuestions,
    questionText,
    startTime,
  ];
}

/// Transcript review state - user reviews STT output before proceeding.
class InterviewTranscriptReview extends InterviewState {
  const InterviewTranscriptReview({
    required this.questionNumber,
    required this.totalQuestions,
    required this.questionText,
    required this.transcript,
    required this.audioPath,
    this.isLowConfidence = false,
    this.assistantText,
    this.ttsAudioUrl = '',
    this.coachingFeedback,
    this.isComplete = false,
  });

  final int questionNumber;
  final int totalQuestions;
  final String questionText;
  final String transcript;
  final String audioPath;
  final bool isLowConfidence;
  final String? assistantText;
  final String ttsAudioUrl;
  final CoachingFeedback? coachingFeedback;
  final bool isComplete;

  @override
  InterviewStage get stage => InterviewStage.transcriptReview;

  @override
  List<Object?> get props => [
    questionNumber,
    totalQuestions,
    questionText,
    transcript,
    audioPath,
    isLowConfidence,
    assistantText,
    ttsAudioUrl,
    coachingFeedback,
    isComplete,
  ];
}

/// Thinking state - LLM is generating the next response.
class InterviewThinking extends InterviewState {
  const InterviewThinking({
    required this.questionNumber,
    required this.totalQuestions,
    required this.questionText,
    required this.transcript,
    required this.startTime,
    this.coachingFeedback,
  });

  final int questionNumber;
  final int totalQuestions;
  final String questionText;
  final String transcript;
  final DateTime startTime;
  final CoachingFeedback? coachingFeedback;

  @override
  InterviewStage get stage => InterviewStage.thinking;

  @override
  List<Object?> get props => [
    questionNumber,
    totalQuestions,
    questionText,
    transcript,
    startTime,
    coachingFeedback,
  ];
}

/// Speaking state - TTS audio is playing (coach is speaking).
class InterviewSpeaking extends InterviewState {
  const InterviewSpeaking({
    required this.questionNumber,
    required this.totalQuestions,
    required this.questionText,
    required this.transcript,
    required this.responseText,
    required this.ttsAudioUrl,
    this.coachingFeedback,
    this.isPaused = false,
    this.isBuffering = false,
  });

  final int questionNumber;
  final int totalQuestions;
  final String questionText;
  final String transcript;
  final String responseText;
  final String ttsAudioUrl;
  final CoachingFeedback? coachingFeedback;
  final bool isPaused;
  final bool isBuffering;

  @override
  InterviewStage get stage => InterviewStage.speaking;

  @override
  List<Object?> get props => [
    questionNumber,
    totalQuestions,
    questionText,
    transcript,
    responseText,
    ttsAudioUrl,
    coachingFeedback,
    isPaused,
    isBuffering,
  ];
}

/// Session complete state - all questions answered.
class InterviewSessionComplete extends InterviewState {
  const InterviewSessionComplete({
    required this.totalQuestions,
    required this.lastTranscript,
    this.lastResponseText,
  });

  final int totalQuestions;
  final String lastTranscript;
  final String? lastResponseText;

  @override
  InterviewStage get stage => InterviewStage.sessionComplete;

  @override
  List<Object?> get props => [
    totalQuestions,
    lastTranscript,
    lastResponseText,
  ];
}

/// Error state - a recoverable error has occurred.
class InterviewError extends InterviewState {
  const InterviewError({
    required this.failure,
    required this.previousState,
    required this.failedStage,
    this.audioPath,
    this.transcript,
  });

  final InterviewFailure failure;
  final InterviewState previousState;
  final InterviewStage failedStage;
  final String? audioPath; // Preserved for upload/STT retry
  final String? transcript; // Preserved for LLM retry

  @override
  InterviewStage get stage => InterviewStage.error;

  @override
  List<Object?> get props => [
    failure,
    previousState,
    failedStage,
    audioPath,
    transcript,
  ];
}
