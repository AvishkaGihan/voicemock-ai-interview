import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/features/interview/presentation/cubit/cubit.dart';
import 'package:voicemock/features/interview/presentation/view/'
    'interview_view.dart';
import 'package:voicemock/features/interview/presentation/widgets/hold_to_talk_button.dart';
import 'package:voicemock/features/interview/presentation/widgets/transcript_review_card.dart';

class MockInterviewCubit extends MockCubit<InterviewState>
    implements InterviewCubit {}

void main() {
  late InterviewCubit mockCubit;

  setUp(() {
    mockCubit = MockInterviewCubit();
  });

  group('InterviewView', () {
    testWidgets('renders InterviewView', (tester) async {
      when(() => mockCubit.state).thenReturn(const InterviewIdle());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<InterviewCubit>.value(
            value: mockCubit,
            child: const InterviewView(),
          ),
        ),
      );

      expect(find.byType(InterviewView), findsOneWidget);
    });

    testWidgets('shows Hold-to-Talk button in Ready state', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const InterviewReady(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Tell me about yourself',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<InterviewCubit>.value(
            value: mockCubit,
            child: const InterviewView(),
          ),
        ),
      );

      expect(find.text('Hold to talk'), findsOneWidget);
    });

    testWidgets('shows stepper during Uploading state', (tester) async {
      when(() => mockCubit.state).thenReturn(
        InterviewUploading(
          questionNumber: 1,
          questionText: 'Q1',
          audioPath: '/path',
          startTime: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<InterviewCubit>.value(
            value: mockCubit,
            child: const InterviewView(),
          ),
        ),
      );

      expect(find.text('Uploading'), findsOneWidget);
    });

    testWidgets('shows stepper during Transcribing state', (tester) async {
      when(() => mockCubit.state).thenReturn(
        InterviewTranscribing(
          questionNumber: 1,
          questionText: 'Q1',
          startTime: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<InterviewCubit>.value(
            value: mockCubit,
            child: const InterviewView(),
          ),
        ),
      );

      expect(find.text('Transcribing'), findsOneWidget);
      expect(find.text('Uploading'), findsOneWidget);
      expect(find.text('Thinking'), findsOneWidget);
      expect(find.text('Speaking'), findsOneWidget);
    });

    testWidgets('shows transcript in Thinking state', (tester) async {
      when(() => mockCubit.state).thenReturn(
        InterviewThinking(
          questionNumber: 1,
          questionText: 'Tell me about a challenge you faced',
          transcript: 'I faced a bug in production and fixed it quickly',
          startTime: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<InterviewCubit>.value(
            value: mockCubit,
            child: const InterviewView(),
          ),
        ),
      );

      expect(find.text('You said:'), findsOneWidget);
      expect(
        find.text('I faced a bug in production and fixed it quickly'),
        findsOneWidget,
      );
      expect(find.text('Thinking'), findsOneWidget);
    });

    testWidgets('Hold-to-Talk button is disabled during Speaking', (
      tester,
    ) async {
      when(() => mockCubit.state).thenReturn(
        const InterviewSpeaking(
          questionNumber: 1,
          questionText: 'Q1',
          transcript: 'User said this',
          responseText: 'Coach response',
          ttsAudioUrl: 'url',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<InterviewCubit>.value(
            value: mockCubit,
            child: const InterviewView(),
          ),
        ),
      );

      expect(find.text('Waiting...'), findsOneWidget);
    });

    testWidgets('shows Turn Card with question', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const InterviewReady(
          questionNumber: 2,
          totalQuestions: 5,
          questionText: 'What motivates you?',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<InterviewCubit>.value(
            value: mockCubit,
            child: const InterviewView(),
          ),
        ),
      );

      expect(find.text('Question 2 of 5'), findsOneWidget);
      expect(find.text('What motivates you?'), findsOneWidget);
    });

    group('HoldToTalkButton recording integration', () {
      testWidgets('onPressStart triggers cubit.startRecording', (
        tester,
      ) async {
        when(() => mockCubit.state).thenReturn(
          const InterviewReady(
            questionNumber: 1,
            totalQuestions: 5,
            questionText: 'Test question',
          ),
        );
        when(() => mockCubit.startRecording()).thenAnswer((_) async {});
        when(() => mockCubit.stopRecording()).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InterviewCubit>.value(
              value: mockCubit,
              child: const InterviewView(),
            ),
          ),
        );

        final button = find.byType(HoldToTalkButton);
        expect(button, findsOneWidget);

        // Simulate long press (calls both start and end)
        await tester.longPress(button);
        await tester.pumpAndSettle();

        verify(() => mockCubit.startRecording()).called(1);
      });

      testWidgets('onPressEnd triggers cubit.stopRecording', (tester) async {
        when(() => mockCubit.state).thenReturn(
          InterviewRecording(
            questionNumber: 1,
            totalQuestions: 5,
            questionText: 'Test question',
            recordingStartTime: DateTime.now(),
          ),
        );
        when(() => mockCubit.startRecording()).thenAnswer((_) async {});
        when(() => mockCubit.stopRecording()).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InterviewCubit>.value(
              value: mockCubit,
              child: const InterviewView(),
            ),
          ),
        );

        final button = find.byType(HoldToTalkButton);
        expect(button, findsOneWidget);

        // Simulate long-press (start and end)
        await tester.longPress(button);
        await tester.pump();

        // Both called because long press triggers start and end
        verify(() => mockCubit.stopRecording()).called(1);
      });

      testWidgets('shows recording duration during Recording state', (
        tester,
      ) async {
        final recordingStartTime = DateTime.now().subtract(
          const Duration(seconds: 5),
        );
        when(() => mockCubit.state).thenReturn(
          InterviewRecording(
            questionNumber: 1,
            totalQuestions: 5,
            questionText: 'Test question',
            recordingStartTime: recordingStartTime,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InterviewCubit>.value(
              value: mockCubit,
              child: const InterviewView(),
            ),
          ),
        );

        // Verify Release to send text is displayed (indicates recording)
        expect(find.text('Release to send'), findsOneWidget);

        // Note: Actual duration text format depends on HoldToTalkButton
        // implementation which uses recordingDuration parameter to format
        // the time display
      });
    });

    group('Transcript Review', () {
      testWidgets('shows TranscriptReviewCard when in TranscriptReview state', (
        tester,
      ) async {
        when(() => mockCubit.state).thenReturn(
          const InterviewTranscriptReview(
            questionNumber: 1,
            questionText: 'What is your greatest strength?',
            transcript: 'My greatest strength is problem solving',
            audioPath: '/path/audio.m4a',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InterviewCubit>.value(
              value: mockCubit,
              child: const InterviewView(),
            ),
          ),
        );

        expect(find.byType(TranscriptReviewCard), findsOneWidget);
        expect(find.text('What we heard:'), findsOneWidget);
        expect(
          find.text('My greatest strength is problem solving'),
          findsOneWidget,
        );
      });

      testWidgets('Hold-to-Talk button disabled during transcript review', (
        tester,
      ) async {
        when(() => mockCubit.state).thenReturn(
          const InterviewTranscriptReview(
            questionNumber: 1,
            questionText: 'Question 1',
            transcript: 'Answer',
            audioPath: '/path/audio.m4a',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InterviewCubit>.value(
              value: mockCubit,
              child: const InterviewView(),
            ),
          ),
        );

        expect(find.text('Waiting...'), findsOneWidget);
      });

      testWidgets('Accept button calls cubit.acceptTranscript()', (
        tester,
      ) async {
        when(() => mockCubit.state).thenReturn(
          const InterviewTranscriptReview(
            questionNumber: 1,
            questionText: 'Question 1',
            transcript: 'Answer',
            audioPath: '/path/audio.m4a',
          ),
        );
        when(() => mockCubit.acceptTranscript()).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InterviewCubit>.value(
              value: mockCubit,
              child: const InterviewView(),
            ),
          ),
        );

        final acceptButton = find.widgetWithText(
          FilledButton,
          'Accept & Continue',
        );
        await tester.tap(acceptButton);
        await tester.pump();

        verify(() => mockCubit.acceptTranscript()).called(1);
      });

      testWidgets('Re-record button calls cubit.reRecord()', (tester) async {
        when(() => mockCubit.state).thenReturn(
          const InterviewTranscriptReview(
            questionNumber: 1,
            questionText: 'Question 1',
            transcript: 'Answer',
            audioPath: '/path/audio.m4a',
          ),
        );
        when(() => mockCubit.reRecord()).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InterviewCubit>.value(
              value: mockCubit,
              child: const InterviewView(),
            ),
          ),
        );

        final reRecordButton = find.widgetWithText(OutlinedButton, 'Re-record');
        await tester.tap(reRecordButton);
        await tester.pump();

        verify(() => mockCubit.reRecord()).called(1);
      });

      testWidgets('Voice Pipeline Stepper shows Review stage', (tester) async {
        when(() => mockCubit.state).thenReturn(
          const InterviewTranscriptReview(
            questionNumber: 1,
            questionText: 'Question 1',
            transcript: 'Answer',
            audioPath: '/path/audio.m4a',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InterviewCubit>.value(
              value: mockCubit,
              child: const InterviewView(),
            ),
          ),
        );

        expect(find.text('Review'), findsOneWidget);
        expect(find.text('Uploading'), findsOneWidget);
        expect(find.text('Transcribing'), findsOneWidget);
        expect(find.text('Thinking'), findsOneWidget);
        expect(find.text('Speaking'), findsOneWidget);
      });

      testWidgets('shows low-confidence hint when isLowConfidence is true', (
        tester,
      ) async {
        when(() => mockCubit.state).thenReturn(
          const InterviewTranscriptReview(
            questionNumber: 1,
            questionText: 'Question 1',
            transcript: 'um',
            audioPath: '/path/audio.m4a',
            isLowConfidence: true,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InterviewCubit>.value(
              value: mockCubit,
              child: const InterviewView(),
            ),
          ),
        );

        expect(
          find.text("If this isn't right, re-record."),
          findsOneWidget,
        );
      });
    });

    group('Session Complete', () {
      testWidgets('shows SessionCompleteCard during SessionComplete state', (
        tester,
      ) async {
        when(() => mockCubit.state).thenReturn(
          const InterviewSessionComplete(
            totalQuestions: 5,
            lastTranscript: 'My final answer',
            lastResponseText: 'Great job! Session complete.',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InterviewCubit>.value(
              value: mockCubit,
              child: const InterviewView(),
            ),
          ),
        );

        expect(find.text('Session Complete'), findsOneWidget);
        expect(
          find.text('Great job! You completed all 5 questions.'),
          findsOneWidget,
        );
        expect(find.text('Back to Home'), findsOneWidget);
        expect(find.text('Start New Session'), findsOneWidget);
      });

      testWidgets('hides Hold-to-Talk button during SessionComplete', (
        tester,
      ) async {
        when(() => mockCubit.state).thenReturn(
          const InterviewSessionComplete(
            totalQuestions: 5,
            lastTranscript: 'My final answer',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InterviewCubit>.value(
              value: mockCubit,
              child: const InterviewView(),
            ),
          ),
        );

        expect(find.byType(HoldToTalkButton), findsNothing);
      });

      testWidgets('hides stepper during SessionComplete', (
        tester,
      ) async {
        when(() => mockCubit.state).thenReturn(
          const InterviewSessionComplete(
            totalQuestions: 5,
            lastTranscript: 'My final answer',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InterviewCubit>.value(
              value: mockCubit,
              child: const InterviewView(),
            ),
          ),
        );

        expect(find.text('Uploading'), findsNothing);
        expect(find.text('Transcribing'), findsNothing);
        expect(find.text('Thinking'), findsNothing);
        expect(find.text('Speaking'), findsNothing);
      });
    });

    group('Cancel Session', () {
      testWidgets('shows end session dialog when close button tapped', (
        tester,
      ) async {
        when(() => mockCubit.state).thenReturn(
          const InterviewReady(
            questionNumber: 1,
            totalQuestions: 5,
            questionText: 'Tell me about yourself',
          ),
        );
        when(() => mockCubit.cancel()).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InterviewCubit>.value(
              value: mockCubit,
              child: const InterviewView(),
            ),
          ),
        );

        // Tap the close button in the app bar
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Dialog should be shown
        expect(find.text('End session?'), findsOneWidget);
        expect(
          find.text('Are you sure you want to end this interview session?'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('End'), findsOneWidget);
      });

      testWidgets('cancels session when dialog confirmed', (
        tester,
      ) async {
        when(() => mockCubit.state).thenReturn(
          const InterviewReady(
            questionNumber: 1,
            totalQuestions: 5,
            questionText: 'Tell me about yourself',
          ),
        );
        when(() => mockCubit.cancel()).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InterviewCubit>.value(
              value: mockCubit,
              child: const InterviewView(),
            ),
          ),
        );

        // Tap the close button
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Confirm end session
        await tester.tap(find.text('End'));
        await tester.pumpAndSettle();

        // Verify cubit.cancel() was called
        verify(() => mockCubit.cancel()).called(1);
      });

      testWidgets('does not cancel when dialog dismissed', (
        tester,
      ) async {
        when(() => mockCubit.state).thenReturn(
          const InterviewReady(
            questionNumber: 1,
            totalQuestions: 5,
            questionText: 'Tell me about yourself',
          ),
        );
        when(() => mockCubit.cancel()).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InterviewCubit>.value(
              value: mockCubit,
              child: const InterviewView(),
            ),
          ),
        );

        // Tap the close button
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Cancel the dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify cubit.cancel() was NOT called
        verifyNever(() => mockCubit.cancel());
      });
    });
  });
}
