import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voicemock/core/connectivity/connectivity.dart';
import 'package:voicemock/core/storage/disclosure_prefs.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_state.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_state.dart';
import 'package:voicemock/features/interview/presentation/cubit/session_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/session_state.dart';
import 'package:voicemock/features/interview/presentation/view/permission_rationale_page.dart';
import 'package:voicemock/features/interview/presentation/widgets/connectivity_banner.dart';
import 'package:voicemock/features/interview/presentation/widgets/difficulty_selector.dart';
import 'package:voicemock/features/interview/presentation/widgets/disclosure_banner.dart';
import 'package:voicemock/features/interview/presentation/widgets/disclosure_detail_sheet.dart';
import 'package:voicemock/features/interview/presentation/widgets/permission_denied_banner.dart';
import 'package:voicemock/features/interview/presentation/widgets/question_count_selector.dart';
import 'package:voicemock/features/interview/presentation/widgets/role_selector.dart';
import 'package:voicemock/features/interview/presentation/widgets/session_error_dialog.dart';
import 'package:voicemock/features/interview/presentation/widgets/type_selector.dart';
import 'package:voicemock/l10n/l10n.dart';

/// Main setup view for configuring interview parameters.
///
/// Provides selectors for role, type, difficulty, and question count.
/// Shows a summary of selections and a Start Interview button.
/// Handles permission checking and shows banner when permission is denied.
class SetupView extends StatefulWidget {
  const SetupView({super.key});

