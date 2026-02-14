import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/audio/recording_service.dart';
import 'package:voicemock/core/models/models.dart';
import 'package:voicemock/core/permissions/permissions.dart';
import 'package:voicemock/features/interview/data/data.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_state.dart';

class MockRecordingService extends Mock implements RecordingService {}

class MockPermissionService extends Mock implements PermissionService {}

class MockTurnRemoteDataSource extends Mock implements TurnRemoteDataSource {}

// Stub functions for tearoffs
Future<void> _disposeStub(Invocation _) => Future.value();
Future<bool> _isRecordingStub(Invocation _) => Future.value(false);

// Helper to create a properly stubbed mock service
MockRecordingService createMockRecordingService({
  Future<void> Function()? onStartRecording,
  Future<String?> Function()? onStopRecording,
  Future<bool> Function()? onIsRecording,
}) {
  final service = MockRecordingService();
  when(service.dispose).thenAnswer(_disposeStub);
  if (onStartRecording != null) {
    when(service.startRecording).thenAnswer((_) => onStartRecording());
  }
  if (onStopRecording != null) {
    when(service.stopRecording).thenAnswer((_) => onStopRecording());
  }
  if (onIsRecording != null) {
    when(() => service.isRecording).thenAnswer((_) => onIsRecording());
  }
  when(() => service.deleteRecording(any())).thenAnswer((_) async {});
  return service;
}

// Helper to create a properly stubbed mock permission service
MockPermissionService createMockPermissionService({
  MicrophonePermissionStatus status = MicrophonePermissionStatus.granted,
}) {
  final service = MockPermissionService();
  when(
    service.checkMicrophonePermission,
  ).thenAnswer((_) => Future.value(status));
  return service;
}

