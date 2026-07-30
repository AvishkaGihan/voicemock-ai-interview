import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/cubit/cubit.dart';
import 'package:voicemock/features/interview/presentation/widgets/disclosure_detail_sheet.dart';
import 'package:voicemock/features/settings/presentation/widgets/delete_session_dialog.dart';
import 'package:voicemock/features/settings/presentation/widgets/settings_data_pipeline.dart';
import 'package:voicemock/features/settings/presentation/widgets/settings_section_card.dart';
import 'package:voicemock/features/settings/presentation/widgets/settings_tile.dart';
import 'package:voicemock/l10n/l10n.dart';

/// Redesigned settings page with clearly sectioned groups.
///
/// Organized into: Account & Preferences, Privacy & Data, Interview Data.
/// Consistent with the Setup/Interview visual language using section labels,
/// glassmorphic cards, and tinted icons.
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
        leading: Padding(
          padding: const EdgeInsets.only(left: VoiceMockSpacing.sm),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: VoiceMockColors.surfaceBorder),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                color: VoiceMockColors.textPrimary,
                onPressed: () => context.pop(),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: VoiceMockSpacing.md),
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.only(
              top: VoiceMockSpacing.sm,
              bottom: VoiceMockSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: VoiceMockTypography.h1,
                ),
                const SizedBox(height: VoiceMockSpacing.xs),
                Text(
                  'Manage your account and preferences',
                  style: VoiceMockTypography.small,
                ),
              ],
            ),
          ),

          // ── 1. Account & Preferences Section ──
          SettingsSectionCard(
            label: l10n.settingsAccountPreferences,
            children: [
              SettingsTile(
                icon: Icons.person_outline_rounded,
                title: l10n.settingsProfile,
                subtitle: l10n.settingsProfileSubtitle,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile settings coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              SettingsTile(
                icon: Icons.tune_rounded,
                title: l10n.settingsInterviewPreferences,
                subtitle: l10n.settingsInterviewPreferencesSubtitle,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Interview preferences coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.xl),

          // ── 2. Privacy & Data Section ──
          SettingsSectionCard(
            label: l10n.settingsPrivacyData,
            children: [
              // Privacy & Data Processing tile
              SettingsTile(
                icon: Icons.shield_outlined,
                title: l10n.settingsPrivacyProcessingTitle,
                subtitle: l10n.settingsPrivacyProcessingSubtitle,
                iconColor: VoiceMockColors.secondary,
                onTap: () => DisclosureDetailSheet.show(context),
              ),
            ],
          ),

          const SizedBox(height: VoiceMockSpacing.md),

          // Data pipeline visualization
          Container(
            padding: const EdgeInsets.only(
              top: VoiceMockSpacing.xs,
              bottom: VoiceMockSpacing.md,
            ),
            decoration: VoiceMockColors.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sub-header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    VoiceMockSpacing.md,
                    VoiceMockSpacing.md,
                    VoiceMockSpacing.md,
                    0,
                  ),
                  child: Text(
                    'How your data is processed',
                    style: VoiceMockTypography.sectionLabel.copyWith(
                      fontSize: 11,
                    ),
                  ),
                ),

                // Pipeline steps
                const SettingsDataPipeline(),

                // Explanatory text
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VoiceMockSpacing.md,
                  ),
                  child: Text(
                    'VoiceMock uses third-party AI services to process audio '
                    'and generate transcripts, interview questions, and '
                    'performance feedback.',
                    style: VoiceMockTypography.micro.copyWith(
                      color: VoiceMockColors.textMuted.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: VoiceMockSpacing.md),

                // Reassurance chip
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VoiceMockSpacing.md,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: VoiceMockSpacing.md,
                      vertical: VoiceMockSpacing.sm + 2,
                    ),
                    decoration: BoxDecoration(
                      color: VoiceMockColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(VoiceMockRadius.md),
                      border: Border.all(
                        color: VoiceMockColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: VoiceMockColors.primary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                        const SizedBox(width: VoiceMockSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.settingsAudioNotStored,
                            style: VoiceMockTypography.small.copyWith(
                              color: VoiceMockColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: VoiceMockSpacing.xl),

          // ── 3. Interview Data Section ──
          SettingsSectionCard(
            label: l10n.settingsInterviewData,
            children: [
              // Interview History tile
              SettingsTile(
                icon: Icons.history_rounded,
                title: l10n.settingsInterviewHistory,
                subtitle: l10n.settingsInterviewHistorySubtitle,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Interview history coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),

              // Diagnostics tile (if available)
              if (interviewCubit != null)
                SettingsTile(
                  icon: Icons.analytics_outlined,
                  title: 'Diagnostics',
                  subtitle: 'View timing metrics & error info',
                  iconColor: VoiceMockColors.secondary,
                  onTap: () => context.push(
                    '/diagnostics',
                    extra: interviewCubit,
                  ),
                ),

              // Delete all data tile
              SettingsTile(
                icon: Icons.delete_outline_rounded,
                title: l10n.settingsDeleteAllData,
                subtitle: l10n.settingsDeleteAllDataSubtitle,
                iconColor: VoiceMockColors.error,
                titleColor: VoiceMockColors.error,
                enabled: _storedSession != null && !_isDeleting,
                trailing: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _onDeleteTap,
              ),
            ],
          ),

          const SizedBox(height: VoiceMockSpacing.xl),

          // ── 4. Privacy Footer ──
          _buildPrivacyFooter(l10n),

          const SizedBox(height: VoiceMockSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildPrivacyFooter(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VoiceMockSpacing.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: VoiceMockColors.textMuted.withValues(alpha: 0.6),
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Flexible(
                child: Text(
                  l10n.settingsPrivacyFooter,
                  style: VoiceMockTypography.micro.copyWith(
                    color: VoiceMockColors.textMuted.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.sm),
          GestureDetector(
            onTap: () => DisclosureDetailSheet.show(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.settingsPrivacyPolicyLink,
                  style: VoiceMockTypography.micro.copyWith(
                    color: VoiceMockColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: VoiceMockColors.primary.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
