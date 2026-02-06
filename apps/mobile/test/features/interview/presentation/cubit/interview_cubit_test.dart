import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_state.dart';

void main() {
  group('InterviewCubit', () {
    late InterviewCubit cubit;

    setUp(() {
      cubit = InterviewCubit();
    });

    tearDown(() async {
      await cubit.close();
    });

    test('initial state is InterviewIdle', () {
      expect(cubit.state, equals(const InterviewIdle()));
    });

    group('startRecording', () {
      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewRecording when called from Ready state',
        build: InterviewCubit.new,
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) => cubit.startRecording(),
        expect: () => [
          isA<InterviewRecording>()
              .having((s) => s.questionNumber, 'questionNumber', 1)
              .having((s) => s.questionText, 'questionText', 'Test question')
              .having(
                (s) => s.recordingStartTime,
                'recordingStartTime',
                isA<DateTime>(),
              ),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Recording state',
        build: InterviewCubit.new,
        seed: () => InterviewRecording(
          questionNumber: 1,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) => cubit.startRecording(),
        expect: () => <InterviewState>[],
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Uploading state',
        build: InterviewCubit.new,
        seed: () => InterviewUploading(
          questionNumber: 1,
          questionText: 'Q1',
          audioPath: '/path',
          startTime: DateTime.now(),
        ),
        act: (cubit) => cubit.startRecording(),
        expect: () => <InterviewState>[],
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Speaking state',
        build: InterviewCubit.new,
        seed: () => const InterviewSpeaking(
          questionNumber: 1,
          questionText: 'Q1',
          transcript: 'transcript',
          responseText: 'response',
          ttsAudioUrl: 'url',
        ),
        act: (cubit) => cubit.startRecording(),
        expect: () => <InterviewState>[],
      );
    });

    group('stopRecording', () {
      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewUploading when called from Recording state',
        build: InterviewCubit.new,
        seed: () => InterviewRecording(
          questionNumber: 1,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) => cubit.stopRecording('/path/to/audio.m4a'),
        expect: () => [
          isA<InterviewUploading>()
              .having((s) => s.questionNumber, 'questionNumber', 1)
              .having((s) => s.questionText, 'questionText', 'Q1')
              .having((s) => s.audioPath, 'audioPath', '/path/to/audio.m4a')
              .having((s) => s.startTime, 'startTime', isA<DateTime>()),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Ready state',
        build: InterviewCubit.new,
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) => cubit.stopRecording('/path'),
        expect: () => <InterviewState>[],
      );
    });

    group('onUploadComplete', () {
      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewTranscribing when called from Uploading state',
        build: InterviewCubit.new,
        seed: () => InterviewUploading(
          questionNumber: 1,
          questionText: 'Q1',
          audioPath: '/path',
          startTime: DateTime.now(),
        ),
        act: (cubit) => cubit.onUploadComplete(),
        expect: () => [
          isA<InterviewTranscribing>()
              .having((s) => s.questionNumber, 'questionNumber', 1)
              .having((s) => s.questionText, 'questionText', 'Q1')
              .having((s) => s.startTime, 'startTime', isA<DateTime>()),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Recording state',
        build: InterviewCubit.new,
        seed: () => InterviewRecording(
          questionNumber: 1,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) => cubit.onUploadComplete(),
        expect: () => <InterviewState>[],
      );
    });

    group('onTranscriptReceived', () {
      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewThinking when called from Transcribing state',
        build: InterviewCubit.new,
        seed: () => InterviewTranscribing(
          questionNumber: 1,
          questionText: 'Q1',
          startTime: DateTime.now(),
        ),
        act: (cubit) => cubit.onTranscriptReceived('User transcript'),
        expect: () => [
          isA<InterviewThinking>()
              .having((s) => s.questionNumber, 'questionNumber', 1)
              .having((s) => s.questionText, 'questionText', 'Q1')
              .having((s) => s.transcript, 'transcript', 'User transcript')
              .having((s) => s.startTime, 'startTime', isA<DateTime>()),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Ready state',
        build: InterviewCubit.new,
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) => cubit.onTranscriptReceived('transcript'),
        expect: () => <InterviewState>[],
      );
    });

    group('onResponseReady', () {
      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewSpeaking when called from Thinking state',
        build: InterviewCubit.new,
        seed: () => InterviewThinking(
          questionNumber: 1,
          questionText: 'Q1',
          transcript: 'User transcript',
          startTime: DateTime.now(),
        ),
        act: (cubit) => cubit.onResponseReady(
          responseText: 'Coach response',
          ttsAudioUrl: 'https://example.com/audio.mp3',
        ),
        expect: () => [
          isA<InterviewSpeaking>()
              .having((s) => s.questionNumber, 'questionNumber', 1)
              .having((s) => s.questionText, 'questionText', 'Q1')
              .having((s) => s.transcript, 'transcript', 'User transcript')
              .having((s) => s.responseText, 'responseText', 'Coach response')
              .having(
                (s) => s.ttsAudioUrl,
                'ttsAudioUrl',
                'https://example.com/audio.mp3',
              ),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Ready state',
        build: InterviewCubit.new,
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) => cubit.onResponseReady(
          responseText: 'response',
          ttsAudioUrl: 'url',
        ),
        expect: () => <InterviewState>[],
      );
    });

    group('onSpeakingComplete', () {
      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewReady when called from Speaking state',
        build: InterviewCubit.new,
        seed: () => const InterviewSpeaking(
          questionNumber: 1,
          questionText: 'Q1',
          transcript: 'User transcript',
          responseText: 'Coach response',
          ttsAudioUrl: 'url',
        ),
        act: (cubit) => cubit.onSpeakingComplete(
          nextQuestionText: 'Next question',
          totalQuestions: 5,
        ),
        expect: () => [
          isA<InterviewReady>()
              .having((s) => s.questionNumber, 'questionNumber', 2)
              .having((s) => s.totalQuestions, 'totalQuestions', 5)
              .having((s) => s.questionText, 'questionText', 'Next question')
              .having(
                (s) => s.previousTranscript,
                'previousTranscript',
                'User transcript',
              ),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Ready state',
        build: InterviewCubit.new,
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) => cubit.onSpeakingComplete(
          nextQuestionText: 'Next',
          totalQuestions: 5,
        ),
        expect: () => <InterviewState>[],
      );
    });

    group('handleError', () {
      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewError from any state',
        build: InterviewCubit.new,
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) => cubit.handleError(
          const NetworkFailure(message: 'Network error'),
        ),
        expect: () => [
          isA<InterviewError>()
              .having(
                (s) => s.failure,
                'failure',
                const NetworkFailure(message: 'Network error'),
              )
              .having(
                (s) => s.previousState,
                'previousState',
                isA<InterviewReady>(),
              ),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'can transition from Uploading to Error',
        build: InterviewCubit.new,
        seed: () => InterviewUploading(
          questionNumber: 1,
          questionText: 'Q1',
          audioPath: '/path',
          startTime: DateTime.now(),
        ),
        act: (cubit) => cubit.handleError(
          const ServerFailure(message: 'Upload failed', stage: 'uploading'),
        ),
        expect: () => [
          isA<InterviewError>()
              .having(
                (s) => s.failure,
                'failure',
                const ServerFailure(
                  message: 'Upload failed',
                  stage: 'uploading',
                ),
              )
              .having(
                (s) => s.previousState,
                'previousState',
                isA<InterviewUploading>(),
              ),
        ],
      );
    });

    group('retry', () {
      blocTest<InterviewCubit, InterviewState>(
        'restores previous state when called from Error state',
        build: InterviewCubit.new,
        seed: () => const InterviewError(
          failure: NetworkFailure(message: 'Network error'),
          previousState: InterviewReady(
            questionNumber: 1,
            totalQuestions: 5,
            questionText: 'Test question',
          ),
        ),
        act: (cubit) => cubit.retry(),
        expect: () => [
          isA<InterviewReady>().having(
            (s) => s.questionNumber,
            'questionNumber',
            1,
          ),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Ready state',
        build: InterviewCubit.new,
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) => cubit.retry(),
        expect: () => <InterviewState>[],
      );
    });

    group('cancel', () {
      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewIdle from Ready state',
        build: InterviewCubit.new,
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) => cubit.cancel(),
        expect: () => [const InterviewIdle()],
      );

      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewIdle from Recording state',
        build: InterviewCubit.new,
        seed: () => InterviewRecording(
          questionNumber: 1,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) => cubit.cancel(),
        expect: () => [const InterviewIdle()],
      );

      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewIdle from Speaking state',
        build: InterviewCubit.new,
        seed: () => const InterviewSpeaking(
          questionNumber: 1,
          questionText: 'Q1',
          transcript: 'User transcript',
          responseText: 'Coach response',
          ttsAudioUrl: 'url',
        ),
        act: (cubit) => cubit.cancel(),
        expect: () => [const InterviewIdle()],
      );
    });

    group('state data preservation', () {
      blocTest<InterviewCubit, InterviewState>(
        'preserves question number through flow',
        build: InterviewCubit.new,
        seed: () => const InterviewReady(
          questionNumber: 3,
          totalQuestions: 5,
          questionText: 'Question 3',
        ),
        act: (cubit) => cubit
          ..startRecording()
          ..stopRecording('/path')
          ..onUploadComplete(),
        expect: () => [
          isA<InterviewRecording>().having(
            (s) => s.questionNumber,
            'questionNumber',
            3,
          ),
          isA<InterviewUploading>().having(
            (s) => s.questionNumber,
            'questionNumber',
            3,
          ),
          isA<InterviewTranscribing>().having(
            (s) => s.questionNumber,
            'questionNumber',
            3,
          ),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'preserves transcript through Thinking to Speaking',
        build: InterviewCubit.new,
        seed: () => InterviewThinking(
          questionNumber: 2,
          questionText: 'Question 2',
          transcript: 'My answer to question 2',
          startTime: DateTime.now(),
        ),
        act: (cubit) => cubit.onResponseReady(
          responseText: 'Great answer!',
          ttsAudioUrl: 'url',
        ),
        expect: () => [
          isA<InterviewSpeaking>()
              .having(
                (s) => s.transcript,
                'transcript',
                'My answer to question 2',
              )
              .having((s) => s.questionNumber, 'questionNumber', 2),
        ],
      );
    });
  });
}
