import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Large circular button for push-to-talk recording.
///
/// Simplified gesture handler — the primary visual recording experience
/// is now handled by `RecordingZone`. This widget remains as a compact
/// fallback and for backward compatibility.
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
      child: Listener(
        onPointerDown: isEnabled
            ? (_) {
                unawaited(HapticFeedback.lightImpact());
                onPressStart();
              }
            : null,
        onPointerUp: isEnabled
            ? (_) {
                unawaited(HapticFeedback.mediumImpact());
                onPressEnd();
              }
            : null,
        onPointerCancel: isEnabled ? (_) => onPressEnd() : null,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRecording
                ? VoiceMockColors.primary.withValues(alpha: 0.12)
                : (isEnabled
                    ? VoiceMockColors.surfaceCard
                    : VoiceMockColors.surfaceElevated),
            border: Border.all(
              color: isRecording
                  ? VoiceMockColors.primary
                  : (isEnabled
                      ? VoiceMockColors.primary.withValues(alpha: 0.3)
                      : VoiceMockColors.surfaceBorder),
              width: isRecording ? 3 : 2,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: VoiceMockColors.primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic,
                size: 32,
                color: _getIconColor(),
              ),
              if (isRecording && recordingDuration != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatDuration(recordingDuration!),
                  style: VoiceMockTypography.micro.copyWith(
                    color: VoiceMockColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getAccessibilityLabel() {
    if (isRecording) return 'Recording. Release to send.';
    if (!isEnabled) return 'Disabled while coach is speaking.';
    return 'Hold to record answer';
  }

  Color _getIconColor() {
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
