import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

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
                    color: VoiceMockColors.primary,
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
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: VoiceMockColors.primary,
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
      return VoiceMockColors.primary.withValues(alpha: 0.2); // 51/255 ~= 0.2
    }
    if (!isEnabled) {
      return const Color(0xFFE2E8F0); // Light grey/outline variant
    }
    return VoiceMockColors.primary.withValues(alpha: 0.1); // Container-like
  }

  Color _getIconColor(BuildContext context) {
    if (isRecording) return VoiceMockColors.primary;
    if (!isEnabled) return VoiceMockColors.textMuted;
    return VoiceMockColors.primary;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
