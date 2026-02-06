import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/widgets/voice_pipeline_stepper.dart';

void main() {
  group('VoicePipelineStepper', () {
    testWidgets('renders all 4 steps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoicePipelineStepper(
              currentStage: InterviewStage.uploading,
            ),
          ),
        ),
      );

      expect(find.byType(VoicePipelineStepper), findsOneWidget);
      // Should have 4 steps visible
      expect(find.text('Uploading'), findsOneWidget);
      expect(find.text('Transcribing'), findsOneWidget);
      expect(find.text('Thinking'), findsOneWidget);
      expect(find.text('Speaking'), findsOneWidget);
    });

    testWidgets('highlights current stage (Uploading)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoicePipelineStepper(
              currentStage: InterviewStage.uploading,
            ),
          ),
        ),
      );

      // Verify Uploading step is visible
      expect(find.text('Uploading'), findsOneWidget);
      expect(find.byIcon(Icons.upload), findsOneWidget);
    });

    testWidgets('highlights current stage (Transcribing)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoicePipelineStepper(
              currentStage: InterviewStage.transcribing,
            ),
          ),
        ),
      );

      // Verify Transcribing step is visible, Uploading should show checkmark
      expect(find.text('Transcribing'), findsOneWidget);
      expect(find.byIcon(Icons.transcribe), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('highlights current stage (Thinking)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoicePipelineStepper(
              currentStage: InterviewStage.thinking,
            ),
          ),
        ),
      );

      // Verify Thinking step is visible
      expect(find.text('Thinking'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('highlights current stage (Speaking)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoicePipelineStepper(
              currentStage: InterviewStage.speaking,
            ),
          ),
        ),
      );

      // Verify Speaking step is visible
      expect(find.text('Speaking'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });

    testWidgets('shows icons for each step', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoicePipelineStepper(
              currentStage: InterviewStage.uploading,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.upload), findsOneWidget);
      expect(find.byIcon(Icons.transcribe), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });

    testWidgets('shows checkmark for completed steps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoicePipelineStepper(
              currentStage: InterviewStage.thinking,
            ),
          ),
        ),
      );

      // Uploading and Transcribing should be complete (checkmarks)
      // Thinking is current, Speaking is pending
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    });

    testWidgets('does not show stepper for Ready stage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoicePipelineStepper(
              currentStage: InterviewStage.ready,
            ),
          ),
        ),
      );

      // Stepper should be hidden (SizedBox or not rendered)
      expect(find.text('Uploading'), findsNothing);
      expect(find.text('Transcribing'), findsNothing);
      expect(find.text('Thinking'), findsNothing);
      expect(find.text('Speaking'), findsNothing);
    });

    testWidgets('does not show stepper for Recording stage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoicePipelineStepper(
              currentStage: InterviewStage.recording,
            ),
          ),
        ),
      );

      // Stepper should be hidden
      expect(find.text('Uploading'), findsNothing);
    });

    testWidgets('shows error indicator when hasError is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoicePipelineStepper(
              currentStage: InterviewStage.uploading,
              hasError: true,
              errorStage: InterviewStage.uploading,
            ),
          ),
        ),
      );

      // Should show error icon
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows hint when processing exceeds 10 seconds', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoicePipelineStepper(
              currentStage: InterviewStage.uploading,
              stageStartTime: DateTime.now().subtract(
                const Duration(seconds: 11),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Usually ~5-15s'), findsOneWidget);
    });

    testWidgets('does not show hint when processing under 10 seconds', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoicePipelineStepper(
              currentStage: InterviewStage.uploading,
              stageStartTime: DateTime.now().subtract(
                const Duration(seconds: 5),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Usually ~5-15s'), findsNothing);
    });
  });
}
