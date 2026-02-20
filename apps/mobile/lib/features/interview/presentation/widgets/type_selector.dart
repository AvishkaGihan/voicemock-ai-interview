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
        Text(
          'Interview Type',
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
