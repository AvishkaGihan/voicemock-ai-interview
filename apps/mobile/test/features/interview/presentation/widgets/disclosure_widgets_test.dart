import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/connectivity/connectivity.dart';
import 'package:voicemock/core/permissions/permission_service.dart';
import 'package:voicemock/core/storage/disclosure_prefs.dart';
import 'package:voicemock/features/interview/domain/interview_config.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_state.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_state.dart';
import 'package:voicemock/features/interview/presentation/cubit/session_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/session_state.dart';
import 'package:voicemock/features/interview/presentation/view/setup_view.dart';
import 'package:voicemock/features/interview/presentation/widgets/disclosure_banner.dart';
import 'package:voicemock/features/interview/presentation/widgets/disclosure_detail_sheet.dart';
import 'package:voicemock/l10n/l10n.dart';

// ---------------------------------------------------------------------------
// Constants for test verification (matching arb file)
// ---------------------------------------------------------------------------
const _kBannerText =
    'Your audio and responses are processed by third-party AI services to '
    'generate transcripts, questions, and feedback. Audio is not stored after '
    'processing.';
const _kBannerGotIt = 'Got it';
const _kBannerLearnMore = 'Learn more';
const _kDetailTitle = 'Data & Privacy';
const _kDetailClose = 'Got it';
// We only check headers for sections to keep it concise
const _kSection1Header = 'What data is processed';
const _kSection2Header = "How it's processed";
const _kSection3Header = 'Data retention';
const _kSection4Header = 'Your controls';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockConnectivityCubit extends MockCubit<ConnectivityState>
    implements ConnectivityCubit {}

class MockSessionCubit extends MockCubit<SessionState>
    implements SessionCubit {}

class MockConfigurationCubit extends MockCubit<ConfigurationState>
    implements ConfigurationCubit {}

class MockPermissionCubit extends MockCubit<PermissionState>
    implements PermissionCubit {}

class MockDisclosurePrefs extends Mock implements DisclosurePrefs {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps [widget] in MaterialApp with localisation and optional cubits.
Future<void> pumpDisclosureApp(
  WidgetTester tester,
  Widget widget, {
  ConnectivityCubit? connectivityCubit,
  SessionCubit? sessionCubit,
  ConfigurationCubit? configurationCubit,
  PermissionCubit? permissionCubit,
  DisclosurePrefs? disclosurePrefs,
  GoRouter? router,
}) async {
  final mockConnectivity = connectivityCubit ?? MockConnectivityCubit();
  final mockSession = sessionCubit ?? MockSessionCubit();
  final mockConfig = configurationCubit ?? MockConfigurationCubit();
  final mockPermission = permissionCubit ?? MockPermissionCubit();
  final mockDisclosurePrefs = disclosurePrefs ?? MockDisclosurePrefs();

  if (connectivityCubit == null) {
    when(() => mockConnectivity.state).thenReturn(const ConnectivityOnline());
    when(mockConnectivity.checkConnectivity).thenAnswer((_) async {});
  }
  if (sessionCubit == null) {
    when(() => mockSession.state).thenReturn(SessionInitial());
  }
  if (configurationCubit == null) {
    when(() => mockConfig.state).thenReturn(ConfigurationState.initial());
    when(mockConfig.loadSavedConfiguration).thenAnswer((_) async {});
  }
  if (permissionCubit == null) {
    when(() => mockPermission.state).thenReturn(
      PermissionState.initial().copyWith(
        status: MicrophonePermissionStatus.granted,
        hasChecked: true,
      ),
    );
  }
  if (disclosurePrefs == null) {
    // Default to acknowledged so basic widgets don't break if they check it
    when(
      mockDisclosurePrefs.hasAcknowledgedDisclosure,
    ).thenAnswer((_) async => true);
    when(mockDisclosurePrefs.acknowledgeDisclosure).thenAnswer((_) async {});
  }

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DisclosurePrefs>.value(value: mockDisclosurePrefs),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectivityCubit>.value(value: mockConnectivity),
          BlocProvider<SessionCubit>.value(value: mockSession),
          BlocProvider<ConfigurationCubit>.value(value: mockConfig),
          BlocProvider<PermissionCubit>.value(value: mockPermission),
        ],
        child: router != null
            ? MaterialApp.router(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: router,
              )
            : MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(body: widget),
              ),
      ),
    ),
  );
}

GoRouter _buildSetupRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SetupView(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) =>
          const Scaffold(body: Text('Settings Screen')),
    ),
    GoRoute(
      path: '/interview',
      name: 'interview',
      builder: (context, state) =>
          const Scaffold(body: Text('Interview Screen')),
    ),
    GoRoute(
      path: '/permission',
      name: 'permission',
      builder: (context, state) =>
          const Scaffold(body: Text('Permission Screen')),
    ),
  ],
);

// ---------------------------------------------------------------------------
// 8.1–8.4  DisclosureBanner unit-level widget tests
// ---------------------------------------------------------------------------

