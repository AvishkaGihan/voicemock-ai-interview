import 'package:flutter/material.dart';
import 'package:voicemock/core/permissions/permission_service.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Banner displayed when microphone permission is denied.
///
/// Provides a non-alarming warning message and actions to enable the mic.
/// Follows UX guidelines for neutral styling (no red/error colors).
class PermissionDeniedBanner extends StatelessWidget {
  const PermissionDeniedBanner({
    required this.status,
    required this.onEnableTap,
    required this.onDismissTap,
    super.key,
  });

  /// The current permission status.
  final MicrophonePermissionStatus status;

  /// Called when the user taps "Enable Microphone" or "Open Settings".
  final VoidCallback onEnableTap;

  /// Called when the user taps "Not now" to dismiss.
  final VoidCallback onDismissTap;

  @override
  Widget build(BuildContext context) {
    final isPermanentlyDenied =
        status == MicrophonePermissionStatus.permanentlyDenied;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      decoration: BoxDecoration(
        color: VoiceMockColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
        border: Border.all(
          color: VoiceMockColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.mic_off_rounded,
                color: VoiceMockColors.warning,
                size: 20,
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Expanded(
                child: Text(
                  'Microphone access is required for voice practice',
                  style: VoiceMockTypography.body.copyWith(
                    color: VoiceMockColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.md),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Secondary action - Not now
              TextButton(
                onPressed: onDismissTap,
                style: TextButton.styleFrom(
                  foregroundColor: VoiceMockColors.textMuted,
                  textStyle: VoiceMockTypography.small,
                ),
                child: const Text('Not now'),
              ),
              const SizedBox(width: VoiceMockSpacing.sm),

              // Primary action - Enable Microphone or Open Settings
              FilledButton(
                onPressed: onEnableTap,
                style: FilledButton.styleFrom(
                  backgroundColor: VoiceMockColors.warning,
                  foregroundColor: VoiceMockColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VoiceMockRadius.md),
                  ),
                  textStyle: VoiceMockTypography.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: VoiceMockColors.surface,
                  ),
                ),
                child: Text(
                  isPermanentlyDenied ? 'Open Settings' : 'Enable Microphone',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
