import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_state.dart';

/// View showing the microphone permission rationale.
///
/// Displays a calming explanation of why microphone access is needed
/// and provides a clear CTA to request permission.
class PermissionRationaleView extends StatelessWidget {
  const PermissionRationaleView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PermissionCubit, PermissionState>(
      listener: (context, state) {
        // Navigate back after permission is granted or if permanently denied
        // (so the setup page banner can handle the "Open Settings" flow)
        if (state.hasChecked &&
            (state.isGranted || state.isPermanentlyDenied)) {
          if (context.canPop()) {
            context.pop();
          } else {
            // Fallback if not pushed
            context.go('/');
          }
        }
      },
      child: Scaffold(
        backgroundColor: VoiceMockColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(VoiceMockSpacing.lg),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Microphone icon with friendly visual
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: VoiceMockColors.primaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: VoiceMockColors.accentGlow,
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    size: 64,
                    color: VoiceMockColors.primary,
                  ),
                ),

                const SizedBox(height: VoiceMockSpacing.xl),

                // Headline
                Text(
                  'VoiceMock needs microphone access',
                  style: VoiceMockTypography.h1.copyWith(
                    color: VoiceMockColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: VoiceMockSpacing.md),

                // Rationale body text
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VoiceMockSpacing.md,
                  ),
                  child: Text(
                    'To practice interview answers with your voice, we need '
                    'access to your microphone. Your audio is processed to '
                    'create your personal interview experience.',
                    style: VoiceMockTypography.body.copyWith(
                      color: VoiceMockColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(flex: 3),

                // Primary CTA - Allow Microphone Access
                BlocBuilder<PermissionCubit, PermissionState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: state.isLoading
                            ? null
                            : () {
                                unawaited(
                                  context
                                      .read<PermissionCubit>()
                                      .requestPermission(),
                                );
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: VoiceMockColors.primary,
                          foregroundColor: VoiceMockColors.surface,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              VoiceMockRadius.md,
                            ),
                          ),
                          textStyle: VoiceMockTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: state.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: VoiceMockColors.surface,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Allow Microphone Access'),
                      ),
                    );
                  },
                ),

                const SizedBox(height: VoiceMockSpacing.md),

                // Secondary action - Not now
                TextButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: VoiceMockColors.textMuted,
                    textStyle: VoiceMockTypography.body,
                  ),
                  child: const Text('Not now'),
                ),

                const SizedBox(height: VoiceMockSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
