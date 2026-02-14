import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicemock/core/audio/recording_service.dart';
import 'package:voicemock/core/http/exceptions.dart';
import 'package:voicemock/core/permissions/permissions.dart';
import 'package:voicemock/features/interview/data/data.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_state.dart';

/// Cubit managing the interview state machine.
///
/// Implements the deterministic flow:
/// Ready → Recording → Uploading → Transcribing → Thinking → Speaking
/// → Ready (+ Error)
///
/// State transitions are guarded to prevent invalid combinations.
class InterviewCubit extends Cubit<InterviewState> {
  InterviewCubit({
    required RecordingService recordingService,
    required TurnRemoteDataSource turnRemoteDataSource,
    required String sessionId,
    required String sessionToken,
    PermissionService? permissionService,
    int questionNumber = 1,
    int totalQuestions = 5,
    String? initialQuestionText,
    Duration maxRecordingDuration = const Duration(seconds: 120),
  }) : _recordingService = recordingService,
       _turnRemoteDataSource = turnRemoteDataSource,
       _sessionId = sessionId,
       _sessionToken = sessionToken,
       _permissionService =
           permissionService ?? const MicrophonePermissionService(),
       _maxRecordingDuration = maxRecordingDuration,
       _totalQuestions = totalQuestions,
       super(
         initialQuestionText != null
             ? InterviewReady(
                 questionNumber: questionNumber,
                 totalQuestions: totalQuestions,
                 questionText: initialQuestionText,
               )
             : const InterviewIdle(),
       );

  final RecordingService _recordingService;
  final TurnRemoteDataSource _turnRemoteDataSource;
  final String _sessionId;
  final String _sessionToken;
  final PermissionService _permissionService;
  final Duration _maxRecordingDuration;
  final int _totalQuestions;
  Timer? _maxDurationTimer;

  /// Start recording - only valid from Ready state.
  ///
  /// Checks microphone permission before starting recording.
  /// If permission is not granted, emits an error state.
  Future<void> startRecording() async {
    final current = state;
    if (current is! InterviewReady) {
      _logInvalidTransition('startRecording', current);
      return;
    }

    try {
      // Check microphone permission before recording
      final permissionStatus = await _permissionService
          .checkMicrophonePermission();
      if (permissionStatus != MicrophonePermissionStatus.granted) {
        handleError(
          const RecordingFailure(
            message: 'Microphone permission is required to record audio',
          ),
        );
        return;
      }

      await _recordingService.startRecording();
      emit(
        InterviewRecording(
          questionNumber: current.questionNumber,
          totalQuestions: current.totalQuestions,
          questionText: current.questionText,
          recordingStartTime: DateTime.now(),
        ),
      );
      _logTransition('Recording');
      _startMaxDurationTimer();
    } on Object catch (e) {
      handleError(
        RecordingFailure(message: 'Failed to start recording: $e'),
      );
    }
  }

  /// Stop recording - only valid from Recording state.
  Future<void> stopRecording() async {
    final current = state;
    if (current is! InterviewRecording) {
      _logInvalidTransition('stopRecording', current);
      return;
    }

    _maxDurationTimer?.cancel();

    try {
      final audioPath = await _recordingService.stopRecording();
      if (audioPath == null || audioPath.isEmpty) {
        handleError(const RecordingFailure(message: 'No audio recorded'));
        return;
      }
      emit(
        InterviewUploading(
          questionNumber: current.questionNumber,
          questionText: current.questionText,
          audioPath: audioPath,
          startTime: DateTime.now(),
        ),
      );
      _logTransition('Uploading');

      // Automatically trigger turn submission
      unawaited(submitTurn());
    } on Object catch (e) {
      handleError(
        RecordingFailure(message: 'Failed to stop recording: $e'),
      );
    }
  }

