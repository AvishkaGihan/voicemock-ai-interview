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
    return Card(
      elevation: 0,
      color: VoiceMockColors.secondary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
        side: BorderSide(
          color: VoiceMockColors.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VoiceMockSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row: icon + banner text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: VoiceMockColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: VoiceMockSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.disclosureBannerText,
                    style: VoiceMockTypography.small.copyWith(
                      color: VoiceMockColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: VoiceMockSpacing.sm),

            // Action row: "Learn more" (left) + "Got it" (right)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onLearnMore,
                  style: TextButton.styleFrom(
                    foregroundColor: VoiceMockColors.secondary,
                    textStyle: VoiceMockTypography.small.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(l10n.disclosureBannerLearnMore),
                ),
                const SizedBox(width: VoiceMockSpacing.sm),
                TextButton(
                  onPressed: onGotIt,
                  style: TextButton.styleFrom(
                    foregroundColor: VoiceMockColors.textMuted,
                    textStyle: VoiceMockTypography.small,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(l10n.disclosureBannerGotIt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
