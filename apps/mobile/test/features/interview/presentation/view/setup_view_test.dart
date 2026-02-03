import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/permissions/permission_service.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_state.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_state.dart';
import 'package:voicemock/features/interview/presentation/view/setup_view.dart';

class MockConfigurationCubit extends MockCubit<ConfigurationState>
    implements ConfigurationCubit {}

class MockPermissionCubit extends MockCubit<PermissionState>
    implements PermissionCubit {}

extension on WidgetTester {
  Future<void> pumpSetupView(
    ConfigurationCubit configCubit,
    PermissionCubit permissionCubit,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<ConfigurationCubit>.value(value: configCubit),
              BlocProvider<PermissionCubit>.value(value: permissionCubit),
            ],
            child: const SetupView(),
          ),
        ),
        GoRoute(
          path: '/interview',
          name: 'interview',
          builder: (context, state) => const Scaffold(
            body: Text('Interview Screen'),
          ),
        ),
        GoRoute(
          path: '/permission',
          name: 'permission',
          builder: (context, state) => const Scaffold(
            body: Text('Permission Screen'),
          ),
        ),
      ],
    );

    await pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );
  }
}

void main() {
  late MockConfigurationCubit mockConfigCubit;
  late MockPermissionCubit mockPermissionCubit;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(InterviewRole.softwareEngineer);
    registerFallbackValue(InterviewType.behavioral);
    registerFallbackValue(DifficultyLevel.medium);
    registerFallbackValue(MicrophonePermissionStatus.granted);
  });

  setUp(() {
    mockConfigCubit = MockConfigurationCubit();
    mockPermissionCubit = MockPermissionCubit();

    // Default permission state (granted)
    when(() => mockPermissionCubit.state).thenReturn(
      const PermissionState(
        status: MicrophonePermissionStatus.granted,
        hasChecked: true,
      ),
    );
  });

  group('SetupView', () {
    testWidgets('shows loading indicator when isLoading is true', (
      tester,
    ) async {
      when(() => mockConfigCubit.state).thenReturn(
        const ConfigurationState(
          config: InterviewConfig(
            role: InterviewRole.softwareEngineer,
            type: InterviewType.behavioral,
            difficulty: DifficultyLevel.medium,
            questionCount: 5,
          ),
          isLoading: true,
        ),
      );

      await tester.pumpSetupView(mockConfigCubit, mockPermissionCubit);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders all selectors when loaded', (tester) async {
      when(
        () => mockConfigCubit.state,
      ).thenReturn(ConfigurationState.initial());

      await tester.pumpSetupView(mockConfigCubit, mockPermissionCubit);

      // Check for role selector card
      expect(find.text('Target Role'), findsOneWidget);
      // Software Engineer appears in selector and summary
      expect(find.text('Software Engineer'), findsWidgets);

      // Check for type selector
      expect(find.text('Interview Type'), findsOneWidget);
      expect(find.text('Behavioral'), findsWidgets);
      expect(find.text('Technical'), findsOneWidget);

      // Check for difficulty selector
      expect(find.text('Difficulty Level'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Medium'), findsWidgets);
      expect(find.text('Hard'), findsOneWidget);

      // Check for question count selector
      expect(find.text('Number of Questions'), findsOneWidget);

      // Check for summary card
      expect(find.text('Interview Summary'), findsOneWidget);

      // Check for Start Interview button
      expect(find.text('Start Interview'), findsOneWidget);
    });

    testWidgets('displays configuration summary with current selections', (
      tester,
    ) async {
      when(() => mockConfigCubit.state).thenReturn(
        const ConfigurationState(
          config: InterviewConfig(
            role: InterviewRole.productManager,
            type: InterviewType.technical,
            difficulty: DifficultyLevel.hard,
            questionCount: 8,
          ),
        ),
      );

      await tester.pumpSetupView(mockConfigCubit, mockPermissionCubit);

      // Summary should show the selected values
      expect(find.text('Product Manager'), findsWidgets);
      expect(find.text('Technical'), findsWidgets);
      expect(find.text('Hard'), findsWidgets);
      expect(find.text('8 questions'), findsOneWidget);
    });

    testWidgets('calls updateType when type selector is tapped', (
      tester,
    ) async {
      when(
        () => mockConfigCubit.state,
      ).thenReturn(ConfigurationState.initial());
      when(
        () => mockConfigCubit.updateType(InterviewType.technical),
      ).thenReturn(null);

      await tester.pumpSetupView(mockConfigCubit, mockPermissionCubit);

      // Tap on Technical option in type selector
      await tester.tap(find.text('Technical'));
      await tester.pump();

      verify(
        () => mockConfigCubit.updateType(InterviewType.technical),
      ).called(1);
    });

    testWidgets('calls updateDifficulty when difficulty selector is tapped', (
      tester,
    ) async {
      when(
        () => mockConfigCubit.state,
      ).thenReturn(ConfigurationState.initial());
      when(
        () => mockConfigCubit.updateDifficulty(DifficultyLevel.hard),
      ).thenReturn(null);

      await tester.pumpSetupView(mockConfigCubit, mockPermissionCubit);

      // Tap on Hard option in difficulty selector
      await tester.tap(find.text('Hard'));
      await tester.pump();

      verify(
        () => mockConfigCubit.updateDifficulty(DifficultyLevel.hard),
      ).called(1);
    });

    testWidgets(
      'Start Interview button navigates to interview when mic granted',
      (tester) async {
        when(() => mockConfigCubit.state).thenReturn(
          ConfigurationState.initial(),
        );
        when(() => mockPermissionCubit.state).thenReturn(
          const PermissionState(
            status: MicrophonePermissionStatus.granted,
            hasChecked: true,
          ),
        );

        await tester.pumpSetupView(mockConfigCubit, mockPermissionCubit);

        // Tap Start Interview button
        await tester.tap(find.text('Start Interview'));
        await tester.pumpAndSettle();

        expect(find.text('Interview Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'Start Interview button navigates to permission when mic not granted',
      (tester) async {
        when(() => mockConfigCubit.state).thenReturn(
          ConfigurationState.initial(),
        );
        when(() => mockPermissionCubit.state).thenReturn(
          const PermissionState(
            status: MicrophonePermissionStatus.denied,
            hasChecked: true,
          ),
        );

        await tester.pumpSetupView(mockConfigCubit, mockPermissionCubit);

        // Tap Start Interview button
        await tester.tap(find.text('Start Interview'));
        await tester.pumpAndSettle();

        expect(find.text('Permission Screen'), findsOneWidget);
      },
    );

    testWidgets('Start Interview button is always enabled', (tester) async {
      when(
        () => mockConfigCubit.state,
      ).thenReturn(ConfigurationState.initial());

      await tester.pumpSetupView(mockConfigCubit, mockPermissionCubit);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('calls updateRole when role is selected', (tester) async {
      when(
        () => mockConfigCubit.state,
      ).thenReturn(ConfigurationState.initial());
      when(
        () => mockConfigCubit.updateRole(InterviewRole.dataScientist),
      ).thenReturn(null);

      await tester.pumpSetupView(mockConfigCubit, mockPermissionCubit);

      // Open role picker using first instance (the selector card)
      await tester.tap(find.text('Software Engineer').first);
      await tester.pumpAndSettle();

      // Select Data Scientist
      await tester.tap(find.text('Data Scientist'));
      await tester.pumpAndSettle();

      verify(
        () => mockConfigCubit.updateRole(InterviewRole.dataScientist),
      ).called(1);
    });

    testWidgets(
      'shows permission denied banner when permission is denied',
      (tester) async {
        when(() => mockConfigCubit.state).thenReturn(
          ConfigurationState.initial(),
        );
        when(() => mockPermissionCubit.state).thenReturn(
          const PermissionState(
            status: MicrophonePermissionStatus.denied,
            hasChecked: true,
          ),
        );

        await tester.pumpSetupView(mockConfigCubit, mockPermissionCubit);

        expect(
          find.text('Microphone access is required for voice practice'),
          findsOneWidget,
        );
        expect(find.text('Enable Microphone'), findsOneWidget);
        expect(find.text('Not now'), findsOneWidget);
      },
    );

    testWidgets(
      'shows Open Settings button when permanently denied',
      (tester) async {
        when(() => mockConfigCubit.state).thenReturn(
          ConfigurationState.initial(),
        );
        when(() => mockPermissionCubit.state).thenReturn(
          const PermissionState(
            status: MicrophonePermissionStatus.permanentlyDenied,
            hasChecked: true,
          ),
        );

        await tester.pumpSetupView(mockConfigCubit, mockPermissionCubit);

        expect(find.text('Open Settings'), findsOneWidget);
      },
    );

    testWidgets(
      'does not show banner when permission is granted',
      (tester) async {
        when(() => mockConfigCubit.state).thenReturn(
          ConfigurationState.initial(),
        );
        when(() => mockPermissionCubit.state).thenReturn(
          const PermissionState(
            status: MicrophonePermissionStatus.granted,
            hasChecked: true,
          ),
        );

        await tester.pumpSetupView(mockConfigCubit, mockPermissionCubit);

        expect(
          find.text('Microphone access is required for voice practice'),
          findsNothing,
        );
      },
    );
  });
}
