/// Widget displaying last error summary with request ID and stage.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Displays the last error's request ID and stage.
///
/// Shown at the top of diagnostics when an error has occurred.
/// Allows copying request ID for troubleshooting.
class ErrorSummaryCard extends StatelessWidget {
  const ErrorSummaryCard({
    required this.requestId,
    required this.stage,
    super.key,
  });

  final String requestId;
  final String stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(VoiceMockSpacing.md),
      padding: const EdgeInsets.all(VoiceMockSpacing.md),
      decoration: BoxDecoration(
        color: VoiceMockColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(VoiceMockRadius.md),
        border: Border.all(
          color: VoiceMockColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: VoiceMockColors.error,
                size: 20,
              ),
              const SizedBox(width: VoiceMockSpacing.sm),
              Text(
                'Last Error',
                style: VoiceMockTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: VoiceMockColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.sm),

          // Stage
          Row(
            children: [
              Text(
                'Stage: ',
                style: VoiceMockTypography.small.copyWith(
                  fontWeight: FontWeight.w500,
                  color: VoiceMockColors.error.withValues(alpha: 0.8),
                ),
              ),
              Text(
                stage.toUpperCase(),
                style: VoiceMockTypography.small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: VoiceMockColors.error,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: VoiceMockSpacing.sm),

          // Request ID (tap to copy)
          GestureDetector(
            onTap: () => _copyRequestId(context),
            child: Row(
              children: [
                const Icon(
                  Icons.tag,
                  size: 14,
                  color: VoiceMockColors.error,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    requestId,
                    style: VoiceMockTypography.small.copyWith(
                      fontFamily: 'monospace',
                      color: VoiceMockColors.error,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.content_copy,
                  size: 14,
                  color: VoiceMockColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyRequestId(BuildContext context) {
    unawaited(Clipboard.setData(ClipboardData(text: requestId)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