// Helper to create a properly stubbed mock turn remote data source
MockTurnRemoteDataSource createMockTurnRemoteDataSource({
  TurnResponseData? response,
  Exception? throwsException,
}) {
  final dataSource = MockTurnRemoteDataSource();
  if (throwsException != null) {
    when(
      () => dataSource.submitTurn(
        audioPath: any(named: 'audioPath'),
        sessionId: any(named: 'sessionId'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenThrow(throwsException);
  } else {
    when(
      () => dataSource.submitTurn(
        audioPath: any(named: 'audioPath'),
        sessionId: any(named: 'sessionId'),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer(
      (_) => Future.value(
        response ??
            const TurnResponseData(
              transcript: 'Test transcript here',
              timings: {},
              questionNumber: 1,
              totalQuestions: 5,
            ),
      ),
    );
  }
  return dataSource;
}

void main() {
  group('InterviewCubit', () {
    late InterviewCubit cubit;
    late RecordingService mockRecordingService;
    late TurnRemoteDataSource mockTurnRemoteDataSource;

    setUp(() {
      mockRecordingService = MockRecordingService();
      // Stub dispose to prevent type error in tearDown
      when(() => mockRecordingService.dispose()).thenAnswer(_disposeStub);
      // Stub isRecording default to false
      when(
        () => mockRecordingService.isRecording,
      ).thenAnswer(_isRecordingStub);
      mockTurnRemoteDataSource = createMockTurnRemoteDataSource();
      cubit = InterviewCubit(
        recordingService: mockRecordingService,
        turnRemoteDataSource: mockTurnRemoteDataSource,
        sessionId: 'test-session-123',
        sessionToken: 'test-token',
        permissionService: createMockPermissionService(),
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('initial state is InterviewIdle', () {
      expect(cubit.state, equals(const InterviewIdle()));
    });

    group('startRecording', () {
      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewRecording when called from Ready state with service',
        build: () {
          final service = MockRecordingService();
          when(service.startRecording).thenAnswer((_) async {});
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) async {
          await cubit.startRecording();
        },
        expect: () => [
          isA<InterviewRecording>()
              .having((s) => s.questionNumber, 'questionNumber', 1)
              .having((s) => s.questionText, 'questionText', 'Test question')
              .having(
                (s) => s.recordingStartTime,
                'recordingStartTime',
                isA<DateTime>(),
              )
              .having((s) => s.totalQuestions, 'totalQuestions', 5),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewError when recording service fails to start',
        build: () {
          final service = MockRecordingService();
          when(
            service.startRecording,
          ).thenThrow(Exception('Failed to start recording'));
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) async {
          await cubit.startRecording();
        },
        expect: () => [
          isA<InterviewError>()
              .having((s) => s.failure, 'failure', isA<RecordingFailure>())
              .having(
                (s) => s.failure.message,
                'failure.message',
                contains('Failed to start recording'),
              ),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Recording state',
        build: () {
          final service = MockRecordingService();
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => InterviewRecording(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) async {
          await cubit.startRecording();
        },
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Uploading state',
        build: () {
          final service = MockRecordingService();
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => InterviewUploading(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Q1',
          audioPath: '/path',
          startTime: DateTime.now(),
        ),
        act: (cubit) async {
          await cubit.startRecording();
        },
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Speaking state',
        build: () {
          final service = MockRecordingService();
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => const InterviewSpeaking(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Q1',
          transcript: 'transcript',
          responseText: 'response',
          ttsAudioUrl: 'url',
        ),
        act: (cubit) async {
          await cubit.startRecording();
        },
      );
    });

    group('stopRecording', () {
      blocTest<InterviewCubit, InterviewState>(
        'emits Uploading → Transcribing → TranscriptReview flow',
        build: () {
          final service = MockRecordingService();
          when(
            service.stopRecording,
          ).thenAnswer((_) async => '/path/to/audio.m4a');
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => InterviewRecording(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) async {
          await cubit.stopRecording();
          // Give async submitTurn time to complete
          await Future<void>.delayed(const Duration(milliseconds: 100));
        },
        expect: () => [
          isA<InterviewUploading>()
              .having((s) => s.questionNumber, 'questionNumber', 1)
              .having((s) => s.questionText, 'questionText', 'Q1')
              .having((s) => s.audioPath, 'audioPath', '/path/to/audio.m4a')
              .having((s) => s.startTime, 'startTime', isA<DateTime>()),
          isA<InterviewTranscribing>()
              .having((s) => s.questionNumber, 'questionNumber', 1)
              .having((s) => s.questionText, 'questionText', 'Q1'),
          isA<InterviewTranscriptReview>()
              .having((s) => s.questionNumber, 'questionNumber', 1)
              .having((s) => s.questionText, 'questionText', 'Q1')
              .having((s) => s.transcript, 'transcript', 'Test transcript here')
              .having((s) => s.audioPath, 'audioPath', '/path/to/audio.m4a')
              .having((s) => s.isLowConfidence, 'isLowConfidence', false),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewError when service returns null path',
        build: () {
          final service = MockRecordingService();
          when(service.stopRecording).thenAnswer((_) async => null);
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => InterviewRecording(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) async {
          await cubit.stopRecording();
        },
        expect: () => [
          isA<InterviewError>()
              .having((s) => s.failure, 'failure', isA<RecordingFailure>())
              .having(
                (s) => s.failure.message,
                'failure.message',
                contains('No audio recorded'),
              ),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewError when service returns empty path',
        build: () {
          final service = MockRecordingService();
          when(service.stopRecording).thenAnswer((_) async => '');
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => InterviewRecording(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) async {
          await cubit.stopRecording();
        },
        expect: () => [
          isA<InterviewError>()
              .having((s) => s.failure, 'failure', isA<RecordingFailure>())
              .having(
                (s) => s.failure.message,
                'failure.message',
                contains('No audio recorded'),
              ),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewError when stopRecording fails',
        build: () {
          final service = MockRecordingService();
          when(
            service.stopRecording,
          ).thenThrow(Exception('Failed to stop recording'));
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => InterviewRecording(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) async {
          await cubit.stopRecording();
        },
        expect: () => [
          isA<InterviewError>()
              .having((s) => s.failure, 'failure', isA<RecordingFailure>())
              .having(
                (s) => s.failure.message,
                'failure.message',
                contains('Failed to stop recording'),
              ),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Ready state',
        build: () {
          final service = MockRecordingService();
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) async {
          await cubit.stopRecording();
        },
      );
    });

    group('cancelRecording', () {
      blocTest<InterviewCubit, InterviewState>(
        'stops recording and returns to Ready when called from Recording',
        build: () {
          final service = MockRecordingService();
          when(service.stopRecording).thenAnswer((_) async => '/path');
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => InterviewRecording(
          questionNumber: 2,
          totalQuestions: 5,
          questionText: 'Q2',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) async {
          await cubit.cancelRecording();
        },
        expect: () => [
          isA<InterviewReady>()
              .having((s) => s.questionNumber, 'questionNumber', 2)
              .having((s) => s.totalQuestions, 'totalQuestions', 5)
              .having((s) => s.questionText, 'questionText', 'Q2'),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Ready state',
        build: () {
          final service = MockRecordingService();
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) async {
          await cubit.cancelRecording();
        },
      );
    });

    group('max duration timer', () {
      blocTest<InterviewCubit, InterviewState>(
        'auto-stops recording after max duration (2 seconds for test)',
        build: () {
          final service = MockRecordingService();
          when(service.startRecording).thenAnswer((_) async {});
          when(
            service.stopRecording,
          ).thenAnswer((_) async => '/path/audio.m4a');
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
            maxRecordingDuration: const Duration(seconds: 2),
          );
        },
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) async {
          await cubit.startRecording();
          await Future<void>.delayed(const Duration(seconds: 3));
        },
        expect: () => [
          isA<InterviewRecording>(),
          isA<InterviewUploading>().having(
            (s) => s.audioPath,
            'audioPath',
            '/path/audio.m4a',
          ),
          isA<InterviewTranscribing>(),
          isA<InterviewTranscriptReview>().having(
            (s) => s.transcript,
            'transcript',
            'Test transcript here',
          ),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'populates assistantText and isComplete in TranscriptReview',
        build: () {
          final service = MockRecordingService();
          when(
            service.stopRecording,
          ).thenAnswer((_) async => '/path/to/audio.m4a');
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(
              response: const TurnResponseData(
                transcript: 'My answer to question 3',
                timings: {'stt_ms': 800.0, 'llm_ms': 1200.0},
                questionNumber: 3,
                totalQuestions: 5,
                assistantText: 'What frameworks have you worked with?',
              ),
            ),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => InterviewRecording(
          questionNumber: 3,
          totalQuestions: 5,
          questionText: 'Previous question',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) async {
          await cubit.stopRecording();
          // Give async submitTurn time to complete
          await Future<void>.delayed(const Duration(milliseconds: 100));
        },
        expect: () => [
          isA<InterviewUploading>(),
          isA<InterviewTranscribing>(),
          isA<InterviewTranscriptReview>()
              .having(
                (s) => s.transcript,
                'transcript',
                'My answer to question 3',
              )
              .having(
                (s) => s.assistantText,
                'assistantText',
                'What frameworks have you worked with?',
              )
              .having((s) => s.isComplete, 'isComplete', false)
              .having((s) => s.questionNumber, 'questionNumber', 3),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'marks session complete when isComplete is true from backend',
        build: () {
          final service = MockRecordingService();
          when(
            service.stopRecording,
          ).thenAnswer((_) async => '/path/to/audio.m4a');
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(
              response: const TurnResponseData(
                transcript: 'My final answer',
                timings: {'stt_ms': 850.0, 'llm_ms': 1100.0},
                questionNumber: 5,
                totalQuestions: 5,
                assistantText: 'Great work! Session complete.',
                isComplete: true,
              ),
            ),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => InterviewRecording(
          questionNumber: 5,
          totalQuestions: 5,
          questionText: 'Final question',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) async {
          await cubit.stopRecording();
          // Give async submitTurn time to complete
          await Future<void>.delayed(const Duration(milliseconds: 100));
        },
        expect: () => [
          isA<InterviewUploading>(),
          isA<InterviewTranscribing>(),
          isA<InterviewTranscriptReview>()
              .having((s) => s.transcript, 'transcript', 'My final answer')
              .having(
                (s) => s.assistantText,
                'assistantText',
                'Great work! Session complete.',
              )
              .having((s) => s.isComplete, 'isComplete', true),
        ],
      );
    });

    group('cancel', () {
      blocTest<InterviewCubit, InterviewState>(
        'stops recording and emits InterviewIdle from Recording state',
        build: () {
          final service = MockRecordingService();
          when(service.stopRecording).thenAnswer((_) async => '/path');
          when(() => service.isRecording).thenAnswer((_) async => true);
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => InterviewRecording(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) => cubit.cancel(),
        expect: () => [const InterviewIdle()],
      );

      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewIdle from Ready state without stopping recording',
        build: () {
          final service = MockRecordingService();
          when(() => service.isRecording).thenAnswer((_) async => false);
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) => cubit.cancel(),
        expect: () => [const InterviewIdle()],
      );

      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewIdle from Speaking state',
        build: () {
          final service = MockRecordingService();
          when(() => service.isRecording).thenAnswer((_) async => false);
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => const InterviewSpeaking(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Q1',
          transcript: 'User transcript',
          responseText: 'Coach response',
          ttsAudioUrl: 'url',
        ),
        act: (cubit) => cubit.cancel(),
        expect: () => [const InterviewIdle()],
      );
    });

    group('close', () {
      test('disposes RecordingService', () async {
        final service = MockRecordingService();
        when(service.dispose).thenAnswer((_) async {});
        final cubit = InterviewCubit(
          recordingService: service,
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        );
        await cubit.close();
        verify(service.dispose).called(1);
      });
    });

    group('onResponseReady', () {
      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewSpeaking when called from Thinking state',
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
        seed: () => InterviewThinking(
          questionNumber: 1,
          totalQuestions: 5,
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
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) => cubit.onResponseReady(
          responseText: 'response',
          ttsAudioUrl: 'url',
        ),
      );
    });

    group('onSpeakingComplete', () {
      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewReady when called from Speaking state',
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
        seed: () => const InterviewSpeaking(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Q1',
          transcript: 'User transcript',
          responseText: 'Next question',
          ttsAudioUrl: 'url',
        ),
        act: (cubit) => cubit.onSpeakingComplete(),
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
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) => cubit.onSpeakingComplete(),
      );
    });

    group('handleError', () {
      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewError from any state',
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
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
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
        seed: () => InterviewUploading(
          questionNumber: 1,
          totalQuestions: 5,
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
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
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
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Test question',
        ),
        act: (cubit) => cubit.retry(),
      );
    });

    group('state data preservation', () {
      blocTest<InterviewCubit, InterviewState>(
        'preserves question number through flow',
        build: () {
          final service = MockRecordingService();
          when(service.startRecording).thenAnswer((_) async {});
          when(
            service.stopRecording,
          ).thenAnswer((_) async => '/path/audio.m4a');
          when(service.dispose).thenAnswer((_) async {});
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => const InterviewReady(
          questionNumber: 3,
          totalQuestions: 5,
          questionText: 'Question 3',
        ),
        act: (cubit) async {
          await cubit.startRecording();
          await cubit.stopRecording();
          // Give async submitTurn time to complete
          await Future<void>.delayed(const Duration(milliseconds: 100));
        },
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
          isA<InterviewTranscriptReview>().having(
            (s) => s.questionNumber,
            'questionNumber',
            3,
          ),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'preserves transcript through Thinking to Speaking',
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
        seed: () => InterviewThinking(
          questionNumber: 2,
          totalQuestions: 5,
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

    group('acceptTranscript', () {
      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewThinking when called from TranscriptReview',
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
        seed: () => const InterviewTranscriptReview(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question 1',
          transcript: 'User transcript',
          audioPath: '/path/audio.m4a',
        ),
        act: (cubit) async {
          await cubit.acceptTranscript();
        },
        expect: () => [
          isA<InterviewThinking>()
              .having((s) => s.questionNumber, 'questionNumber', 1)
              .having((s) => s.questionText, 'questionText', 'Question 1')
              .having((s) => s.transcript, 'transcript', 'User transcript')
              .having((s) => s.startTime, 'startTime', isA<DateTime>()),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Ready state',
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question 1',
        ),
        act: (cubit) async {
          await cubit.acceptTranscript();
        },
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Recording state',
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
        seed: () => InterviewRecording(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question 1',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) async {
          await cubit.acceptTranscript();
        },
      );

      blocTest<InterviewCubit, InterviewState>(
        'cleans up audio file when accepting transcript',
        build: () {
          final service = createMockRecordingService();
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => const InterviewTranscriptReview(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question 1',
          transcript: 'User transcript',
          audioPath: '/path/audio.m4a',
        ),
        act: (cubit) async {
          await cubit.acceptTranscript();
        },
        expect: () => [
          isA<InterviewThinking>(),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewSessionComplete when isComplete is true',
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
        seed: () => const InterviewTranscriptReview(
          questionNumber: 5,
          totalQuestions: 5,
          questionText: 'Final question',
          transcript: 'Final answer',
          audioPath: '/path/audio.m4a',
          isComplete: true,
          assistantText: 'Great job completing all questions!',
        ),
        act: (cubit) async {
          await cubit.acceptTranscript();
        },
        expect: () => [
          isA<InterviewSessionComplete>()
              .having((s) => s.totalQuestions, 'totalQuestions', 5)
              .having((s) => s.lastTranscript, 'lastTranscript', 'Final answer')
              .having(
                (s) => s.lastResponseText,
                'lastResponseText',
                'Great job completing all questions!',
              ),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'emits Thinking then Speaking when assistantText is present',
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
        seed: () => const InterviewTranscriptReview(
          questionNumber: 2,
          totalQuestions: 5,
          questionText: 'Question 2',
          transcript: 'My answer',
          audioPath: '/path/audio.m4a',
          assistantText: 'Next question from LLM',
        ),
        act: (cubit) async {
          await cubit.acceptTranscript();
        },
        expect: () => [
          isA<InterviewThinking>()
              .having((s) => s.questionNumber, 'questionNumber', 2)
              .having((s) => s.transcript, 'transcript', 'My answer'),
          isA<InterviewSpeaking>()
              .having((s) => s.questionNumber, 'questionNumber', 2)
              .having(
                (s) => s.responseText,
                'responseText',
                'Next question from LLM',
              )
              .having((s) => s.ttsAudioUrl, 'ttsAudioUrl', ''), // No TTS yet
        ],
      );
    });

    group('reRecord', () {
      blocTest<InterviewCubit, InterviewState>(
        'emits InterviewReady with same question when called from '
        'TranscriptReview',
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
        seed: () => const InterviewTranscriptReview(
          questionNumber: 2,
          totalQuestions: 5,
          questionText: 'Question 2',
          transcript: 'Bad transcript',
          audioPath: '/path/audio.m4a',
        ),
        act: (cubit) async {
          await cubit.reRecord();
        },
        expect: () => [
          isA<InterviewReady>()
              .having((s) => s.questionNumber, 'questionNumber', 2)
              .having((s) => s.totalQuestions, 'totalQuestions', 5)
              .having((s) => s.questionText, 'questionText', 'Question 2'),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Ready state',
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
        seed: () => const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question 1',
        ),
        act: (cubit) async {
          await cubit.reRecord();
        },
      );

      blocTest<InterviewCubit, InterviewState>(
        'does not emit when called from Thinking state',
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
        ),
        seed: () => InterviewThinking(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question 1',
          transcript: 'transcript',
          startTime: DateTime.now(),
        ),
        act: (cubit) async {
          await cubit.reRecord();
        },
      );

      blocTest<InterviewCubit, InterviewState>(
        'cleans up audio file when re-recording',
        build: () {
          final service = createMockRecordingService();
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => const InterviewTranscriptReview(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question 1',
          transcript: 'User transcript',
          audioPath: '/path/audio.m4a',
        ),
        act: (cubit) async {
          await cubit.reRecord();
        },
        expect: () => [
          isA<InterviewReady>(),
        ],
      );
    });

    group('low-confidence detection', () {
      blocTest<InterviewCubit, InterviewState>(
        'sets isLowConfidence to true for transcript with < 3 words',
        build: () {
          final service = createMockRecordingService(
            onStopRecording: () => Future.value('/path/audio.m4a'),
          );
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(
              response: const TurnResponseData(
                transcript: 'yes',
                timings: {},
                questionNumber: 1,
                totalQuestions: 5,
              ),
            ),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => InterviewRecording(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) async {
          await cubit.stopRecording();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        },
        skip: 2, // Skip Uploading and Transcribing
        expect: () => [
          isA<InterviewTranscriptReview>()
              .having((s) => s.transcript, 'transcript', 'yes')
              .having((s) => s.isLowConfidence, 'isLowConfidence', true),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'sets isLowConfidence to true for empty transcript',
        build: () {
          final service = createMockRecordingService(
            onStopRecording: () => Future.value('/path/audio.m4a'),
          );
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(
              response: const TurnResponseData(
                transcript: '',
                timings: {},
                questionNumber: 1,
                totalQuestions: 5,
              ),
            ),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => InterviewRecording(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) async {
          await cubit.stopRecording();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        },
        skip: 2,
        expect: () => [
          isA<InterviewTranscriptReview>()
              .having((s) => s.transcript, 'transcript', '')
              .having((s) => s.isLowConfidence, 'isLowConfidence', true),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'sets isLowConfidence to false for transcript with ≥ 3 words',
        build: () {
          final service = createMockRecordingService(
            onStopRecording: () => Future.value('/path/audio.m4a'),
          );
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(
              response: const TurnResponseData(
                transcript: 'I am a software engineer',
                timings: {},
                questionNumber: 1,
                totalQuestions: 5,
              ),
            ),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => InterviewRecording(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) async {
          await cubit.stopRecording();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        },
        skip: 2,
        expect: () => [
          isA<InterviewTranscriptReview>()
              .having(
                (s) => s.transcript,
                'transcript',
                'I am a software engineer',
              )
              .having((s) => s.isLowConfidence, 'isLowConfidence', false),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'sets isLowConfidence to false for exactly 3 words',
        build: () {
          final service = createMockRecordingService(
            onStopRecording: () => Future.value('/path/audio.m4a'),
          );
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(
              response: const TurnResponseData(
                transcript: 'I am ready',
                timings: {},
                questionNumber: 1,
                totalQuestions: 5,
              ),
            ),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => InterviewRecording(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Q1',
          recordingStartTime: DateTime.now(),
        ),
        act: (cubit) async {
          await cubit.stopRecording();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        },
        skip: 2,
        expect: () => [
          isA<InterviewTranscriptReview>()
              .having((s) => s.transcript, 'transcript', 'I am ready')
              .having((s) => s.isLowConfidence, 'isLowConfidence', false),
        ],
      );
    });

    group('re-record cycle', () {
      blocTest<InterviewCubit, InterviewState>(
        'full re-record cycle: Review → Ready → Recording → Review',
        build: () {
          final service = createMockRecordingService(
            onStartRecording: Future.value,
            onStopRecording: () => Future.value('/path/new-audio.m4a'),
          );
          return InterviewCubit(
            recordingService: service,
            turnRemoteDataSource: createMockTurnRemoteDataSource(
              response: const TurnResponseData(
                transcript: 'New transcript',
                timings: {},
                questionNumber: 1,
                totalQuestions: 5,
              ),
            ),
            sessionId: 'test-session-123',
            sessionToken: 'test-token',
            permissionService: createMockPermissionService(),
          );
        },
        seed: () => const InterviewTranscriptReview(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question 1',
          transcript: 'Bad transcript',
          audioPath: '/path/audio.m4a',
        ),
        act: (cubit) async {
          await cubit.reRecord();
          await cubit.startRecording();
          await cubit.stopRecording();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        },
        expect: () => [
          // Re-record → Ready
          isA<InterviewReady>()
              .having((s) => s.questionNumber, 'questionNumber', 1)
              .having((s) => s.questionText, 'questionText', 'Question 1'),
          // Start recording
          isA<InterviewRecording>().having(
            (s) => s.questionNumber,
            'questionNumber',
            1,
          ),
          // Stop recording → Uploading
          isA<InterviewUploading>()
              .having((s) => s.questionNumber, 'questionNumber', 1)
              .having((s) => s.audioPath, 'audioPath', '/path/new-audio.m4a'),
          // Transcribing
          isA<InterviewTranscribing>().having(
            (s) => s.questionNumber,
            'questionNumber',
            1,
          ),
          // New TranscriptReview
          isA<InterviewTranscriptReview>()
              .having((s) => s.questionNumber, 'questionNumber', 1)
              .having((s) => s.transcript, 'transcript', 'New transcript'),
        ],
      );

      blocTest<InterviewCubit, InterviewState>(
        'question context preserved through re-record cycle',
        build: () => InterviewCubit(
          recordingService: createMockRecordingService(),
          turnRemoteDataSource: createMockTurnRemoteDataSource(),
          sessionId: 'test-session-123',
          sessionToken: 'test-token',
          permissionService: createMockPermissionService(),
          totalQuestions: 10,
        ),
        seed: () => const InterviewTranscriptReview(
          questionNumber: 7,
          totalQuestions: 10,
          questionText: 'Question 7 text',
          transcript: 'Old transcript',
          audioPath: '/path/audio.m4a',
        ),
        act: (cubit) async {
          await cubit.reRecord();
        },
        expect: () => [
          isA<InterviewReady>()
              .having((s) => s.questionNumber, 'questionNumber', 7)
              .having((s) => s.totalQuestions, 'totalQuestions', 10)
              .having((s) => s.questionText, 'questionText', 'Question 7 text'),
        ],
      );
    });
  });
}
