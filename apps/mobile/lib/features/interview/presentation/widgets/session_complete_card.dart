import 'package:flutter/material.dart';
import 'package:voicemock/core/models/models.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

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
    this.sessionSummary,
  });

  final int totalQuestions;
  final String lastTranscript;
  final String? lastResponseText;
  final SessionSummary? sessionSummary;
  final VoidCallback onBackToHome;
  final VoidCallback onStartNew;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
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

              if (sessionSummary != null) ...[
                const SizedBox(height: 24),
                _SummarySection(
                  title: 'Overall assessment',
                  child: Text(
                    sessionSummary!.overallAssessment,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 16),
                _SummarySection(
                  title: 'Strengths',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sessionSummary!.strengths
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color: VoiceMockColors.success,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SummarySection(
                  title: 'Improvements',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sessionSummary!.improvements
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.trending_up,
                                    size: 16,
                                    color: VoiceMockColors.secondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SummarySection(
                  title: 'Average scores',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sessionSummary!.averageScores.entries
                        .map(
                          (entry) => Chip(
                            label: Text(
                              '${_formatLabel(entry.key)}: '
                              '${entry.value.toStringAsFixed(1)}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],

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
      ),
    );
  }

  String _formatLabel(String value) {
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
