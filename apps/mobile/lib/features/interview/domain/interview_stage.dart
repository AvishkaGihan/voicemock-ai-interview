/// Interview state machine stages.
///
/// Defines the deterministic flow through the voice turn loop:
/// Ready → Recording → Uploading → Transcribing → TranscriptReview → Thinking
/// → Speaking → Ready (+ Error + SessionComplete)
enum InterviewStage {
  /// Waiting for user to record - mic available
  ready,

  /// User is actively recording audio
  recording,

  /// Audio file is being uploaded to backend
  uploading,

  /// Speech-to-text transcription in progress
  transcribing,

  /// User reviewing transcript before continuing
  transcriptReview,

  /// LLM is generating the next response
  thinking,

  /// TTS audio is playing - coach is speaking
  speaking,

  /// Session complete - all questions answered
  sessionComplete,

  /// Recoverable error occurred
  error,
}

/// Extension providing helper methods for [InterviewStage].
extension InterviewStageX on InterviewStage {
  /// Returns true if the stage represents backend processing.
  ///
  /// Processing stages: uploading, transcribing, thinking.
  bool get isProcessing =>
      this == InterviewStage.uploading ||
      this == InterviewStage.transcribing ||
      this == InterviewStage.thinking;

  /// Returns true if it's the user's turn to interact.
  ///
  /// User turn: ready, recording.
  bool get isUserTurn =>
      this == InterviewStage.ready || this == InterviewStage.recording;

  /// Returns true if it's the coach's turn (speaking).
  bool get isCoachTurn => this == InterviewStage.speaking;
}
