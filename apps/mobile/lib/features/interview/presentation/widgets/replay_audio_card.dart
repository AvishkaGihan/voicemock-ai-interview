import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Card for replaying the coach's audio response.
///
/// Provides a play button, progress indicator, and label
/// in a compact card layout.
class ReplayAudioCard extends StatelessWidget {
  const ReplayAudioCard({
    required this.onReplay,
    super.key,
  });

  /// Callback to trigger audio replay.
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      decoration: VoiceMockColors.cardDecoration(),
      child: Row(
        children: [
          // Play button
          GestureDetector(
            onTap: onReplay,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VoiceMockColors.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: VoiceMockColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: VoiceMockColors.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: VoiceMockSpacing.md),

          // Label and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replay your answer',
                  style: VoiceMockTypography.h4.copyWith(
                    color: VoiceMockColors.textPrimary,
                  ),
                ),
                const SizedBox(height: VoiceMockSpacing.xs),
                // Static progress line (visual placeholder)
                ClipRRect(
                  borderRadius: BorderRadius.circular(VoiceMockRadius.full),
                  child: const LinearProgressIndicator(
                    value: 0,
                    backgroundColor: VoiceMockColors.surfaceBorder,
                    color: VoiceMockColors.primary,
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: VoiceMockSpacing.md),

          // Replay icon
          Icon(
            Icons.replay,
            size: 20,
            color: VoiceMockColors.textMuted.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
