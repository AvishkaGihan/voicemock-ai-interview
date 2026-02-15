import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemock/app/router.dart';
import 'package:voicemock/app/view/app.dart';
import 'package:voicemock/core/http/api_client.dart';
import 'package:voicemock/features/diagnostics/presentation/view/diagnostics_page.dart';
import 'package:voicemock/features/interview/domain/session.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockApiClient mockApiClient;
  late MockSharedPreferences mockPrefs;

  final testSession = Session(
    sessionId: 'session-123',
    sessionToken: 'token-123',
    openingPrompt: 'Welcome',
    totalQuestions: 5,
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockApiClient = MockApiClient();
    mockPrefs = MockSharedPreferences();

    // Setup basic mock behavior for prefs if needed by SetupPage
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockPrefs.getString(any())).thenReturn(null);
  });

  testWidgets('navigating to diagnostics from interview provides cubit', (
    tester,
  ) async {
    // Use the real App widget with mocked dependencies
    await tester.pumpWidget(
      App(prefs: mockPrefs, apiClient: mockApiClient),
    );

    // 1. Navigate to interview
    appRouter.go('/interview', extra: testSession);
    await tester.pumpAndSettle();

    // Verify we are on Interview Page (title check)
    expect(find.text('Interview'), findsOneWidget);

    // 2. Enable diagnostics (triple tap) - although it might be on by default
    // in debug/test mode.
    // Let's check for the icon first.
    final diagnosticsIcon = find.byIcon(Icons.analytics_outlined);
    if (diagnosticsIcon.evaluate().isEmpty) {
      final titleFinder = find.text('Interview');
      await tester.tap(titleFinder);
      await tester.tap(titleFinder);
      await tester.tap(titleFinder);
      await tester.pump();
    }

    expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);

    // 3. Tap diagnostics button
    await tester.tap(find.byIcon(Icons.analytics_outlined));

    // 4. Pump and Settle should NOT throw ProviderNotFoundException
    await tester.pumpAndSettle();

    // 5. Verify DiagnosticsPage is shown
    expect(find.byType(DiagnosticsPage), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);

    // If it reached here without crashing, the Provider was found.
  });
}
