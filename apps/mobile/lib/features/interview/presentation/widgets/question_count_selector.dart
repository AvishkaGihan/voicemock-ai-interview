import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// Slider-based selector for question count (5-10).
class QuestionCountSelector extends StatelessWidget {
  const QuestionCountSelector({
    required this.questionCount,
    required this.onQuestionCountChanged,
    super.key,
  });

  final int questionCount;
  final ValueChanged<int> onQuestionCountChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Number of Questions',
              style: VoiceMockTypography.micro,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VoiceMockSpacing.sm,
                vertical: VoiceMockSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: VoiceMockColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(VoiceMockRadius.sm),
              ),
              child: Text(
                '$questionCount',
                style: VoiceMockTypography.body.copyWith(
                  color: VoiceMockColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: VoiceMockSpacing.sm),
        Material(
          color: VoiceMockColors.surface,
          borderRadius: BorderRadius.circular(VoiceMockRadius.md),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VoiceMockSpacing.sm,
              vertical: VoiceMockSpacing.sm,
            ),
            child: Row(
              children: [
                const Text(
                  '${InterviewConfig.minQuestionCount}',
                  style: VoiceMockTypography.small,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: VoiceMockColors.primary,
                      inactiveTrackColor: VoiceMockColors.primary.withValues(
                        alpha: 0.2,
                      ),
                      thumbColor: VoiceMockColors.primary,
                      overlayColor: VoiceMockColors.primary.withValues(
                        alpha: 0.1,
                      ),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                      ),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: questionCount.toDouble(),
                      min: InterviewConfig.minQuestionCount.toDouble(),
                      max: InterviewConfig.maxQuestionCount.toDouble(),
                      divisions:
                          InterviewConfig.maxQuestionCount -
                          InterviewConfig.minQuestionCount,
                      onChanged: (value) =>
                          onQuestionCountChanged(value.round()),
                    ),
                  ),
                ),
                const Text(
                  '${InterviewConfig.maxQuestionCount}',
                  style: VoiceMockTypography.small,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