  @override
  State<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<SetupView> with WidgetsBindingObserver {
  bool _bannerDismissed = false;

  // Disclosure state
  bool _disclosureAcknowledged = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadDisclosureState());
  }

  Future<void> _loadDisclosureState() async {
    final disclosurePrefs = context.read<DisclosurePrefs>();
    final acknowledged = await disclosurePrefs.hasAcknowledgedDisclosure();
    if (mounted) {
      setState(() {
        _disclosureAcknowledged = acknowledged;
      });
    }
  }

  Future<void> _acknowledgeDisclosure() async {
    await context.read<DisclosurePrefs>().acknowledgeDisclosure();
    if (mounted) {
      setState(() => _disclosureAcknowledged = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check permission status when app comes to foreground
      // This handles the case where user enabled permission in settings
      unawaited(context.read<PermissionCubit>().checkPermission());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SessionCubit, SessionState>(
          listener: (context, sessionState) {
            if (sessionState is SessionSuccess) {
              // Navigate to interview screen with session
              unawaited(
                context.push('/interview', extra: sessionState.session),
              );
            } else if (sessionState is SessionFailure) {
              // Show error dialog with retry/cancel
              unawaited(
                showDialog<void>(
                  context: context,
                  builder: (_) => SessionErrorDialog(
                    failure: sessionState.failure,
                    onRetry: () {
                      Navigator.of(context).pop();
                      final config = context
                          .read<ConfigurationCubit>()
                          .state
                          .config;
                      // Fire-and-forget session start on retry
                      // ignore: discarded_futures
                      context.read<SessionCubit>().startSession(config);
                    },
                    onCancel: () => Navigator.of(context).pop(),
                  ),
                ),
              );
            }
          },
        ),
        BlocListener<ConnectivityCubit, ConnectivityState>(
          listener: (context, state) {
            // Banner handles UI, no action needed here
          },
        ),
      ],
      child: BlocBuilder<ConfigurationCubit, ConfigurationState>(
        builder: (context, configState) {
          if (configState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: VoiceMockColors.primary,
              ),
            );
          }

          final configCubit = context.read<ConfigurationCubit>();
          final config = configState.config;

          return Scaffold(
            backgroundColor: VoiceMockColors.background,
            appBar: AppBar(
              backgroundColor: VoiceMockColors.background,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: Row(
                children: [
                  Text(
                    'Voice',
                    style: VoiceMockTypography.h2.copyWith(
                      color: VoiceMockColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    'Mock',
                    style: VoiceMockTypography.h2.copyWith(
                      color: VoiceMockColors.primary,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              centerTitle: false,
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: VoiceMockSpacing.sm),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VoiceMockColors.surfaceBorder,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    color: VoiceMockColors.primary,
                    tooltip: 'Settings',
                    onPressed: () => context.push('/settings'),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // Subtitle brand moment
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VoiceMockSpacing.md,
                      0,
                      VoiceMockSpacing.md,
                      VoiceMockSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Prepare smarter. Perform better.',
                          style: VoiceMockTypography.small,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VoiceMockSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Connectivity banner (shown when offline)
                          BlocBuilder<ConnectivityCubit, ConnectivityState>(
                            builder: (context, connectivityState) {
                              if (connectivityState is ConnectivityOffline) {
                                return const Padding(
                                  padding: EdgeInsets.only(
                                    bottom: VoiceMockSpacing.lg,
                                  ),
                                  child: ConnectivityBanner(),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),

                          // Permission denied banner (hero microphone card)
                          BlocBuilder<PermissionCubit, PermissionState>(
                            builder: (context, permissionState) {
                              final shouldShowBanner =
                                  permissionState.hasChecked &&
                                  !permissionState.isGranted &&
                                  !_bannerDismissed;

                              if (!shouldShowBanner) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: VoiceMockSpacing.lg,
                                ),
                                child: PermissionDeniedBanner(
                                  status: permissionState.status,
                                  onEnableTap: () {
                                    _handleEnableMic(
                                      context,
                                      permissionState,
                                    );
                                  },
                                  onDismissTap: () {
                                    setState(() {
                                      _bannerDismissed = true;
                                    });
                                  },
                                ),
                              );
                            },
                          ),

                          // ── INTERVIEW SETUP section card ──
                          Container(
                            width: double.infinity,
                            decoration: VoiceMockColors.cardDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section header
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    VoiceMockSpacing.md,
                                    VoiceMockSpacing.md,
                                    VoiceMockSpacing.md,
                                    VoiceMockSpacing.xs,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '✦',
                                        style: VoiceMockTypography.sectionLabel
                                            .copyWith(fontSize: 14),
                                      ),
                                      const SizedBox(
                                        width: VoiceMockSpacing.sm,
                                      ),
                                      Text(
                                        'INTERVIEW SETUP',
                                        style:
                                            VoiceMockTypography.sectionLabel,
                                      ),
                                    ],
                                  ),
                                ),

                                // Role selector row
                                RoleSelector(
                                  selectedRole: config.role,
                                  onRoleSelected: configCubit.updateRole,
                                ),

                                _sectionDivider(),

                                // Interview type selector row
                                TypeSelector(
                                  selectedType: config.type,
                                  onTypeSelected: configCubit.updateType,
                                ),

                                _sectionDivider(),

                                // Difficulty selector row
                                DifficultySelector(
                                  selectedDifficulty: config.difficulty,
                                  onDifficultySelected:
                                      configCubit.updateDifficulty,
                                ),

                                _sectionDivider(),

                                // Question count selector
                                QuestionCountSelector(
                                  questionCount: config.questionCount,
                                  onQuestionCountChanged:
                                      configCubit.updateQuestionCount,
                                ),

                                const SizedBox(height: VoiceMockSpacing.sm),
                              ],
                            ),
                          ),

                          const SizedBox(height: VoiceMockSpacing.lg),

                          // Disclosure banner
                          if (!_disclosureAcknowledged)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: VoiceMockSpacing.lg,
                              ),
                              child: DisclosureBanner(
                                onGotIt: _acknowledgeDisclosure,
                                onLearnMore: () =>
                                    DisclosureDetailSheet.show(context),
                              ),
                            ),

                          // Bottom spacing before button
                          const SizedBox(height: VoiceMockSpacing.md),
                        ],
                      ),
                    ),
                  ),

                  // Start Interview button - anchored at bottom
                  _StartInterviewButton(
                    onBeforeStart: _disclosureAcknowledged
                        ? null
                        : _acknowledgeDisclosure,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Thin divider between selector rows inside the setup card.
  Widget _sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VoiceMockSpacing.md),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: VoiceMockColors.surfaceBorder.withValues(alpha: 0.6),
      ),
    );
  }

  void _handleEnableMic(BuildContext context, PermissionState state) {
    if (state.isPermanentlyDenied) {
      // Open app settings for permanently denied
      unawaited(context.read<PermissionCubit>().openSettings());
    } else {
      // Navigate to permission rationale page
      unawaited(
        context.pushNamed(PermissionRationalePage.routeName.substring(1)),
      );
    }
  }
}

