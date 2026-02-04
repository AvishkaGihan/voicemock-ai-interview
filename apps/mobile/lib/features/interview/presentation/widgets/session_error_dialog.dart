import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text("Couldn't Start Session"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            failure.message,
            style: theme.textTheme.bodyMedium,
          ),
          if (failure.requestId != null) ...[
            const SizedBox(height: 12),
            Text(
              'Request ID: ${failure.requestId}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        if (failure.retryable)
          FilledButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
      ],
    );
  }
}
