import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_state.dart';

void main() {
  group('InterviewState', () {
    group('InterviewIdle', () {
      test('should extend InterviewState and Equatable', () {
        const state = InterviewIdle();
        expect(state, isA<InterviewState>());
        expect(state, isA<Equatable>());
      });

      test('stage should return ready', () {
        const state = InterviewIdle();
        expect(state.stage, InterviewStage.ready);
      });

      test('supports equality', () {
        const state1 = InterviewIdle();
        const state2 = InterviewIdle();
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('props should be empty', () {
        const state = InterviewIdle();
        expect(state.props, isEmpty);
      });
    });

    group('InterviewReady', () {
      test('should extend InterviewState', () {
        const state = InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        );
        expect(state, isA<InterviewState>());
      });

      test('stage should return ready', () {
        const state = InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        );
        expect(state.stage, InterviewStage.ready);
      });

      test('supports equality', () {
        const state1 = InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        );
        const state2 = InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        );
        expect(state1, equals(state2));
      });

      test('different values should not be equal', () {
        const state1 = InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        );
        const state2 = InterviewReady(
          questionNumber: 2,
          totalQuestions: 5,
          questionText: 'Test question',
        );
        expect(state1, isNot(equals(state2)));
      });

      test('previousTranscript should be optional', () {
        const state = InterviewReady(
          questionNumber: 2,
          totalQuestions: 5,
          questionText: 'Next question',
          previousTranscript: 'Previous answer',
        );
        expect(state.previousTranscript, equals('Previous answer'));
      });

      test('props should include all non-null values', () {
        const state = InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
          previousTranscript: 'Previous',
        );
        expect(
          state.props,
          containsAll([1, 5, 'Test question', 'Previous']),
        );
      });
    });

    group('InterviewRecording', () {
      test('should extend InterviewState', () {
        final state = InterviewRecording(
          questionNumber: 1,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        );
        expect(state, isA<InterviewState>());
      });

      test('stage should return recording', () {
        final state = InterviewRecording(
          questionNumber: 1,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        );
        expect(state.stage, InterviewStage.recording);
      });

      test('supports equality', () {
        final time = DateTime.now();
        final state1 = InterviewRecording(
          questionNumber: 1,
          questionText: 'Q1',
          recordingStartTime: time,
        );
        final state2 = InterviewRecording(
          questionNumber: 1,
          questionText: 'Q1',
          recordingStartTime: time,
        );
        expect(state1, equals(state2));
      });

      test('props should include all values', () {
        final time = DateTime.now();
        final state = InterviewRecording(
          questionNumber: 2,
          questionText: 'Q2',
          recordingStartTime: time,
        );
        expect(state.props, containsAll([2, 'Q2', time]));
      });
    });

    group('InterviewUploading', () {
      test('should extend InterviewState', () {
        final state = InterviewUploading(
          questionNumber: 1,
          questionText: 'Q1',
          audioPath: '/path/to/audio.m4a',
          startTime: DateTime.now(),
        );
        expect(state, isA<InterviewState>());
      });

      test('stage should return uploading', () {
        final state = InterviewUploading(
          questionNumber: 1,
          questionText: 'Q1',
          audioPath: '/path/to/audio.m4a',
          startTime: DateTime.now(),
        );
        expect(state.stage, InterviewStage.uploading);
      });

      test('supports equality', () {
        final time = DateTime.now();
        final state1 = InterviewUploading(
          questionNumber: 1,
          questionText: 'Q1',
          audioPath: '/path/to/audio.m4a',
          startTime: time,
        );
        final state2 = InterviewUploading(
          questionNumber: 1,
          questionText: 'Q1',
          audioPath: '/path/to/audio.m4a',
          startTime: time,
        );
        expect(state1, equals(state2));
      });

      test('props should include all values', () {
        final time = DateTime.now();
        final state = InterviewUploading(
          questionNumber: 1,
          questionText: 'Q1',
          audioPath: '/path/to/audio.m4a',
          startTime: time,
        );
        expect(
          state.props,
          containsAll([1, 'Q1', '/path/to/audio.m4a', time]),
        );
      });
    });

    group('InterviewTranscribing', () {
      test('should extend InterviewState', () {
        final state = InterviewTranscribing(
          questionNumber: 1,
          questionText: 'Q1',
          startTime: DateTime.now(),
        );
        expect(state, isA<InterviewState>());
      });

      test('stage should return transcribing', () {
        final state = InterviewTranscribing(
          questionNumber: 1,
          questionText: 'Q1',
          startTime: DateTime.now(),
        );
        expect(state.stage, InterviewStage.transcribing);
      });

      test('supports equality', () {
        final time = DateTime.now();
        final state1 = InterviewTranscribing(
          questionNumber: 1,
          questionText: 'Q1',
          startTime: time,
        );
        final state2 = InterviewTranscribing(
          questionNumber: 1,
          questionText: 'Q1',
          startTime: time,
        );
        expect(state1, equals(state2));
      });
    });

    group('InterviewThinking', () {
      test('should extend InterviewState', () {
        final state = InterviewThinking(
          questionNumber: 1,
          questionText: 'Q1',
          transcript: 'User said this',
          startTime: DateTime.now(),
        );
        expect(state, isA<InterviewState>());
      });

      test('stage should return thinking', () {
        final state = InterviewThinking(
          questionNumber: 1,
          questionText: 'Q1',
          transcript: 'User said this',
          startTime: DateTime.now(),
        );
        expect(state.stage, InterviewStage.thinking);
      });

      test('supports equality', () {
        final time = DateTime.now();
        final state1 = InterviewThinking(
          questionNumber: 1,
          questionText: 'Q1',
          transcript: 'User said this',
          startTime: time,
        );
        final state2 = InterviewThinking(
          questionNumber: 1,
          questionText: 'Q1',
          transcript: 'User said this',
          startTime: time,
        );
        expect(state1, equals(state2));
      });
    });

    group('InterviewSpeaking', () {
      test('should extend InterviewState', () {
        const state = InterviewSpeaking(
          questionNumber: 1,
          questionText: 'Q1',
          transcript: 'User said this',
          responseText: 'Coach response',
          ttsAudioUrl: 'https://example.com/audio.mp3',
        );
        expect(state, isA<InterviewState>());
      });

      test('stage should return speaking', () {
        const state = InterviewSpeaking(
          questionNumber: 1,
          questionText: 'Q1',
          transcript: 'User said this',
          responseText: 'Coach response',
          ttsAudioUrl: 'https://example.com/audio.mp3',
        );
        expect(state.stage, InterviewStage.speaking);
      });

      test('supports equality', () {
        const state1 = InterviewSpeaking(
          questionNumber: 1,
          questionText: 'Q1',
          transcript: 'User said this',
          responseText: 'Coach response',
          ttsAudioUrl: 'https://example.com/audio.mp3',
        );
        const state2 = InterviewSpeaking(
          questionNumber: 1,
          questionText: 'Q1',
          transcript: 'User said this',
          responseText: 'Coach response',
          ttsAudioUrl: 'https://example.com/audio.mp3',
        );
        expect(state1, equals(state2));
      });

      test('props should include all values', () {
        const state = InterviewSpeaking(
          questionNumber: 2,
          questionText: 'Q2',
          transcript: 'User said this',
          responseText: 'Coach response',
          ttsAudioUrl: 'https://example.com/audio.mp3',
        );
        expect(
          state.props,
          containsAll([
            2,
            'Q2',
            'User said this',
            'Coach response',
            'https://example.com/audio.mp3',
          ]),
        );
      });
    });

    group('InterviewError', () {
      test('should extend InterviewState', () {
        const failure = NetworkFailure(message: 'Network error');
        const previousState = InterviewIdle();
        const state = InterviewError(
          failure: failure,
          previousState: previousState,
        );
        expect(state, isA<InterviewState>());
      });

      test('stage should return error', () {
        const failure = NetworkFailure(message: 'Network error');
        const previousState = InterviewIdle();
        const state = InterviewError(
          failure: failure,
          previousState: previousState,
        );
        expect(state.stage, InterviewStage.error);
      });

      test('supports equality', () {
        const failure = NetworkFailure(message: 'Network error');
        const previousState = InterviewIdle();
        const state1 = InterviewError(
          failure: failure,
          previousState: previousState,
        );
        const state2 = InterviewError(
          failure: failure,
          previousState: previousState,
        );
        expect(state1, equals(state2));
      });

      test('different failures should not be equal', () {
        const failure1 = NetworkFailure(message: 'Network error');
        const failure2 = ServerFailure(message: 'Server error');
        const previousState = InterviewIdle();
        const state1 = InterviewError(
          failure: failure1,
          previousState: previousState,
        );
        const state2 = InterviewError(
          failure: failure2,
          previousState: previousState,
        );
        expect(state1, isNot(equals(state2)));
      });

      test('props should include failure and previousState', () {
        const failure = NetworkFailure(message: 'Network error');
        const previousState = InterviewIdle();
        const state = InterviewError(
          failure: failure,
          previousState: previousState,
        );
        expect(state.props, containsAll([failure, previousState]));
      });
    });
  });
}
