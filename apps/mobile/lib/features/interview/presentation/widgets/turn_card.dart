import 'package:flutter/material.dart';
import 'package:voicemock/core/models/models.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/presentation/widgets/coaching_score_grid.dart';
import 'package:voicemock/features/interview/presentation/widgets/question_header_card.dart';
import 'package:voicemock/features/interview/presentation/widgets/replay_audio_card.dart';
import 'package:voicemock/features/interview/presentation/widgets/transcript_display_card.dart';

/// Card displaying the current interview turn information.
///
/// Composes purpose-built section widgets for question, transcript,
/// coaching feedback, and replay — providing a sectioned layout.
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
    this.isListening = false,
    this.isRecording = false,
  });

  final int questionNumber;
  final int totalQuestions;
  final String questionText;
  final String? transcript;
  final String? responseText;
  final CoachingFeedback? coachingFeedback;
  final VoidCallback? onReplay;
  final bool isListening;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Question Card ──
        QuestionHeaderCard(
          questionText: questionText,
          isListening: isListening,
          isRecording: isRecording,
        ),

        // ── Transcript Section ──
        if (transcript != null) ...[
          const SizedBox(height: VoiceMockSpacing.md),
          TranscriptDisplayCard(transcript: transcript!),
        ],

        // ── Coach Response Section ──
        if (responseText != null) ...[
          const SizedBox(height: VoiceMockSpacing.md),
          _CoachResponseCard(responseText: responseText!),
        ],

        // ── Coaching Feedback Grid ──
        if (coachingFeedback != null) ...[
          const SizedBox(height: VoiceMockSpacing.md),
          CoachingScoreGrid(feedback: coachingFeedback!),
        ],

        // ── Replay Audio Card ──
        if (onReplay != null) ...[
          const SizedBox(height: VoiceMockSpacing.md),
          ReplayAudioCard(onReplay: onReplay!),
        ],
      ],
    );
  }
}

/// Card displaying the coach's response text.
class _CoachResponseCard extends StatelessWidget {
  const _CoachResponseCard({required this.responseText});

  final String responseText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      decoration: VoiceMockColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '✦',
                style: VoiceMockTypography.sectionLabel.copyWith(fontSize: 14),
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Text(
                'COACH SAYS',
                style: VoiceMockTypography.sectionLabel.copyWith(
                  color: VoiceMockColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.sm),
          Text(
            responseText,
            style: VoiceMockTypography.body,
          ),
        ],
      ),
    );
  }
}