class _StartInterviewButton extends StatelessWidget {
  const _StartInterviewButton({this.onBeforeStart});

  /// Optional callback invoked before the interview starts.
  /// Used to auto-acknowledge the disclosure when the banner is still visible.
  final VoidCallback? onBeforeStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            VoiceMockColors.background.withValues(alpha: 0),
            VoiceMockColors.background.withValues(alpha: 0.95),
            VoiceMockColors.background,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivityState) {
          return BlocBuilder<SessionCubit, SessionState>(
            builder: (context, sessionState) {
              final isLoading = sessionState is SessionLoading;
              final isOffline = connectivityState is ConnectivityOffline;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient CTA button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(VoiceMockRadius.full),
                      gradient: (isLoading || isOffline)
                          ? null
                          : const LinearGradient(
                              colors: [
                                VoiceMockColors.gradientStart,
                                VoiceMockColors.gradientEnd,
                              ],
                            ),
                      color: (isLoading || isOffline)
                          ? VoiceMockColors.surfaceBorder
                          : null,
                      boxShadow: (isLoading || isOffline)
                          ? null
                          : [
                              BoxShadow(
                                color: VoiceMockColors.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: (isLoading || isOffline)
                            ? null
                            : () => _handleStartInterview(context),
                        borderRadius:
                            BorderRadius.circular(VoiceMockRadius.full),
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          child: DefaultTextStyle(
                            style: VoiceMockTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: VoiceMockColors.background,
                            ),
                            child: IconTheme(
                              data: const IconThemeData(
                                color: VoiceMockColors.background,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: VoiceMockColors.surface,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          isOffline
                                              ? l10n.noInternetConnection
                                              : l10n.startInterview,
                                        ),
                                        if (!isOffline) ...[
                                          const SizedBox(
                                            width: VoiceMockSpacing.sm,
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: VoiceMockSpacing.sm),

                  // Helper subtitle
                  Text(
                    'Review your settings and ensure microphone\n'
                    'access is enabled before starting.',
                    textAlign: TextAlign.center,
                    style: VoiceMockTypography.micro.copyWith(
                      color: VoiceMockColors.textMuted.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _handleStartInterview(BuildContext context) {
    // Auto-acknowledge disclosure if still visible (AC 5)
    onBeforeStart?.call();

    // Check connectivity immediately before starting
    unawaited(context.read<ConnectivityCubit>().checkConnectivity());

    // Only proceed if online
    final connectivityState = context.read<ConnectivityCubit>().state;
    if (connectivityState is ConnectivityOffline) {
      return;
    }

    final permissionState = context.read<PermissionCubit>().state;

    // If permission is not granted, navigate to permission rationale page
    if (!permissionState.isGranted) {
      unawaited(
        context.pushNamed(PermissionRationalePage.routeName.substring(1)),
      );
      return;
    }

    // Permission is granted, start session
    final config = context.read<ConfigurationCubit>().state.config;
    // Fire-and-forget session start after permission granted
    // ignore: discarded_futures
    context.read<SessionCubit>().startSession(config);
  }
}
