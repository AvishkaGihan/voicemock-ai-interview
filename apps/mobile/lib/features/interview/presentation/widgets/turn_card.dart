import 'package:flutter/material.dart';
import 'package:voicemock/core/models/models.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Card displaying the current interview turn information.
///
/// Shows question, user transcript, and coach response
/// with clear visual hierarchy.
class TurnCard extends StatelessWidget {
  const TurnCard({
    required this.questionNumber,
    required this.totalQuestions,
    required this.questionText,
    super.key,
    this.transcript,
    this.responseText,
    this.coachingFeedback,
    this.onReplay,
  });

  final int questionNumber;
  final int totalQuestions;
  final String questionText;
  final String? transcript;
  final String? responseText;
  final CoachingFeedback? coachingFeedback;
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VoiceMockColors.surface,
        borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
        boxShadow: [
          BoxShadow(
            color: VoiceMockColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: VoiceMockColors.textPrimary.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFAFBFF), Colors.white],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Bar & Question Count
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(VoiceMockRadius.full),
                    child: LinearProgressIndicator(
                      value: questionNumber / totalQuestions,
                      backgroundColor: VoiceMockColors.primary.withValues(
                        alpha: 0.1,
                      ),
                      color: VoiceMockColors.primary,
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: VoiceMockSpacing.sm),
                Text(
                  '$questionNumber/$totalQuestions',
                  style: VoiceMockTypography.micro.copyWith(
                    color: VoiceMockColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VoiceMockSpacing.lg),

            // Question text
            Text(
              questionText,
              style: VoiceMockTypography.h3,
            ),

            // Transcript section
            if (transcript != null) ...[
              const SizedBox(height: VoiceMockSpacing.lg),
              const _SectionPill(
                label: 'You said',
                color: VoiceMockColors.secondary,
              ),
              const SizedBox(height: VoiceMockSpacing.sm),
              Text(
                transcript!,
                style: VoiceMockTypography.body,
              ),
            ],

            // Response section
            if (responseText != null) ...[
              const SizedBox(height: VoiceMockSpacing.lg),
              const _SectionPill(
                label: 'Coach says',
                color: VoiceMockColors.textMuted,
              ),
              const SizedBox(height: VoiceMockSpacing.sm),
              Text(
                responseText!,
                style: VoiceMockTypography.body,
              ),
            ],

            if (coachingFeedback != null) ...[
              const SizedBox(height: VoiceMockSpacing.lg),
              const _SectionPill(
                label: 'Top Tip',
                color: VoiceMockColors.warning,
              ),
              const SizedBox(height: VoiceMockSpacing.sm),
              Text(
                coachingFeedback!.summaryTip,
                style: VoiceMockTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: VoiceMockSpacing.md),
              ...coachingFeedback!.dimensions.map(
                (dimension) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8, top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: VoiceMockColors.secondary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            VoiceMockRadius.sm,
                          ),
                        ),
                        child: Text(
                          '${dimension.score}/5',
                          style: VoiceMockTypography.micro.copyWith(
                            color: VoiceMockColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dimension.label,
                              style: VoiceMockTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              dimension.tip,
                              style: VoiceMockTypography.small,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (onReplay != null) ...[
              const SizedBox(height: 24),
              Semantics(
                label: 'Replay last response',
                button: true,
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onReplay,
                    icon: const Icon(Icons.replay),
                    label: const Text('Replay response'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: VoiceMockColors.textMuted),
                      foregroundColor: VoiceMockColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionPill extends StatelessWidget {
  const _SectionPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VoiceMockSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(VoiceMockRadius.full),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: VoiceMockTypography.micro.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          fontSize: 10,
        ),
      ),
    );
  }
}
