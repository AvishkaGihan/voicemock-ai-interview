import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/settings/presentation/view/settings_page.dart';
import 'package:voicemock/l10n/l10n.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockSessionRepository repository;

  final storedSession = Session(
    sessionId: 'session-123',
    sessionToken: 'token-123',
    openingPrompt: 'Welcome',
    totalQuestions: 5,
    createdAt: DateTime(2026),
  );

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryProvider<SessionRepository>.value(
        value: repository,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: VoiceMockColors.primary,
              surface: VoiceMockColors.surface,
            ),
            useMaterial3: true,
          ),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = MockSessionRepository();
  });

  testWidgets('shows Delete Session Data tile', (tester) async {
    when(repository.getStoredSession).thenAnswer((_) async => storedSession);

    await pumpSettings(tester);

    expect(find.text('Delete Session Data'), findsOneWidget);
    expect(
      find.text('Remove transcripts, feedback, and summary'),
      findsOneWidget,
    );
  });

  testWidgets('tapping tile shows confirmation dialog', (tester) async {
    when(repository.getStoredSession).thenAnswer((_) async => storedSession);

    await pumpSettings(tester);
    await tester.tap(find.text('Delete Session Data'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Session Data?'), findsOneWidget);
  });

  testWidgets('successful deletion shows snackbar and disables tile', (
    tester,
  ) async {
    when(repository.getStoredSession).thenAnswer((_) async => storedSession);
    when(
      () => repository.deleteSession('session-123', 'token-123'),
    ).thenAnswer((_) async => const Right(true));

    await pumpSettings(tester);
    await tester.tap(find.text('Delete Session Data'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Session data deleted.'), findsOneWidget);

    final listTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Delete Session Data'),
    );
    expect(listTile.enabled, isFalse);
  });

  testWidgets('failed deletion shows retry snackbar action', (tester) async {
    when(repository.getStoredSession).thenAnswer((_) async => storedSession);
    when(
      () => repository.deleteSession('session-123', 'token-123'),
    ).thenAnswer(
      (_) async => const Left(
        NetworkFailure(
          message: 'Cannot connect to server. Please check your internet.',
        ),
      ),
    );

    await pumpSettings(tester);
    await tester.tap(find.text('Delete Session Data'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(
      find.text('Cannot connect to server. Please check your internet.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}