  /// Submit the recorded turn for processing.
  ///
  /// Uploads the audio file and processes the transcript.
  /// Transitions: Uploading → Transcribing → TranscriptReview
  Future<void> submitTurn() async {
    final current = state;
    if (current is! InterviewUploading) {
      _logInvalidTransition('submitTurn', current);
      return;
    }

    try {
      // Call backend to process the turn
      final turnResponse = await _turnRemoteDataSource.submitTurn(
        audioPath: current.audioPath,
        sessionId: _sessionId,
        sessionToken: _sessionToken,
      );

      // Brief transition to Transcribing state
      emit(
        InterviewTranscribing(
          questionNumber: current.questionNumber,
          questionText: current.questionText,
          startTime: DateTime.now(),
        ),
      );
      _logTransition('Transcribing');

      // Detect low-confidence transcript (< 3 words)
      final wordCount = turnResponse.transcript
          .trim()
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .length;
      final isLowConfidence = wordCount < 3;

      // Transition to TranscriptReview instead of Thinking
      emit(
        InterviewTranscriptReview(
          questionNumber: current.questionNumber,
          questionText: current.questionText,
          transcript: turnResponse.transcript,
          audioPath: current.audioPath,
          isLowConfidence: isLowConfidence,
          assistantText: turnResponse.assistantText,
          isComplete: turnResponse.isComplete,
        ),
      );
      _logTransition(
        'TranscriptReview (transcript: ${turnResponse.transcript}, '
        'lowConfidence: $isLowConfidence, '
        'isComplete: ${turnResponse.isComplete})',
      );
    } on ServerException catch (e) {
      // Clean up audio on error
      await _cleanupAudioFile(current.audioPath);
      handleError(
        ServerFailure(
          message: e.message,
          code: e.code,
          stage: e.stage,
          retryable: e.retryable ?? false,
          requestId: e.requestId,
        ),
      );
    } on NetworkException catch (e) {
      // Clean up audio on error
      await _cleanupAudioFile(current.audioPath);
      handleError(NetworkFailure(message: e.message));
    } on Object catch (e) {
      // Clean up audio on error
      await _cleanupAudioFile(current.audioPath);
      handleError(
        ServerFailure(
          message: 'Failed to process turn: $e',
          code: 'unknown_error',
          retryable: true,
        ),
      );
    }
  }

  /// Accept the transcript and continue to thinking stage.
  /// Only valid from InterviewTranscriptReview state.
  Future<void> acceptTranscript() async {
    final current = state;
    if (current is! InterviewTranscriptReview) {
      _logInvalidTransition('acceptTranscript', current);
      return;
    }

    // Clean up audio file — no longer needed after acceptance
    await _cleanupAudioFile(current.audioPath);

    // Check if session is complete
    if (current.isComplete) {
      emit(
        InterviewSessionComplete(
          totalQuestions: _totalQuestions,
          lastTranscript: current.transcript,
          lastResponseText: current.assistantText,
        ),
      );
      _logTransition('Session complete');
      return;
    }

    // Transition to Thinking with accepted transcript
    emit(
      InterviewThinking(
        questionNumber: current.questionNumber,
        questionText: current.questionText,
        transcript: current.transcript,
        startTime: DateTime.now(),
      ),
    );
    _logTransition('Transcript accepted → Thinking');

    // Immediately transition to Speaking since we already have the LLM response
    if (current.assistantText != null) {
      onResponseReady(
        responseText: current.assistantText!,
        ttsAudioUrl: '', // No TTS yet (Story 3.1)
      );
    }
  }

  /// Re-record the answer — return to Ready with same question.
  /// Only valid from InterviewTranscriptReview state.
  Future<void> reRecord() async {
    final current = state;
    if (current is! InterviewTranscriptReview) {
      _logInvalidTransition('reRecord', current);
      return;
    }

    // Clean up previous audio file
    await _cleanupAudioFile(current.audioPath);

    emit(
      InterviewReady(
        questionNumber: current.questionNumber,
        totalQuestions: _totalQuestions,
        questionText: current.questionText,
      ),
    );

    _logTransition('Re-record requested → Ready');
  }

  /// Clean up temporary audio file from disk.
  /// Non-blocking — does not throw on failure.
  Future<void> _cleanupAudioFile(String path) async {
    try {
      await _recordingService.deleteRecording(path);
      developer.log(
        'Audio cleanup: deleted $path',
        name: 'InterviewCubit',
      );
    } on Object catch (e) {
      developer.log(
        'Audio cleanup failed: $e',
        name: 'InterviewCubit',
        level: 900, // warning
      );
      // Non-blocking — continue even if cleanup fails
    }
  }

