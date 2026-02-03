import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// Segmented control for selecting interview type.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interview Type',
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
              children: InterviewType.values.map((type) {
                final isSelected = type == selectedType;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTypeSelected(type),
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
                        type.displayName,
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
