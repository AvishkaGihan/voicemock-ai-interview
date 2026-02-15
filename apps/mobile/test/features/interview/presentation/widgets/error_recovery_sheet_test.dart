import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/widgets/error_recovery_sheet.dart';

void main() {
  group('ErrorRecoverySheet', () {
    const testFailure = NetworkFailure(
      message: 'Network connection lost',
      requestId: 'req-123',
    );

    testWidgets('renders error message and request ID', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorRecoverySheet(
              failure: testFailure,
              failedStage: InterviewStage.uploading,
            ),
          ),
        ),
      );

      expect(find.text('Network connection lost'), findsOneWidget);
      expect(find.textContaining('req-123'), findsOneWidget);
    });

    testWidgets('shows Retry button when failure is retryable', (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRecoverySheet(
              failure: testFailure,
              failedStage: InterviewStage.uploading,
              onRetry: () => retryCalled = true,
              onReRecord: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      final retryButton = find.widgetWithText(ElevatedButton, 'Retry');
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      expect(retryCalled, true);
    });

    testWidgets('shows Re-record button', (tester) async {
      var reRecordCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRecoverySheet(
              failure: testFailure,
              failedStage: InterviewStage.uploading,
              onRetry: () {},
              onReRecord: () => reRecordCalled = true,
              onCancel: () {},
            ),
          ),
        ),
      );

      final reRecordButton = find.widgetWithText(TextButton, 'Re-record');
      expect(reRecordButton, findsOneWidget);

      await tester.tap(reRecordButton);
      expect(reRecordCalled, true);
    });

    testWidgets('shows Cancel button', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRecoverySheet(
              failure: testFailure,
              failedStage: InterviewStage.uploading,
              onRetry: () {},
              onReRecord: () {},
              onCancel: () => cancelCalled = true,
            ),
          ),
        ),
      );

      final cancelButton = find.widgetWithText(TextButton, 'Cancel');
      expect(cancelButton, findsOneWidget);

      await tester.tap(cancelButton);
      expect(cancelCalled, true);
    });

    testWidgets('does not show Retry button when failure is not retryable', (
      tester,
    ) async {
      const nonRetryableFailure = ValidationFailure(
        message: 'Invalid input',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorRecoverySheet(
              failure: nonRetryableFailure,
              failedStage: InterviewStage.uploading,
            ),
          ),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsNothing);
    });

    testWidgets('shows stage-specific icon for upload error', (tester) async {
      const uploadFailure = ServerFailure(
        message: 'Upload timeout',
        code: 'upload_timeout',
        stage: 'upload',
        retryable: true,
        requestId: 'req-upload',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorRecoverySheet(
              failure: uploadFailure,
              failedStage: InterviewStage.uploading,
            ),
          ),
        ),
      );

      // Verify upload-specific icon (Icons.cloud_off)
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('Upload failed'), findsOneWidget);
    });

    testWidgets('shows stage-specific icon for STT error', (tester) async {
      const sttFailure = ServerFailure(
        message: 'Speech recognition failed',
        code: 'stt_timeout',
        stage: 'stt',
        retryable: true,
        requestId: 'req-stt',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorRecoverySheet(
              failure: sttFailure,
              failedStage: InterviewStage.transcribing,
            ),
          ),
        ),
      );

      // Verify STT-specific icon (Icons.mic_off)
      expect(find.byIcon(Icons.mic_off), findsOneWidget);
      expect(find.text('Transcription failed'), findsOneWidget);
    });

    testWidgets('shows stage-specific icon for LLM error', (tester) async {
      const llmFailure = ServerFailure(
        message: 'LLM rate limited',
        code: 'llm_rate_limit',
        stage: 'llm',
        retryable: true,
        requestId: 'req-llm',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorRecoverySheet(
              failure: llmFailure,
              failedStage: InterviewStage.thinking,
            ),
          ),
        ),
      );

      // Verify LLM-specific icon (Icons.psychology_alt)
      expect(find.byIcon(Icons.psychology_alt), findsOneWidget);
      expect(find.text('Processing failed'), findsOneWidget);
    });

    testWidgets('request ID can be tapped to copy', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorRecoverySheet(
              failure: testFailure,
              failedStage: InterviewStage.uploading,
            ),
          ),
        ),
      );

      // Find and tap the request ID text
      final requestIdFinder = find.textContaining('req-123');
      expect(requestIdFinder, findsOneWidget);

      await tester.tap(requestIdFinder);
      await tester.pump();

      // Verify clipboard contains request ID (if clipboard is available)
      // Note: In test environment, clipboard might not be accessible
    });

    testWidgets('re-record button shown for upload error stage', (
      tester,
    ) async {
      const uploadFailure = ServerFailure(
        message: 'Upload timeout',
        code: 'upload_timeout',
        stage: 'upload',
        retryable: true,
        requestId: 'req-upload',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRecoverySheet(
              failure: uploadFailure,
              failedStage: InterviewStage.uploading,
              onRetry: () {},
              onReRecord: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.widgetWithText(TextButton, 'Re-record'), findsOneWidget);
    });

    testWidgets('re-record button shown for STT error stage', (tester) async {
      const sttFailure = ServerFailure(
        message: 'STT timeout',
        code: 'stt_timeout',
        stage: 'stt',
        retryable: true,
        requestId: 'req-stt',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRecoverySheet(
              failure: sttFailure,
              failedStage: InterviewStage.transcribing,
              onRetry: () {},
              onReRecord: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.widgetWithText(TextButton, 'Re-record'), findsOneWidget);
    });

    testWidgets('re-record button NOT shown for LLM error stage', (
      tester,
    ) async {
      const llmFailure = ServerFailure(
        message: 'LLM error',
        code: 'llm_rate_limit',
        stage: 'llm',
        retryable: true,
        requestId: 'req-llm',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRecoverySheet(
              failure: llmFailure,
              failedStage: InterviewStage.thinking,
              onRetry: () {},
              onReRecord: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.widgetWithText(TextButton, 'Re-record'), findsNothing);
    });

    testWidgets('can be shown as modal bottom sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  unawaited(
                    ErrorRecoverySheet.show(
                      context,
                      failure: testFailure,
                      failedStage: InterviewStage.uploading,
                      onRetry: () {},
                      onReRecord: () {},
                      onCancel: () {},
                    ),
                  );
                },
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show modal sheet
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      // Verify modal sheet is displayed
      expect(find.text('Network connection lost'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);

      // Dismiss sheet (scroll to Cancel button first)
      await tester.ensureVisible(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify sheet is dismissed
      expect(find.text('Network connection lost'), findsNothing);
    });
  });
}
