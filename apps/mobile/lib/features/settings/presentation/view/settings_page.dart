import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/widgets/disclosure_detail_sheet.dart';
import 'package:voicemock/features/settings/presentation/widgets/delete_session_dialog.dart';
import 'package:voicemock/l10n/l10n.dart';

/// Minimal settings page for MVP.
///
/// Contains a "Data & Privacy" section exposing the processing disclosure.
/// Additional settings sections are added as future epics require them.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  /// Route path for navigation.
  static const String routeName = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Session? _storedSession;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadStoredSession());
  }

  Future<void> _loadStoredSession() async {
    final session = await context.read<SessionRepository>().getStoredSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _storedSession = session;
    });
  }

  Future<void> _onDeleteTap() async {
    final session = _storedSession;
    if (session == null || _isDeleting) {
      return;
    }

    final confirmed = await DeleteSessionDialog.show(context);
    if (confirmed != true || !mounted) {
      return;
    }

    await _deleteSession(session);
  }

  Future<void> _deleteSession(Session session) async {
    setState(() {
      _isDeleting = true;
    });

    final result = await context.read<SessionRepository>().deleteSession(
      session.sessionId,
      session.sessionToken,
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                unawaited(_deleteSession(session));
              },
            ),
          ),
        );
      },
      (deleted) {
        setState(() {
          _isDeleting = false;
          if (deleted) {
            _storedSession = null;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session data deleted.')),
        );
      },
    );
  }

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
          ListTile(
            tileColor: VoiceMockColors.surface,
            enabled: _storedSession != null && !_isDeleting,
            leading: const Icon(
              Icons.delete_outline,
              color: VoiceMockColors.secondary,
            ),
            title: const Text(
              'Delete Session Data',
              style: VoiceMockTypography.body,
            ),
            subtitle: const Text(
              'Remove transcripts, feedback, and summary',
              style: VoiceMockTypography.small,
            ),
            trailing: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.chevron_right_rounded,
                    color: VoiceMockColors.textMuted,
                  ),
            onTap: _onDeleteTap,
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
