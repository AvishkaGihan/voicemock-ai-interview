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
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Question header
            Text(
              'Question $questionNumber of $totalQuestions',
              style: VoiceMockTypography.micro.copyWith(
                color: VoiceMockColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: VoiceMockSpacing.sm),

            // Question text
            Text(
              questionText,
              style: VoiceMockTypography.h3,
            ),

            // Transcript section
            if (transcript != null) ...[
              const SizedBox(height: VoiceMockSpacing.md),
              Text(
                'You said:',
                style: VoiceMockTypography.micro.copyWith(
                  color: VoiceMockColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: VoiceMockSpacing.xs),
              Text(
                transcript!,
                style: VoiceMockTypography.body,
              ),
            ],

            // Response section
            if (responseText != null) ...[
              const SizedBox(height: VoiceMockSpacing.md),
              Text(
                'Coach says:',
                style: VoiceMockTypography.micro.copyWith(
                  color: VoiceMockColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: VoiceMockSpacing.xs),
              Text(
                responseText!,
                style: VoiceMockTypography.body,
              ),
            ],

            if (coachingFeedback != null) ...[
              const SizedBox(height: VoiceMockSpacing.md),
              Text(
                'Top Tip',
                style: VoiceMockTypography.micro.copyWith(
                  color: VoiceMockColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: VoiceMockSpacing.xs),
              Text(
                coachingFeedback!.summaryTip,
                style: VoiceMockTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: VoiceMockSpacing.sm),
              ...coachingFeedback!.dimensions.map(
                (dimension) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dimension.label,
                        style: VoiceMockTypography.small.copyWith(
                          color: VoiceMockColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: VoiceMockColors.secondary,
                          borderRadius: BorderRadius.circular(
                            VoiceMockRadius.lg,
                          ),
                        ),
                        child: Text(
                          '${dimension.score}/5',
                          style: VoiceMockTypography.micro.copyWith(
                            color: VoiceMockColors.surface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '— ${dimension.tip}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
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

            if (onReplay != null) ...[
              const SizedBox(height: 16),
              Semantics(
                label: 'Replay last response',
                button: true,
                child: OutlinedButton.icon(
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay),
                  label: const Text('Replay response'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
