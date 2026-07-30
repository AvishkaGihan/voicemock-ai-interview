import 'dart:async';
import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Dedicated card for displaying the current AI interview question.
///
/// Extracted from TurnCard — shows the section label, question text,
/// and an optional listening status indicator.
class QuestionHeaderCard extends StatelessWidget {
  const QuestionHeaderCard({
    required this.questionText,
    this.isListening = false,
    this.isRecording = false,
    super.key,
  });

  /// The interview question to display.
  final String questionText;

  /// Whether the AI is currently listening for a response.
  final bool isListening;

  /// Whether the user is currently recording.
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      decoration: VoiceMockColors.cardDecorationElevated(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section label
          Row(
            children: [
              Text(
                '✦',
                style: VoiceMockTypography.sectionLabel.copyWith(fontSize: 14),
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Text(
                'AI INTERVIEWER',
                style: VoiceMockTypography.sectionLabel,
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.md),

          // Question text
          Text(
            questionText,
            style: VoiceMockTypography.h3,
          ),

          // Listening indicator
          if (isListening || isRecording) ...[
            const SizedBox(height: VoiceMockSpacing.md),
            _ListeningIndicator(isRecording: isRecording),
          ],
        ],
      ),
    );
  }
}

class _ListeningIndicator extends StatefulWidget {
  const _ListeningIndicator({this.isRecording = false});

  final bool isRecording;

  @override
  State<_ListeningIndicator> createState() => _ListeningIndicatorState();
}

class _ListeningIndicatorState extends State<_ListeningIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    unawaited(_controller.repeat(reverse: true));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.mic,
          size: 14,
          color: VoiceMockColors.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: VoiceMockSpacing.xs),

        // Animated waveform bars
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              children: List.generate(4, (index) {
                final offset = (index * 0.15).clamp(0.0, 1.0);
                final progress =
                    ((_controller.value + offset) % 1.0).clamp(0.0, 1.0);
                final height = 4.0 + (progress * 8.0);
                return Container(
                  width: 2,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: VoiceMockColors.primary.withValues(
                      alpha: 0.4 + (progress * 0.4),
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(width: VoiceMockSpacing.sm),

        Text(
          widget.isRecording
              ? 'AI is listening for your response'
              : 'Ready for your answer',
          style: VoiceMockTypography.micro.copyWith(
            color: VoiceMockColors.primary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
