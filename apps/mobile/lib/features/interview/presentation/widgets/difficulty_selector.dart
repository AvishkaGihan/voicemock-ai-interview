import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// Segmented control for selecting difficulty level.
class DifficultySelector extends StatelessWidget {
  const DifficultySelector({
    required this.selectedDifficulty,
    required this.onDifficultySelected,
    super.key,
  });

  final DifficultyLevel selectedDifficulty;
  final ValueChanged<DifficultyLevel> onDifficultySelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Difficulty Level',
          style: VoiceMockTypography.micro,
        ),
        const SizedBox(height: VoiceMockSpacing.sm),
        Material(
          color: VoiceMockColors.surface,
          borderRadius: BorderRadius.circular(VoiceMockRadius.md),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(VoiceMockSpacing.xs),
            child: Row(
              children: DifficultyLevel.values.map((difficulty) {
                final isSelected = difficulty == selectedDifficulty;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDifficultySelected(difficulty),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: VoiceMockSpacing.sm + 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? VoiceMockColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(VoiceMockRadius.sm),
                      ),
                      child: Text(
                        difficulty.displayName,
                        textAlign: TextAlign.center,
                        style: VoiceMockTypography.body.copyWith(
                          color: isSelected
                              ? VoiceMockColors.surface
                              : VoiceMockColors.textMuted,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
