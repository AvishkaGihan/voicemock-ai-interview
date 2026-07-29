import 'package:flutter/material.dart';
import 'package:voicemock/core/storage/disclosure_prefs.dart'
    show DisclosurePrefs;
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/l10n/l10n.dart';

/// Informational banner informing the user that audio and transcripts are
/// processed by third-party AI services.
///
/// This is NOT a consent gate. The user can tap "Got it" to dismiss or
/// "Learn more" to see full disclosure details.
///
/// The parent is responsible for determining whether to display this widget
/// (i.e., when [DisclosurePrefs.hasAcknowledgedDisclosure] returns `false`).
class DisclosureBanner extends StatelessWidget {
  const DisclosureBanner({
    required this.onGotIt,
    required this.onLearnMore,
    super.key,
  });

  /// Called when the user taps "Got it" to acknowledge and dismiss the banner.
  final VoidCallback onGotIt;

  /// Called when the user taps "Learn more" to see the full disclosure sheet.
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: VoiceMockColors.surfaceCard,
        borderRadius: BorderRadius.circular(VoiceMockRadius.xl),
        border: Border.all(
          color: VoiceMockColors.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VoiceMockSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lock icon in tinted container
            Container(
              padding: const EdgeInsets.all(VoiceMockSpacing.sm + 2),
              decoration: BoxDecoration(
                color: VoiceMockColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(VoiceMockRadius.md),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: VoiceMockColors.secondary,
                size: 22,
              ),
            ),
            const SizedBox(width: VoiceMockSpacing.md),

            // Text + actions column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'AI Data Privacy',
                    style: VoiceMockTypography.h3.copyWith(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: VoiceMockSpacing.xs),

                  // Body text
                  Text(
                    l10n.disclosureBannerText,
                    style: VoiceMockTypography.small.copyWith(
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: VoiceMockSpacing.md),

                  // Actions: Learn more + Got it
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onLearnMore,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.disclosureBannerLearnMore,
                              style: VoiceMockTypography.small.copyWith(
                                color: VoiceMockColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: VoiceMockColors.primary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: VoiceMockSpacing.lg),
                      OutlinedButton(
                        onPressed: onGotIt,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: VoiceMockColors.textPrimary,
                          side: const BorderSide(
                            color: VoiceMockColors.surfaceBorder,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              VoiceMockRadius.full,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: VoiceMockSpacing.lg,
                            vertical: VoiceMockSpacing.sm,
                          ),
                        ),
                        child: Text(l10n.disclosureBannerGotIt),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
