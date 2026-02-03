import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_state.dart';
import 'package:voicemock/features/interview/presentation/view/setup_view.dart';

class MockConfigurationCubit extends MockCubit<ConfigurationState>
    implements ConfigurationCubit {}

extension on WidgetTester {
  Future<void> pumpSetupView(ConfigurationCubit cubit) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider<ConfigurationCubit>.value(
            value: cubit,
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
  late MockConfigurationCubit mockCubit;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(InterviewRole.softwareEngineer);
    registerFallbackValue(InterviewType.behavioral);
    registerFallbackValue(DifficultyLevel.medium);
  });

  setUp(() {
    mockCubit = MockConfigurationCubit();
  });

  group('SetupView', () {
    testWidgets('shows loading indicator when isLoading is true', (
      tester,
    ) async {
      when(() => mockCubit.state).thenReturn(
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

      await tester.pumpSetupView(mockCubit);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders all selectors when loaded', (tester) async {
      when(() => mockCubit.state).thenReturn(ConfigurationState.initial());

      await tester.pumpSetupView(mockCubit);

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
      when(() => mockCubit.state).thenReturn(
        const ConfigurationState(
          config: InterviewConfig(
            role: InterviewRole.productManager,
            type: InterviewType.technical,
            difficulty: DifficultyLevel.hard,
            questionCount: 8,
          ),
        ),
      );

      await tester.pumpSetupView(mockCubit);

      // Summary should show the selected values
      expect(find.text('Product Manager'), findsWidgets);
      expect(find.text('Technical'), findsWidgets);
      expect(find.text('Hard'), findsWidgets);
      expect(find.text('8 questions'), findsOneWidget);
    });

    testWidgets('calls updateType when type selector is tapped', (
      tester,
    ) async {
      when(() => mockCubit.state).thenReturn(ConfigurationState.initial());
      when(
        () => mockCubit.updateType(InterviewType.technical),
      ).thenReturn(null);

      await tester.pumpSetupView(mockCubit);

      // Tap on Technical option in type selector
      await tester.tap(find.text('Technical'));
      await tester.pump();

      verify(() => mockCubit.updateType(InterviewType.technical)).called(1);
    });

    testWidgets('calls updateDifficulty when difficulty selector is tapped', (
      tester,
    ) async {
      when(() => mockCubit.state).thenReturn(ConfigurationState.initial());
      when(
        () => mockCubit.updateDifficulty(DifficultyLevel.hard),
      ).thenReturn(null);

      await tester.pumpSetupView(mockCubit);

      // Tap on Hard option in difficulty selector
      await tester.tap(find.text('Hard'));
      await tester.pump();

      verify(() => mockCubit.updateDifficulty(DifficultyLevel.hard)).called(1);
    });

    testWidgets('Start Interview button navigates to interview screen', (
      tester,
    ) async {
      when(() => mockCubit.state).thenReturn(ConfigurationState.initial());

      await tester.pumpSetupView(mockCubit);

      // Tap Start Interview button
      await tester.tap(find.text('Start Interview'));
      await tester.pumpAndSettle();

      expect(find.text('Interview Screen'), findsOneWidget);
    });

    testWidgets('Start Interview button is always enabled', (tester) async {
      when(() => mockCubit.state).thenReturn(ConfigurationState.initial());

      await tester.pumpSetupView(mockCubit);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('calls updateRole when role is selected', (tester) async {
      when(() => mockCubit.state).thenReturn(ConfigurationState.initial());
      when(
        () => mockCubit.updateRole(InterviewRole.dataScientist),
      ).thenReturn(null);

      await tester.pumpSetupView(mockCubit);

      // Open role picker using first instance (the selector card)
      await tester.tap(find.text('Software Engineer').first);
      await tester.pumpAndSettle();

      // Select Data Scientist
      await tester.tap(find.text('Data Scientist'));
      await tester.pumpAndSettle();

      verify(() => mockCubit.updateRole(InterviewRole.dataScientist)).called(1);
    });
  });
}
