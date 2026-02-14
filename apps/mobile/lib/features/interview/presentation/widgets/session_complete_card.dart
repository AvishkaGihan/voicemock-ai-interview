import 'package:flutter/material.dart';

/// Card displaying session complete summary.
///
/// Shows completion message and navigation actions.
class SessionCompleteCard extends StatelessWidget {
  const SessionCompleteCard({
    required this.totalQuestions,
    required this.lastTranscript,
    required this.onBackToHome,
    required this.onStartNew,
    super.key,
    this.lastResponseText,
  });

  final int totalQuestions;
  final String lastTranscript;
  final String? lastResponseText;
  final VoidCallback onBackToHome;
  final VoidCallback onStartNew;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),

            // Completion message
            Text(
              'Session Complete',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'Great job! You completed all $totalQuestions questions.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),

            // Last response from coach
            if (lastResponseText != null) ...[
              const SizedBox(height: 24),
              Text(
                'Final feedback:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lastResponseText!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),

            // Primary action: Back to Home
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onBackToHome,
                child: const Text('Back to Home'),
              ),
            ),

            const SizedBox(height: 12),

            // Secondary action: Start New Session
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onStartNew,
                child: const Text('Start New Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
