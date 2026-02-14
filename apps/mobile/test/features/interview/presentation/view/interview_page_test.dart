import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/http/api_client.dart';
import 'package:voicemock/features/interview/domain/session.dart';
import 'package:voicemock/features/interview/presentation/cubit/cubit.dart';
import 'package:voicemock/features/interview/presentation/view/interview_page.dart';
import 'package:voicemock/features/interview/presentation/view/interview_view.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  group('InterviewPage', () {
    final mockSession = Session(
      sessionId: 'test-session-id',
      sessionToken: 'test-token',
      openingPrompt: 'This is the opening question.',
      createdAt: DateTime(2025),
    );
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();
    });

    testWidgets('provides InterviewCubit to descendants', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RepositoryProvider<ApiClient>.value(
            value: mockApiClient,
            child: InterviewPage(session: mockSession),
          ),
        ),
      );

      // Verify InterviewView is rendered (which requires the cubit provider)
      expect(find.byType(InterviewView), findsOneWidget);

      // Access cubit from InterviewView's context
      final context = tester.element(find.byType(InterviewView));
      // Using context.read from flutter_bloc/provider extension
      final cubit = context.read<InterviewCubit>();
      expect(cubit, isNotNull);
    });

    testWidgets('initializes cubit with session opening prompt', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RepositoryProvider<ApiClient>.value(
            value: mockApiClient,
            child: InterviewPage(session: mockSession),
          ),
        ),
      );

      // Let the cubit emit the initial state
      await tester.pump();

      // Access cubit from InterviewView's context
      final context = tester.element(find.byType(InterviewView));
      final cubit = context.read<InterviewCubit>();

      expect(cubit.state, isA<InterviewReady>());
      final readyState = cubit.state as InterviewReady;
      expect(readyState.questionText, equals('This is the opening question.'));
      expect(readyState.questionNumber, equals(1));
      expect(readyState.totalQuestions, equals(5));
    });

    testWidgets('route factory creates MaterialPageRoute', (tester) async {
      final route = InterviewPage.route(mockSession);

      expect(route, isA<MaterialPageRoute<void>>());
    });
  });
}
