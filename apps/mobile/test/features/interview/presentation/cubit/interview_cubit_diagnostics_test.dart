/// Unit tests for InterviewCubit diagnostics functionality.
library;

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/audio/audio_focus_service.dart';
import 'package:voicemock/core/audio/recording_service.dart';
import 'package:voicemock/core/models/session_diagnostics.dart';
import 'package:voicemock/core/models/turn_models.dart';
import 'package:voicemock/features/interview/data/datasources/turn_remote_data_source.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/domain/failures.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_state.dart';

class MockRecordingService extends Mock implements RecordingService {}

class MockTurnRemoteDataSource extends Mock implements TurnRemoteDataSource {}

class MockAudioFocusService extends Mock implements AudioFocusService {}

class TestInterviewCubit extends InterviewCubit {
  TestInterviewCubit({
    required super.audioFocusService,
    required super.recordingService,
    required super.turnRemoteDataSource,
    required super.sessionId,
    required super.sessionToken,
    super.initialQuestionText,
  });

  void seedState(InterviewState state) => emit(state);

  SessionDiagnostics seedErrorFromThinking({
    required InterviewThinking thinkingState,
    required ServerFailure failure,
    required String transcript,
  }) {
    seedState(thinkingState);
    handleError(failure, transcript: transcript);
    return diagnostics;
  }

  SessionDiagnostics clearAndSnapshotDiagnostics() {
    clearDiagnostics();
    return diagnostics;
  }
}