  /// Cancel recording - only valid from Recording state.
  Future<void> cancelRecording() async {
    final current = state;
    if (current is! InterviewRecording) {
      _logInvalidTransition('cancelRecording', current);
      return;
    }

    _maxDurationTimer?.cancel();

    try {
      // stopRecording returns the path, which we then delete
      final path = await _recordingService.stopRecording();
      if (path != null && path.isNotEmpty) {
        await _recordingService.deleteRecording(path);
      }

      emit(
        InterviewReady(
          questionNumber: current.questionNumber,
          totalQuestions: current.totalQuestions,
          questionText: current.questionText,
        ),
      );
      _logTransition('Ready (cancelled)');
    } on Object catch (e) {
      developer.log(
        'InterviewCubit: Error cancelling recording: $e',
        name: 'InterviewCubit',
        level: 900,
      );
      // Still transition to Ready even if stop/delete fails
      emit(
        InterviewReady(
          questionNumber: current.questionNumber,
          totalQuestions: current.totalQuestions,
          questionText: current.questionText,
        ),
      );
    }
  }

  void _startMaxDurationTimer() {
    _maxDurationTimer = Timer(_maxRecordingDuration, () {
      developer.log(
        'InterviewCubit: Max recording duration reached, auto-stopping',
        name: 'InterviewCubit',
      );
      unawaited(stopRecording());
    });
  }

  /// Response ready - transition to Speaking.
  void onResponseReady({
    required String responseText,
    required String ttsAudioUrl,
  }) {
    final current = state;
    if (current is! InterviewThinking) {
      _logInvalidTransition('onResponseReady', current);
      return;
    }

    emit(
      InterviewSpeaking(
        questionNumber: current.questionNumber,
        questionText: current.questionText,
        transcript: current.transcript,
        responseText: responseText,
        ttsAudioUrl: ttsAudioUrl,
      ),
    );
    _logTransition('Speaking');
  }

  /// Speaking complete - transition back to Ready with next question.
  void onSpeakingComplete() {
    final current = state;
    if (current is! InterviewSpeaking) {
      _logInvalidTransition('onSpeakingComplete', current);
      return;
    }

    // The responseText IS the next question from the LLM
    emit(
      InterviewReady(
        questionNumber: current.questionNumber + 1,
        totalQuestions: _totalQuestions,
        questionText: current.responseText,
        previousTranscript: current.transcript,
      ),
    );
    _logTransition('Ready with next question');
  }

  /// Handle error - can occur from any active state.
  void handleError(InterviewFailure failure) {
    emit(
      InterviewError(
        failure: failure,
        previousState: state,
      ),
    );
    _logTransition('Error: ${failure.message}');
  }

  /// Retry from error state - restores previous state.
  void retry() {
    final current = state;
    if (current is! InterviewError) {
      _logInvalidTransition('retry', current);
      return;
    }
    // Restore to appropriate state based on failure stage
    emit(current.previousState);
    _logTransition('Retry → ${current.previousState.stage}');
  }

  /// Cancel interview - return to idle.
  Future<void> cancel() async {
    // Stop recording if currently recording
    if (await _recordingService.isRecording) {
      try {
        await _recordingService.stopRecording();
      } on Object catch (e) {
        developer.log(
          'InterviewCubit: Error stopping recording during cancel: $e',
          name: 'InterviewCubit',
          level: 900,
        );
      }
    }
    _maxDurationTimer?.cancel();
    emit(const InterviewIdle());
    _logTransition('Cancelled → Idle');
  }

  @override
  Future<void> close() async {
    _maxDurationTimer?.cancel();
    await _recordingService.dispose();
    return super.close();
  }

  void _logTransition(String to) {
    developer.log(
      'InterviewCubit: → $to',
      name: 'InterviewCubit',
    );
  }

  void _logInvalidTransition(String method, InterviewState current) {
    developer.log(
      'InterviewCubit: Invalid transition - $method called from '
      '${current.stage}',
      name: 'InterviewCubit',
      level: 900, // Warning level
    );
  }
}
