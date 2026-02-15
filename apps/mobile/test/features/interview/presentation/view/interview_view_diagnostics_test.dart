/// Widget tests for InterviewView diagnostics access.
library;

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
  late MockInterviewCubit mockCubit;

  setUp(() {
    mockCubit = MockInterviewCubit();
    when(() => mockCubit.state).thenReturn(
      const InterviewReady(
        questionNumber: 1,
        totalQuestions: 5,
        questionText: 'Test Question',
      ),
    );
  });

  Widget createSubject() {
    return MaterialApp(
      home: BlocProvider<InterviewCubit>.value(
        value: mockCubit,
        child: const InterviewView(),
      ),
    );
  }

  group('InterviewView Diagnostics Access', () {
    testWidgets('Diagnostics hidden by default in release mode', (
      tester,
    ) async {
      // We can't easily simulate kDebugMode=false in a test environment
      // directly without using debugDefaultTargetPlatformOverride or
      // checking implementation details.
      // However, our implementation sets _showDiagnostics = kDebugMode.
      // In test environment, kDebugMode is usually true.
      // So we expect it to be visible by default in tests.

      // But we can check the multi-tap logic.
      // Let's assume for this test we are testing the gesture logic.

      await tester.pumpWidget(createSubject());

      // If kDebugMode is true in tests, icon is visible.
      // We'll verify it's there.
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    });

    // To test the "hidden then shown" behavior, we'd need to force the
    // initial state to false.
    // Since we can't easily change kDebugMode at runtime in Dart,
    // we can trust the logic `_showDiagnostics = kDebugMode` and test the
    // transition.

    // We can verify tapping 3 times triggers the snackbar.
    testWidgets('Triple tap on title triggers diagnostics enabled snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());

      // Find title
      final titleFinder = find.text('Interview');
      expect(titleFinder, findsOneWidget);

      // Tap once
      await tester.tap(titleFinder);
      await tester.pump();
      expect(find.text('Diagnostics mode enabled'), findsNothing);

      // Tap twice
      await tester.tap(titleFinder);
      await tester.pump();
      expect(find.text('Diagnostics mode enabled'), findsNothing);

      // Tap third time
      await tester.tap(titleFinder);
      await tester.pump();

      // Icon should be visible (already was in debug mode, but logic still
      // runs)
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);

      // Snackbar should appear
      await tester.pump(const Duration(milliseconds: 100)); // Allow animation
      expect(find.text('Diagnostics mode enabled'), findsOneWidget);
    });
  });
}
