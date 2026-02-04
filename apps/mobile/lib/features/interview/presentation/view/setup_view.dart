import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voicemock/core/connectivity/connectivity.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_state.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_state.dart';
import 'package:voicemock/features/interview/presentation/cubit/session_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/session_state.dart';
import 'package:voicemock/features/interview/presentation/view/permission_rationale_page.dart';
import 'package:voicemock/features/interview/presentation/widgets/configuration_summary_card.dart';
import 'package:voicemock/features/interview/presentation/widgets/connectivity_banner.dart';
import 'package:voicemock/features/interview/presentation/widgets/difficulty_selector.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
              context.go('/interview', extra: sessionState.session);
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
              title: Text(
                context.l10n.interviewSetupTitle,
                style: VoiceMockTypography.h2,
              ),
              centerTitle: false,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(VoiceMockSpacing.md),
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

                          // Permission denied banner (shown when permission is
                          // not granted)
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
                                    _handleEnableMic(context, permissionState);
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

                          // Role selector
                          RoleSelector(
                            selectedRole: config.role,
                            onRoleSelected: configCubit.updateRole,
                          ),
                          const SizedBox(height: VoiceMockSpacing.lg),

                          // Interview type selector
                          TypeSelector(
                            selectedType: config.type,
                            onTypeSelected: configCubit.updateType,
                          ),
                          const SizedBox(height: VoiceMockSpacing.lg),

                          // Difficulty selector
                          DifficultySelector(
                            selectedDifficulty: config.difficulty,
                            onDifficultySelected: configCubit.updateDifficulty,
                          ),
                          const SizedBox(height: VoiceMockSpacing.lg),

                          // Question count selector
                          QuestionCountSelector(
                            questionCount: config.questionCount,
                            onQuestionCountChanged:
                                configCubit.updateQuestionCount,
                          ),
                          const SizedBox(height: VoiceMockSpacing.xl),

                          // Configuration summary
                          ConfigurationSummaryCard(config: config),
                        ],
                      ),
                    ),
                  ),

                  // Start Interview button - anchored at bottom
                  const _StartInterviewButton(),
                ],
              ),
            ),
          );
        },
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
  const _StartInterviewButton();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      decoration: BoxDecoration(
        color: VoiceMockColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivityState) {
          return BlocBuilder<SessionCubit, SessionState>(
            builder: (context, sessionState) {
              final isLoading = sessionState is SessionLoading;
              final isOffline = connectivityState is ConnectivityOffline;

              return FilledButton(
                onPressed: (isLoading || isOffline)
                    ? null
                    : () => _handleStartInterview(context),
                style: FilledButton.styleFrom(
                  backgroundColor: VoiceMockColors.primary,
                  foregroundColor: VoiceMockColors.surface,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VoiceMockRadius.md),
                  ),
                  textStyle: VoiceMockTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
                    : Text(
                        isOffline
                            ? l10n.noInternetConnection
                            : l10n.startInterview,
                      ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleStartInterview(BuildContext context) {
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
