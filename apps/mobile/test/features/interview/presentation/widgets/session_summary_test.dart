import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/core/models/models.dart';
import 'package:voicemock/features/interview/presentation/widgets/session_complete_card.dart';

void main() {
  Widget buildTestWidget(SessionSummary? summary) {
    return MaterialApp(
      home: Scaffold(
        body: SessionCompleteCard(
          totalQuestions: 5,
          lastTranscript: 'Final transcript',
          lastResponseText: 'Great job!',
          sessionSummary: summary,
          onBackToHome: () {},
          onStartNew: () {},
        ),
      ),
    );
  }

  group('SessionCompleteCard summary rendering', () {
    const summary = SessionSummary(
      overallAssessment: 'You communicated clearly and stayed relevant.',
      strengths: ['Clear examples', 'Strong structure'],
      improvements: ['Add quantified outcomes'],
      averageScores: {'clarity': 4.0, 'relevance': 4.5},
    );

    testWidgets('renders summary sections when sessionSummary is provided', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(summary));

      expect(find.text('Overall assessment'), findsOneWidget);
      expect(find.text('Strengths'), findsOneWidget);
      expect(find.text('Improvements'), findsOneWidget);
      expect(find.text('Average scores'), findsOneWidget);
      expect(
        find.text('You communicated clearly and stayed relevant.'),
        findsOneWidget,
      );
      expect(find.text('Clear examples'), findsOneWidget);
      expect(find.text('Add quantified outcomes'), findsOneWidget);
      expect(find.text('Clarity: 4.0'), findsOneWidget);
      expect(find.text('Relevance: 4.5'), findsOneWidget);
    });

    testWidgets(
      'renders fallback completion message when sessionSummary is null',
      (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(null));

        expect(find.text('Session Complete'), findsOneWidget);
        expect(
          find.text('Great job! You completed all 5 questions.'),
          findsOneWidget,
        );
        expect(find.text('Overall assessment'), findsNothing);
        expect(find.text('Strengths'), findsNothing);
      },
    );
  });
}
