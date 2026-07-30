import 'package:flutter/material.dart';
import 'package:voicemock/core/models/models.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Grid-based coaching feedback display with score cards and tip bullets.
///
/// Inspired by the reference design's evaluation grid — shows dimension
/// scores in a horizontal scrollable row and feedback tips as bullet items.
class CoachingScoreGrid extends StatelessWidget {
  const CoachingScoreGrid({
    required this.feedback,
    super.key,
  });

  /// The structured coaching feedback to display.
  final CoachingFeedback feedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      decoration: VoiceMockColors.cardDecorationElevated(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── AI EVALUATION header ──
          Row(
            children: [
              Text(
                '✦',
                style: VoiceMockTypography.sectionLabel.copyWith(fontSize: 14),
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Text(
                'AI EVALUATION',
                style: VoiceMockTypography.sectionLabel,
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.md),

          // ── Score cards row ──
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: feedback.dimensions.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: VoiceMockSpacing.sm),
              itemBuilder: (context, index) {
                final dimension = feedback.dimensions[index];
                return _DimensionScoreCard(dimension: dimension);
              },
            ),
          ),

          const SizedBox(height: VoiceMockSpacing.md),

          // ── Summary tip ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(VoiceMockSpacing.sm),
            decoration: BoxDecoration(
              color: VoiceMockColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(VoiceMockRadius.md),
              border: Border.all(
                color: VoiceMockColors.warning.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: VoiceMockColors.warning.withValues(alpha: 0.8),
                ),
                const SizedBox(width: VoiceMockSpacing.sm),
                Expanded(
                  child: Text(
                    feedback.summaryTip,
                    style: VoiceMockTypography.small.copyWith(
                      color: VoiceMockColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: VoiceMockSpacing.md),

          // ── AI FEEDBACK bullets ──
          Row(
            children: [
              Text(
                '✦',
                style: VoiceMockTypography.sectionLabel.copyWith(fontSize: 14),
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Text(
                'AI FEEDBACK',
                style: VoiceMockTypography.sectionLabel,
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.sm),

          // Dimension tips as bullet items
          ...feedback.dimensions.map(
            (dimension) => Padding(
              padding: const EdgeInsets.only(bottom: VoiceMockSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: VoiceMockColors.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: VoiceMockSpacing.sm),
                  Expanded(
                    child: Text(
                      dimension.tip,
                      style: VoiceMockTypography.small.copyWith(
                        color: VoiceMockColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual dimension score card shown in the horizontal score row.
class _DimensionScoreCard extends StatelessWidget {
  const _DimensionScoreCard({required this.dimension});

  final CoachingDimension dimension;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(
        vertical: VoiceMockSpacing.sm,
        horizontal: VoiceMockSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: VoiceMockColors.surfaceElevated,
        borderRadius: BorderRadius.circular(VoiceMockRadius.md),
        border: Border.all(
          color: VoiceMockColors.surfaceBorder,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Icon(
            _getDimensionIcon(dimension.label),
            size: 18,
            color: VoiceMockColors.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: VoiceMockSpacing.xs),

          // Dimension label
          Text(
            dimension.label,
            style: VoiceMockTypography.micro.copyWith(
              color: VoiceMockColors.textMuted,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${dimension.score}',
                style: VoiceMockTypography.h3.copyWith(
                  color: VoiceMockColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '/5',
                style: VoiceMockTypography.micro.copyWith(
                  color: VoiceMockColors.textMuted,
                ),
              ),
            ],
          ),

          // Qualitative label
          Text(
            _getQualitativeLabel(dimension.score),
            style: VoiceMockTypography.micro.copyWith(
              color: _getScoreColor(dimension.score),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDimensionIcon(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('clarity')) return Icons.visibility_outlined;
    if (normalized.contains('structure')) return Icons.view_list_outlined;
    if (normalized.contains('relevance')) return Icons.center_focus_strong;
    if (normalized.contains('confidence')) return Icons.trending_up;
    if (normalized.contains('pace') || normalized.contains('conciseness')) {
      return Icons.speed;
    }
    if (normalized.contains('depth')) return Icons.layers_outlined;
    return Icons.star_outline;
  }

  String _getQualitativeLabel(int score) {
    if (score >= 5) return 'Excellent';
    if (score >= 4) return 'Great';
    if (score >= 3) return 'Good';
    if (score >= 2) return 'Fair';
    return 'Needs Work';
  }

  Color _getScoreColor(int score) {
    if (score >= 4) return VoiceMockColors.primary;
    if (score >= 3) return VoiceMockColors.secondary;
    return VoiceMockColors.warning;
  }
}
