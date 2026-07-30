import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// AI coach recommendation banner displayed at the bottom of the summary.
///
/// Shows a gradient-accented card with an AI icon and recommendation text
/// summarizing key next steps drawn from the session's recommended actions.
class SummaryCoachCard extends StatelessWidget {
  const SummaryCoachCard({
    required this.recommendationText,
    super.key,
  });

  /// The recommendation text to display.
  final String recommendationText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: VoiceMockColors.surfaceCard,
        borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
        border: Border.all(color: VoiceMockColors.surfaceBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: VoiceMockColors.primary,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.all(VoiceMockSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI coach icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      VoiceMockColors.primary.withValues(alpha: 0.15),
                      VoiceMockColors.secondary.withValues(alpha: 0.15),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: VoiceMockColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: VoiceMockColors.primary,
                ),
              ),
              const SizedBox(width: VoiceMockSpacing.md),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI COACH RECOMMENDATION',
                      style: VoiceMockTypography.sectionLabel.copyWith(
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: VoiceMockSpacing.sm),
                    Text(
                      recommendationText,
                      style: VoiceMockTypography.small.copyWith(
                        color: VoiceMockColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: VoiceMockSpacing.sm),

              // Trailing chevron
              Padding(
                padding: const EdgeInsets.only(top: VoiceMockSpacing.sm),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: VoiceMockColors.textMuted.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
