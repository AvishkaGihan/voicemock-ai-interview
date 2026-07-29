import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// Inline selector for interview type.
///
/// Displays label on top and a full-width pill segmented control underneath.
class TypeSelector extends StatelessWidget {
  const TypeSelector({
    required this.selectedType,
    required this.onTypeSelected,
    super.key,
  });

  final InterviewType selectedType;
  final ValueChanged<InterviewType> onTypeSelected;

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
                Icons.center_focus_strong_outlined,
                color: VoiceMockColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Text(
                'Interview Focus',
                style: VoiceMockTypography.body.copyWith(
                  color: VoiceMockColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.sm),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: VoiceMockColors.surfaceElevated,
              borderRadius: BorderRadius.circular(VoiceMockRadius.full),
              border: Border.all(color: VoiceMockColors.surfaceBorder),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: InterviewType.values.map((type) {
                final isSelected = type == selectedType;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTypeSelected(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        vertical: VoiceMockSpacing.sm + 2,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? VoiceMockColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          VoiceMockRadius.full,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: VoiceMockColors.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSelected) ...[
                            Icon(
                              type == InterviewType.behavioral
                                  ? Icons.people_outline
                                  : Icons.code,
                              size: 16,
                              color: VoiceMockColors.background,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            type.displayName,
                            style: VoiceMockTypography.small.copyWith(
                              color: isSelected
                                  ? VoiceMockColors.background
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
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
