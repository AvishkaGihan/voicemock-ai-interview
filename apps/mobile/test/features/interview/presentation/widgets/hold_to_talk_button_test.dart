import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/features/interview/presentation/widgets/hold_to_talk_button.dart';

void main() {
  group('HoldToTalkButton', () {
    testWidgets('renders with default state (enabled, not recording)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldToTalkButton(
              isEnabled: true,
              isRecording: false,
              onPressStart: () {},
              onPressEnd: () {},
            ),
          ),
        ),
      );

      expect(find.byType(HoldToTalkButton), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.text('Hold to talk'), findsOneWidget);
    });

    testWidgets('shows "Release to send" when recording', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldToTalkButton(
              isEnabled: true,
              isRecording: true,
              onPressStart: () {},
              onPressEnd: () {},
            ),
          ),
        ),
      );

      expect(find.text('Release to send'), findsOneWidget);
      expect(find.text('Hold to talk'), findsNothing);
    });

    testWidgets('shows "Waiting..." when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldToTalkButton(
              isEnabled: false,
              isRecording: false,
              onPressStart: () {},
              onPressEnd: () {},
            ),
          ),
        ),
      );

      expect(find.text('Waiting...'), findsOneWidget);
    });

    testWidgets('shows recording duration when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldToTalkButton(
              isEnabled: true,
              isRecording: true,
              onPressStart: () {},
              onPressEnd: () {},
              recordingDuration: const Duration(minutes: 1, seconds: 23),
            ),
          ),
        ),
      );

      expect(find.text('01:23'), findsOneWidget);
    });

    testWidgets('calls onPressStart when long press starts', (tester) async {
      var pressStartCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldToTalkButton(
              isEnabled: true,
              isRecording: false,
              onPressStart: () => pressStartCalled = true,
              onPressEnd: () {},
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldToTalkButton)),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(pressStartCalled, true);

      await gesture.up();
    });

    testWidgets('calls onPressEnd when long press ends', (tester) async {
      var pressEndCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldToTalkButton(
              isEnabled: true,
              isRecording: false,
              onPressStart: () {},
              onPressEnd: () => pressEndCalled = true,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldToTalkButton)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump();

      expect(pressEndCalled, true);
    });

    testWidgets('does not call callbacks when disabled', (tester) async {
      var pressStartCalled = false;
      var pressEndCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldToTalkButton(
              isEnabled: false,
              isRecording: false,
              onPressStart: () => pressStartCalled = true,
              onPressEnd: () => pressEndCalled = true,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldToTalkButton)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump();

      expect(pressStartCalled, false);
      expect(pressEndCalled, false);
    });

    testWidgets('has correct accessibility label when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldToTalkButton(
              isEnabled: true,
              isRecording: false,
              onPressStart: () {},
              onPressEnd: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(HoldToTalkButton));
      expect(semantics.label, contains('Hold to record answer'));
    });

    testWidgets('has correct accessibility label when recording', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldToTalkButton(
              isEnabled: true,
              isRecording: true,
              onPressStart: () {},
              onPressEnd: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(HoldToTalkButton));
      expect(semantics.label, contains('Recording'));
      expect(semantics.label, contains('Release to send'));
    });

    testWidgets('has correct accessibility label when disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldToTalkButton(
              isEnabled: false,
              isRecording: false,
              onPressStart: () {},
              onPressEnd: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(HoldToTalkButton));
      expect(semantics.label, contains('Disabled while coach is speaking'));
    });

    testWidgets('button size is at least 44dp (minimum touch target)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldToTalkButton(
              isEnabled: true,
              isRecording: false,
              onPressStart: () {},
              onPressEnd: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(HoldToTalkButton),
          matching: find.byType(Container).first,
        ),
      );

      // Button should be 120x120 (well above 44dp minimum)
      expect(container.constraints?.minWidth, greaterThanOrEqualTo(44.0));
      expect(container.constraints?.minHeight, greaterThanOrEqualTo(44.0));
    });
  });
}
