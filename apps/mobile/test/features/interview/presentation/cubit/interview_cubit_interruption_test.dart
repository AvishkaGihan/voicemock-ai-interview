import 'dart:async' show StreamController, unawaited;

import 'package:audio_session/audio_session.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/audio/audio_focus_service.dart';
import 'package:voicemock/core/audio/recording_service.dart';
import 'package:voicemock/core/permissions/permissions.dart';
import 'package:voicemock/features/interview/data/data.dart';
import 'package:voicemock/features/interview/presentation/cubit/cubit.dart';

class MockRecordingService extends Mock implements RecordingService {}

class MockTurnRemoteDataSource extends Mock implements TurnRemoteDataSource {}

class MockAudioFocusService extends Mock implements AudioFocusService {}

class MockPermissionService extends Mock implements PermissionService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InterviewCubit - Interruption Handling', () {
    late MockRecordingService mockRecordingService;
    late MockTurnRemoteDataSource mockTurnRemoteDataSource;
    late MockAudioFocusService mockAudioFocusService;
    late StreamController<AudioInterruptionEvent> interruptionController;

    setUp(() {
      mockRecordingService = MockRecordingService();
      mockTurnRemoteDataSource = MockTurnRemoteDataSource();
      mockAudioFocusService = MockAudioFocusService();
      when(() => mockAudioFocusService.dispose()).thenAnswer((_) async {});
      interruptionController =
          StreamController<AudioInterruptionEvent>.broadcast();

      when(
        () => mockAudioFocusService.interruptions,
      ).thenAnswer((_) => interruptionController.stream);
      when(() => mockRecordingService.dispose()).thenAnswer((_) async {});
    });

    tearDown(() {
      unawaited(interruptionController.close());
    });

    InterviewCubit createCubit({
      int questionNumber = 1,
      int totalQuestions = 5,
      String? initialQuestionText = 'Test question',
    }) {
      final mockPermissionService = MockPermissionService();
      when(
        mockPermissionService.checkMicrophonePermission,
      ).thenAnswer((_) async => MicrophonePermissionStatus.granted);

      return InterviewCubit(
        recordingService: mockRecordingService,
        turnRemoteDataSource: mockTurnRemoteDataSource,
        sessionId: 'test-session',
        sessionToken: 'test-token',
        audioFocusService: mockAudioFocusService,
        permissionService: mockPermissionService,
        questionNumber: questionNumber,
        totalQuestions: totalQuestions,
        initialQuestionText: initialQuestionText,
      );
    }

    blocTest<InterviewCubit, InterviewState>(
      'interruption during Recording → transitions to Ready '
      'with same question',
      build: createCubit,
      act: (cubit) async {
        // Start recording to move to Recording state
        when(
          () => mockRecordingService.startRecording(),
        ).thenAnswer((_) async {});
        await cubit.startRecording();

        // Simulate interruption
        when(
          () => mockRecordingService.stopRecording(),
        ).thenAnswer((_) async => '/tmp/recording.m4a');
        when(
          () => mockRecordingService.deleteRecording('/tmp/recording.m4a'),
        ).thenAnswer((_) async {});

        final interruptionEvent = AudioInterruptionEvent(
          true, // begin
          AudioInterruptionType.unknown,
        );
        interruptionController.add(interruptionEvent);

        // Allow stream event to propagate
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      expect: () => [
        isA<InterviewRecording>().having(
          (s) => s.questionText,
          'questionText',
          'Test question',
        ),
        isA<InterviewReady>()
            .having((s) => s.questionText, 'questionText', 'Test question')
            .having((s) => s.wasInterrupted, 'wasInterrupted', true),
      ],
      verify: (_) {
        verify(() => mockRecordingService.stopRecording()).called(1);
        verify(
          () => mockRecordingService.deleteRecording('/tmp/recording.m4a'),
        ).called(1);
      },
    );

    blocTest<InterviewCubit, InterviewState>(
      'interruption during Ready → no state change',
      build: createCubit,
      act: (cubit) async {
        // Start in Ready state (initial state with question)
        final interruptionEvent = AudioInterruptionEvent(
          true, // begin
          AudioInterruptionType.unknown,
        );
        interruptionController.add(interruptionEvent);

        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      expect: () => <InterviewState>[],
      verify: (_) {
        verifyNever(() => mockRecordingService.stopRecording());
        verifyNever(() => mockRecordingService.deleteRecording(any()));
      },
    );

    blocTest<InterviewCubit, InterviewState>(
      'interruption during Uploading → no state change',
      build: createCubit,
      seed: () => InterviewUploading(
        questionNumber: 1,
        totalQuestions: 5,
        questionText: 'Test question',
        audioPath: '/tmp/recording.m4a',
        startTime: DateTime.now(),
      ),
      act: (cubit) async {
        // Simulate interruption during Uploading
        final interruptionEvent = AudioInterruptionEvent(
          true, // begin
          AudioInterruptionType.unknown,
        );
        interruptionController.add(interruptionEvent);

        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      expect: () => <InterviewState>[],
      verify: (_) {
        // Interruption during non-recording shouldn't call stop/delete
        verifyNever(() => mockRecordingService.stopRecording());
        verifyNever(() => mockRecordingService.deleteRecording(any()));
      },
    );

    blocTest<InterviewCubit, InterviewState>(
      'interruption during Thinking → no state change',
      build: createCubit,
      seed: () => InterviewThinking(
        questionNumber: 1,
        totalQuestions: 5,
        questionText: 'Test question',
        transcript: 'Test transcript',
        startTime: DateTime.now(),
      ),
      act: (cubit) async {
        // Simulate interruption
        final interruptionEvent = AudioInterruptionEvent(
          true, // begin
          AudioInterruptionType.unknown,
        );
        interruptionController.add(interruptionEvent);

        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      expect: () => <InterviewState>[],
      verify: (_) {
        verifyNever(() => mockRecordingService.stopRecording());
        verifyNever(() => mockRecordingService.deleteRecording(any()));
      },
    );

    blocTest<InterviewCubit, InterviewState>(
      'interruption during Speaking → transitions to Ready',
      build: createCubit,
      seed: () => const InterviewSpeaking(
        questionNumber: 1,
        totalQuestions: 5,
        questionText: 'Test question',
        transcript: 'Test transcript',
        responseText: 'Test response',
        ttsAudioUrl: '',
      ),
      act: (cubit) async {
        // Simulate interruption
        final interruptionEvent = AudioInterruptionEvent(
          true, // begin
          AudioInterruptionType.unknown,
        );
        interruptionController.add(interruptionEvent);

        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      expect: () => [
        isA<InterviewReady>()
            .having((s) => s.questionNumber, 'questionNumber', 2)
            .having((s) => s.questionText, 'questionText', 'Test response'),
      ],
      verify: (_) {
        verifyNever(() => mockRecordingService.stopRecording());
        verifyNever(() => mockRecordingService.deleteRecording(any()));
      },
    );

    blocTest<InterviewCubit, InterviewState>(
      'after interruption, can start new recording successfully',
      build: createCubit,
      act: (cubit) async {
        // Start recording
        when(
          () => mockRecordingService.startRecording(),
        ).thenAnswer((_) async {});
        await cubit.startRecording();

        // Simulate interruption
        when(
          () => mockRecordingService.stopRecording(),
        ).thenAnswer((_) async => '/tmp/recording.m4a');
        when(
          () => mockRecordingService.deleteRecording('/tmp/recording.m4a'),
        ).thenAnswer((_) async {});

        final interruptionEvent = AudioInterruptionEvent(
          true, // begin
          AudioInterruptionType.unknown,
        );
        interruptionController.add(interruptionEvent);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Start recording again
        await cubit.startRecording();
      },
      expect: () => [
        isA<InterviewRecording>(), // First recording
        isA<InterviewReady>() // After interruption
            .having((s) => s.wasInterrupted, 'wasInterrupted', true),
        isA<InterviewRecording>(), // Second recording
      ],
      verify: (_) {
        verify(() => mockRecordingService.startRecording()).called(2);
      },
    );

    blocTest<InterviewCubit, InterviewState>(
      'recording service stopRecording and deleteRecording '
      'called on interruption',
      build: createCubit,
      act: (cubit) async {
        // Start recording
        when(
          () => mockRecordingService.startRecording(),
        ).thenAnswer((_) async {});
        await cubit.startRecording();

        // Simulate interruption
        when(
          () => mockRecordingService.stopRecording(),
        ).thenAnswer((_) async => '/tmp/test.m4a');
        when(
          () => mockRecordingService.deleteRecording('/tmp/test.m4a'),
        ).thenAnswer((_) async {});

        final interruptionEvent = AudioInterruptionEvent(
          true, // begin
          AudioInterruptionType.unknown,
        );
        interruptionController.add(interruptionEvent);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      verify: (_) {
        verify(() => mockRecordingService.stopRecording()).called(1);
        verify(
          () => mockRecordingService.deleteRecording('/tmp/test.m4a'),
        ).called(1);
      },
    );
  });
}
