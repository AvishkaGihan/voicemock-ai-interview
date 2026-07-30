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

      expect(find.text('OVERALL ASSESSMENT'), findsOneWidget);
      expect(find.text('YOUR STRENGTHS'), findsOneWidget);
      expect(find.text('AREAS TO IMPROVE'), findsOneWidget);
      expect(
        find.text('AVERAGE SCORES'),
        findsNothing,
      );
      expect(
        find.text('You communicated clearly and stayed relevant.'),
        findsOneWidget,
      );
      expect(find.text('Clear examples'), findsWidgets);
      expect(find.text('Add quantified outcomes'), findsWidgets);
    });

    testWidgets(
      'renders fallback completion message when sessionSummary is null',
      (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(null));

        expect(find.text('Interview Complete'), findsOneWidget);
        expect(
          find.textContaining("You've completed all 5 questions."),
          findsOneWidget,
        );
        expect(find.text('OVERALL ASSESSMENT'), findsNothing);
        expect(find.text('YOUR STRENGTHS'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // AI Coach Recommendation section in SessionCompleteCard
  // ---------------------------------------------------------------------------

  group('SessionCompleteCard recommended actions', () {
    testWidgets(
      'renders AI Coach Recommendation section when '
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

        expect(find.text('AI COACH RECOMMENDATION'), findsOneWidget);
        expect(
          find.textContaining(
            'Try structuring answers with the STAR method',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Practice pausing instead of using filler words',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'hides AI Coach Recommendation section when recommendedActions is empty',
      (tester) async {
        const summaryNoActions = SessionSummary(
          overallAssessment: 'Strong performance.',
          strengths: ['Clear communication'],
          improvements: ['Quantify achievements'],
          averageScores: {'clarity': 4.0},
          // recommendedActions defaults to []
        );

        await tester.pumpWidget(buildTestWidget(summaryNoActions));

        expect(find.text('AI COACH RECOMMENDATION'), findsNothing);
      },
    );
  });
}
