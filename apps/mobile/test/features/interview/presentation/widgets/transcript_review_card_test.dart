import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/features/interview/presentation/widgets/widgets.dart';

import '../../../../helpers/helpers.dart';

void main() {
  group('TranscriptReviewCard', () {
    testWidgets('displays transcript text correctly', (tester) async {
      await tester.pumpApp(
        TranscriptReviewCard(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'What is your greatest strength?',
          transcript: 'My greatest strength is problem solving',
          onAccept: () {},
          onReRecord: () {},
        ),
      );

      expect(
        find.text('My greatest strength is problem solving'),
        findsOneWidget,
      );
    });

    testWidgets('displays question header with correct number and text', (
      tester,
    ) async {
      await tester.pumpApp(
        TranscriptReviewCard(
          questionNumber: 3,
          totalQuestions: 10,
          questionText: 'Tell me about a challenging project',
          transcript: 'I worked on a system migration',
          onAccept: () {},
          onReRecord: () {},
        ),
      );

      expect(find.text('QUESTION 3 OF 10'), findsOneWidget);
      expect(
        find.text('Tell me about a challenging project'),
        findsOneWidget,
      );
    });

    testWidgets('shows "What we heard:" label', (tester) async {
      await tester.pumpApp(
        TranscriptReviewCard(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question',
          transcript: 'Answer',
          onAccept: () {},
          onReRecord: () {},
        ),
      );

      expect(find.text('WHAT WE HEARD:'), findsOneWidget);
    });

    testWidgets('Accept & Continue button is visible and calls onAccept', (
      tester,
    ) async {
      var acceptCalled = false;

      await tester.pumpApp(
        TranscriptReviewCard(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question',
          transcript: 'Answer',
          onAccept: () {
            acceptCalled = true;
          },
          onReRecord: () {},
        ),
      );

      final acceptButton = find.widgetWithText(
        FilledButton,
        'Accept & Continue',
      );
      expect(acceptButton, findsOneWidget);

      await tester.tap(acceptButton);
      await tester.pump();

      expect(acceptCalled, isTrue);
    });

    testWidgets('Re-record button is visible and calls onReRecord', (
      tester,
    ) async {
      var reRecordCalled = false;

      await tester.pumpApp(
        TranscriptReviewCard(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question',
          transcript: 'Answer',
          onAccept: () {},
          onReRecord: () {
            reRecordCalled = true;
          },
        ),
      );

      final reRecordButton = find.widgetWithText(TextButton, 'Re-record');
      expect(reRecordButton, findsOneWidget);

      await tester.tap(reRecordButton);
      await tester.pump();

      expect(reRecordCalled, isTrue);
    });

    testWidgets('shows low-confidence hint when isLowConfidence is true', (
      tester,
    ) async {
      await tester.pumpApp(
        TranscriptReviewCard(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question',
          transcript: 'um',
          isLowConfidence: true,
          onAccept: () {},
          onReRecord: () {},
        ),
      );

      expect(
        find.text("If this isn't right, re-record."),
        findsOneWidget,
      );
    });

    testWidgets('hides low-confidence hint when isLowConfidence is false', (
      tester,
    ) async {
      await tester.pumpApp(
        TranscriptReviewCard(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question',
          transcript: 'This is a good clear transcript',
          onAccept: () {},
          onReRecord: () {},
        ),
      );

      expect(
        find.text("If this isn't right, re-record."),
        findsNothing,
      );
    });

    testWidgets('shows low-confidence hint by default when omitted', (
      tester,
    ) async {
      await tester.pumpApp(
        TranscriptReviewCard(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question',
          transcript: 'This is a good clear transcript',
          onAccept: () {},
          onReRecord: () {},
        ),
      );

      // Default isLowConfidence is false
      expect(
        find.text("If this isn't right, re-record."),
        findsNothing,
      );
    });

    testWidgets('buttons are arranged vertically with Accept first', (
      tester,
    ) async {
      await tester.pumpApp(
        TranscriptReviewCard(
          questionNumber: 1,
          totalQuestions: 5,
          questionText: 'Question',
          transcript: 'Answer',
          onAccept: () {},
          onReRecord: () {},
        ),
      );

      final acceptButton = find.widgetWithText(
        FilledButton,
        'Accept & Continue',
      );
      final reRecordButton = find.widgetWithText(
        TextButton,
        'Re-record',
      );

      expect(acceptButton, findsOneWidget);
      expect(reRecordButton, findsOneWidget);

      // Verify they're in a column and Accept comes before Re-record
      final acceptPos = tester.getCenter(acceptButton);
      final reRecordPos = tester.getCenter(reRecordButton);

      expect(
        acceptPos.dy < reRecordPos.dy,
        isTrue,
        reason: 'Accept button should be above the Re-record button',
      );
    });
  });
}
