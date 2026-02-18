import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/audio/audio.dart';
import 'package:voicemock/core/http/api_client.dart';
import 'package:voicemock/features/interview/domain/session.dart';
import 'package:voicemock/features/interview/presentation/cubit/cubit.dart';
import 'package:voicemock/features/interview/presentation/view/interview_page.dart';
import 'package:voicemock/features/interview/presentation/view/interview_view.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockRecordingService extends Mock implements RecordingService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockAudioFocusService extends Mock implements AudioFocusService {}

void main() {
  group('InterviewPage', () {
    final mockSession = Session(
      sessionId: 'test-session-id',
      sessionToken: 'test-token',
      openingPrompt: 'This is the opening question.',
      totalQuestions: 5,
      createdAt: DateTime(2025),
    );
    late MockApiClient mockApiClient;
    late MockRecordingService mockRecordingService;
    late MockPlaybackService mockPlaybackService;
    late MockAudioFocusService mockAudioFocusService;

    setUp(() {
      mockApiClient = MockApiClient();
      mockRecordingService = MockRecordingService();
      mockPlaybackService = MockPlaybackService();
      mockAudioFocusService = MockAudioFocusService();

      when(() => mockApiClient.baseUrl).thenReturn('https://api.example.com');
      when(() => mockRecordingService.dispose()).thenAnswer((_) async {});
      when(() => mockPlaybackService.dispose()).thenAnswer((_) async {});
      when(() => mockAudioFocusService.initialize()).thenAnswer((_) async {});
      when(() => mockAudioFocusService.dispose()).thenAnswer((_) async {});
      // Stump for AudioFocusService.interruptions stream (needed by Cubit)
      when(
        () => mockAudioFocusService.interruptions,
      ).thenAnswer((_) => const Stream.empty());
    });

    testWidgets('provides InterviewCubit to descendants', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RepositoryProvider<ApiClient>.value(
            value: mockApiClient,
            child: InterviewPage(
              session: mockSession,
              recordingServiceBuilder: () => mockRecordingService,
              playbackServiceBuilder: () => mockPlaybackService,
              audioFocusServiceBuilder: () => mockAudioFocusService,
            ),
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
            child: InterviewPage(
              session: mockSession,
              recordingServiceBuilder: () => mockRecordingService,
              playbackServiceBuilder: () => mockPlaybackService,
              audioFocusServiceBuilder: () => mockAudioFocusService,
            ),
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

    testWidgets('disposes services when page is disposed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RepositoryProvider<ApiClient>.value(
            value: mockApiClient,
            child: InterviewPage(
              session: mockSession,
              recordingServiceBuilder: () => mockRecordingService,
              playbackServiceBuilder: () => mockPlaybackService,
              audioFocusServiceBuilder: () => mockAudioFocusService,
            ),
          ),
        ),
      );

      // Trigger dispose by pushing a different widget
      await tester.pumpWidget(const SizedBox());

      verify(() => mockRecordingService.dispose()).called(1);
      verify(() => mockPlaybackService.dispose()).called(1);
      verify(() => mockAudioFocusService.dispose()).called(1);
    });
  });
}
