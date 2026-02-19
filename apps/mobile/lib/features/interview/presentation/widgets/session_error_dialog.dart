import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/failures.dart';

/// Dialog displaying session start errors with retry/cancel options.
class SessionErrorDialog extends StatelessWidget {
  const SessionErrorDialog({
    required this.failure,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  final InterviewFailure failure;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Couldn't Start Session",
        style: VoiceMockTypography.h3,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            failure.message,
            style: VoiceMockTypography.body,
          ),
          if (failure.requestId != null) ...[
            const SizedBox(height: VoiceMockSpacing.sm),
            Text(
              'Request ID: ${failure.requestId}',
              style: VoiceMockTypography.small.copyWith(
                color: VoiceMockColors.textMuted,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(
            foregroundColor: VoiceMockColors.textMuted,
          ),
          child: const Text('Cancel'),
        ),
        if (failure.retryable)
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: VoiceMockColors.primary,
              foregroundColor: VoiceMockColors.surface,
            ),
            child: const Text('Try Again'),
          ),
      ],
    );
  }
}
