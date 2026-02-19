import 'dart:async' show StreamSubscription, Timer, unawaited;
import 'dart:developer' as developer;

import 'package:audio_session/audio_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicemock/core/audio/audio_focus_service.dart';
import 'package:voicemock/core/audio/playback_service.dart';
import 'package:voicemock/core/audio/recording_service.dart';
import 'package:voicemock/core/http/exceptions.dart';
import 'package:voicemock/core/models/models.dart';
import 'package:voicemock/core/models/session_diagnostics.dart';
import 'package:voicemock/core/models/turn_timing_record.dart';
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
    required AudioFocusService audioFocusService,
    String apiBaseUrl = 'http://localhost:8080',
    PlaybackService? playbackService,
    PermissionService? permissionService,
    int questionNumber = 1,
    int totalQuestions = 5,
    String? initialQuestionText,
    Duration maxRecordingDuration = const Duration(seconds: 120),
  }) : _recordingService = recordingService,
       _turnRemoteDataSource = turnRemoteDataSource,
       _sessionId = sessionId,
       _sessionToken = sessionToken,
       _audioFocusService = audioFocusService,
       _apiBaseUrl = apiBaseUrl,
       _playbackService = playbackService ?? PlaybackService.noop(),
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
       ) {
    // Initialize diagnostics for the session
    _diagnostics = SessionDiagnostics(sessionId: sessionId);

    // Subscribe to audio interruption events
    _audioInterruptionSubscription = _audioFocusService.interruptions.listen(
      _onAudioInterruption,
    );
  }

  final RecordingService _recordingService;
  final TurnRemoteDataSource _turnRemoteDataSource;
  final String _sessionId;
  final String _sessionToken;
  final AudioFocusService _audioFocusService;
  final String _apiBaseUrl;
  final PlaybackService _playbackService;
  final PermissionService _permissionService;
  final Duration _maxRecordingDuration;
  final int _totalQuestions;
  Timer? _maxDurationTimer;
  StreamSubscription<AudioInterruptionEvent>? _audioInterruptionSubscription;
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;
  String _lastTtsAudioUrl = '';
  String _lastResponseText = '';
  bool _isReplaying = false;

  /// Session diagnostics for timing and error tracking.
  late SessionDiagnostics _diagnostics;

  /// Public getter for diagnostics data.
  SessionDiagnostics get diagnostics => _diagnostics;

  bool get canReplay =>
      state is InterviewReady &&
      (state as InterviewReady).lastTtsAudioUrl.isNotEmpty;

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
          totalQuestions: current.totalQuestions,
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

      // Create timing record from response
      final timingRecord = TurnTimingRecord(
        turnNumber: turnResponse.data.questionNumber,
        requestId: turnResponse.requestId,
        uploadMs: turnResponse.data.timings['upload_ms'],
        sttMs: turnResponse.data.timings['stt_ms'],
        llmMs: turnResponse.data.timings['llm_ms'],
        totalMs: turnResponse.data.timings['total_ms'],
        timestamp: DateTime.now(),
      );

      // Add timing record to diagnostics
      _diagnostics = _diagnostics.addTurn(timingRecord);

      _handleTurnResponse(
        turnResponse.data,
        questionText: current.questionText,
        audioPath: current.audioPath,
      );
    } on ServerException catch (e) {
      // Only clean up audio for non-retryable errors
      // For retryable errors, preserve audio for retry
      if (!(e.retryable ?? false)) {
        await _cleanupAudioFile(current.audioPath);
      }

      handleError(
        ServerFailure(
          message: e.message,
          code: e.code,
          stage: e.stage,
          retryable: e.retryable ?? false,
          requestId: e.requestId,
        ),
        audioPath: e.retryable ?? false ? current.audioPath : null,
      );
    } on NetworkException catch (e) {
      // Network errors are typically retryable, preserve audio
      handleError(
        NetworkFailure(message: e.message),
        audioPath: current.audioPath,
      );
    } on Object catch (e) {
      // Unknown errors are retryable, preserve audio
      handleError(
        ServerFailure(
          message: 'Failed to process turn: $e',
          code: 'unknown_error',
          retryable: true,
        ),
        audioPath: current.audioPath,
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
          sessionSummary: current.sessionSummary,
        ),
      );
      _logTransition('Session complete');
      return;
    }

    // Transition to Thinking with accepted transcript
    emit(
      InterviewThinking(
        questionNumber: current.questionNumber,
        totalQuestions: current.totalQuestions,
        questionText: current.questionText,
        transcript: current.transcript,
        startTime: DateTime.now(),
        coachingFeedback: current.coachingFeedback,
      ),
    );
    _logTransition('Transcript accepted → Thinking');

    // Immediately transition to Speaking since we already have the LLM response
    if (current.assistantText != null) {
      onResponseReady(
        responseText: current.assistantText!,
        ttsAudioUrl: current.ttsAudioUrl,
        coachingFeedback: current.coachingFeedback,
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
        coachingFeedback: current.coachingFeedback,
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
  ///
  /// If [wasInterrupted] is true, marks the transition as caused by
  /// an external interruption (e.g., phone call, backgrounding).
  Future<void> cancelRecording({bool wasInterrupted = false}) async {
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
          wasInterrupted: wasInterrupted,
        ),
      );
      _logTransition(
        wasInterrupted ? 'Ready (interrupted)' : 'Ready (cancelled)',
      );
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
          wasInterrupted: wasInterrupted,
        ),
      );
    }
  }

  /// Handles audio interruption events.
  ///
  /// If recording is active, cancels the recording and returns to Ready.
  /// If not recording, logs the event but takes no action.
  void _onAudioInterruption(AudioInterruptionEvent event) {
    final current = state;

    developer.log(
      'InterviewCubit: Audio interruption received in '
      'state ${current.runtimeType}',
      name: 'InterviewCubit',
      error: {
        'began': event.begin,
        'type': event.type.toString(),
      },
    );

    if (!event.begin) {
      return;
    }

    // Handle interruptions during recording and speaking
    if (current is InterviewRecording) {
      developer.log(
        'InterviewCubit: Interruption occurred during recording - '
        'cancelling',
        name: 'InterviewCubit',
      );
      // Use cancelRecording to stop + discard + return to Ready
      unawaited(cancelRecording(wasInterrupted: true));
    } else if (current is InterviewSpeaking) {
      developer.log(
        'InterviewCubit: Interruption occurred during speaking - '
        'stopping playback',
        name: 'InterviewCubit',
      );
      unawaited(_handleSpeakingInterruption());
    } else {
      // Log but take no action for non-recording states
      developer.log(
        'InterviewCubit: Interruption during non-recording state - '
        'no action taken',
        name: 'InterviewCubit',
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
    CoachingFeedback? coachingFeedback,
  }) {
    final current = state;
    if (current is! InterviewThinking) {
      _logInvalidTransition('onResponseReady', current);
      return;
    }

    _lastResponseText = responseText;

    emit(
      InterviewSpeaking(
        questionNumber: current.questionNumber,
        totalQuestions: current.totalQuestions,
        questionText: current.questionText,
        transcript: current.transcript,
        responseText: responseText,
        ttsAudioUrl: ttsAudioUrl,
        coachingFeedback: coachingFeedback ?? current.coachingFeedback,
      ),
    );
    _logTransition('Speaking');

    if (ttsAudioUrl.trim().isEmpty) {
      onSpeakingComplete();
      return;
    }

    unawaited(_startPlayback(ttsAudioUrl));
  }

  /// Speaking complete - transition back to Ready with next question.
  void onSpeakingComplete() {
    final current = state;
    if (current is! InterviewSpeaking) {
      _logInvalidTransition('onSpeakingComplete', current);
      return;
    }

    if (_isReplaying) {
      _isReplaying = false;
      emit(
        InterviewReady(
          questionNumber: current.questionNumber,
          totalQuestions: _totalQuestions,
          questionText: current.questionText,
          previousTranscript: current.transcript,
          coachingFeedback: current.coachingFeedback,
          lastTtsAudioUrl: _lastTtsAudioUrl,
        ),
      );
      _logTransition('Replay complete → Ready');
      return;
    }

    // The responseText IS the next question from the LLM
    emit(
      InterviewReady(
        questionNumber: current.questionNumber + 1,
        totalQuestions: _totalQuestions,
        questionText: current.responseText,
        previousTranscript: current.transcript,
        coachingFeedback: current.coachingFeedback,
        lastTtsAudioUrl: _lastTtsAudioUrl,
      ),
    );
    _logTransition('Ready with next question');
  }

  void pausePlayback() {
    final current = state;
    if (current is! InterviewSpeaking || current.isPaused) {
      _logInvalidTransition('pausePlayback', current);
      return;
    }
    unawaited(_pausePlayback(current));
  }

  Future<void> _pausePlayback(InterviewSpeaking current) async {
    await _playbackService.pause();
    emit(
      InterviewSpeaking(
        questionNumber: current.questionNumber,
        totalQuestions: current.totalQuestions,
        questionText: current.questionText,
        transcript: current.transcript,
        responseText: current.responseText,
        ttsAudioUrl: current.ttsAudioUrl,
        coachingFeedback: current.coachingFeedback,
        isPaused: true,
      ),
    );
  }

  void resumePlayback() {
    final current = state;
    if (current is! InterviewSpeaking || !current.isPaused) {
      _logInvalidTransition('resumePlayback', current);
      return;
    }
    unawaited(_resumePlayback(current));
  }

  Future<void> _resumePlayback(InterviewSpeaking current) async {
    await _playbackService.resume();
    emit(
      InterviewSpeaking(
        questionNumber: current.questionNumber,
        totalQuestions: current.totalQuestions,
        questionText: current.questionText,
        transcript: current.transcript,
        responseText: current.responseText,
        ttsAudioUrl: current.ttsAudioUrl,
        coachingFeedback: current.coachingFeedback,
      ),
    );
  }

  void stopPlayback() {
    final current = state;
    if (current is! InterviewSpeaking) {
      _logInvalidTransition('stopPlayback', current);
      return;
    }
    unawaited(_stopPlayback());
  }

  Future<void> _stopPlayback() async {
    await _playbackService.stop();
    if (state is InterviewSpeaking) {
      onSpeakingComplete();
    }
  }

  Future<bool> replayLastResponse() async {
    final current = state;
    if (current is! InterviewReady || current.lastTtsAudioUrl.isEmpty) {
      _logInvalidTransition('replayLastResponse', current);
      return false;
    }

    _lastTtsAudioUrl = current.lastTtsAudioUrl;
    if (_lastResponseText.isEmpty) {
      _lastResponseText = current.questionText;
    }

    _isReplaying = true;
    emit(
      InterviewSpeaking(
        questionNumber: current.questionNumber,
        totalQuestions: current.totalQuestions,
        questionText: current.questionText,
        transcript: current.previousTranscript ?? '',
        responseText: _lastResponseText,
        ttsAudioUrl: _lastTtsAudioUrl,
        coachingFeedback: current.coachingFeedback,
      ),
    );

    final started = await _startPlayback(_lastTtsAudioUrl);
    if (!started) {
      _isReplaying = false;
      developer.log(
        'Replay URL may be expired: $_lastTtsAudioUrl',
        name: 'InterviewCubit',
        level: 900,
      );
      return false;
    }

    return true;
  }

  /// Handle error - can occur from any active state.
  ///
  /// Preserves audio path for upload/STT errors (retryable).
  /// Preserves transcript for LLM errors (retryable).
  void handleError(
    InterviewFailure failure, {
    String? audioPath,
    String? transcript,
  }) {
    final current = state;

    if (audioPath != null) {
      developer.log(
        'Preserving audio path for retry: $audioPath',
        name: 'InterviewCubit',
      );
    }

    if (transcript != null) {
      developer.log(
        'Preserving transcript for retry: $transcript',
        name: 'InterviewCubit',
      );
    }

    var mappedFailure = failure;
    if (failure is ServerFailure && failure.code == 'content_refused') {
      mappedFailure = ServerFailure(
        message:
            "Let's stay focused on the interview. "
            'Please try answering the question again.',
        code: failure.code,
        stage: failure.stage,
        requestId: failure.requestId,
      );
    }

    // Record error in diagnostics if we have stage and request ID
    if (mappedFailure is ServerFailure &&
        mappedFailure.stage != null &&
        mappedFailure.requestId != null) {
      _diagnostics = _diagnostics.recordError(
        mappedFailure.requestId!,
        mappedFailure.stage!,
      );
    }

    // Map failure stage to InterviewStage enum
    var failedStage = current.stage;
    if (mappedFailure is ServerFailure && mappedFailure.stage != null) {
      switch (mappedFailure.stage) {
        case 'upload':
          failedStage = InterviewStage.uploading;
        case 'stt':
          failedStage = InterviewStage.transcribing;
        case 'llm':
          failedStage = InterviewStage.thinking;
        case 'tts':
          failedStage = InterviewStage.speaking;
        default:
          failedStage = current.stage;
      }
    }

    emit(
      InterviewError(
        failure: mappedFailure,
        previousState: state,
        failedStage: failedStage,
        audioPath: audioPath,
        transcript: transcript,
      ),
    );
    _logTransition('Error: ${mappedFailure.message} at stage $failedStage');
  }

  /// Retry from error state with stage-aware retry logic.
  ///
  /// - Upload/STT failure (retryable) → re-submit same audio
  /// - STT failure (non-retryable) → go to re-record (Ready state)
  /// - LLM failure → re-submit same transcript (not implemented yet - no
  ///   LLM-only endpoint)
  Future<void> retry() async {
    final current = state;
    if (current is! InterviewError) {
      _logInvalidTransition('retry', current);
      return;
    }

    final previousState = current.previousState;
    final failure = current.failure;

    // Non-retryable errors should go to re-record
    if (!failure.retryable) {
      developer.log(
        'Non-retryable error, transitioning to re-record flow',
        name: 'InterviewCubit',
      );
      await reRecordFromError();
      return;
    }

    // Stage-aware retry logic
    if (previousState is InterviewUploading ||
        previousState is InterviewTranscribing) {
      // Retry upload/STT: re-submit the same audio
      if (current.audioPath != null) {
        await retryTurn(current.audioPath!);
      } else {
        // Audio path not preserved, fall back to re-record
        await reRecordFromError();
      }
    } else if (previousState is InterviewThinking) {
      // Retry LLM: re-submit transcript
      if (current.transcript != null) {
        await retryLLM(current.transcript!);
      } else {
        developer.log(
          'Cannot retry LLM: transcript missing in error state',
          name: 'InterviewCubit',
          level: 900,
        );
        await reRecordFromError();
      }
    } else {
      // For other error states, restore previous state
      emit(previousState);
      _logTransition('Retry → ${previousState.stage}');
    }
  }

  /// Retry turn submission from error state (for upload/STT errors).
  ///
  /// Re-submits the same audio file that was preserved in error state.
  Future<void> retryTurn(String audioPath) async {
    final current = state;
    if (current is! InterviewError) {
      _logInvalidTransition('retryTurn', current);
      return;
    }

    final previousState = current.previousState;
    if (previousState is! InterviewUploading &&
        previousState is! InterviewTranscribing) {
      developer.log(
        'retryTurn called from invalid previous state: ${previousState.stage}',
        name: 'InterviewCubit',
        level: 900,
      );
      return;
    }

    // Extract question info from previous state
    int questionNumber;
    String questionText;

    if (previousState is InterviewUploading) {
      questionNumber = previousState.questionNumber;
      questionText = previousState.questionText;
    } else if (previousState is InterviewTranscribing) {
      questionNumber = previousState.questionNumber;
      questionText = previousState.questionText;
    } else {
      developer.log(
        'Could not extract question info from previous state',
        name: 'InterviewCubit',
        level: 900,
      );
      return;
    }

    // Transition back to Uploading state with preserved audio
    emit(
      InterviewUploading(
        questionNumber: questionNumber,
        totalQuestions: _totalQuestions,
        questionText: questionText,
        audioPath: audioPath,
        startTime: DateTime.now(),
      ),
    );
    _logTransition('Retry → Uploading with preserved audio');

    // Trigger turn submission
    await submitTurn();
  }

  /// Re-record from error state.
  ///
  /// Cleans up retained audio and transitions to Ready state with same
  /// question.
  Future<void> reRecordFromError() async {
    final current = state;
    if (current is! InterviewError) {
      _logInvalidTransition('reRecordFromError', current);
      return;
    }

    // Clean up retained audio if any
    if (current.audioPath != null) {
      await _cleanupAudioFile(current.audioPath!);
    }

    final previousState = current.previousState;

    // Extract question info from previous state
    var questionNumber = 1;
    var questionText = '';

    if (previousState is InterviewUploading) {
      questionNumber = previousState.questionNumber;
      questionText = previousState.questionText;
    } else if (previousState is InterviewTranscribing) {
      questionNumber = previousState.questionNumber;
      questionText = previousState.questionText;
    } else if (previousState is InterviewThinking) {
      questionNumber = previousState.questionNumber;
      questionText = previousState.questionText;
    } else if (previousState is InterviewReady) {
      questionNumber = previousState.questionNumber;
      questionText = previousState.questionText;
    }

    emit(
      InterviewReady(
        questionNumber: questionNumber,
        totalQuestions: _totalQuestions,
        questionText: questionText,
      ),
    );

    _logTransition('Re-record from error → Ready');
  }

  /// Retry LLM generation from error state.
  ///
  /// Re-submits the preserved transcript to the backend.
  Future<void> retryLLM(String transcript) async {
    final current = state;
    if (current is! InterviewError) {
      _logInvalidTransition('retryLLM', current);
      return;
    }

    final previousState = current.previousState;

    // Extract question info from previous state
    int questionNumber;
    String questionText;

    if (previousState is InterviewThinking) {
      questionNumber = previousState.questionNumber;
      questionText = previousState.questionText;
    } else {
      developer.log(
        'retryLLM called from invalid previous state: ${previousState.stage}',
        name: 'InterviewCubit',
        level: 900,
      );
      return;
    }

    // Transition back to Thinking state with preserved transcript
    emit(
      InterviewThinking(
        questionNumber: questionNumber,
        totalQuestions: _totalQuestions,
        questionText: questionText,
        transcript: transcript,
        startTime: DateTime.now(),
      ),
    );
    _logTransition('Retry LLM → Thinking with preserved transcript');

    try {
      final response = await _turnRemoteDataSource.submitTurn(
        sessionId: _sessionId,
        sessionToken: _sessionToken,
        transcript: transcript,
      );

      // Create timing record from response
      final timingRecord = TurnTimingRecord(
        turnNumber: response.data.questionNumber,
        requestId: response.requestId,
        uploadMs: response.data.timings['upload_ms'],
        sttMs: response.data.timings['stt_ms'],
        llmMs: response.data.timings['llm_ms'],
        totalMs: response.data.timings['total_ms'],
        timestamp: DateTime.now(),
      );

      // Add timing record to diagnostics
      _diagnostics = _diagnostics.addTurn(timingRecord);

      _handleTurnResponse(
        response.data,
        questionText: questionText,
        // audioPath is null for transcript-only retry
      );
    } on Exception catch (e) {
      developer.log(
        'InterviewCubit: Error during LLM retry: $e',
        name: 'InterviewCubit',
        level: 900,
      );

      final failure = e is ServerException
          ? ServerFailure(
              message: e.message,
              requestId: e.requestId,
              retryable: e.retryable ?? false,
              stage: e.stage,
              code: e.code,
            )
          : const NetworkFailure(
              message: 'Failed to connect. Please check your internet.',
            );

      handleError(
        failure,
        transcript: transcript, // Preserve transcript again for next retry
      );
    }
  }

  /// Cancel interview - return to idle.
  ///
  /// Cleans up any retained audio files from error state.
  Future<void> cancel() async {
    await _playbackEventSubscription?.cancel();
    _playbackEventSubscription = null;
    await _playbackService.stop();

    // Clean up retained audio in error state
    if (state is InterviewError) {
      final errorState = state as InterviewError;
      if (errorState.audioPath != null) {
        await _cleanupAudioFile(errorState.audioPath!);
      }
    }

    // Stop recording if currently recording
    if (await _recordingService.isRecording) {
      try {
        final audioPath = await _recordingService.stopRecording();
        if (audioPath != null && audioPath.isNotEmpty) {
          await _recordingService.deleteRecording(audioPath);
        }
      } on Object catch (e) {
        developer.log(
          'InterviewCubit: Error stopping recording during cancel: $e',
          name: 'InterviewCubit',
          level: 900,
        );
      }
    }
    _maxDurationTimer?.cancel();
    _lastTtsAudioUrl = '';
    _lastResponseText = '';
    _isReplaying = false;
    if (!isClosed) {
      emit(const InterviewIdle());
    }
    _logTransition('Cancelled → Idle');
  }

  @override
  Future<void> close() async {
    _maxDurationTimer?.cancel();
    await _playbackEventSubscription?.cancel();
    await _audioInterruptionSubscription?.cancel();
    await super.close();
  }

  Future<bool> _startPlayback(String ttsAudioUrl) async {
    _lastTtsAudioUrl = ttsAudioUrl;
    final requestId = _extractRequestId(ttsAudioUrl);
    final fullUrl = _resolveTtsUrl(ttsAudioUrl);

    await _playbackEventSubscription?.cancel();
    _playbackEventSubscription = _playbackService.events.listen((event) {
      final current = state;
      if (current is! InterviewSpeaking) {
        return;
      }

      switch (event) {
        case PlaybackPlaying():
          // Ensure buffering state is cleared when playing starts
          if (current.isBuffering) {
            emit(
              InterviewSpeaking(
                questionNumber: current.questionNumber,
                totalQuestions: current.totalQuestions,
                questionText: current.questionText,
                transcript: current.transcript,
                responseText: current.responseText,
                ttsAudioUrl: current.ttsAudioUrl,
                coachingFeedback: current.coachingFeedback,
                isPaused: current.isPaused,
              ),
            );
          }
        case PlaybackPaused():
          break;
        case PlaybackBuffering():
          if (!current.isBuffering) {
            emit(
              InterviewSpeaking(
                questionNumber: current.questionNumber,
                totalQuestions: current.totalQuestions,
                questionText: current.questionText,
                transcript: current.transcript,
                responseText: current.responseText,
                ttsAudioUrl: current.ttsAudioUrl,
                coachingFeedback: current.coachingFeedback,
                isPaused: current.isPaused,
                isBuffering: true,
              ),
            );
          }
        case PlaybackCompleted():
          onSpeakingComplete();
        case PlaybackError(:final message):
          developer.log(
            'TTS playback failed: $message',
            name: 'InterviewCubit',
            error: {'request_id': requestId, 'tts_url': ttsAudioUrl},
            level: 900,
          );
          onSpeakingComplete();
      }
    });

    try {
      await _playbackService.playUrl(
        fullUrl,
        bearerToken: _sessionToken,
      );
      return true;
    } on Object catch (error) {
      developer.log(
        'TTS playback start failed: $error',
        name: 'InterviewCubit',
        error: {'request_id': requestId, 'tts_url': ttsAudioUrl},
        level: 900,
      );

      if (state is InterviewSpeaking) {
        onSpeakingComplete();
      }
      return false;
    }
  }

  Future<void> _handleSpeakingInterruption() async {
    final current = state;
    if (current is InterviewSpeaking && !current.isPaused) {
      await _pausePlayback(current);
    }
  }

  String _resolveTtsUrl(String ttsAudioUrl) {
    final parsed = Uri.parse(ttsAudioUrl);
    if (parsed.hasScheme) {
      return ttsAudioUrl;
    }

    final base = Uri.parse(_apiBaseUrl);
    return base.resolve(ttsAudioUrl).toString();
  }

  String? _extractRequestId(String ttsAudioUrl) {
    final parsed = Uri.parse(ttsAudioUrl);
    final segments = parsed.pathSegments;
    if (segments.length >= 2 && segments[segments.length - 2] == 'tts') {
      return segments.last;
    }

    return null;
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

  void _handleTurnResponse(
    TurnResponseData response, {
    required String questionText,
    String? audioPath,
  }) {
    // Brief transition to Transcribing state (if audio path exists, otherwise
    // skip?) Actually, consistency is good. Let's show it briefly or just
    // go straight to Review.
    if (audioPath != null) {
      emit(
        InterviewTranscribing(
          questionNumber: response.questionNumber,
          totalQuestions: response.totalQuestions,
          questionText: questionText,
          startTime: DateTime.now(),
        ),
      );
      _logTransition('Transcribing');
    }

    // Detect low-confidence transcript (< 3 words)
    final wordCount = response.transcript
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    final isLowConfidence = wordCount < 3;

    // Transition to TranscriptReview instead of Thinking
    emit(
      InterviewTranscriptReview(
        questionNumber: response.questionNumber,
        totalQuestions: response.totalQuestions,
        questionText: questionText,
        transcript: response.transcript,
        audioPath:
            audioPath ?? '', // Empty string if no audio (transcript-only flow)
        isLowConfidence: isLowConfidence,
        assistantText: response.assistantText,
        ttsAudioUrl: response.ttsAudioUrl ?? '',
        coachingFeedback: response.coachingFeedback,
        sessionSummary: response.sessionSummary,
        isComplete: response.isComplete,
      ),
    );
    _logTransition(
      'TranscriptReview (transcript: ${response.transcript}, '
      'lowConfidence: $isLowConfidence, '
      'isComplete: ${response.isComplete})',
    );
  }
}
