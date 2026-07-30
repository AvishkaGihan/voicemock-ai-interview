import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Horizontal row of 3 stat capsules: Completed, Session Time, Performance.
///
/// Displayed inside a single glassmorphic card in the summary screen.
class SummaryStatStrip extends StatelessWidget {
  const SummaryStatStrip({
    required this.completedCount,
    required this.totalCount,
    required this.sessionDuration,
    required this.averageScore,
    super.key,
  });

  final int completedCount;
  final int totalCount;
  final Duration sessionDuration;
  final double averageScore;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    if (minutes < 1) return '<1 min';
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: VoiceMockSpacing.sm,
        vertical: VoiceMockSpacing.md,
      ),
      decoration: VoiceMockColors.cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _StatCapsule(
              icon: Icons.description_outlined,
              value: '$completedCount / $totalCount',
              label: 'Completed',
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _StatCapsule(
              icon: Icons.access_time_rounded,
              value: _formatDuration(sessionDuration),
              label: 'Session time',
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _StatCapsule(
              icon: Icons.star_outline_rounded,
              value: '${averageScore.toStringAsFixed(1)} / 5',
              label: 'Performance',
              isHighlighted: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: VoiceMockColors.surfaceBorder,
    );
  }
}

class _StatCapsule extends StatelessWidget {
  const _StatCapsule({
    required this.icon,
    required this.value,
    required this.label,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final color = isHighlighted
        ? VoiceMockColors.primary
        : VoiceMockColors.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: VoiceMockSpacing.xs),
        Text(
          value,
          style: VoiceMockTypography.h4.copyWith(
            color: isHighlighted
                ? VoiceMockColors.primary
                : VoiceMockColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: VoiceMockTypography.micro.copyWith(
            color: VoiceMockColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
