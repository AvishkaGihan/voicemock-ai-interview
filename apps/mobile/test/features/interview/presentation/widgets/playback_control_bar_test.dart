import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/features/interview/presentation/widgets/playback_control_bar.dart';

void main() {
  group('PlaybackControlBar', () {
    testWidgets('renders Pause and Stop buttons when not paused', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackControlBar(
              isPaused: false,
              onPause: () {},
              onResume: () {},
              onStop: () {},
            ),
          ),
        ),
      );

      expect(find.byTooltip('Pause coach audio'), findsOneWidget);
      expect(find.byTooltip('Stop coach audio'), findsOneWidget);
      expect(find.byTooltip('Resume coach audio'), findsNothing);
    });

    testWidgets('renders Resume and Stop buttons when paused', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackControlBar(
              isPaused: true,
              onPause: () {},
              onResume: () {},
              onStop: () {},
            ),
          ),
        ),
      );

      expect(find.byTooltip('Resume coach audio'), findsOneWidget);
      expect(find.byTooltip('Stop coach audio'), findsOneWidget);
      expect(find.byTooltip('Pause coach audio'), findsNothing);
    });

    testWidgets('renders CircularProgressIndicator when buffering', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackControlBar(
              isPaused: false,
              isBuffering: true,
              onPause: () {},
              onResume: () {},
              onStop: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('tapping Pause calls onPause', (tester) async {
      var didPause = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackControlBar(
              isPaused: false,
              onPause: () => didPause = true,
              onResume: () {},
              onStop: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Pause coach audio'));
      expect(didPause, isTrue);
    });

    testWidgets('tapping Resume calls onResume', (tester) async {
      var didResume = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackControlBar(
              isPaused: true,
              onPause: () {},
              onResume: () => didResume = true,
              onStop: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Resume coach audio'));
      expect(didResume, isTrue);
    });

    testWidgets('tapping Stop calls onStop', (tester) async {
      var didStop = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackControlBar(
              isPaused: false,
              onPause: () {},
              onResume: () {},
              onStop: () => didStop = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Stop coach audio'));
      expect(didStop, isTrue);
    });

    testWidgets('buttons expose semantic labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackControlBar(
              isPaused: false,
              onPause: () {},
              onResume: () {},
              onStop: () {},
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Pause coach audio'), findsOneWidget);
      expect(find.bySemanticsLabel('Stop coach audio'), findsOneWidget);
    });
  });
}
