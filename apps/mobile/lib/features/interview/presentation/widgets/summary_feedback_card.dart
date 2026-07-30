import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Compact glassmorphic card for displaying a single strength or improvement.
///
/// Used in horizontal scroll rows to show categorized feedback items
/// with an icon, title, and description text.
class SummaryFeedbackCard extends StatelessWidget {
  const SummaryFeedbackCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    super.key,
  });

  /// Icon displayed at the top of the card.
  final IconData icon;

  /// Short title (2-3 words).
  final String title;

  /// Longer description text.
  final String description;

  /// Accent color for the icon background and border tint.
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      decoration: BoxDecoration(
        color: VoiceMockColors.surfaceCard,
        borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon in tinted circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: accentColor,
            ),
          ),
          const SizedBox(height: VoiceMockSpacing.sm),

          // Title
          Text(
            title,
            style: VoiceMockTypography.h4.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: VoiceMockSpacing.xs),

          // Description
          Text(
            description,
            style: VoiceMockTypography.micro.copyWith(
              color: VoiceMockColors.textMuted,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
