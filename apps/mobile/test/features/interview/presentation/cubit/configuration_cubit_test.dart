import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_state.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('ConfigurationCubit', () {
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      // Default behavior: return null for all prefs (no stored values)
      when(() => mockPrefs.getInt(any())).thenReturn(null);
      when(() => mockPrefs.getString(any())).thenReturn(null);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      when(
        () => mockPrefs.setString(any(), any()),
      ).thenAnswer((_) async => true);
    });

    group('initial state', () {
      test('has default configuration values', () {
        final cubit = ConfigurationCubit();
        expect(cubit.state.config.role, InterviewRole.softwareEngineer);
        expect(cubit.state.config.type, InterviewType.behavioral);
        expect(cubit.state.config.difficulty, DifficultyLevel.medium);
        expect(cubit.state.config.questionCount, 5);
        expect(cubit.state.isLoading, false);
        expect(cubit.state.isRestoredFromPrefs, false);
      });
    });

    group('updateRole', () {
      blocTest<ConfigurationCubit, ConfigurationState>(
        'emits state with updated role',
        build: () => ConfigurationCubit(prefs: mockPrefs),
        act: (cubit) => cubit.updateRole(InterviewRole.productManager),
        expect: () => [
          isA<ConfigurationState>().having(
            (s) => s.config.role,
            'role',
            InterviewRole.productManager,
          ),
        ],
      );

      blocTest<ConfigurationCubit, ConfigurationState>(
        'persists role to shared preferences',
        build: () => ConfigurationCubit(prefs: mockPrefs),
        act: (cubit) => cubit.updateRole(InterviewRole.dataScientist),
        verify: (_) {
          verify(
            () => mockPrefs.setString(
              'interview_role',
              InterviewRole.dataScientist.name,
            ),
          ).called(1);
        },
      );
    });

    group('updateType', () {
      blocTest<ConfigurationCubit, ConfigurationState>(
        'emits state with updated type',
        build: () => ConfigurationCubit(prefs: mockPrefs),
        act: (cubit) => cubit.updateType(InterviewType.technical),
        expect: () => [
          isA<ConfigurationState>().having(
            (s) => s.config.type,
            'type',
            InterviewType.technical,
          ),
        ],
      );

      blocTest<ConfigurationCubit, ConfigurationState>(
        'persists type to shared preferences',
        build: () => ConfigurationCubit(prefs: mockPrefs),
        act: (cubit) => cubit.updateType(InterviewType.technical),
        verify: (_) {
          verify(
            () => mockPrefs.setString(
              'interview_type',
              InterviewType.technical.name,
            ),
          ).called(1);
        },
      );
    });

    group('updateDifficulty', () {
      blocTest<ConfigurationCubit, ConfigurationState>(
        'emits state with updated difficulty',
        build: () => ConfigurationCubit(prefs: mockPrefs),
        act: (cubit) => cubit.updateDifficulty(DifficultyLevel.hard),
        expect: () => [
          isA<ConfigurationState>().having(
            (s) => s.config.difficulty,
            'difficulty',
            DifficultyLevel.hard,
          ),
        ],
      );

      blocTest<ConfigurationCubit, ConfigurationState>(
        'persists difficulty to shared preferences',
        build: () => ConfigurationCubit(prefs: mockPrefs),
        act: (cubit) => cubit.updateDifficulty(DifficultyLevel.easy),
        verify: (_) {
          verify(
            () => mockPrefs.setString(
              'interview_difficulty',
              DifficultyLevel.easy.name,
            ),
          ).called(1);
        },
      );
    });

    group('updateQuestionCount', () {
      blocTest<ConfigurationCubit, ConfigurationState>(
        'emits state with updated question count when valid',
        build: () => ConfigurationCubit(prefs: mockPrefs),
        act: (cubit) => cubit.updateQuestionCount(8),
        expect: () => [
          isA<ConfigurationState>().having(
            (s) => s.config.questionCount,
            'questionCount',
            8,
          ),
        ],
      );

      blocTest<ConfigurationCubit, ConfigurationState>(
        'ignores question count below minimum',
        build: () => ConfigurationCubit(prefs: mockPrefs),
        act: (cubit) => cubit.updateQuestionCount(4),
        expect: () => <ConfigurationState>[],
      );

      blocTest<ConfigurationCubit, ConfigurationState>(
        'ignores question count above maximum',
        build: () => ConfigurationCubit(prefs: mockPrefs),
        act: (cubit) => cubit.updateQuestionCount(11),
        expect: () => <ConfigurationState>[],
      );

      blocTest<ConfigurationCubit, ConfigurationState>(
        'persists valid question count to shared preferences',
        build: () => ConfigurationCubit(prefs: mockPrefs),
        act: (cubit) => cubit.updateQuestionCount(7),
        verify: (_) {
          verify(
            () => mockPrefs.setInt('interview_question_count', 7),
          ).called(1);
        },
      );
    });

    group('resetToDefaults', () {
      blocTest<ConfigurationCubit, ConfigurationState>(
        'resets configuration to defaults',
        build: () => ConfigurationCubit(prefs: mockPrefs),
        seed: () => const ConfigurationState(
          config: InterviewConfig(
            role: InterviewRole.dataScientist,
            type: InterviewType.technical,
            difficulty: DifficultyLevel.hard,
            questionCount: 10,
          ),
          isRestoredFromPrefs: true,
        ),
        act: (cubit) => cubit.resetToDefaults(),
        expect: () => [
          isA<ConfigurationState>()
              .having(
                (s) => s.config.role,
                'role',
                InterviewRole.softwareEngineer,
              )
              .having(
                (s) => s.config.type,
                'type',
                InterviewType.behavioral,
              )
              .having(
                (s) => s.config.difficulty,
                'difficulty',
                DifficultyLevel.medium,
              )
              .having(
                (s) => s.config.questionCount,
                'questionCount',
                5,
              )
              .having(
                (s) => s.isRestoredFromPrefs,
                'isRestoredFromPrefs',
                false,
              ),
        ],
      );
    });

    group('loadSavedConfiguration', () {
      blocTest<ConfigurationCubit, ConfigurationState>(
        'loads stored configuration from preferences',
        setUp: () {
          when(
            () => mockPrefs.getString('interview_role'),
          ).thenReturn(InterviewRole.productManager.name);
          when(
            () => mockPrefs.getString('interview_type'),
          ).thenReturn(InterviewType.technical.name);
          when(
            () => mockPrefs.getString('interview_difficulty'),
          ).thenReturn(DifficultyLevel.hard.name);
          when(
            () => mockPrefs.getInt('interview_question_count'),
          ).thenReturn(8);
        },
        build: () => ConfigurationCubit(prefs: mockPrefs),
        act: (cubit) => cubit.loadSavedConfiguration(),
        expect: () => [
          isA<ConfigurationState>().having(
            (s) => s.isLoading,
            'isLoading',
            true,
          ),
          isA<ConfigurationState>()
              .having(
                (s) => s.config.role,
                'role',
                InterviewRole.productManager,
              )
              .having((s) => s.config.type, 'type', InterviewType.technical)
              .having(
                (s) => s.config.difficulty,
                'difficulty',
                DifficultyLevel.hard,
              )
              .having((s) => s.config.questionCount, 'questionCount', 8)
              .having((s) => s.isLoading, 'isLoading', false)
              .having(
                (s) => s.isRestoredFromPrefs,
                'isRestoredFromPrefs',
                true,
              ),
        ],
      );

      blocTest<ConfigurationCubit, ConfigurationState>(
        'keeps defaults when no stored values exist',
        build: () => ConfigurationCubit(prefs: mockPrefs),
        act: (cubit) => cubit.loadSavedConfiguration(),
        expect: () => [
          isA<ConfigurationState>().having(
            (s) => s.isLoading,
            'isLoading',
            true,
          ),
          isA<ConfigurationState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having(
                (s) => s.isRestoredFromPrefs,
                'isRestoredFromPrefs',
                false,
              ),
        ],
      );

      blocTest<ConfigurationCubit, ConfigurationState>(
        'does nothing when prefs is null',
        build: ConfigurationCubit.new,
        act: (cubit) => cubit.loadSavedConfiguration(),
        expect: () => <ConfigurationState>[],
      );
    });
  });
}
