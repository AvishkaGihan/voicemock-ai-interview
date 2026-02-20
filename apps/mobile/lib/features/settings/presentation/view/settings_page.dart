import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/cubit/cubit.dart';
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
    InterviewCubit? interviewCubit;
    try {
      interviewCubit = context.read<InterviewCubit>();
    } on Exception {
      interviewCubit = null;
    }
    return Scaffold(
      backgroundColor: VoiceMockColors.background,
      appBar: AppBar(
        backgroundColor: VoiceMockColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: VoiceMockColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: VoiceMockSpacing.md),
        children: [
          // Custom Header
          Padding(
            padding: const EdgeInsets.only(
              top: VoiceMockSpacing.lg,
              bottom: VoiceMockSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: VoiceMockTypography.h2,
                ),
                const SizedBox(height: VoiceMockSpacing.xs),
                Text(
                  'Manage your account and preferences.',
                  style: VoiceMockTypography.small,
                ),
              ],
            ),
          ),

          // Settings Group Card
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: VoiceMockColors.surface,
              borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
              border: Border.all(
                color: VoiceMockColors.primaryContainer,
              ),
              boxShadow: const [
                BoxShadow(
                  color: VoiceMockColors.accentGlow,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ──────────────────────────────────────────────
                // Data & Privacy section header
                // ──────────────────────────────────────────────
                Container(
                  color: VoiceMockColors.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: VoiceMockSpacing.md,
                    vertical: VoiceMockSpacing.sm,
                  ),
                  child: Text(
                    l10n.disclosureSettingsSectionTitle,
                    style: VoiceMockTypography.label,
                  ),
                ),
                ListTile(
                  tileColor: VoiceMockColors.surface,
                  leading: _buildTintedIcon(
                    icon: Icons.privacy_tip_outlined,
                    color: VoiceMockColors.secondary,
                    backgroundColor: VoiceMockColors.primaryContainer,
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
                if (interviewCubit != null) ...[
                  ListTile(
                    tileColor: VoiceMockColors.surface,
                    leading: _buildTintedIcon(
                      icon: Icons.analytics_outlined,
                      color: VoiceMockColors.secondary,
                      backgroundColor: VoiceMockColors.primaryContainer,
                    ),
                    title: Text(
                      'Diagnostics',
                      style: VoiceMockTypography.body,
                    ),
                    subtitle: Text(
                      'View timing metrics & error info',
                      style: VoiceMockTypography.small,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: VoiceMockColors.textMuted,
                    ),
                    onTap: () => context.push(
                      '/diagnostics',
                      extra: interviewCubit,
                    ),
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  tileColor: VoiceMockColors.surface,
                  enabled: _storedSession != null && !_isDeleting,
                  leading: _buildTintedIcon(
                    icon: Icons.delete_outline,
                    color: VoiceMockColors.error,
                    backgroundColor: VoiceMockColors.error.withValues(
                      alpha: 0.1,
                    ),
                  ),
                  title: Text(
                    'Delete Session Data',
                    style: VoiceMockTypography.body.copyWith(
                      color: VoiceMockColors.error,
                    ),
                  ),
                  subtitle: Text(
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
              ],
            ),
          ),
          const SizedBox(height: VoiceMockSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildTintedIcon({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }
}
