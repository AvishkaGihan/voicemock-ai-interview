/// Widget tests for DiagnosticsPage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/models/session_diagnostics.dart';
import 'package:voicemock/core/models/turn_timing_record.dart';
import 'package:voicemock/features/diagnostics/presentation/view/diagnostics_page.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_state.dart';

class MockInterviewCubit extends Mock implements InterviewCubit {
  @override
  Stream<InterviewState> get stream => const Stream.empty();
}

void main() {
  late MockInterviewCubit mockCubit;

  setUp(() {
    mockCubit = MockInterviewCubit();
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
        find.text('Complete a turn to see timing metrics'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    });

    testWidgets('shows turn timing records', (tester) async {
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
        TurnTimingRecord(
          turnNumber: 2,
          requestId: 'req-2',
          uploadMs: 45,
          sttMs: 780,
          llmMs: 160,
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
  });
}
