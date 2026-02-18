import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/audio/audio_focus_service.dart';
import 'package:voicemock/core/audio/recording_service.dart';
import 'package:voicemock/core/models/models.dart';
import 'package:voicemock/core/permissions/permissions.dart';
import 'package:voicemock/features/interview/data/data.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_state.dart';
import 'package:voicemock/features/interview/presentation/widgets/turn_card.dart';

class _MockRecordingService extends Mock implements RecordingService {}

class _MockTurnRemoteDataSource extends Mock implements TurnRemoteDataSource {}

class _MockAudioFocusService extends Mock implements AudioFocusService {}

class _MockPermissionService extends Mock implements PermissionService {}

void main() {
  const coachingFeedback = CoachingFeedback(
    dimensions: [
      CoachingDimension(
        label: 'Clarity',
        score: 4,
        tip: 'Lead with your strongest point first.',
      ),
      CoachingDimension(
        label: 'Relevance',
        score: 5,
        tip: 'Tie each example to the role you target.',
      ),
    ],
    summaryTip: 'Open with one clear thesis and support it with one metric.',
  );

  group('CoachingFeedback UI', () {
    testWidgets('shows summary and dimensions on TurnCard', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TurnCard(
              questionNumber: 1,
              totalQuestions: 5,
              questionText: 'Tell me about yourself',
              responseText: 'Can you share one challenge you solved?',
              coachingFeedback: coachingFeedback,
            ),
          ),
        ),
      );

      expect(find.text('Top Tip'), findsOneWidget);
      expect(find.textContaining('clear thesis'), findsOneWidget);
      expect(find.textContaining('Clarity'), findsOneWidget);
      expect(find.textContaining('4/5'), findsOneWidget);
      expect(find.textContaining('Relevance'), findsOneWidget);
    });

    testWidgets('hides coaching section when feedback is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TurnCard(
              questionNumber: 1,
              totalQuestions: 5,
              questionText: 'Tell me about yourself',
              responseText: 'Can you share one challenge you solved?',
            ),
          ),
        ),
      );

      expect(find.text('Top Tip'), findsNothing);
    });
  });

  group('CoachingFeedback state transitions', () {
    blocTest<InterviewCubit, InterviewState>(
      'preserves coaching feedback from Thinking -> Speaking -> Ready',
      build: () {
        final recordingService = _MockRecordingService();
        final turnRemoteDataSource = _MockTurnRemoteDataSource();
        final audioFocusService = _MockAudioFocusService();
        final permissionService = _MockPermissionService();
        final interruptionController =
            StreamController<AudioInterruptionEvent>.broadcast();

        when(recordingService.dispose).thenAnswer((_) async {});
        when(() => recordingService.isRecording).thenAnswer((_) async => false);
        when(
          () => audioFocusService.interruptions,
        ).thenAnswer((_) => interruptionController.stream);
        when(permissionService.checkMicrophonePermission).thenAnswer(
          (_) async => MicrophonePermissionStatus.granted,
        );

        return InterviewCubit(
          recordingService: recordingService,
          turnRemoteDataSource: turnRemoteDataSource,
          sessionId: 'session-1',
          sessionToken: 'token-1',
          audioFocusService: audioFocusService,
          permissionService: permissionService,
          initialQuestionText: 'Tell me about yourself',
        );
      },
      seed: () => InterviewThinking(
        questionNumber: 1,
        totalQuestions: 5,
        questionText: 'Tell me about yourself',
        transcript: 'I built a distributed pipeline.',
        startTime: DateTime.now(),
        coachingFeedback: coachingFeedback,
      ),
      act: (cubit) {
        cubit.onResponseReady(
          responseText: 'Great. How did you test reliability?',
          ttsAudioUrl: '',
          coachingFeedback: coachingFeedback,
        );
      },
      expect: () => [
        isA<InterviewSpeaking>().having(
          (state) => state.coachingFeedback,
          'speaking.coachingFeedback',
          coachingFeedback,
        ),
        isA<InterviewReady>().having(
          (state) => state.coachingFeedback,
          'ready.coachingFeedback',
          coachingFeedback,
        ),
      ],
    );
  });
}
