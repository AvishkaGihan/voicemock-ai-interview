import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/core/permissions/permission_service.dart';
import 'package:voicemock/features/interview/presentation/widgets/permission_denied_banner.dart';

void main() {
  group('PermissionDeniedBanner', () {
    testWidgets('renders warning message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionDeniedBanner(
              status: MicrophonePermissionStatus.denied,
              onEnableTap: () {},
              onDismissTap: () {},
            ),
          ),
        ),
      );

      expect(
        find.text('Microphone access is required for voice practice'),
        findsOneWidget,
      );
    });

    testWidgets('renders mic off icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionDeniedBanner(
              status: MicrophonePermissionStatus.denied,
              onEnableTap: () {},
              onDismissTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
    });

    testWidgets(
      'shows Enable Microphone button when status is denied',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PermissionDeniedBanner(
                status: MicrophonePermissionStatus.denied,
                onEnableTap: () {},
                onDismissTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Enable Microphone'), findsOneWidget);
        expect(find.text('Open Settings'), findsNothing);
      },
    );

    testWidgets(
      'shows Open Settings button when status is permanentlyDenied',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PermissionDeniedBanner(
                status: MicrophonePermissionStatus.permanentlyDenied,
                onEnableTap: () {},
                onDismissTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Open Settings'), findsOneWidget);
        expect(find.text('Enable Microphone'), findsNothing);
      },
    );

    testWidgets('renders Not now button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionDeniedBanner(
              status: MicrophonePermissionStatus.denied,
              onEnableTap: () {},
              onDismissTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('calls onEnableTap when Enable Microphone is tapped', (
      tester,
    ) async {
      var enableTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionDeniedBanner(
              status: MicrophonePermissionStatus.denied,
              onEnableTap: () => enableTapped = true,
              onDismissTap: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Enable Microphone'));
      await tester.pump();

      expect(enableTapped, isTrue);
    });

    testWidgets('calls onEnableTap when Open Settings is tapped', (
      tester,
    ) async {
      var enableTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionDeniedBanner(
              status: MicrophonePermissionStatus.permanentlyDenied,
              onEnableTap: () => enableTapped = true,
              onDismissTap: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Settings'));
      await tester.pump();

      expect(enableTapped, isTrue);
    });

    testWidgets('calls onDismissTap when Not now is tapped', (tester) async {
      var dismissTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionDeniedBanner(
              status: MicrophonePermissionStatus.denied,
              onEnableTap: () {},
              onDismissTap: () => dismissTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Not now'));
      await tester.pump();

      expect(dismissTapped, isTrue);
    });
  });
}
