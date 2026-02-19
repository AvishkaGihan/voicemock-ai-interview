/// Widget tests for DiagnosticsPage.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/models/session_diagnostics.dart';
import 'package:voicemock/core/models/turn_timing_record.dart';
import 'package:voicemock/features/diagnostics/presentation/view/diagnostics_page.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_state.dart';

class MockInterviewCubit extends Mock implements InterviewCubit {}

void main() {
  late MockInterviewCubit mockCubit;
  String? copiedText;

  setUp(() {
    mockCubit = MockInterviewCubit();
    // Stub stream and state for BlocBuilder
    when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockCubit.state).thenReturn(const InterviewIdle());
    when(() => mockCubit.close()).thenAnswer((_) async {});

    copiedText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget createDiagnosticsPage() {
    return MaterialApp(
      home: BlocProvider<InterviewCubit>.value(
        value: mockCubit,
        child: const DiagnosticsPage(),
      ),
    );
  }

  group('DiagnosticsPage', () {
    testWidgets('shows empty state when no timing data', (tester) async {
      when(() => mockCubit.diagnostics).thenReturn(
        const SessionDiagnostics(sessionId: 'test-session'),
      );

      await tester.pumpWidget(createDiagnosticsPage());

      expect(find.text('No timing data yet'), findsOneWidget);
      expect(
        find.textContaining('Complete a turn to see timing metrics'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
      expect(find.text('Session ID: '), findsOneWidget);
      expect(find.text('test-session'), findsOneWidget);
    });

    testWidgets('shows turn timing records', (tester) async {
      final records = [
        TurnTimingRecord(
          turnNumber: 1,
          requestId: 'req-1',
          uploadMs: 50,
          sttMs: 800,
          llmMs: 150,
          ttsMs: 220,
          totalMs: 1000,
          timestamp: DateTime.now(),
        ),
        TurnTimingRecord(
          turnNumber: 2,
          requestId: 'req-2',
          uploadMs: 45,
          sttMs: 780,
          llmMs: 160,
          ttsMs: 200,
          totalMs: 985,
          timestamp: DateTime.now(),
        ),
      ];

      when(() => mockCubit.diagnostics).thenReturn(
        SessionDiagnostics(
          sessionId: 'test-session',
          turnRecords: records,
        ),
      );

      await tester.pumpWidget(createDiagnosticsPage());

      expect(find.text('Turn 1'), findsOneWidget);
      expect(find.text('Turn 2'), findsOneWidget);
      expect(find.text('1000ms total'), findsOneWidget);
      expect(find.text('985ms total'), findsOneWidget);
      expect(find.text('TTS: 220ms'), findsOneWidget);
      expect(find.text('TTS: 200ms'), findsOneWidget);
    });

    testWidgets('shows error summary card when error exists', (tester) async {
      when(() => mockCubit.diagnostics).thenReturn(
        SessionDiagnostics(
          sessionId: 'test-session',
          turnRecords: [
            TurnTimingRecord(
              turnNumber: 1,
              requestId: 'req-turn-1',
              uploadMs: 50,
              sttMs: 800,
              llmMs: 150,
              totalMs: 1000,
              timestamp: DateTime(2024),
            ),
          ],
          lastErrorRequestId: 'req-err-123',
          lastErrorStage: 'stt',
        ),
      );

      await tester.pumpWidget(createDiagnosticsPage());
      expect(find.text('Last Error'), findsOneWidget);
      expect(find.text('STT'), findsOneWidget);
      expect(find.text('req-err-123'), findsOneWidget);
    });

    testWidgets('does not show error card when no error', (tester) async {
      final records = [
        TurnTimingRecord(
          turnNumber: 1,
          requestId: 'req-1',
          uploadMs: 50,
          sttMs: 800,
          llmMs: 150,
          totalMs: 1000,
          timestamp: DateTime.now(),
        ),
      ];

      when(() => mockCubit.diagnostics).thenReturn(
        SessionDiagnostics(
          sessionId: 'test-session',
          turnRecords: records,
        ),
      );

      await tester.pumpWidget(createDiagnosticsPage());

      expect(find.text('Last Error'), findsNothing);
    });

    testWidgets('session ID is copyable from header card', (tester) async {
      when(() => mockCubit.diagnostics).thenReturn(
        const SessionDiagnostics(sessionId: 'session-copy-1'),
      );

      await tester.pumpWidget(createDiagnosticsPage());
      await tester.tap(find.text('session-copy-1'));
      await tester.pump();

      expect(find.text('Session ID copied to clipboard'), findsOneWidget);
      expect(copiedText, 'session-copy-1');
    });

    testWidgets('request ID is copyable from timing row', (tester) async {
      when(() => mockCubit.diagnostics).thenReturn(
        SessionDiagnostics(
          sessionId: 'test-session',
          turnRecords: [
            TurnTimingRecord(
              turnNumber: 1,
              requestId: 'req-copy-1',
              uploadMs: 10,
              sttMs: 20,
              llmMs: 30,
              totalMs: 60,
              timestamp: DateTime(2026),
            ),
          ],
        ),
      );

      await tester.pumpWidget(createDiagnosticsPage());
      await tester.tap(find.text('req-copy-1'));
      await tester.pump();

      expect(find.text('Request ID copied to clipboard'), findsOneWidget);
      expect(copiedText, 'req-copy-1');
    });

    testWidgets('clear diagnostics action resets page to empty state', (
      tester,
    ) async {
      var diagnostics = SessionDiagnostics(
        sessionId: 'test-session',
        turnRecords: [
          TurnTimingRecord(
            turnNumber: 1,
            requestId: 'req-1',
            uploadMs: 50,
            sttMs: 800,
            llmMs: 150,
            totalMs: 1000,
            timestamp: DateTime(2026),
          ),
        ],
        lastErrorRequestId: 'req-error',
        lastErrorStage: 'stt',
      );

      when(() => mockCubit.diagnostics).thenAnswer((_) => diagnostics);
      when(() => mockCubit.clearDiagnostics()).thenAnswer((_) {
        diagnostics = const SessionDiagnostics(sessionId: 'test-session');
      });

      await tester.pumpWidget(createDiagnosticsPage());
      expect(find.text('Turn 1'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear Diagnostics'));
      await tester.pump();

      verify(() => mockCubit.clearDiagnostics()).called(1);
      expect(find.text('Turn 1'), findsNothing);
      expect(
        find.textContaining('Complete a turn to see timing metrics'),
        findsOneWidget,
      );
    });
  });
}
