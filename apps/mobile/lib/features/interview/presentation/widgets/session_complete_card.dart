import 'package:flutter/material.dart';
import 'package:voicemock/core/models/models.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/presentation/widgets/summary_coach_card.dart';
import 'package:voicemock/features/interview/presentation/widgets/summary_feedback_card.dart';
import 'package:voicemock/features/interview/presentation/widgets/summary_score_gauge.dart';
import 'package:voicemock/features/interview/presentation/widgets/summary_stat_strip.dart';

/// Card displaying session complete summary.
///
/// Shows a rich, visually engaging summary page section with hero zone,
/// stats strip, score gauge, categorized feedback, coach recommendation,
/// and navigation actions.
class SessionCompleteCard extends StatelessWidget {
  const SessionCompleteCard({
    required this.totalQuestions,
    required this.lastTranscript,
    required this.onBackToHome,
    required this.onStartNew,
    super.key,
    this.lastResponseText,
    this.sessionSummary,
    this.sessionStartTime,
  });

  final int totalQuestions;
  final String lastTranscript;
  final String? lastResponseText;
  final SessionSummary? sessionSummary;
  final DateTime? sessionStartTime;
  final VoidCallback onBackToHome;
  final VoidCallback onStartNew;

  double _computeAverageScore() {
    if (sessionSummary == null || sessionSummary!.averageScores.isEmpty) {
      return 0;
    }
    final scores = sessionSummary!.averageScores.values;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  String _getQualitativeLabel(double score) {
    if (score >= 4.5) return 'Excellent Performance';
    if (score >= 3.5) return 'Strong Performance';
    if (score >= 2.5) return 'Good Performance';
    if (score >= 1.5) return 'Fair Performance';
    return 'Needs Improvement';
  }

  Duration _getSessionDuration() {
    if (sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(sessionStartTime!);
  }

  @override
  Widget build(BuildContext context) {
    final avgScore = _computeAverageScore();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 1. Completion Hero Zone ──
          _buildHeroZone(),

          const SizedBox(height: VoiceMockSpacing.md),

          // ── 2. Stats Summary Strip ──
          SummaryStatStrip(
            completedCount: totalQuestions,
            totalCount: totalQuestions,
            sessionDuration: _getSessionDuration(),
            averageScore: avgScore,
          ),

          if (sessionSummary != null) ...[
            const SizedBox(height: VoiceMockSpacing.md),

            // ── 3. Overall Assessment Card ──
            _buildOverallAssessment(avgScore),

            const SizedBox(height: VoiceMockSpacing.md),

            // ── 4. Strengths Section ──
            if (sessionSummary!.strengths.isNotEmpty)
              _buildFeedbackSection(
                title: 'YOUR STRENGTHS',
                subtitle: 'What you did well',
                items: sessionSummary!.strengths,
                accentColor: VoiceMockColors.primary,
                defaultIcon: Icons.check_circle_outline,
              ),

            if (sessionSummary!.strengths.isNotEmpty)
              const SizedBox(height: VoiceMockSpacing.md),

            // ── 5. Areas to Improve Section ──
            if (sessionSummary!.improvements.isNotEmpty)
              _buildFeedbackSection(
                title: 'AREAS TO IMPROVE',
                subtitle: 'Where you can become stronger',
                items: sessionSummary!.improvements,
                accentColor: VoiceMockColors.warning,
                defaultIcon: Icons.trending_up_rounded,
              ),

            if (sessionSummary!.improvements.isNotEmpty)
              const SizedBox(height: VoiceMockSpacing.md),

            // ── 6. AI Coach Recommendation ──
            if (sessionSummary!.recommendedActions.isNotEmpty)
              SummaryCoachCard(
                recommendationText: sessionSummary!.recommendedActions.join(
                  ' ',
                ),
              ),

            if (sessionSummary!.recommendedActions.isNotEmpty)
              const SizedBox(height: VoiceMockSpacing.md),
          ],

          const SizedBox(height: VoiceMockSpacing.sm),

          // ── 7. Action Buttons ──
          _buildActions(),

          // ── 8. Footer ──
          const SizedBox(height: VoiceMockSpacing.md),
          _buildFooter(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Hero Zone
  // ─────────────────────────────────────────────────────────
  Widget _buildHeroZone() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoiceMockSpacing.lg),
      decoration: VoiceMockColors.cardDecorationElevated(),
      child: Column(
        children: [
          // Animated glow ring check icon
          Container(
            padding: const EdgeInsets.all(VoiceMockSpacing.md),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VoiceMockColors.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: VoiceMockColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: VoiceMockColors.primary.withValues(alpha: 0.15),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(VoiceMockSpacing.sm),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VoiceMockColors.primary.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: VoiceMockColors.primary,
              ),
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
            "You've completed all $totalQuestions questions.\n"
            "Great work. Here's how you performed and what you can "
            'improve next.',
            style: VoiceMockTypography.small,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Overall Assessment
  // ─────────────────────────────────────────────────────────
  Widget _buildOverallAssessment(double avgScore) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      decoration: VoiceMockColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Text(
                '✦',
                style: VoiceMockTypography.sectionLabel.copyWith(fontSize: 14),
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Text(
                'OVERALL ASSESSMENT',
                style: VoiceMockTypography.sectionLabel,
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.lg),

          // Score gauge + qualitative label
          Row(
            children: [
              SummaryScoreGauge(score: avgScore),
              const SizedBox(width: VoiceMockSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getQualitativeLabel(avgScore),
                      style: VoiceMockTypography.scoreLabel,
                    ),
                    const SizedBox(height: VoiceMockSpacing.sm),
                    Text(
                      sessionSummary!.overallAssessment,
                      style: VoiceMockTypography.small.copyWith(
                        color: VoiceMockColors.textMuted,
                        height: 1.5,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Feedback Section (Strengths / Improvements)
  // ─────────────────────────────────────────────────────────
  Widget _buildFeedbackSection({
    required String title,
    required String subtitle,
    required List<String> items,
    required Color accentColor,
    required IconData defaultIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: VoiceMockSpacing.xs),
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
                  Text(title, style: VoiceMockTypography.sectionLabel),
                ],
              ),
              const SizedBox(height: VoiceMockSpacing.xs),
              Text(subtitle, style: VoiceMockTypography.micro),
            ],
          ),
        ),
        const SizedBox(height: VoiceMockSpacing.md),

        // Horizontal scrollable card row
        SizedBox(
          height: 155,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: VoiceMockSpacing.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              final parts = _splitFeedbackItem(item);
              return SummaryFeedbackCard(
                icon: _getFeedbackIcon(parts.title, defaultIcon),
                title: parts.title,
                description: parts.description,
                accentColor: accentColor,
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Action Buttons
  // ─────────────────────────────────────────────────────────
  Widget _buildActions() {
    return Column(
      children: [
        // Primary CTA — Practice Again
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

        // Secondary — Back to Home
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
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Footer
  // ─────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.bookmark_outline_rounded,
          size: 14,
          color: VoiceMockColors.textMuted.withValues(alpha: 0.6),
        ),
        const SizedBox(width: VoiceMockSpacing.xs),
        Text(
          'Saved to your history',
          style: VoiceMockTypography.micro.copyWith(
            color: VoiceMockColors.textMuted.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: VoiceMockSpacing.sm),
        Text(
          '|',
          style: VoiceMockTypography.micro.copyWith(
            color: VoiceMockColors.textMuted.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: VoiceMockSpacing.sm),
        Text(
          _formatTimestamp(),
          style: VoiceMockTypography.micro.copyWith(
            color: VoiceMockColors.textMuted.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    return 'Today • ${hour == 0 ? 12 : hour}:$minute $period';
  }

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────

  /// Split a feedback string into a short title and description.
  ///
  /// If the text is short, uses it as both. If longer, extracts the first
  /// 2-3 words as a title.
  ({String title, String description}) _splitFeedbackItem(String text) {
    // Try to split on colon, dash, or period for a natural title
    for (final separator in [':', ' – ', ' - ']) {
      final idx = text.indexOf(separator);
      if (idx > 0 && idx < 30) {
        return (
          title: text.substring(0, idx).trim(),
          description: text.substring(idx + separator.length).trim(),
        );
      }
    }

    // Fallback: use first 2-3 words as title
    final words = text.split(' ');
    if (words.length <= 3) {
      return (title: text, description: text);
    }
    final titleWords = words.take(3).join(' ');
    return (title: titleWords, description: text);
  }

  IconData _getFeedbackIcon(String title, IconData defaultIcon) {
    final lower = title.toLowerCase();
    if (lower.contains('relevance')) return Icons.center_focus_strong;
    if (lower.contains('communication') || lower.contains('clarity')) {
      return Icons.chat_bubble_outline;
    }
    if (lower.contains('confidence') || lower.contains('delivery')) {
      return Icons.record_voice_over_outlined;
    }
    if (lower.contains('structure')) return Icons.view_list_outlined;
    if (lower.contains('filler') || lower.contains('reduce')) {
      return Icons.graphic_eq;
    }
    if (lower.contains('detail') || lower.contains('specific')) {
      return Icons.bar_chart_rounded;
    }
    if (lower.contains('depth')) return Icons.layers_outlined;
    if (lower.contains('pace') || lower.contains('concise')) {
      return Icons.speed;
    }
    return defaultIcon;
  }
}
