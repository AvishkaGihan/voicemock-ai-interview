import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/l10n/l10n.dart';

/// Full disclosure detail shown in a modal bottom sheet.
///
/// Covers: what data is processed, how it's processed, data retention,
/// and user controls. Uses calm, non-legalistic language per UX spec.
///
/// Open via [DisclosureDetailSheet.show].
class DisclosureDetailSheet extends StatelessWidget {
  const DisclosureDetailSheet({super.key});

  /// Convenience method to show the sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VoiceMockRadius.xl),
        ),
      ),
      builder: (_) => const DisclosureDetailSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: VoiceMockSpacing.sm,
              ),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: VoiceMockColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(VoiceMockRadius.sm),
                ),
              ),
            ),

            // Sheet title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VoiceMockSpacing.lg,
                vertical: VoiceMockSpacing.sm,
              ),
              child: Text(
                l10n.disclosureDetailTitle,
                style: VoiceMockTypography.h2,
              ),
            ),

            const Divider(height: 1),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(VoiceMockSpacing.lg),
                children: [
                  _DisclosureSection(
                    header: l10n.disclosureSection1Header,
                    body: l10n.disclosureSection1Body,
                  ),
                  const SizedBox(height: VoiceMockSpacing.lg),
                  _DisclosureSection(
                    header: l10n.disclosureSection2Header,
                    body: l10n.disclosureSection2Body,
                  ),
                  const SizedBox(height: VoiceMockSpacing.lg),
                  _DisclosureSection(
                    header: l10n.disclosureSection3Header,
                    body: l10n.disclosureSection3Body,
                  ),
                  const SizedBox(height: VoiceMockSpacing.lg),
                  _DisclosureSection(
                    header: l10n.disclosureSection4Header,
                    body: l10n.disclosureSection4Body,
                  ),
                  const SizedBox(height: VoiceMockSpacing.xl),
                ],
              ),
            ),

            // "Got it" close button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VoiceMockSpacing.lg,
                0,
                VoiceMockSpacing.lg,
                VoiceMockSpacing.lg,
              ),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: VoiceMockColors.secondary,
                  foregroundColor: VoiceMockColors.surface,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VoiceMockRadius.md),
                  ),
                  textStyle: VoiceMockTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(l10n.disclosureDetailClose),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A single labelled section in the disclosure detail sheet.
class _DisclosureSection extends StatelessWidget {
  const _DisclosureSection({
    required this.header,
    required this.body,
  });

  final String header;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          header,
          style: VoiceMockTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: VoiceMockColors.textPrimary,
          ),
        ),
        const SizedBox(height: VoiceMockSpacing.xs),
        Text(
          body,
          style: VoiceMockTypography.small.copyWith(
            color: VoiceMockColors.textMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
