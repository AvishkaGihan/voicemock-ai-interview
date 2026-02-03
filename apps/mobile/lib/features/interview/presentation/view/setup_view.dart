import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_state.dart';
import 'package:voicemock/features/interview/presentation/widgets/configuration_summary_card.dart';
import 'package:voicemock/features/interview/presentation/widgets/difficulty_selector.dart';
import 'package:voicemock/features/interview/presentation/widgets/question_count_selector.dart';
import 'package:voicemock/features/interview/presentation/widgets/role_selector.dart';
import 'package:voicemock/features/interview/presentation/widgets/type_selector.dart';

/// Main setup view for configuring interview parameters.
///
/// Provides selectors for role, type, difficulty, and question count.
/// Shows a summary of selections and a Start Interview button.
class SetupView extends StatelessWidget {
  const SetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationCubit, ConfigurationState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: VoiceMockColors.primary,
            ),
          );
        }

        final cubit = context.read<ConfigurationCubit>();
        final config = state.config;

        return Scaffold(
          backgroundColor: VoiceMockColors.background,
          appBar: AppBar(
            backgroundColor: VoiceMockColors.background,
            elevation: 0,
            title: const Text(
              'Interview Setup',
              style: VoiceMockTypography.h2,
            ),
            centerTitle: false,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(VoiceMockSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role selector
                        RoleSelector(
                          selectedRole: config.role,
                          onRoleSelected: cubit.updateRole,
                        ),
                        const SizedBox(height: VoiceMockSpacing.lg),

                        // Interview type selector
                        TypeSelector(
                          selectedType: config.type,
                          onTypeSelected: cubit.updateType,
                        ),
                        const SizedBox(height: VoiceMockSpacing.lg),

                        // Difficulty selector
                        DifficultySelector(
                          selectedDifficulty: config.difficulty,
                          onDifficultySelected: cubit.updateDifficulty,
                        ),
                        const SizedBox(height: VoiceMockSpacing.lg),

                        // Question count selector
                        QuestionCountSelector(
                          questionCount: config.questionCount,
                          onQuestionCountChanged: cubit.updateQuestionCount,
                        ),
                        const SizedBox(height: VoiceMockSpacing.xl),

                        // Configuration summary
                        ConfigurationSummaryCard(config: config),
                      ],
                    ),
                  ),
                ),

                // Start Interview button - anchored at bottom
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(VoiceMockSpacing.md),
                  decoration: BoxDecoration(
                    color: VoiceMockColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    onPressed: () {
                      context.goNamed('interview');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: VoiceMockColors.primary,
                      foregroundColor: VoiceMockColors.surface,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(VoiceMockRadius.md),
                      ),
                      textStyle: VoiceMockTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Start Interview'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
