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
      margin: const EdgeInsets.all(VoiceMockSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(VoiceMockSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: VoiceMockColors.primary,
              ),
              const SizedBox(height: VoiceMockSpacing.md),

              // Completion message
              const Text(
                'Session Complete',
                style: VoiceMockTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: VoiceMockSpacing.sm),

              Text(
                'Great job! You completed all $totalQuestions questions.',
                style: VoiceMockTypography.body,
                textAlign: TextAlign.center,
              ),

              if (sessionSummary != null) ...[
                const SizedBox(height: VoiceMockSpacing.lg),
                _SummarySection(
                  title: 'Overall assessment',
                  child: Text(
                    sessionSummary!.overallAssessment,
                    style: VoiceMockTypography.body,
                  ),
                ),
                const SizedBox(height: VoiceMockSpacing.md),
                _SummarySection(
                  title: 'Strengths',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sessionSummary!.strengths
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: VoiceMockSpacing.sm,
                            ),
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
                                const SizedBox(width: VoiceMockSpacing.sm),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: VoiceMockTypography.body,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: VoiceMockSpacing.md),
                _SummarySection(
                  title: 'Improvements',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sessionSummary!.improvements
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: VoiceMockSpacing.sm,
                            ),
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
                                const SizedBox(width: VoiceMockSpacing.sm),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: VoiceMockTypography.body,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (sessionSummary!.recommendedActions.isNotEmpty) ...[
                  const SizedBox(height: VoiceMockSpacing.md),
                  _SummarySection(
                    title: 'What to Practice Next',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sessionSummary!.recommendedActions
                          .map(
                            (action) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: VoiceMockSpacing.sm,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: VoiceMockColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: VoiceMockSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      action,
                                      style: VoiceMockTypography.body,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: VoiceMockSpacing.md),
                _SummarySection(
                  title: 'Average scores',
                  child: Wrap(
                    spacing: VoiceMockSpacing.sm,
                    runSpacing: VoiceMockSpacing.sm,
                    children: sessionSummary!.averageScores.entries
                        .map(
                          (entry) => Chip(
                            label: Text(
                              '${_formatLabel(entry.key)}: '
                              '${entry.value.toStringAsFixed(1)}',
                              style: VoiceMockTypography.small,
                            ),
                            backgroundColor: VoiceMockColors.background,
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],

              // Last response from coach
              if (lastResponseText != null) ...[
                const SizedBox(height: VoiceMockSpacing.lg),
                Text(
                  'Final feedback:',
                  style: VoiceMockTypography.micro.copyWith(
                    color: VoiceMockColors
                        .textMuted, // Matching TurnCard "Coach says"
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: VoiceMockSpacing.xs),
                Text(
                  lastResponseText!,
                  style: VoiceMockTypography.body,
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: VoiceMockSpacing.xl),

              // Primary action: Back to Home
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onBackToHome,
                  style: FilledButton.styleFrom(
                    backgroundColor: VoiceMockColors.primary,
                    foregroundColor: VoiceMockColors.surface,
                  ),
                  child: const Text('Back to Home'),
                ),
              ),

              const SizedBox(height: VoiceMockSpacing.md),

              // Secondary action: Start New Session
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onStartNew,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VoiceMockColors.primary,
                    side: const BorderSide(color: VoiceMockColors.primary),
                  ),
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
          style: VoiceMockTypography.h3,
        ),
        const SizedBox(height: VoiceMockSpacing.sm),
        child,
      ],
    );
  }
}
