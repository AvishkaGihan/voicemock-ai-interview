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

            // Transcript section
            if (transcript != null) ...[
              const SizedBox(height: 16),
              Text(
                'You said:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transcript!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],

            // Response section
            if (responseText != null) ...[
              const SizedBox(height: 16),
              Text(
                'Coach says:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                responseText!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],

            if (coachingFeedback != null) ...[
              const SizedBox(height: 16),
              Text(
                'Top Tip',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                coachingFeedback!.summaryTip,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...coachingFeedback!.dimensions.map(
                (dimension) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dimension.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${dimension.score}/5',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '— ${dimension.tip}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
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
