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
        Text(
          'Difficulty Level',
          style: VoiceMockTypography.label,
        ),
        const SizedBox(height: VoiceMockSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: VoiceMockColors.surface,
            borderRadius: BorderRadius.circular(VoiceMockRadius.md),
            border: const Border(
              left: BorderSide(color: VoiceMockColors.primary, width: 3),
            ),
            boxShadow: const [
              BoxShadow(
                color: VoiceMockColors.accentGlow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
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
                        color: isSelected ? null : Colors.transparent,
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [
                                  VoiceMockColors.primary,
                                  VoiceMockColors.secondary,
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(
                          VoiceMockRadius.full,
                        ),
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
