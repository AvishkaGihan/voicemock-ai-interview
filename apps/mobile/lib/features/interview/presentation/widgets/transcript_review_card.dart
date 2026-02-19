import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Card displaying transcript for user review.
///
/// Shows the STT transcript with "Accept & Continue" and "Re-record" actions.
/// Includes optional low-confidence hint for uncertain transcripts.
class TranscriptReviewCard extends StatelessWidget {
  const TranscriptReviewCard({
    required this.questionNumber,
    required this.totalQuestions,
    required this.questionText,
    required this.transcript,
    required this.onAccept,
    required this.onReRecord,
    this.isLowConfidence = false,
    super.key,
  });

  final int questionNumber;
  final int totalQuestions;
  final String questionText;
  final String transcript;
  final VoidCallback onAccept;
  final VoidCallback onReRecord;
  final bool isLowConfidence;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(VoiceMockSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(VoiceMockSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Question header (same pattern as TurnCard)
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
            const SizedBox(height: VoiceMockSpacing.md),

            // Transcript section label
            Text(
              'What we heard:',
              style: VoiceMockTypography.micro.copyWith(
                color: VoiceMockColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: VoiceMockSpacing.sm),

            // Transcript text in distinct container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(VoiceMockSpacing.sm),
              decoration: BoxDecoration(
                color: VoiceMockColors.background,
                borderRadius: BorderRadius.circular(VoiceMockRadius.md),
              ),
              child: Text(
                transcript,
                style: VoiceMockTypography.body,
              ),
            ),

            // Low-confidence hint (conditional, neutral styling)
            if (isLowConfidence) ...[
              const SizedBox(height: VoiceMockSpacing.sm),
              Text(
                "If this isn't right, re-record.",
                style: VoiceMockTypography.small.copyWith(
                  color: VoiceMockColors.textMuted,
                ),
              ),
            ],

            const SizedBox(height: VoiceMockSpacing.md),

            // Action buttons (Re-record secondary, Accept primary)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReRecord,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VoiceMockColors.textMuted,
                      side: const BorderSide(color: VoiceMockColors.textMuted),
                    ),
                    child: const Text('Re-record'),
                  ),
                ),
                const SizedBox(width: VoiceMockSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: VoiceMockColors.primary,
                      foregroundColor: VoiceMockColors.surface,
                    ),
                    child: const Text('Accept & Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
