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

  // ---------------------------------------------------------------------------
  // Task 6.3 / 6.4: "What to Practice Next" section in SessionCompleteCard
  // ---------------------------------------------------------------------------

  group('SessionCompleteCard recommended actions', () {
    testWidgets(
      'renders What to Practice Next section when '
      'recommendedActions is non-empty',
      (tester) async {
        const summaryWithActions = SessionSummary(
          overallAssessment: 'Strong performance with room to grow.',
          strengths: ['Clear communication'],
          improvements: ['Quantify achievements'],
          averageScores: {'clarity': 3.5},
          recommendedActions: [
            'Try structuring answers with the STAR method for clearer stories.',
            'Practice pausing instead of using filler words when thinking.',
          ],
        );

        await tester.pumpWidget(buildTestWidget(summaryWithActions));

        expect(find.text('What to Practice Next'), findsOneWidget);
        expect(
          find.text(
            'Try structuring answers with the STAR method for clearer stories.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Practice pausing instead of using filler words when thinking.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'hides What to Practice Next section when recommendedActions is empty',
      (tester) async {
        const summaryNoActions = SessionSummary(
          overallAssessment: 'Strong performance.',
          strengths: ['Clear communication'],
          improvements: ['Quantify achievements'],
          averageScores: {'clarity': 4.0},
          // recommendedActions defaults to []
        );

        await tester.pumpWidget(buildTestWidget(summaryNoActions));

        expect(find.text('What to Practice Next'), findsNothing);
      },
    );
  });
}
