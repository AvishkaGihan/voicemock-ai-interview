import 'package:flutter/material.dart';

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
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Question header (same pattern as TurnCard)
            Text(
              'Question $questionNumber of $totalQuestions',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // Question text
            Text(
              questionText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Transcript section label
            Text(
              'What we heard:',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // Transcript text in distinct container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transcript,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

            // Low-confidence hint (conditional, neutral styling)
            if (isLowConfidence) ...[
              const SizedBox(height: 8),
              Text(
                "If this isn't right, re-record.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons (Re-record secondary, Accept primary)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReRecord,
                    child: const Text('Re-record'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
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
