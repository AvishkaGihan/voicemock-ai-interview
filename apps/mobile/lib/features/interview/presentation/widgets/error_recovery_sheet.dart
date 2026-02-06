import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// Modal bottom sheet for error recovery.
///
/// Displays error details and recovery actions (Retry/Re-record/Cancel).
class ErrorRecoverySheet extends StatelessWidget {
  const ErrorRecoverySheet({
    required this.failure,
    super.key,
    this.onRetry,
    this.onReRecord,
    this.onCancel,
  });

  final InterviewFailure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onReRecord;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error icon
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error.withAlpha(204),
          ),
          const SizedBox(height: 16),

          // Error message
          Text(
            failure.message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Request ID (copyable)
          if (failure.requestId != null) ...[
            GestureDetector(
              onTap: () async {
                await Clipboard.setData(
                  ClipboardData(text: failure.requestId!),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Request ID copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.copy,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ID: ${failure.requestId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Action buttons
          if (failure.retryable && onRetry != null)
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          if (failure.retryable && onRetry != null) const SizedBox(height: 12),

          if (onReRecord != null)
            TextButton(
              onPressed: onReRecord,
              child: const Text('Re-record'),
            ),
          if (onReRecord != null) const SizedBox(height: 8),

          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }

  /// Show the error recovery sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required InterviewFailure failure,
    VoidCallback? onRetry,
    VoidCallback? onReRecord,
    VoidCallback? onCancel,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => ErrorRecoverySheet(
        failure: failure,
        onRetry: onRetry,
        onReRecord: onReRecord,
        onCancel: onCancel,
      ),
    );
  }
}
