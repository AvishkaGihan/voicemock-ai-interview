import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// Inline selector for difficulty level.
///
/// Displays label on top and a 3-way full-width segmented control underneath.
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
    return Padding(
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                color: VoiceMockColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Text(
                'Difficulty',
                style: VoiceMockTypography.body.copyWith(
                  color: VoiceMockColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.sm),
          Row(
            children: DifficultyLevel.values.map((difficulty) {
              final isSelected = difficulty == selectedDifficulty;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: difficulty == DifficultyLevel.values.last
                        ? 0
                        : VoiceMockSpacing.sm,
                  ),
                  child: GestureDetector(
                    onTap: () => onDifficultySelected(difficulty),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        vertical: VoiceMockSpacing.sm + 2,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? VoiceMockColors.primary.withValues(alpha: 0.12)
                            : VoiceMockColors.surfaceElevated,
                        borderRadius:
                            BorderRadius.circular(VoiceMockRadius.full),
                        border: Border.all(
                          color: isSelected
                              ? VoiceMockColors.primary
                              : VoiceMockColors.surfaceBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? VoiceMockColors.primary
                                    : VoiceMockColors.textMuted,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: VoiceMockColors.primary,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            difficulty.displayName,
                            style: VoiceMockTypography.small.copyWith(
                              color: isSelected
                                  ? VoiceMockColors.primary
                                  : VoiceMockColors.textMuted,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
