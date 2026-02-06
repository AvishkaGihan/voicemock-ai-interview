import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

      expect(find.text('Question 2 of 5'), findsOneWidget);
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

      expect(find.textContaining('You said'), findsOneWidget);
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

      expect(find.textContaining('Coach says'), findsOneWidget);
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
  });
}