void main() {
  group('DisclosureBanner', () {
    // 8.1 — renders when not acknowledged
    testWidgets('renders banner text and action buttons', (tester) async {
      await pumpDisclosureApp(
        tester,
        DisclosureBanner(
          onGotIt: () {},
          onLearnMore: () {},
        ),
      );

      expect(find.text(_kBannerText), findsOneWidget);
      expect(find.text(_kBannerGotIt), findsOneWidget);
      expect(find.text(_kBannerLearnMore), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    // 8.2 — banner is hidden when acknowledged (parent controls visibility)
    testWidgets('banner is not visible when parent hides it', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(),
          ),
        ),
      );

      expect(find.text(_kBannerText), findsNothing);
    });

    // 8.3 — "Learn more" tap fires onLearnMore callback
    testWidgets('"Learn more" tap fires onLearnMore callback', (tester) async {
      var learnMoreTapped = false;

      await pumpDisclosureApp(
        tester,
        DisclosureBanner(
          onGotIt: () {},
          onLearnMore: () => learnMoreTapped = true,
        ),
      );

      await tester.tap(find.text(_kBannerLearnMore));
      await tester.pump();

      expect(learnMoreTapped, isTrue);
    });

    // 8.4 — "Got it" tap fires onGotIt callback
    testWidgets('"Got it" tap fires onGotIt callback', (tester) async {
      var gotItTapped = false;

      await pumpDisclosureApp(
        tester,
        DisclosureBanner(
          onGotIt: () => gotItTapped = true,
          onLearnMore: () {},
        ),
      );

      await tester.tap(find.text(_kBannerGotIt));
      await tester.pump();

      expect(gotItTapped, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 8.5  DisclosureDetailSheet renders all required sections
  // ---------------------------------------------------------------------------

  group('DisclosureDetailSheet', () {
    // 8.5 — renders all required sections
    // Pump the widget directly to avoid lazy-list clipping in bottom sheet.
    testWidgets('renders all four disclosure sections', (tester) async {
      await pumpDisclosureApp(
        tester,
        const DisclosureDetailSheet(),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(_kDetailTitle, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(_kSection1Header, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(_kSection2Header, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(_kSection3Header, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(_kSection4Header, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(_kDetailClose, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('"Got it" button dismisses the sheet', (tester) async {
      await pumpDisclosureApp(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => DisclosureDetailSheet.show(context),
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(_kDetailTitle), findsOneWidget);

      await tester.tap(find.text(_kDetailClose));
      await tester.pumpAndSettle();

      expect(find.text(_kDetailTitle), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // 8.6  SetupView shows disclosure banner on first launch
  // ---------------------------------------------------------------------------

  group('SetupView disclosure integration', () {
    late MockDisclosurePrefs mockPrefs;

    setUpAll(() {
      // Required by mocktail when using any() with InterviewConfig parameter.
      registerFallbackValue(InterviewConfig.defaults());
    });

    setUp(() {
      mockPrefs = MockDisclosurePrefs();
      // Default stubs
      when(mockPrefs.acknowledgeDisclosure).thenAnswer((_) async {});
    });

    // 8.6
    testWidgets('shows disclosure banner when not yet acknowledged', (
      tester,
    ) async {
      when(mockPrefs.hasAcknowledgedDisclosure).thenAnswer((_) async => false);

      await pumpDisclosureApp(
        tester,
        const SetupView(),
        disclosurePrefs: mockPrefs,
        router: _buildSetupRouter(),
      );

      // Allow initState async to complete
      // (DisclosurePrefs.hasAcknowledgedDisclosure)
      await tester.pumpAndSettle();

      expect(find.byType(DisclosureBanner), findsOneWidget);
      expect(find.text(_kBannerText), findsOneWidget);
    });

    testWidgets('hides disclosure banner when already acknowledged', (
      tester,
    ) async {
      when(mockPrefs.hasAcknowledgedDisclosure).thenAnswer((_) async => true);

      await pumpDisclosureApp(
        tester,
        const SetupView(),
        disclosurePrefs: mockPrefs,
        router: _buildSetupRouter(),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DisclosureBanner), findsNothing);
    });

    // 8.7 — auto-acknowledge on "Start Interview" tap
    testWidgets('auto-acknowledges disclosure when Start Interview is tapped', (
      tester,
    ) async {
      when(mockPrefs.hasAcknowledgedDisclosure).thenAnswer((_) async => false);
      when(mockPrefs.acknowledgeDisclosure).thenAnswer((_) async {});

      // We need a session cubit that responds to startSession
      final mockSession = MockSessionCubit();
      when(() => mockSession.state).thenReturn(SessionInitial());
      when(
        () => mockSession.startSession(any()),
      ).thenAnswer((_) async {});

      final mockConnectivity = MockConnectivityCubit();
      when(() => mockConnectivity.state).thenReturn(const ConnectivityOnline());
      when(mockConnectivity.checkConnectivity).thenAnswer((_) async {});

      final mockConfig = MockConfigurationCubit();
      when(() => mockConfig.state).thenReturn(ConfigurationState.initial());

      final mockPermission = MockPermissionCubit();
      when(() => mockPermission.state).thenReturn(
        PermissionState.initial().copyWith(
          status: MicrophonePermissionStatus.granted,
          hasChecked: true,
        ),
      );

      await pumpDisclosureApp(
        tester,
        const SetupView(),
        disclosurePrefs: mockPrefs,
        connectivityCubit: mockConnectivity,
        sessionCubit: mockSession,
        configurationCubit: mockConfig,
        permissionCubit: mockPermission,
        router: _buildSetupRouter(),
      );

      // Wait for the async disclosure state to load
      await tester.pumpAndSettle();

      // Banner visible
      expect(find.byType(DisclosureBanner), findsOneWidget);

      // Tap Start Interview
      await tester.tap(find.text('Start Interview'));
      await tester.pumpAndSettle();

      // Verify acknowledge was called
      verify(mockPrefs.acknowledgeDisclosure).called(1);
    });
  });
}
