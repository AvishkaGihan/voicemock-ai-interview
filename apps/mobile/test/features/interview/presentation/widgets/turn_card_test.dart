import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/core/models/models.dart';
import 'package:voicemock/features/interview/presentation/widgets/turn_card.dart';

void main() {
  group('TurnCard', () {
    testWidgets('renders question header and text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TurnCard(
              questionNumber: 2,
              totalQuestions: 5,
              questionText: 'What is your greatest strength?',
            ),
          ),
        ),
      );

      expect(find.text('2/5'), findsOneWidget);
      expect(find.text('What is your greatest strength?'), findsOneWidget);
    });

    testWidgets('shows transcript when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TurnCard(
              questionNumber: 1,
              totalQuestions: 5,
              questionText: 'Tell me about yourself',
              transcript: 'I am a software engineer...',
            ),
          ),
        ),
      );

      expect(find.textContaining('YOU SAID'), findsOneWidget);
      expect(find.text('I am a software engineer...'), findsOneWidget);
    });

    testWidgets('shows response text when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TurnCard(
              questionNumber: 1,
              totalQuestions: 5,
              questionText: 'Tell me about yourself',
              transcript: 'I am a software engineer',
              responseText: 'Great! Tell me more about your experience.',
            ),
          ),
        ),
      );

      expect(find.textContaining('COACH SAYS'), findsOneWidget);
      expect(
        find.text('Great! Tell me more about your experience.'),
        findsOneWidget,
      );
    });

    testWidgets('does not show transcript section when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TurnCard(
              questionNumber: 1,
              totalQuestions: 5,
              questionText: 'Tell me about yourself',
            ),
          ),
        ),
      );

      expect(find.textContaining('You said'), findsNothing);
    });

    testWidgets('does not show response section when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TurnCard(
              questionNumber: 1,
              totalQuestions: 5,
              questionText: 'Tell me about yourself',
              transcript: 'I am a software engineer',
            ),
          ),
        ),
      );

      expect(find.textContaining('Coach says'), findsNothing);
    });

    testWidgets('shows Replay button when onReplay is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TurnCard(
              questionNumber: 1,
              totalQuestions: 5,
              questionText: 'Tell me about yourself',
              responseText: 'Coach response',
              onReplay: () {},
            ),
          ),
        ),
      );

      expect(find.text('Replay response'), findsOneWidget);
    });

    testWidgets('hides Replay button when onReplay is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TurnCard(
              questionNumber: 1,
              totalQuestions: 5,
              questionText: 'Tell me about yourself',
              responseText: 'Coach response',
            ),
          ),
        ),
      );

      expect(find.text('Replay response'), findsNothing);
    });

    testWidgets('renders coaching feedback summary and dimensions', (
      tester,
    ) async {
      const feedback = CoachingFeedback(
        dimensions: [
          CoachingDimension(
            label: 'Clarity',
            score: 4,
            tip: 'Lead with your strongest point first.',
          ),
          CoachingDimension(
            label: 'Structure',
            score: 3,
            tip: 'Use problem-action-result flow.',
          ),
        ],
        summaryTip:
            'Lead with one clear thesis and support it with '
            'one concrete example.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TurnCard(
              questionNumber: 1,
              totalQuestions: 5,
              questionText: 'Tell me about yourself',
              responseText: 'Thanks. Can you share a challenge?',
              coachingFeedback: feedback,
            ),
          ),
        ),
      );

      expect(find.text('TOP TIP'), findsOneWidget);
      expect(find.textContaining('clear thesis'), findsOneWidget);
      expect(find.textContaining('Clarity'), findsOneWidget);
      expect(find.textContaining('4/5'), findsOneWidget);
      expect(find.textContaining('Structure'), findsOneWidget);
    });

    testWidgets('hides coaching section when coachingFeedback is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TurnCard(
              questionNumber: 1,
              totalQuestions: 5,
              questionText: 'Tell me about yourself',
              responseText: 'Thanks. Can you share a challenge?',
            ),
          ),
        ),
      );

      expect(find.text('Top Tip'), findsNothing);
    });
  });
}
