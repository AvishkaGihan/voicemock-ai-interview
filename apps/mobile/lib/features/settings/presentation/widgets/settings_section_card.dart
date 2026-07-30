import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Reusable section group container for the Settings screen.
///
/// Renders a `✦ SECTION_LABEL` header followed by a glassmorphic card
/// containing divider-separated child widgets, consistent with the
/// setup screen's card pattern.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    required this.label,
    required this.children,
    super.key,
  });

  /// Section header text (displayed in all-caps neon green).
  final String label;

  /// Tile widgets to render inside the card, separated by dividers.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Padding(
          padding: const EdgeInsets.only(
            left: VoiceMockSpacing.xs,
            bottom: VoiceMockSpacing.md,
          ),
          child: Row(
            children: [
              Text(
                '✦',
                style: VoiceMockTypography.sectionLabel.copyWith(fontSize: 14),
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Text(
                label,
                style: VoiceMockTypography.sectionLabel,
              ),
            ],
          ),
        ),

        // Glassmorphic card containing tiles
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: VoiceMockColors.cardDecoration(),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VoiceMockSpacing.md,
                    ),
                    child: Divider(
                      height: 1,
                      thickness: 0.5,
                      color: VoiceMockColors.surfaceBorder.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
