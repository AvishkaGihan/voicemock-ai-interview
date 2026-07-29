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
    return Container(
      margin: const EdgeInsets.all(VoiceMockSpacing.md),
      decoration: BoxDecoration(
        color: VoiceMockColors.surface,
        borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
        border: Border.all(color: VoiceMockColors.surfaceBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      VoiceMockColors.primary.withValues(alpha: 0.15),
                      VoiceMockColors.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: VoiceMockColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              VoiceMockColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 48,
                        color: VoiceMockColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Interview Complete',
                      style: VoiceMockTypography.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Great job! You completed all $totalQuestions questions.',
                      style: VoiceMockTypography.small,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (sessionSummary != null) ...[
                      _SummarySection(
                        title: 'Overall Assessment',
                        child: Text(
                          sessionSummary!.overallAssessment,
                          style: VoiceMockTypography.body,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SummarySection(
                        title: 'Strengths',
                        child: Column(
                          children: sessionSummary!.strengths
                              .map(
                                (item) => _buildListItem(
                                  item,
                                  Icons.check_circle,
                                  VoiceMockColors.primary,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SummarySection(
                        title: 'Improvements',
                        child: Column(
                          children: sessionSummary!.improvements
                              .map(
                                (item) => _buildListItem(
                                  item,
                                  Icons.trending_up,
                                  VoiceMockColors.warning,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      if (sessionSummary!.recommendedActions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SummarySection(
                          title: 'Practice Next',
                          child: Column(
                            children: sessionSummary!.recommendedActions
                                .map(
                                  (item) => _buildListItem(
                                    item,
                                    Icons.arrow_forward,
                                    VoiceMockColors.secondary,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 32),

                    // Actions — gradient CTA
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          VoiceMockRadius.full,
                        ),
                        gradient: const LinearGradient(
                          colors: [
                            VoiceMockColors.gradientStart,
                            VoiceMockColors.gradientEnd,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: VoiceMockColors.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onStartNew,
                          borderRadius: BorderRadius.circular(
                            VoiceMockRadius.full,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Practice Again',
                                  style: VoiceMockTypography.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: VoiceMockColors.background,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onBackToHome,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: VoiceMockColors.textMuted,
                          side: const BorderSide(
                            color: VoiceMockColors.surfaceBorder,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              VoiceMockRadius.full,
                            ),
                          ),
                        ),
                        child: const Text('Review Questions'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: VoiceMockTypography.body),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VoiceMockColors.surfaceElevated,
        borderRadius: BorderRadius.circular(VoiceMockRadius.md),
        border: Border.all(
          color: VoiceMockColors.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: VoiceMockTypography.sectionLabel,
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
