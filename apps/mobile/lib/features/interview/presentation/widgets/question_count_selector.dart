import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// Inline selector for question count (5-10).
///
/// Shows label + count badge on the top row, with a slider underneath.
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
    return Padding(
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + label + count badge
          Row(
            children: [
              const Icon(
                Icons.format_list_numbered_rounded,
                color: VoiceMockColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Text(
                'Number of Questions',
                style: VoiceMockTypography.body.copyWith(
                  color: VoiceMockColors.textMuted,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VoiceMockSpacing.md,
                  vertical: VoiceMockSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: VoiceMockColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(VoiceMockRadius.md),
                  border: Border.all(color: VoiceMockColors.surfaceBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$questionCount',
                      style: VoiceMockTypography.h3.copyWith(
                        color: VoiceMockColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Questions',
                      style: VoiceMockTypography.micro.copyWith(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: VoiceMockSpacing.md),

          // Slider row
          Row(
            children: [
              Text(
                '${InterviewConfig.minQuestionCount}',
                style: VoiceMockTypography.small,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: VoiceMockColors.primary,
                    inactiveTrackColor: VoiceMockColors.surfaceBorder,
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
                    divisions: InterviewConfig.maxQuestionCount -
                        InterviewConfig.minQuestionCount,
                    onChanged: (value) =>
                        onQuestionCountChanged(value.round()),
                  ),
                ),
              ),
              Text(
                '${InterviewConfig.maxQuestionCount}',
                style: VoiceMockTypography.small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
