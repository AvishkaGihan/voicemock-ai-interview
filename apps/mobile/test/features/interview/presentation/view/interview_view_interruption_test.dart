import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/features/interview/presentation/cubit/cubit.dart';
import 'package:voicemock/features/interview/presentation/view/interview_view.dart';

class MockInterviewCubit extends MockCubit<InterviewState>
    implements InterviewCubit {}

void main() {
  group('InterviewView - Interruption Handling', () {
    late MockInterviewCubit mockCubit;

    setUp(() {
      mockCubit = MockInterviewCubit();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: BlocProvider<InterviewCubit>.value(
          value: mockCubit,
          child: const InterviewView(),
        ),
      );
    }

    testWidgets(
      'SnackBar appears when recording is interrupted',
      (tester) async {
        // Start with normal Ready state
        when(() => mockCubit.state).thenReturn(
          const InterviewReady(
            questionNumber: 1,
            totalQuestions: 5,
            questionText: 'Test question',
          ),
        );

        whenListen(
          mockCubit,
          Stream<InterviewState>.fromIterable([
            const InterviewReady(
              questionNumber: 1,
              totalQuestions: 5,
              questionText: 'Test question',
            ),
            const InterviewReady(
              questionNumber: 1,
              totalQuestions: 5,
              questionText: 'Test question',
              wasInterrupted: true, // Interrupted!
            ),
          ]),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Trigger state change by pumping again
        await tester.pump();

        // SnackBar should appear
        expect(
          find.text('Recording interrupted — hold to try again'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'SnackBar does not appear when not interrupted',
      (tester) async {
        when(() => mockCubit.state).thenReturn(
          const InterviewReady(
            questionNumber: 1,
            totalQuestions: 5,
            questionText: 'Test question',
          ),
        );

        whenListen(
          mockCubit,
          Stream<InterviewState>.fromIterable([
            const InterviewReady(
              questionNumber: 1,
              totalQuestions: 5,
              questionText: 'Test question',
            ),
          ]),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // No SnackBar should appear
        expect(
          find.text('Recording interrupted — hold to try again'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'user can restart recording after interruption',
      (tester) async {
        when(() => mockCubit.state).thenReturn(
          const InterviewReady(
            questionNumber: 1,
            totalQuestions: 5,
            questionText: 'Test question',
            wasInterrupted: true, // After interruption
          ),
        );

        whenListen(
          mockCubit,
          Stream<InterviewState>.fromIterable([
            const InterviewReady(
              questionNumber: 1,
              totalQuestions: 5,
              questionText: 'Test question',
              wasInterrupted: true,
            ),
          ]),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Verify hold-to-talk button is still available
        expect(find.text('Hold to talk'), findsOneWidget);

        // SnackBar shown explaining interruption
        await tester.pump();
        expect(
          find.text('Recording interrupted — hold to try again'),
          findsOneWidget,
        );
      },
    );
  });
}
