import 'package:flutter/material.dart';
import 'package:voicemock/core/permissions/permission_service.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Hero card displayed when microphone permission is denied.
///
/// Two-column layout: left has badge + headline + subtitle,
/// right has a large mic icon with concentric glow rings.
/// Provides "Decline for now" and "Enable microphone" CTAs.
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

  /// Called when the user taps "Decline for now" to dismiss.
  final VoidCallback onDismissTap;

  @override
  Widget build(BuildContext context) {
    final isPermanentlyDenied =
        status == MicrophonePermissionStatus.permanentlyDenied;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoiceMockSpacing.lg),
      decoration: BoxDecoration(
        color: VoiceMockColors.surfaceCard,
        borderRadius: BorderRadius.circular(VoiceMockRadius.xl),
        border: Border.all(color: VoiceMockColors.surfaceBorder),
        boxShadow: const [
          BoxShadow(
            color: VoiceMockColors.accentGlow,
            blurRadius: 32,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top section: Badge + mic icon row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column: badge + text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // REQUIRED badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VoiceMockSpacing.sm,
                        vertical: VoiceMockSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: VoiceMockColors.primary.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(VoiceMockRadius.full),
                        border: Border.all(
                          color: VoiceMockColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'REQUIRED',
                        style: VoiceMockTypography.micro.copyWith(
                          color: VoiceMockColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: VoiceMockSpacing.md),

                    // Headline
                    Text(
                      'Microphone access\nrequired',
                      style: VoiceMockTypography.h2.copyWith(
                        color: VoiceMockColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: VoiceMockSpacing.sm),

                    // Subtitle
                    Text(
                      'Your microphone is required for voice practice.',
                      style: VoiceMockTypography.small,
                    ),
                  ],
                ),
              ),

              // Right column: glowing mic icon
              const _GlowingMicIcon(),
            ],
          ),

          const SizedBox(height: VoiceMockSpacing.lg),

          // Action buttons
          Row(
            children: [
              // Decline for now
              Expanded(
                child: OutlinedButton(
                  onPressed: onDismissTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VoiceMockColors.textPrimary,
                    side: const BorderSide(
                      color: VoiceMockColors.surfaceBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(VoiceMockRadius.full),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Decline for now',
                      style: VoiceMockTypography.small.copyWith(
                        color: VoiceMockColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: VoiceMockSpacing.md),

              // Enable microphone
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(VoiceMockRadius.full),
                    gradient: const LinearGradient(
                      colors: [
                        VoiceMockColors.gradientStart,
                        VoiceMockColors.gradientEnd,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            VoiceMockColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onEnableTap,
                      borderRadius:
                          BorderRadius.circular(VoiceMockRadius.full),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 14,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isPermanentlyDenied
                                ? 'Open Settings'
                                : 'Enable microphone',
                            textAlign: TextAlign.center,
                            style: VoiceMockTypography.small.copyWith(
                              color: VoiceMockColors.background,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
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

/// Large mic icon with concentric green glow rings.
class _GlowingMicIcon extends StatelessWidget {
  const _GlowingMicIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: VoiceMockColors.primary.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
          ),

          // Middle glow ring
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: VoiceMockColors.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
          ),

          // Inner glow circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VoiceMockColors.primary.withValues(alpha: 0.08),
              boxShadow: [
                BoxShadow(
                  color: VoiceMockColors.primary.withValues(alpha: 0.2),
                  blurRadius: 24,
                ),
              ],
            ),
          ),

          // Mic icon
          const Icon(
            Icons.mic_rounded,
            size: 40,
            color: VoiceMockColors.primary,
          ),
        ],
      ),
    );
  }
}
