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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Question section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(VoiceMockSpacing.md),
          decoration: VoiceMockColors.cardDecorationElevated(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '✦',
                    style: VoiceMockTypography.sectionLabel
                        .copyWith(fontSize: 14),
                  ),
                  const SizedBox(width: VoiceMockSpacing.sm),
                  Text(
                    'AI INTERVIEWER',
                    style: VoiceMockTypography.sectionLabel,
                  ),
                ],
              ),
              const SizedBox(height: VoiceMockSpacing.sm),
              Text(questionText, style: VoiceMockTypography.h3),
            ],
          ),
        ),

        const SizedBox(height: VoiceMockSpacing.md),

        // Transcript section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(VoiceMockSpacing.md),
          decoration: VoiceMockColors.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '✦',
                    style: VoiceMockTypography.sectionLabel
                        .copyWith(fontSize: 14),
                  ),
                  const SizedBox(width: VoiceMockSpacing.sm),
                  Text(
                    'WHAT WE HEARD',
                    style: VoiceMockTypography.sectionLabel.copyWith(
                      color: VoiceMockColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VoiceMockSpacing.md),

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

              // Low-confidence hint
              if (isLowConfidence) ...[
                const SizedBox(height: VoiceMockSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: VoiceMockColors.warning.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: VoiceMockSpacing.xs),
                    Text(
                      "If this isn't right, re-record.",
                      style: VoiceMockTypography.small.copyWith(
                        color: VoiceMockColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: VoiceMockSpacing.lg),

        // Primary Action (Accept)
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VoiceMockRadius.full),
            gradient: const LinearGradient(
              colors: [
                VoiceMockColors.gradientStart,
                VoiceMockColors.gradientEnd,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: VoiceMockColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAccept,
              borderRadius: BorderRadius.circular(VoiceMockRadius.full),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                child: Text(
                  'Accept & Continue',
                  style: VoiceMockTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: VoiceMockColors.background,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: VoiceMockSpacing.sm),

        // Secondary Action (Re-record)
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: onReRecord,
            style: OutlinedButton.styleFrom(
              foregroundColor: VoiceMockColors.textMuted,
              side: const BorderSide(color: VoiceMockColors.surfaceBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VoiceMockRadius.full),
              ),
            ),
            child: const Text('Re-record'),
          ),
        ),
      ],
    );
  }
}
