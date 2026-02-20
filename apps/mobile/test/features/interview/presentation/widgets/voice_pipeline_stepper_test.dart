import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/widgets/voice_pipeline_stepper.dart';

void main() {
  group('VoicePipelineStepper', () {
    testWidgets('renders all 5 steps', (tester) async {
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
      // Should have 5 steps visible
      expect(find.text('Upload'), findsOneWidget);
      expect(find.text('Transcribe'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Thinking'), findsOneWidget);
      expect(find.text('Speaking'), findsOneWidget);
    });

    testWidgets('highlights current stage (Upload)', (tester) async {
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
      expect(find.text('Upload'), findsOneWidget);
      expect(
        find.byIcon(Icons.cloud_upload_outlined),
        findsOneWidget,
      ); // Icon might be different if checkmark
      // Since it's active, it should show original icon?
      // Code says: isCompleted ? Icons.check_circle : config.icon
      // isActive is not isCompleted. So it shows config.icon.
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    });

    testWidgets('highlights current stage (Transcribe)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoicePipelineStepper(
              currentStage: InterviewStage.transcribing,
            ),
          ),
        ),
      );

      // Transcribing is active. Upload is complete.
      expect(find.text('Transcribe'), findsOneWidget);
      expect(find.byIcon(Icons.graphic_eq), findsOneWidget);

      // Upload should be complete (checkmark)
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

      // Thinking is active. Upload, Transcribe, Review are complete.
      expect(find.text('Thinking'), findsOneWidget);
      expect(find.byIcon(Icons.psychology_outlined), findsOneWidget);

      // 3 completed steps
      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
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

      // Stepper should be hidden
      expect(find.text('Upload'), findsNothing);
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
      expect(find.text('Upload'), findsNothing);
    });
  });
}
