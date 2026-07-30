import 'dart:async';
import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Dedicated section for displaying the user's transcribed response.
///
/// Shows section label, transcript text, and a transcription status
/// indicator when STT is in progress.
class TranscriptDisplayCard extends StatelessWidget {
  const TranscriptDisplayCard({
    required this.transcript,
    this.isTranscribing = false,
    super.key,
  });

  /// The user's transcribed text.
  final String transcript;

  /// Whether transcription is still in progress.
  final bool isTranscribing;

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
          // Header row
          Row(
            children: [
              // Section label
              Text(
                '✦',
                style: VoiceMockTypography.sectionLabel.copyWith(fontSize: 14),
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Text(
                'YOUR RESPONSE',
                style: VoiceMockTypography.sectionLabel,
              ),
              const Spacer(),

              // Live indicator
              if (isTranscribing) _LiveIndicator(),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.md),

          // Transcript text
          Text(
            transcript,
            style: VoiceMockTypography.body,
          ),

          // Transcribing status
          if (isTranscribing) ...[
            const SizedBox(height: VoiceMockSpacing.sm),
            _TranscribingIndicator(),
          ],
        ],
      ),
    );
  }
}

/// Pulsing live indicator dot with "Live transcription" label.
class _LiveIndicator extends StatefulWidget {
  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Live transcription',
          style: VoiceMockTypography.micro.copyWith(
            color: VoiceMockColors.textMuted,
          ),
        ),
        const SizedBox(width: VoiceMockSpacing.xs),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VoiceMockColors.primary.withValues(
                alpha: 0.4 + (_controller.value * 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Transcribing shimmer indicator with waveform bars.
class _TranscribingIndicator extends StatefulWidget {
  @override
  State<_TranscribingIndicator> createState() => _TranscribingIndicatorState();
}

class _TranscribingIndicatorState extends State<_TranscribingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
        // Animated bars
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            children: List.generate(3, (index) {
              final offset = (index * 0.2).clamp(0.0, 1.0);
              final progress =
                  ((_controller.value + offset) % 1.0).clamp(0.0, 1.0);
              final height = 6.0 + (progress * 6.0);
              return Container(
                width: 2,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: VoiceMockColors.primary.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: VoiceMockSpacing.sm),
        Text(
          'Transcribing…',
          style: VoiceMockTypography.micro.copyWith(
            color: VoiceMockColors.primary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
