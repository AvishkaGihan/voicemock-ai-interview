import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

class PlaybackControlBar extends StatelessWidget {
  const PlaybackControlBar({
    required this.isPaused,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    this.isBuffering = false,
    super.key,
  });

  final bool isPaused;
  final bool isBuffering;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        VoiceMockSpacing.md,
        0,
        VoiceMockSpacing.md,
        VoiceMockSpacing.md,
      ),
      padding: const EdgeInsets.all(VoiceMockSpacing.sm),
      decoration: BoxDecoration(
        color: VoiceMockColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: isBuffering
                ? 'Buffering audio'
                : isPaused
                ? 'Resume coach audio'
                : 'Pause coach audio',
            child: SizedBox(
              width: 44,
              height: 44,
              child: isBuffering
                  ? const Padding(
                      padding: EdgeInsets.all(
                        10,
                      ), // slightly smaller padding for 24px icon feel
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: VoiceMockColors.secondary,
                      ),
                    )
                  : IconButton.filled(
                      // Using filled but with custom colors to match
                      // "filledTonal" look
                      style: IconButton.styleFrom(
                        backgroundColor: VoiceMockColors.secondary.withValues(
                          alpha: 0.2,
                        ),
                        foregroundColor: VoiceMockColors.secondary,
                      ),
                      onPressed: isPaused ? onResume : onPause,
                      tooltip: isPaused
                          ? 'Resume coach audio'
                          : 'Pause coach audio',
                      icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                    ),
            ),
          ),
          const SizedBox(width: VoiceMockSpacing.md),
          Semantics(
            label: 'Stop coach audio',
            child: SizedBox(
              width: 44,
              height: 44,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: VoiceMockColors.secondary.withValues(
                    alpha: 0.2,
                  ),
                  foregroundColor: VoiceMockColors.secondary,
                ),
                onPressed: onStop,
                tooltip: 'Stop coach audio',
                icon: const Icon(Icons.stop),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
