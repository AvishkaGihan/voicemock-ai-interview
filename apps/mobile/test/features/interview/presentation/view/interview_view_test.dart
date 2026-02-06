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
  });
}
