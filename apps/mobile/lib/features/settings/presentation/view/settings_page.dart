import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/presentation/widgets/disclosure_detail_sheet.dart';
import 'package:voicemock/l10n/l10n.dart';

/// Minimal settings page for MVP.
///
/// Contains a "Data & Privacy" section exposing the processing disclosure.
/// Additional settings sections are added as future epics require them.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  /// Route path for navigation.
  static const String routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: VoiceMockColors.background,
      appBar: AppBar(
        backgroundColor: VoiceMockColors.background,
        elevation: 0,
        title: const Text(
          'Settings',
          style: VoiceMockTypography.h2,
        ),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // ──────────────────────────────────────────────
          // Data & Privacy section
          // ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VoiceMockSpacing.md,
              VoiceMockSpacing.lg,
              VoiceMockSpacing.md,
              VoiceMockSpacing.sm,
            ),
            child: Text(
              l10n.disclosureSettingsSectionTitle,
              style: VoiceMockTypography.small.copyWith(
                color: VoiceMockColors.secondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            tileColor: VoiceMockColors.surface,
            leading: const Icon(
              Icons.privacy_tip_outlined,
              color: VoiceMockColors.secondary,
            ),
            title: Text(
              l10n.disclosureSettingsTileTitle,
              style: VoiceMockTypography.body,
            ),
            subtitle: Text(
              l10n.disclosureSettingsTileSubtitle,
              style: VoiceMockTypography.small,
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: VoiceMockColors.textMuted,
            ),
            onTap: () => DisclosureDetailSheet.show(context),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
