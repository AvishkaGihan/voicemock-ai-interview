import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

void main() {
  group('InterviewRole', () {
    test('has correct display names', () {
      expect(InterviewRole.softwareEngineer.displayName, 'Software Engineer');
      expect(InterviewRole.productManager.displayName, 'Product Manager');
      expect(InterviewRole.dataScientist.displayName, 'Data Scientist');
      expect(InterviewRole.generalBusiness.displayName, 'General Business');
    });

    test('has exactly 4 roles for MVP', () {
      expect(InterviewRole.values.length, 4);
    });
  });

  group('InterviewType', () {
    test('has correct display names', () {
      expect(InterviewType.behavioral.displayName, 'Behavioral');
      expect(InterviewType.technical.displayName, 'Technical');
    });

    test('has exactly 2 types', () {
      expect(InterviewType.values.length, 2);
    });
  });

  group('DifficultyLevel', () {
    test('has correct display names', () {
      expect(DifficultyLevel.easy.displayName, 'Easy');
      expect(DifficultyLevel.medium.displayName, 'Medium');
      expect(DifficultyLevel.hard.displayName, 'Hard');
    });

    test('has exactly 3 levels', () {
      expect(DifficultyLevel.values.length, 3);
    });
  });

  group('InterviewConfig', () {
    test('defaults creates config with expected values', () {
      final config = InterviewConfig.defaults();

      expect(config.role, InterviewRole.softwareEngineer);
      expect(config.type, InterviewType.behavioral);
      expect(config.difficulty, DifficultyLevel.medium);
      expect(config.questionCount, 5);
    });

    test('minQuestionCount is 5', () {
      expect(InterviewConfig.minQuestionCount, 5);
    });

    test('maxQuestionCount is 10', () {
      expect(InterviewConfig.maxQuestionCount, 10);
    });

    test('defaultQuestionCount is 5', () {
      expect(InterviewConfig.defaultQuestionCount, 5);
    });

    test('copyWith updates role correctly', () {
      final config = InterviewConfig.defaults();
      final updated = config.copyWith(role: InterviewRole.productManager);

      expect(updated.role, InterviewRole.productManager);
      expect(updated.type, config.type);
      expect(updated.difficulty, config.difficulty);
      expect(updated.questionCount, config.questionCount);
    });

    test('copyWith updates type correctly', () {
      final config = InterviewConfig.defaults();
      final updated = config.copyWith(type: InterviewType.technical);

      expect(updated.type, InterviewType.technical);
      expect(updated.role, config.role);
    });

    test('copyWith updates difficulty correctly', () {
      final config = InterviewConfig.defaults();
      final updated = config.copyWith(difficulty: DifficultyLevel.hard);

      expect(updated.difficulty, DifficultyLevel.hard);
    });

    test('copyWith updates questionCount correctly', () {
      final config = InterviewConfig.defaults();
      final updated = config.copyWith(questionCount: 8);

      expect(updated.questionCount, 8);
    });

    test('supports value equality', () {
      final config1 = InterviewConfig.defaults();
      final config2 = InterviewConfig.defaults();

      expect(config1, equals(config2));
    });

    test('different configs are not equal', () {
      final config1 = InterviewConfig.defaults();
      final config2 = config1.copyWith(role: InterviewRole.productManager);

      expect(config1, isNot(equals(config2)));
    });

    test('valid question counts between 5 and 10 are accepted', () {
      for (var count = 5; count <= 10; count++) {
        expect(
          () => InterviewConfig(
            role: InterviewRole.softwareEngineer,
            type: InterviewType.behavioral,
            difficulty: DifficultyLevel.medium,
            questionCount: count,
          ),
          returnsNormally,
        );
      }
    });

    test('question count below 5 throws assertion error', () {
      expect(
        () => InterviewConfig(
          role: InterviewRole.softwareEngineer,
          type: InterviewType.behavioral,
          difficulty: DifficultyLevel.medium,
          questionCount: 4,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('question count above 10 throws assertion error', () {
      expect(
        () => InterviewConfig(
          role: InterviewRole.softwareEngineer,
          type: InterviewType.behavioral,
          difficulty: DifficultyLevel.medium,
          questionCount: 11,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
