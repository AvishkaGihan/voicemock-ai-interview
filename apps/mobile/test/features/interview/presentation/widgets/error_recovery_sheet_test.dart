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
            ),
          ),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsNothing);
    });
  });
}
