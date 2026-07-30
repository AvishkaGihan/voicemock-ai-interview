import 'package:flutter/material.dart';
import 'package:voicemock/core/models/models.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Card displaying session complete summary.
///
/// Shows completion message, summary sections, and navigation actions.
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
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        // ── Completion Header ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(VoiceMockSpacing.lg),
          decoration: VoiceMockColors.cardDecorationElevated(),
          child: Column(
            children: [
              // Check icon
              Container(
                padding: const EdgeInsets.all(VoiceMockSpacing.md),
                decoration: BoxDecoration(
                  color: VoiceMockColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: VoiceMockColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: VoiceMockColors.primary,
                ),
              ),
              const SizedBox(height: VoiceMockSpacing.md),
              Text(
                'Interview Complete',
                style: VoiceMockTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: VoiceMockSpacing.sm),
              Text(
                'Great job! You completed all $totalQuestions questions.',
                style: VoiceMockTypography.small,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        if (sessionSummary != null) ...[
          const SizedBox(height: VoiceMockSpacing.md),

          // ── Overall Assessment ──
          _SummarySection(
            title: 'OVERALL ASSESSMENT',
            child: Text(
              sessionSummary!.overallAssessment,
              style: VoiceMockTypography.body,
            ),
          ),

          const SizedBox(height: VoiceMockSpacing.md),

          // ── Strengths ──
          _SummarySection(
            title: 'YOUR STRENGTHS',
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

          const SizedBox(height: VoiceMockSpacing.md),

          // ── Improvements ──
          _SummarySection(
            title: 'AREAS TO IMPROVE',
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
            const SizedBox(height: VoiceMockSpacing.md),

            // ── Practice Next ──
            _SummarySection(
              title: 'PRACTICE NEXT',
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

        const SizedBox(height: VoiceMockSpacing.lg),

        // ── Actions — gradient CTA ──
        Container(
          width: double.infinity,
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
              onTap: onStartNew,
              borderRadius: BorderRadius.circular(VoiceMockRadius.full),
              child: Container(
                height: 52,
                alignment: Alignment.center,
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
                    const SizedBox(width: VoiceMockSpacing.sm),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: VoiceMockColors.background,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: VoiceMockSpacing.sm),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: onBackToHome,
            style: OutlinedButton.styleFrom(
              foregroundColor: VoiceMockColors.textMuted,
              side: const BorderSide(color: VoiceMockColors.surfaceBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VoiceMockRadius.full),
              ),
            ),
            child: const Text('Back to Home'),
          ),
        ),
      ]),
    );
  }

  Widget _buildListItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VoiceMockSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: VoiceMockSpacing.sm),
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
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      decoration: VoiceMockColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '✦',
                style: VoiceMockTypography.sectionLabel.copyWith(fontSize: 14),
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Text(
                title,
                style: VoiceMockTypography.sectionLabel,
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.md),
          child,
        ],
      ),
    );
  }
}
