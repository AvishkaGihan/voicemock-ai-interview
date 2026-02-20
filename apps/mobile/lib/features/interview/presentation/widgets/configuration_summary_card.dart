import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// Card displaying current interview configuration summary.
///
/// Shows all selected options clearly before starting the interview.
class ConfigurationSummaryCard extends StatelessWidget {
  const ConfigurationSummaryCard({
    required this.config,
    super.key,
  });

  final InterviewConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      decoration: BoxDecoration(
        color: VoiceMockColors.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VoiceMockColors.surface,
            VoiceMockColors.primaryContainer.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
        border: Border.all(
          color: VoiceMockColors.primaryContainer,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: VoiceMockColors.accentGlow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(VoiceMockSpacing.xs),
                decoration: const BoxDecoration(
                  color: VoiceMockColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: VoiceMockColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Text(
                'Interview Summary',
                style: VoiceMockTypography.h3.copyWith(
                  color: VoiceMockColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.md),
          _SummaryRow(
            icon: Icons.work_outline,
            label: 'Role',
            value: config.role.displayName,
          ),
          const SizedBox(height: VoiceMockSpacing.sm),
          _SummaryRow(
            icon: Icons.chat_bubble_outline,
            label: 'Type',
            value: config.type.displayName,
          ),
          const SizedBox(height: VoiceMockSpacing.sm),
          _SummaryRow(
            icon: Icons.trending_up,
            label: 'Difficulty',
            value: config.difficulty.displayName,
          ),
          const SizedBox(height: VoiceMockSpacing.sm),
          _SummaryRow(
            icon: Icons.format_list_numbered,
            label: 'Questions',
            value: '${config.questionCount} questions',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: VoiceMockColors.textMuted,
        ),
        const SizedBox(width: VoiceMockSpacing.sm),
        Text(
          '$label:',
          style: VoiceMockTypography.small,
        ),
        const SizedBox(width: VoiceMockSpacing.sm),
        Text(
          value,
          style: VoiceMockTypography.body.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
