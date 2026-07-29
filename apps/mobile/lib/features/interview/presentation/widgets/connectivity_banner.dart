import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicemock/core/connectivity/connectivity.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/l10n/l10n.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: VoiceMockSpacing.md,
        vertical: VoiceMockSpacing.md,
      ),
      decoration: BoxDecoration(
        color: VoiceMockColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
        border: Border.all(
          color: VoiceMockColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(VoiceMockSpacing.sm),
            decoration: BoxDecoration(
              color: VoiceMockColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(VoiceMockRadius.sm),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: VoiceMockColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: VoiceMockSpacing.md),
          Expanded(
            child: Text(
              l10n.internetConnectionRequired,
              style: VoiceMockTypography.small.copyWith(
                color: VoiceMockColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              unawaited(context.read<ConnectivityCubit>().checkConnectivity());
            },
            style: TextButton.styleFrom(
              foregroundColor: VoiceMockColors.warning,
              padding: const EdgeInsets.symmetric(
                horizontal: VoiceMockSpacing.md,
                vertical: VoiceMockSpacing.sm,
              ),
            ),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
