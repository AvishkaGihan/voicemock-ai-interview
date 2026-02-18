import 'package:flutter/material.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
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
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : IconButton.filledTonal(
                      onPressed: isPaused ? onResume : onPause,
                      tooltip: isPaused
                          ? 'Resume coach audio'
                          : 'Pause coach audio',
                      icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: 'Stop coach audio',
            child: SizedBox(
              width: 44,
              height: 44,
              child: IconButton.filledTonal(
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
