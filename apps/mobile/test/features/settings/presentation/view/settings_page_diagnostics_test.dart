import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_state.dart';
import 'package:voicemock/features/settings/presentation/view/settings_page.dart';
import 'package:voicemock/l10n/l10n.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

class MockInterviewCubit extends Mock implements InterviewCubit {
  @override
  Stream<InterviewState> get stream => const Stream.empty();
}

void main() {
  late MockSessionRepository repository;
  late MockInterviewCubit cubit;

  setUp(() {
    repository = MockSessionRepository();
    cubit = MockInterviewCubit();
    when(() => repository.getStoredSession()).thenAnswer((_) async => null);
  });

  Widget createApp({InterviewCubit? interviewCubit}) {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) {
            Widget page = const SettingsPage();
            page = RepositoryProvider<SessionRepository>.value(
              value: repository,
              child: page,
            );
            if (interviewCubit != null) {
              page = BlocProvider<InterviewCubit>.value(
                value: interviewCubit,
                child: page,
              );
            }
            return page;
          },
        ),
        GoRoute(
          path: '/diagnostics',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Diagnostics destination')),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  testWidgets('shows diagnostics tile when InterviewCubit is available', (
    tester,
  ) async {
    await tester.pumpWidget(createApp(interviewCubit: cubit));
    await tester.pumpAndSettle();

    expect(find.text('Diagnostics'), findsOneWidget);
    expect(find.text('View timing metrics & error info'), findsOneWidget);
  });

  testWidgets('hides diagnostics tile when InterviewCubit is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(createApp());
    await tester.pumpAndSettle();

    expect(find.text('Diagnostics'), findsNothing);
    expect(find.text('View timing metrics & error info'), findsNothing);
  });

  testWidgets('tapping diagnostics tile navigates to diagnostics route', (
    tester,
  ) async {
    await tester.pumpWidget(createApp(interviewCubit: cubit));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Diagnostics'));
    await tester.pumpAndSettle();

    expect(find.text('Diagnostics destination'), findsOneWidget);
  });
}
