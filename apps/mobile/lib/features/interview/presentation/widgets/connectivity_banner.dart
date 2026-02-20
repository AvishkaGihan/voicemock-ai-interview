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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: VoiceMockColors.warning.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: VoiceMockColors.warning.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off,
            color: VoiceMockColors.warning,
            size: 20,
          ),
          const SizedBox(width: 12),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