void main() {
  late MockRecordingService mockRecordingService;
  late MockTurnRemoteDataSource mockTurnRemoteDataSource;
  late MockAudioFocusService mockAudioFocusService;

  setUp(() {
    mockRecordingService = MockRecordingService();
    mockTurnRemoteDataSource = MockTurnRemoteDataSource();
    mockAudioFocusService = MockAudioFocusService();
    when(
      () => mockAudioFocusService.interruptions,
    ).thenAnswer((_) => const Stream<AudioInterruptionEvent>.empty());
    when(() => mockAudioFocusService.dispose()).thenAnswer((_) async {});
    registerFallbackValue(Uri());
  });

  group('InterviewCubit - Diagnostics', () {
    test('initializes SessionDiagnostics with session ID', () {
      final cubit = InterviewCubit(
        audioFocusService: mockAudioFocusService,
        recordingService: mockRecordingService,
        turnRemoteDataSource: mockTurnRemoteDataSource,
        sessionId: 'test-session-123',
        sessionToken: 'test-token',
      );

      expect(cubit.diagnostics.sessionId, 'test-session-123');
      expect(cubit.diagnostics.turnRecords, isEmpty);
      expect(cubit.diagnostics.lastErrorRequestId, isNull);
      expect(cubit.diagnostics.lastErrorStage, isNull);
    });

    test('accumulates diagnostics records across retryLLM turns', () async {
      final cubit = TestInterviewCubit(
        audioFocusService: mockAudioFocusService,
        recordingService: mockRecordingService,
        turnRemoteDataSource: mockTurnRemoteDataSource,
        sessionId: 'test-session',
        sessionToken: 'test-token',
      );

      when(
        () => mockTurnRemoteDataSource.submitTurn(
          sessionId: any(named: 'sessionId'),
          sessionToken: any(named: 'sessionToken'),
          transcript: any(named: 'transcript'),
        ),
      ).thenAnswer((invocation) async {
        final transcript = invocation.namedArguments[#transcript] as String;
        final turn = transcript == 'first transcript' ? 1 : 2;
        return TurnResponseWithId(
          data: TurnResponseData(
            transcript: transcript,
            timings: {
              'upload_ms': 10.0 * turn,
              'stt_ms': 20.0 * turn,
              'llm_ms': 30.0 * turn,
              'tts_ms': 40.0 * turn,
              'total_ms': 100.0 * turn,
            },
            questionNumber: turn,
            totalQuestions: 5,
            assistantText: 'Assistant $turn',
          ),
          requestId: 'req-$turn',
        );
      });

      cubit.seedErrorFromThinking(
        thinkingState: InterviewThinking(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question 1',
          transcript: 'first transcript',
          startTime: DateTime.now(),
        ),
        failure: const ServerFailure(
          message: 'LLM failed',
          requestId: 'req-error-1',
          retryable: true,
          stage: 'llm',
          code: 'llm_timeout',
        ),
        transcript: 'first transcript',
      );
      await cubit.retryLLM('first transcript');

      cubit.seedErrorFromThinking(
        thinkingState: InterviewThinking(
          questionNumber: 2,
          totalQuestions: 5,
          questionText: 'Question 2',
          transcript: 'second transcript',
          startTime: DateTime.now(),
        ),
        failure: const ServerFailure(
          message: 'LLM failed again',
          requestId: 'req-error-2',
          retryable: true,
          stage: 'llm',
          code: 'llm_timeout',
        ),
        transcript: 'second transcript',
      );
      await cubit.retryLLM('second transcript');

      final diagnostics = cubit.diagnostics;
      expect(diagnostics.turnRecords, hasLength(2));
      expect(diagnostics.turnRecords[0].requestId, 'req-1');
      expect(diagnostics.turnRecords[0].ttsMs, 40.0);
      expect(diagnostics.turnRecords[1].requestId, 'req-2');
      expect(diagnostics.turnRecords[1].ttsMs, 80.0);
    });

    test('records error diagnostics on failed turn', () {
      // Arrange
      final cubit = InterviewCubit(
        audioFocusService: mockAudioFocusService,
        recordingService: mockRecordingService,
        turnRemoteDataSource: mockTurnRemoteDataSource,
        sessionId: 'test-session',
        sessionToken: 'test-token',
        initialQuestionText: 'Initial question',
      );

      const failure = ServerFailure(
        message: 'STT failed',
        requestId: 'req-err-123',
        retryable: true,
        stage: 'stt',
        code: 'stt_timeout',
      );

      // Act
      cubit.handleError(failure);

      // Assert
      final diagnostics = cubit.diagnostics;
      expect(diagnostics.lastErrorRequestId, 'req-err-123');
      expect(diagnostics.lastErrorStage, 'stt');
      expect(cubit.state, isA<InterviewError>());
    });

    test(
      'does not record error if request ID or stage is missing',
      () {
        // Arrange
        final cubit = InterviewCubit(
          audioFocusService: mockAudioFocusService,
          recordingService: mockRecordingService,
          turnRemoteDataSource: mockTurnRemoteDataSource,
          sessionId: 'test-session',
          sessionToken: 'test-token',
        );

        const failure = ServerFailure(
          message: 'Unknown error',
          code: 'unknown',
        );

        // Act
        cubit.handleError(failure);

        // Assert
        final diagnostics = cubit.diagnostics;
        expect(diagnostics.lastErrorRequestId, isNull);
        expect(diagnostics.lastErrorStage, isNull);
      },
    );

    test('clearDiagnostics resets turn records and error metadata', () {
      final cubit = TestInterviewCubit(
        audioFocusService: mockAudioFocusService,
        recordingService: mockRecordingService,
        turnRemoteDataSource: mockTurnRemoteDataSource,
        sessionId: 'test-session',
        sessionToken: 'test-token',
      );

      final diagnosticsBeforeClear = cubit.seedErrorFromThinking(
        thinkingState: InterviewThinking(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question',
          transcript: 'Transcript',
          startTime: DateTime.now(),
        ),
        failure: const ServerFailure(
          message: 'Failure',
          requestId: 'req-clear-1',
          retryable: true,
          stage: 'llm',
          code: 'llm_error',
        ),
        transcript: 'Transcript',
      );

      expect(diagnosticsBeforeClear.lastErrorRequestId, 'req-clear-1');

      final diagnostics = cubit.clearAndSnapshotDiagnostics();

      expect(diagnostics.sessionId, 'test-session');
      expect(diagnostics.turnRecords, isEmpty);
      expect(diagnostics.lastErrorRequestId, isNull);
      expect(diagnostics.lastErrorStage, isNull);
    });
  });
}
