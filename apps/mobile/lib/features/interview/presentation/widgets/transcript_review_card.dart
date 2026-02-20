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
    return Container(
      margin: const EdgeInsets.all(VoiceMockSpacing.md),
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      decoration: BoxDecoration(
        color: VoiceMockColors.surface,
        borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
        border: Border.all(
          color: VoiceMockColors.primaryContainer,
        ),
        boxShadow: const [
          BoxShadow(
            color: VoiceMockColors.accentGlow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Make children full width
        mainAxisSize: MainAxisSize.min,
        children: [
          // Question header (same pattern as TurnCard)
          Text(
            'Question $questionNumber of $totalQuestions'.toUpperCase(),
            style: VoiceMockTypography.label.copyWith(
              color: VoiceMockColors.primary,
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
            'What we heard:'.toUpperCase(),
            style: VoiceMockTypography.label.copyWith(
              color: VoiceMockColors.secondary,
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

          const SizedBox(height: VoiceMockSpacing.lg),

          // Primary Action (Accept)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(VoiceMockRadius.md),
              boxShadow: [
                BoxShadow(
                  color: VoiceMockColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FilledButton(
              onPressed: onAccept,
              style: FilledButton.styleFrom(
                backgroundColor: VoiceMockColors.primary,
                foregroundColor: VoiceMockColors.surface,
              ),
              child: const Text('Accept & Continue'),
            ),
          ),
          const SizedBox(height: VoiceMockSpacing.sm),

          // Secondary Action (Re-record)
          TextButton(
            onPressed: onReRecord,
            style: TextButton.styleFrom(
              foregroundColor: VoiceMockColors.textMuted,
              textStyle: VoiceMockTypography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Re-record'),
          ),
        ],
      ),
    );
  }
}
