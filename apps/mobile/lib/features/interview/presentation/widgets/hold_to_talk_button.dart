import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Large circular button for push-to-talk recording.
///
/// Implements hold-to-talk interaction pattern with visual feedback,
/// recording timer, and accessibility support.
class HoldToTalkButton extends StatelessWidget {
  const HoldToTalkButton({
    required this.isEnabled,
    required this.isRecording,
    required this.onPressStart,
    required this.onPressEnd,
    super.key,
    this.recordingDuration,
  });

  final bool isEnabled;
  final bool isRecording;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final Duration? recordingDuration;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: _getAccessibilityLabel(),
      child: GestureDetector(
        onLongPressStart: isEnabled
            ? (_) {
                unawaited(HapticFeedback.lightImpact());
                onPressStart();
              }
            : null,
        onLongPressEnd: isEnabled
            ? (_) {
                unawaited(HapticFeedback.mediumImpact());
                onPressEnd();
              }
            : null,
        onLongPressCancel: isEnabled ? onPressEnd : null,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getBackgroundColor(context),
            border: isRecording
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 4,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic,
                size: 48,
                color: _getIconColor(context),
              ),
              const SizedBox(height: 4),
              Text(
                _getLabel(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getIconColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              if (isRecording && recordingDuration != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatDuration(recordingDuration!),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getLabel() {
    if (isRecording) return 'Release to send';
    if (!isEnabled) return 'Waiting...';
    return 'Hold to talk';
  }

  String _getAccessibilityLabel() {
    if (isRecording) return 'Recording. Release to send.';
    if (!isEnabled) return 'Disabled while coach is speaking.';
    return 'Hold to record answer';
  }

  Color _getBackgroundColor(BuildContext context) {
    if (isRecording) {
      return Theme.of(context).colorScheme.primary.withAlpha(51);
    }
    if (!isEnabled) return Colors.grey[300]!;
    return Theme.of(context).colorScheme.primaryContainer;
  }

  Color _getIconColor(BuildContext context) {
    if (isRecording) return Theme.of(context).colorScheme.primary;
    if (!isEnabled) return Colors.grey[600]!;
    return Theme.of(context).colorScheme.onPrimaryContainer;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
