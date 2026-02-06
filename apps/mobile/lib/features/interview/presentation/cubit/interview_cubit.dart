import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
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
    int questionNumber = 1,
    int totalQuestions = 5,
    String? initialQuestionText,
  }) : super(
         initialQuestionText != null
             ? InterviewReady(
                 questionNumber: questionNumber,
                 totalQuestions: totalQuestions,
                 questionText: initialQuestionText,
               )
             : const InterviewIdle(),
       );

  /// Start recording - only valid from Ready state.
  void startRecording() {
    final current = state;
    if (current is! InterviewReady) {
      _logInvalidTransition('startRecording', current);
      return;
    }

    emit(
      InterviewRecording(
        questionNumber: current.questionNumber,
        questionText: current.questionText,
        recordingStartTime: DateTime.now(),
      ),
    );
    _logTransition('Recording');
  }

  /// Stop recording - only valid from Recording state.
  void stopRecording(String audioPath) {
    final current = state;
    if (current is! InterviewRecording) {
      _logInvalidTransition('stopRecording', current);
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
  }

  /// Upload complete - transition to Transcribing.
  void onUploadComplete() {
    final current = state;
    if (current is! InterviewUploading) {
      _logInvalidTransition('onUploadComplete', current);
      return;
    }

    emit(
      InterviewTranscribing(
        questionNumber: current.questionNumber,
        questionText: current.questionText,
        startTime: DateTime.now(),
      ),
    );
    _logTransition('Transcribing');
  }

  /// Transcript received - transition to Thinking.
  void onTranscriptReceived(String transcript) {
    final current = state;
    if (current is! InterviewTranscribing) {
      _logInvalidTransition('onTranscriptReceived', current);
      return;
    }

    emit(
      InterviewThinking(
        questionNumber: current.questionNumber,
        questionText: current.questionText,
        transcript: transcript,
        startTime: DateTime.now(),
      ),
    );
    _logTransition('Thinking');
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

  /// Speaking complete - transition back to Ready.
  void onSpeakingComplete({
    required String nextQuestionText,
    required int totalQuestions,
  }) {
    final current = state;
    if (current is! InterviewSpeaking) {
      _logInvalidTransition('onSpeakingComplete', current);
      return;
    }

    emit(
      InterviewReady(
        questionNumber: current.questionNumber + 1,
        totalQuestions: totalQuestions,
        questionText: nextQuestionText,
        previousTranscript: current.transcript,
      ),
    );
    _logTransition('Ready');
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
  void cancel() {
    emit(const InterviewIdle());
    _logTransition('Cancelled → Idle');
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
