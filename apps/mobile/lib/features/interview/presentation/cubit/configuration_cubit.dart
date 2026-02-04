import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_state.dart';

/// Cubit for managing interview configuration state.
///
/// Handles user selections for role, type, difficulty, and question count.
/// Persists the last used configuration to shared preferences.
class ConfigurationCubit extends Cubit<ConfigurationState> {
  ConfigurationCubit({
    SharedPreferences? prefs,
  }) : _prefs = prefs,
       super(ConfigurationState.initial());

  final SharedPreferences? _prefs;

  // Shared preferences keys
  static const String _roleKey = 'interview_role';
  static const String _typeKey = 'interview_type';
  static const String _difficultyKey = 'interview_difficulty';
  static const String _questionCountKey = 'interview_question_count';

  /// Loads the last used configuration from shared preferences.
  Future<void> loadSavedConfiguration() async {
    if (_prefs == null) return;

    emit(state.copyWith(isLoading: true));

    try {
      final roleName = _prefs.getString(_roleKey);
      final typeName = _prefs.getString(_typeKey);
      final difficultyName = _prefs.getString(_difficultyKey);
      final questionCount = _prefs.getInt(_questionCountKey);

      final hasStoredValues =
          roleName != null ||
          typeName != null ||
          difficultyName != null ||
          questionCount != null;

      if (!hasStoredValues) {
        emit(state.copyWith(isLoading: false));
        return;
      }

      final restoredConfig = InterviewConfig(
        role: roleName != null
            ? InterviewRole.values.firstWhere(
                (e) => e.name == roleName,
                orElse: () => state.config.role,
              )
            : state.config.role,
        type: typeName != null
            ? InterviewType.values.firstWhere(
                (e) => e.name == typeName,
                orElse: () => state.config.type,
              )
            : state.config.type,
        difficulty: difficultyName != null
            ? DifficultyLevel.values.firstWhere(
                (e) => e.name == difficultyName,
                orElse: () => state.config.difficulty,
              )
            : state.config.difficulty,
        questionCount: questionCount ?? state.config.questionCount,
      );

      emit(
        state.copyWith(
          config: restoredConfig,
          isLoading: false,
          isRestoredFromPrefs: true,
        ),
      );
    } on Exception {
      // If restoration fails, keep defaults and continue
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Updates the selected interview role.
  void updateRole(InterviewRole role) {
    final newConfig = state.config.copyWith(role: role);
    emit(state.copyWith(config: newConfig));
    unawaited(_persistConfiguration(newConfig));
  }

  /// Updates the selected interview type.
  void updateType(InterviewType type) {
    final newConfig = state.config.copyWith(type: type);
    emit(state.copyWith(config: newConfig));
    unawaited(_persistConfiguration(newConfig));
  }

  /// Updates the selected difficulty level.
  void updateDifficulty(DifficultyLevel difficulty) {
    final newConfig = state.config.copyWith(difficulty: difficulty);
    emit(state.copyWith(config: newConfig));
    unawaited(_persistConfiguration(newConfig));
  }

  /// Updates the question count (5-10).
  void updateQuestionCount(int count) {
    if (count < InterviewConfig.minQuestionCount ||
        count > InterviewConfig.maxQuestionCount) {
      return; // Silently ignore invalid values
    }
    final newConfig = state.config.copyWith(questionCount: count);
    emit(state.copyWith(config: newConfig));
    unawaited(_persistConfiguration(newConfig));
  }

  /// Resets all selections to default values.
  void resetToDefaults() {
    final defaultConfig = InterviewConfig.defaults();
    emit(
      state.copyWith(
        config: defaultConfig,
        isRestoredFromPrefs: false,
      ),
    );
    unawaited(_persistConfiguration(defaultConfig));
  }

  Future<void> _persistConfiguration(InterviewConfig config) async {
    if (_prefs == null) return;

    await Future.wait([
      _prefs.setString(_roleKey, config.role.name),
      _prefs.setString(_typeKey, config.type.name),
      _prefs.setString(_difficultyKey, config.difficulty.name),
      _prefs.setInt(_questionCountKey, config.questionCount),
    ]);
  }
}
