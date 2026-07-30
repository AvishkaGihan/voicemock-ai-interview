import 'dart:async';
import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Playback control bar for coach audio.
///
/// Shows pause/resume and stop buttons with a status label.
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
      width: double.infinity,
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      decoration: VoiceMockColors.cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isPaused && !isBuffering)
                _PulsingDot()
              else
                const SizedBox(width: 8),
              const SizedBox(width: VoiceMockSpacing.sm),
              Text(
                isBuffering
                    ? 'Buffering…'
                    : isPaused
                        ? 'Paused'
                        : 'Coach is speaking…',
                style: VoiceMockTypography.small.copyWith(
                  color: isPaused
                      ? VoiceMockColors.textMuted
                      : VoiceMockColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.sm),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: isBuffering
                    ? 'Buffering audio'
                    : isPaused
                        ? 'Resume coach audio'
                        : 'Pause coach audio',
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: isBuffering
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: VoiceMockColors.primary,
                          ),
                        )
                      : IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: VoiceMockColors.primary
                                .withValues(alpha: 0.15),
                            foregroundColor: VoiceMockColors.primary,
                          ),
                          onPressed: isPaused ? onResume : onPause,
                          tooltip: isPaused
                              ? 'Resume coach audio'
                              : 'Pause coach audio',
                          icon: Icon(
                            isPaused ? Icons.play_arrow : Icons.pause,
                            size: 24,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: VoiceMockSpacing.lg),
              Semantics(
                label: 'Stop coach audio',
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: VoiceMockColors.secondary
                          .withValues(alpha: 0.15),
                      foregroundColor: VoiceMockColors.secondary,
                    ),
                    onPressed: onStop,
                    tooltip: 'Stop coach audio',
                    icon: const Icon(Icons.stop, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small pulsing dot indicating active playback.
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: VoiceMockColors.primary.withValues(
            alpha: 0.5 + (_controller.value * 0.5),
          ),
        ),
      ),
    );
  }
}
